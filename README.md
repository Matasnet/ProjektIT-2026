# Kinder Info

System informacyjny dla przedszkola – projekt na przedmiot **Projekt IT**.

| Aplikacja | Technologia | Dla kogo | Funkcje |
|---|---|---|---|
| [`kinder_admin/`](kinder_admin) | Vue 3 + Vuetify + Vite (web, responsywny) | administrator i dyrektor | grupy, dzieci, konta rodziców, powiadomienia push, jadłospis, płatności, konta dyrektorów |
| [`kinder_parent/`](kinder_parent) | Flutter + Cubit (Android/iOS) | rodzic | dzieci, powiadomienia push, jadłospis, opłaty |

Obie aplikacje korzystają z jednego projektu **Firebase**: Authentication, Cloud Firestore, Cloud Functions i Cloud Messaging.

---

## Spis treści
- [Struktura repozytorium](#struktura-repozytorium)
- [Wymagania](#wymagania)
- [Uruchomienie krok po kroku](#uruchomienie-krok-po-kroku)
  - [1. Projekt Firebase](#1-projekt-firebase)
  - [2. Reguły i Cloud Functions](#2-reguły-i-cloud-functions)
  - [3. Pierwszy administrator](#3-pierwszy-administrator)
  - [4. Panel administracyjny](#4-panel-administracyjny-kinder_admin)
  - [5. Aplikacja rodzica](#5-aplikacja-rodzica-kinder_parent)
- [Scenariusz demonstracyjny](#scenariusz-demonstracyjny)
- [Praca lokalna na emulatorach Firebase](#praca-lokalna-na-emulatorach-firebase)
- [Najczęstsze problemy](#najczęstsze-problemy)

---

## Struktura repozytorium

```
kinder_info/
├── README.md                ← ten plik
├── firebase.json            ← konfiguracja Firebase CLI (funkcje, reguły, hosting, emulatory)
├── .firebaserc.example      ← wzór pliku z ID projektu Firebase
├── firestore.rules          ← reguły bezpieczeństwa bazy
├── firestore.indexes.json
├── functions/               ← Cloud Functions (TypeScript)
├── kinder_admin/            ← panel administracyjny (Vue)
└── kinder_parent/           ← aplikacja rodzica (Flutter)
```

**Pliki z kluczami nie są w repozytorium** (są w `.gitignore`) – trzeba je utworzyć lokalnie według instrukcji poniżej:

| Plik | Skąd go wziąć |
|---|---|
| `.firebaserc` | kopia `.firebaserc.example` z ID projektu |
| `kinder_admin/.env.local` | kopia `kinder_admin/.env.example` z konfiguracją aplikacji Web |
| `kinder_parent/lib/firebase_options.dart`, `kinder_parent/android/app/google-services.json` | generuje `flutterfire configure` |

---

## Wymagania

| Narzędzie | Wersja | Instalacja |
|---|---|---|
| Node.js | 22+ | [nodejs.org](https://nodejs.org) |
| Firebase CLI | aktualna | `npm install -g firebase-tools`, potem `firebase login` |
| Flutter | 3.38+ (Dart 3.10+) | [docs.flutter.dev](https://docs.flutter.dev/get-started/install); na Ubuntu: `sudo snap install flutter --classic` |
| Android Studio | aktualne | z Android SDK i **Android SDK Command-line Tools** (SDK Manager → SDK Tools) |
| FlutterFire CLI | aktualne | `dart pub global activate flutterfire_cli` i dodaj `~/.pub-cache/bin` do `PATH` |

Sprawdzenie: `flutter doctor` – przy **Android toolchain** ma być ✓ (błędy dotyczące Linux/Windows desktop można zignorować).

---

## Uruchomienie krok po kroku

```bash
git clone <adres-repozytorium> kinder_info
cd kinder_info
```

### 1. Projekt Firebase
Jednorazowo, w [Firebase Console](https://console.firebase.google.com):
1. Utwórz projekt (np. `kinder-info`).
2. **Authentication** → Sign-in method → włącz **Email/Password**.
3. **Firestore Database** → utwórz bazę (region np. `europe-central2`).
4. Przełącz projekt na plan **Blaze** – wymagają go Cloud Functions. Przy ruchu projektu studenckiego mieści się w darmowym limicie; warto ustawić alert budżetu.

Potem w głównym folderze repozytorium:
```bash
cp .firebaserc.example .firebaserc     # wpisz w nim ID swojego projektu
```

### 2. Reguły i Cloud Functions
```bash
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions
```
Nowe reguły zaczynają działać po ok. minucie.

### 3. Pierwszy administrator
Konta rodziców i dyrektorów zakłada się później w panelu – pierwszego administratora trzeba dodać ręcznie w Firebase Console:

1. **Authentication** → **Users** → **Add user** – wpisz email (np. `admin@kinder.pl`) i hasło. Skopiuj **User UID** nowego konta.
2. **Firestore Database** → **Start collection** (albo wejdź w istniejącą kolekcję) `users` → **Add document**:
   - **Document ID:** wklejony User UID,
   - pola:

     | Pole | Typ | Wartość |
     |---|---|---|
     | `firstName` | string | np. `Jan` |
     | `lastName` | string | np. `Kowalski` |
     | `email` | string | ten sam email co w Authentication |
     | `roles` | array | jeden element typu string: `admin` |
     | `createdAt` | timestamp | dzisiejsza data |

Bez dokumentu w `users` z rolą `admin` panel wyloguje konto z komunikatem „Brak uprawnień”.

### 4. Panel administracyjny (`kinder_admin`)
1. Firebase Console → Ustawienia projektu → *Twoje aplikacje* → dodaj aplikację **Web** i skopiuj jej konfigurację.
2. Uruchom:
   ```bash
   cd kinder_admin
   cp .env.example .env.local     # wklej wartości apiKey, authDomain, projectId…
   npm install
   npm run dev                    # http://localhost:5173
   ```
3. Zaloguj się kontem administratora z kroku 3.
4. Ustaw dane startowe w panelu:
   - **Płatności → Ustawienia opłaty** – kwota miesięczna, termin, odbiorca i numer konta,
   - **Jadłospis** – posiłki na bieżący tydzień (kolejne tygodnie najszybciej przez *Kopiuj poprzedni tydzień*),
   - **Grupy**, **Dzieci** i **Rodzice** – jak w [scenariuszu demonstracyjnym](#scenariusz-demonstracyjny).

Build produkcyjny i hosting (opcjonalnie): `npm run build`, potem w głównym folderze `firebase deploy --only hosting`.

### 5. Aplikacja rodzica (`kinder_parent`)
1. Połącz aplikację z projektem Firebase (tworzy `firebase_options.dart` i `google-services.json`):
   ```bash
   cd kinder_parent
   flutterfire configure --project=TWOJ-PROJECT-ID --platforms=android
   flutter pub get
   ```
2. Uruchom urządzenie:
   - **emulator:** Android Studio → Device Manager → utwórz urządzenie z obrazem **Google Play** (bez niego push nie działa) i uruchom je, albo `flutter emulators --launch <id>`;
   - **telefon:** włącz Opcje programisty → Debugowanie USB i podłącz kablem.
3. Uruchom aplikację:
   ```bash
   flutter devices              # na liście musi być telefon lub emulator Android
   flutter run                  # r = hot reload, R = restart, q = wyjście
   ```
   Pierwsze budowanie trwa kilka minut (Gradle pobiera zależności).
4. Zaloguj się kontem **rodzica** – załóż je w panelu (**Rodzice → Dodaj rodzica**) i przypisz do dziecka. Konto administratora nie wejdzie do aplikacji.

> **iOS:** push wymaga konta Apple Developer i klucza APNs w Firebase Console → Cloud Messaging. Do prezentacji najprościej używać Androida.

---

## Scenariusz demonstracyjny
1. Panel: **Grupy** → dodaj grupę, **Dzieci** → dodaj dziecko do grupy, **Rodzice** → załóż konto rodzica i przypisz dziecko (panel pokaże login i hasło do przekazania).
2. Telefon: zaloguj się danymi rodzica i zezwól na powiadomienia.
3. Panel: **Powiadomienia** → odbiorcy: grupa dziecka → **Wyślij**. Zminimalizuj aplikację – pojawi się push.
4. Panel: **Jadłospis** → zmień dzisiejszy obiad – aplikacja pokaże go w banerze na ekranie Start.
5. Panel: **Płatności** → **Oznacz jako opłacone** – w aplikacji status i baner zmienią się na zielone.

---

## Praca lokalna na emulatorach Firebase
Bez chmury (np. do testów reguł):
```bash
# terminal 1 – w głównym folderze
cd functions && npm run build && cd ..
firebase emulators:start                       # UI: http://localhost:4000

# terminal 2 – panel (w kinder_admin/.env.local ustaw VITE_USE_EMULATORS=true)
cd kinder_admin && npm run dev

# terminal 3 – aplikacja
cd kinder_parent && flutter run --dart-define=USE_EMULATORS=true

```
Administratora w emulatorze dodaj tak jak w [kroku 3](#3-pierwszy-administrator), tylko w interfejsie emulatora (http://localhost:4000 → Authentication, potem Firestore).
Emulator nie wysyła prawdziwych powiadomień push – push testuj na prawdziwym projekcie.

---

## Najczęstsze problemy

| Objaw | Rozwiązanie |
|---|---|
| `flutter run` nie widzi urządzenia, tylko Chrome/Linux | uruchom emulator Androida albo podłącz telefon z debugowaniem USB |
| `Android sdkmanager not found` | Android Studio → SDK Manager → SDK Tools → zaznacz **Android SDK Command-line Tools**, potem `flutter config --android-sdk ~/Android/Sdk` |
| `flutterfire: command not found` | dodaj do `PATH`: `export PATH="$PATH:$HOME/.pub-cache/bin"` (najlepiej w `~/.bashrc`) |
| Emulator nie startuje: *not enough disk space* | zwolnij miejsce na dysku (emulator potrzebuje kilku GB) |
| Błąd kompilacji: brak `firebase_options.dart` | uruchom `flutterfire configure` (krok 5) |
| Aplikacja: puste zakładki / *PERMISSION_DENIED* | wdróż reguły (`firebase deploy --only firestore:rules`), odczekaj minutę i uruchom aplikację ponownie |
| Panel: biała strona lub błąd Firebase | sprawdź wartości w `kinder_admin/.env.local` |
| Rodzic nie może się zalogować do panelu / admin do aplikacji | to zamierzone – panel jest dla admina i dyrektora, aplikacja tylko dla rodziców |
