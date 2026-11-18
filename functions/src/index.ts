import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();
const auth = getAuth();
const REGION = "europe-central2";

// ============================================
// HELPER: Sprawdź rolę wywołującego
// admin    – wszystko, w tym konta dyrektorów
// director – grupy, dzieci, rodzice, powiadomienia (jak admin, bez dyrektorów)
// ============================================
async function assertRole(request: CallableRequest, allowed: string[]): Promise<void> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Musisz być zalogowany");
  }
  const callerDoc = await db.collection("users").doc(request.auth.uid).get();
  const roles: string[] = callerDoc.data()?.roles ?? [];
  if (!roles.some((r) => allowed.includes(r))) {
    throw new HttpsError("permission-denied", "Brak uprawnień");
  }
}

const assertAdmin = (request: CallableRequest) => assertRole(request, ["admin"]);
const assertStaff = (request: CallableRequest) => assertRole(request, ["admin", "director"]);

type AccountData = { firstName: string; lastName: string; email: string; password?: string };

// ============================================
// HELPER: Utwórz konto z rolą (Auth + users/{uid})
// ============================================
async function createAccount(data: AccountData, role: string): Promise<string> {
  const { firstName, lastName, email, password } = data;

  if (!firstName || !lastName || !email || !password) {
    throw new HttpsError("invalid-argument", "Wymagane: imię, nazwisko, email, hasło");
  }
  if (password.length < 6) {
    throw new HttpsError("invalid-argument", "Hasło musi mieć min. 6 znaków");
  }

  let uid: string;
  try {
    const user = await auth.createUser({
      email: email.trim(),
      password,
      displayName: `${firstName} ${lastName}`,
    });
    uid = user.uid;
  } catch (error: unknown) {
    const authError = error as { code?: string; message?: string };
    if (authError.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Email jest już używany");
    }
    throw new HttpsError("internal", `Błąd tworzenia konta: ${authError.message}`);
  }

  await db.collection("users").doc(uid).set({
    firstName,
    lastName,
    email: email.trim(),
    roles: [role],
    createdAt: FieldValue.serverTimestamp(),
  });

  return uid;
}

// ============================================
// HELPER: Edytuj konto z daną rolą (Auth + users/{uid})
// Konta z inną rolą nie da się zmienić – np. dyrektor nie zmieni danych admina.
// Starego hasła nie da się odczytać – Firebase przechowuje tylko jego skrót.
// ============================================
async function updateAccount(uid: string, data: AccountData, role: string): Promise<void> {
  const { firstName, lastName, email, password } = data;

  if (!uid || !firstName || !lastName || !email) {
    throw new HttpsError("invalid-argument", "Wymagane: ID, imię, nazwisko, email");
  }
  if (password && password.length < 6) {
    throw new HttpsError("invalid-argument", "Hasło musi mieć min. 6 znaków");
  }

  const userRef = db.collection("users").doc(uid);
  const roles: string[] = (await userRef.get()).data()?.roles ?? [];
  if (!roles.includes(role)) {
    throw new HttpsError("not-found", "Nie znaleziono konta");
  }

  try {
    await auth.updateUser(uid, {
      email: email.trim(),
      displayName: `${firstName} ${lastName}`,
      ...(password ? { password } : {}),
    });
  } catch (error: unknown) {
    const authError = error as { code?: string; message?: string };
    if (authError.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Email jest już używany");
    }
    throw new HttpsError("internal", `Błąd edycji konta: ${authError.message}`);
  }

  await userRef.update({ firstName, lastName, email: email.trim() });
}

// ============================================
// HELPER: Sprawdź rolę konta i usuń je z Auth
// (dokument users/{uid} usuwa wywołujący – rodzic wymaga jeszcze sprzątania dzieci)
// ============================================
async function deleteAuthAccount(uid: string, role: string): Promise<void> {
  if (!uid) {
    throw new HttpsError("invalid-argument", "Brak ID konta");
  }
  const roles: string[] = (await db.collection("users").doc(uid).get()).data()?.roles ?? [];
  if (!roles.includes(role)) {
    throw new HttpsError("not-found", "Nie znaleziono konta");
  }

  try {
    await auth.deleteUser(uid);
  } catch (error: unknown) {
    const authError = error as { code?: string; message?: string };
    if (authError.code !== "auth/user-not-found") {
      throw new HttpsError("internal", `Błąd usuwania konta: ${authError.message}`);
    }
  }
}

// ============================================
// CLOUD FUNCTION: Utwórz konto rodzica (Auth + Firestore)
// Admin lub dyrektor podaje dane i hasło startowe, rodzic loguje się w aplikacji mobilnej.
// ============================================
export const createParentAccount = onCall({ region: REGION }, async (request) => {
  await assertStaff(request);
  const uid = await createAccount(request.data as AccountData, "parent");
  return { success: true, uid };
});

// ============================================
// CLOUD FUNCTION: Edytuj konto rodzica (Auth + Firestore)
// Zmiana imienia, nazwiska, loginu (email) i opcjonalnie nowe hasło.
// ============================================
export const updateParentAccount = onCall({ region: REGION }, async (request) => {
  await assertStaff(request);
  const { parentId, ...data } = request.data as AccountData & { parentId: string };
  await updateAccount(parentId, data, "parent");
  return { success: true };
});

// ============================================
// CLOUD FUNCTION: Usuń konto rodzica (Auth + Firestore)
// Dodatkowo usuwa rodzica z listy parentIds u dzieci.
// ============================================
export const deleteParentAccount = onCall({ region: REGION }, async (request) => {
  await assertStaff(request);

  const { parentId } = request.data as { parentId: string };
  await deleteAuthAccount(parentId, "parent");

  const children = await db.collection("children")
    .where("parentIds", "array-contains", parentId).get();
  const batch = db.batch();
  children.forEach((child) => {
    batch.update(child.ref, { parentIds: FieldValue.arrayRemove(parentId) });
  });
  batch.delete(db.collection("users").doc(parentId));
  await batch.commit();

  return { success: true };
});

// ============================================
// CLOUD FUNCTIONS: Konta dyrektorów – tylko admin
// Dyrektor loguje się do panelu i zarządza grupami, dziećmi, rodzicami i powiadomieniami.
// ============================================
export const createDirectorAccount = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);
  const uid = await createAccount(request.data as AccountData, "director");
  return { success: true, uid };
});

export const updateDirectorAccount = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);
  const { directorId, ...data } = request.data as AccountData & { directorId: string };
  await updateAccount(directorId, data, "director");
  return { success: true };
});

export const deleteDirectorAccount = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);
  const { directorId } = request.data as { directorId: string };
  await deleteAuthAccount(directorId, "director");
  await db.collection("users").doc(directorId).delete();
  return { success: true };
});

// ============================================
// CLOUD FUNCTION: Wyślij powiadomienie push (FCM Topics)
// Trigger: nowy dokument w kolekcji notifications/
// groupId = 'all'  → topic 'all_parents'
// groupId = <id>   → topic 'group_<id>'
// (ID dokumentów Firestore zawierają tylko znaki dozwolone w nazwie topica)
// ============================================
export const sendNotification = onDocumentCreated(
  { document: "notifications/{notificationId}", region: REGION },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const { title, body, groupId } = snapshot.data();

    if (!title || !body || !groupId) {
      await snapshot.ref.update({
        status: "error",
        error: "Brak wymaganych pól: title, body, groupId",
      });
      return;
    }

    const topic = groupId === "all" ? "all_parents" : `group_${groupId}`;

    try {
      await getMessaging().send({
        topic,
        notification: { title, body },
      });
      await snapshot.ref.update({
        topic,
        status: "sent",
        sentAt: FieldValue.serverTimestamp(),
      });
    } catch (error: unknown) {
      const fcmError = error as { message?: string };
      await snapshot.ref.update({
        topic,
        status: "error",
        error: fcmError.message ?? "Nieznany błąd FCM",
      });
    }
  }
);
