<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="text-h4 font-weight-bold">Rodzice</h1>
        <div class="text-body-2 text-grey">Konta rodziców do aplikacji mobilnej</div>
      </div>
      <v-spacer />
      <v-btn color="primary" prepend-icon="mdi-plus" @click="openDialog">Dodaj rodzica</v-btn>
    </div>

    <v-card>
      <v-data-table :headers="headers" :items="parents" :loading="loading" no-data-text="Brak rodziców">
        <template #item.children="{ item }">
          {{ childrenOf(item.id) || '—' }}
        </template>
        <template #item.actions="{ item }">
          <v-btn icon="mdi-pencil-outline" size="small" variant="text" title="Edytuj" @click="openEdit(item)" />
          <v-btn
            icon="mdi-delete-outline"
            title="Usuń"
            size="small"
            variant="text"
            color="error"
            :loading="deletingId === item.id"
            @click="remove(item)"
          />
        </template>
      </v-data-table>
    </v-card>

    <v-dialog v-model="dialog" max-width="640">
      <v-card class="pa-2">
        <v-card-title class="font-weight-bold">Nowe konto rodzica</v-card-title>
        <v-card-text>
          <v-btn-toggle v-model="mode" mandatory color="primary" variant="outlined" rounded="pill" class="mb-5 mode-toggle">
            <v-btn value="one" prepend-icon="mdi-account-outline">Jeden rodzic</v-btn>
            <v-btn value="both" prepend-icon="mdi-account-multiple-outline">Oboje rodzice</v-btn>
          </v-btn-toggle>

          <v-autocomplete
            v-model="childId"
            :items="childItems"
            item-title="label"
            item-value="id"
            label="Przypisz do dziecka (opcjonalnie)"
            prepend-inner-icon="mdi-emoticon-happy-outline"
            clearable
            no-data-text="Brak dzieci"
            @update:model-value="fillLastName"
          />

          <div v-for="(p, i) in activeForms" :key="i" class="parent-form">
            <div class="parent-form-title">{{ mode === 'both' ? `Rodzic ${i + 1}` : 'Dane rodzica' }}</div>
            <v-row dense>
              <v-col cols="12" sm="6"><v-text-field v-model="p.firstName" label="Imię" @update:model-value="syncEmail(p)" /></v-col>
              <v-col cols="12" sm="6"><v-text-field v-model="p.lastName" label="Nazwisko" @update:model-value="syncEmail(p)" /></v-col>
            </v-row>
            <v-text-field
              v-model="p.email"
              label="Login (email)"
              prepend-inner-icon="mdi-email-outline"
              @update:model-value="p.emailEdited = true"
            >
              <template #append-inner>
                <v-btn icon="mdi-refresh" size="small" variant="text" title="Wygeneruj z imienia i nazwiska" @click="regenerateEmail(p)" />
              </template>
            </v-text-field>
            <v-text-field v-model="p.password" label="Hasło startowe" prepend-inner-icon="mdi-lock-outline" class="mono">
              <template #append-inner>
                <v-btn icon="mdi-dice-5-outline" size="small" variant="text" title="Wylosuj nowe hasło" @click="p.password = generatePassword()" />
              </template>
            </v-text-field>
          </div>

          <v-alert v-if="error" type="error" variant="tonal" density="compact">{{ error }}</v-alert>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="dialog = false">Anuluj</v-btn>
          <v-btn color="primary" variant="flat" :loading="saving" @click="save">
            {{ mode === 'both' ? 'Utwórz 2 konta' : 'Utwórz konto' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Edycja rodzica -->
    <v-dialog v-model="editDialog" max-width="560">
      <v-card class="pa-2">
        <v-card-title class="font-weight-bold">Edytuj rodzica</v-card-title>
        <v-card-text>
          <v-row dense>
            <v-col cols="12" sm="6"><v-text-field v-model="edit.firstName" label="Imię" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="edit.lastName" label="Nazwisko" /></v-col>
          </v-row>
          <v-text-field v-model="edit.email" label="Login (email)" prepend-inner-icon="mdi-email-outline">
            <template #append-inner>
              <v-btn
                icon="mdi-refresh"
                size="small"
                variant="text"
                title="Wygeneruj z imienia i nazwiska"
                @click="edit.email = generateEmail(edit.firstName, edit.lastName, editedParent?.email)"
              />
            </template>
          </v-text-field>
          <v-autocomplete
            v-model="edit.childIds"
            :items="childItems"
            item-title="label"
            item-value="id"
            label="Dzieci"
            prepend-inner-icon="mdi-emoticon-happy-outline"
            multiple
            chips
            closable-chips
            no-data-text="Brak dzieci"
          />

          <div class="parent-form">
            <div class="d-flex align-center">
              <div>
                <div class="parent-form-title mb-0">Hasło</div>
                <div class="text-caption text-grey-darken-1">
                  Obecnego hasła nie da się odczytać – Firebase przechowuje je zaszyfrowane. Możesz ustawić nowe.
                </div>
              </div>
              <v-switch
                v-model="edit.resetPassword"
                color="primary"
                hide-details
                inset
                class="ml-4 flex-grow-0"
                @update:model-value="onResetToggle"
              />
            </div>
            <v-text-field
              v-if="edit.resetPassword"
              v-model="edit.password"
              label="Nowe hasło"
              prepend-inner-icon="mdi-lock-outline"
              class="mono mt-3"
            >
              <template #append-inner>
                <v-btn icon="mdi-dice-5-outline" size="small" variant="text" title="Wylosuj nowe hasło" @click="edit.password = generatePassword()" />
              </template>
            </v-text-field>
            <div v-else class="pb-3" />
          </div>

          <v-alert v-if="error" type="error" variant="tonal" density="compact">{{ error }}</v-alert>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="editDialog = false">Anuluj</v-btn>
          <v-btn color="primary" variant="flat" :loading="saving" @click="saveEdit">Zapisz</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dane logowania do przekazania rodzicom -->
    <v-dialog v-model="resultDialog" max-width="520">
      <v-card class="pa-2">
        <v-card-title class="font-weight-bold">Dane logowania</v-card-title>
        <v-card-text>
          <div class="text-body-2 text-grey-darken-1 mb-4">
            Przekaż je rodzicom – logują się nimi w aplikacji Kinder Info. Hasło nie będzie już nigdzie widoczne.
          </div>
          <div v-for="c in created" :key="c.email" class="credentials">
            <div class="font-weight-bold mb-2">{{ c.firstName }} {{ c.lastName }}</div>
            <div class="cred-row"><span>Login</span><code>{{ c.email }}</code></div>
            <div class="cred-row"><span>Hasło</span><code>{{ c.password }}</code></div>
          </div>
          <v-alert v-if="error" type="warning" variant="tonal" density="compact" class="mt-2">{{ error }}</v-alert>
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" :prepend-icon="copied ? 'mdi-check' : 'mdi-content-copy'" @click="copyCredentials">
            {{ copied ? 'Skopiowano' : 'Kopiuj' }}
          </v-btn>
          <v-spacer />
          <v-btn color="primary" variant="flat" @click="resultDialog = false">Gotowe</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot, query, where, doc, updateDoc, arrayUnion, arrayRemove, writeBatch } from 'firebase/firestore'
import { httpsCallable } from 'firebase/functions'
import { db, functions } from '../firebase'
import { generatePassword, uniqueEmail } from '../accounts'

type Parent = { id: string; firstName: string; lastName: string; email: string }
type Child = { id: string; firstName: string; lastName: string; parentIds?: string[] }
type ParentForm = { firstName: string; lastName: string; email: string; password: string; emailEdited: boolean }
type Credentials = { firstName: string; lastName: string; email: string; password: string }

const parents = ref<Parent[]>([])
const children = ref<Child[]>([])
const loading = ref(true)

const dialog = ref(false)
const mode = ref<'one' | 'both'>('one')
const childId = ref<string | null>(null)
const forms = ref<ParentForm[]>([])
const saving = ref(false)
const error = ref('')
const deletingId = ref<string | null>(null)

const resultDialog = ref(false)
const created = ref<Credentials[]>([])
const copied = ref(false)

const headers = [
  { title: 'Imię', key: 'firstName' },
  { title: 'Nazwisko', key: 'lastName' },
  { title: 'Email', key: 'email' },
  { title: 'Dzieci', key: 'children', sortable: false },
  { title: '', key: 'actions', sortable: false, align: 'end' as const },
]

const childrenOf = (parentId: string) =>
  children.value
    .filter((c) => c.parentIds?.includes(parentId))
    .map((c) => `${c.firstName} ${c.lastName}`)
    .join(', ')

const childItems = computed(() =>
  children.value.map((c) => ({ id: c.id, label: `${c.firstName} ${c.lastName}` })),
)
const activeForms = computed(() => (mode.value === 'both' ? forms.value : forms.value.slice(0, 1)))

const unsubs: (() => void)[] = []
onMounted(() => {
  unsubs.push(onSnapshot(query(collection(db, 'users'), where('roles', 'array-contains', 'parent')), (snap) => {
    parents.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Parent, 'id'>) }))
    loading.value = false
  }))
  unsubs.push(onSnapshot(collection(db, 'children'), (snap) => {
    children.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Child, 'id'>) }))
  }))
})
onUnmounted(() => unsubs.forEach((u) => u()))

// Unikalny login – jeśli zajęty (w bazie lub w drugim formularzu), dopisuje numer
// ownEmail – obecny login edytowanego rodzica (nie liczy się jako zajęty)
const generateEmail = (firstName: string, lastName: string, ownEmail?: string, otherForm?: ParentForm) => {
  const taken = new Set([
    ...parents.value.map((x) => x.email.toLowerCase()).filter((e) => e !== ownEmail?.toLowerCase()),
    // drugi formularz w oknie dodawania (przy edycji go nie ma)
    ...(otherForm ? forms.value.filter((f) => f !== otherForm).map((f) => f.email.toLowerCase()) : []),
  ])
  return uniqueEmail(firstName, lastName, taken)
}

const syncEmail = (p: ParentForm) => {
  if (!p.emailEdited) p.email = generateEmail(p.firstName, p.lastName, undefined, p)
}
const regenerateEmail = (p: ParentForm) => {
  p.emailEdited = false
  p.email = generateEmail(p.firstName, p.lastName, undefined, p)
}

const emptyForm = (): ParentForm => ({
  firstName: '', lastName: '', email: '', password: generatePassword(), emailEdited: false,
})

// Po wyborze dziecka podpowiada nazwisko rodzicom, którzy go jeszcze nie mają
const fillLastName = (id: string | null) => {
  const child = children.value.find((c) => c.id === id)
  if (!child) return
  for (const p of forms.value) {
    if (!p.lastName.trim()) {
      p.lastName = child.lastName
      syncEmail(p)
    }
  }
}

const openDialog = () => {
  mode.value = 'one'
  childId.value = null
  forms.value = [emptyForm(), emptyForm()]
  error.value = ''
  dialog.value = true
}

// Konto Auth tworzy Cloud Function – klient nie może tworzyć kont innym osobom
const save = async () => {
  const toCreate = activeForms.value
  for (const p of toCreate) {
    if (!p.firstName.trim() || !p.lastName.trim() || !p.email.trim()) {
      error.value = 'Wypełnij imię, nazwisko i login'
      return
    }
    if (p.password.length < 6) {
      error.value = 'Hasło musi mieć min. 6 znaków'
      return
    }
  }
  saving.value = true
  error.value = ''
  created.value = []
  const uids: string[] = []
  try {
    for (const p of toCreate) {
      const data = {
        firstName: p.firstName.trim(),
        lastName: p.lastName.trim(),
        email: p.email.trim().toLowerCase(),
        password: p.password,
      }
      const res = await httpsCallable<typeof data, { uid: string }>(functions, 'createParentAccount')(data)
      uids.push(res.data.uid)
      created.value.push(data)
    }
  } catch (e: any) {
    error.value = created.value.length
      ? `Utworzono tylko część kont: ${e.message || 'błąd'}`
      : e.message || 'Nie udało się utworzyć konta'
  }

  // Powiązanie dziecko ↔ rodzic tylko przez children.parentIds
  if (childId.value && uids.length) {
    try {
      await updateDoc(doc(db, 'children', childId.value), { parentIds: arrayUnion(...uids) })
    } catch (e: any) {
      error.value = `Konta utworzone, ale nie udało się przypisać dziecka: ${e.message}`
    }
  }

  saving.value = false
  if (created.value.length) {
    dialog.value = false
    copied.value = false
    resultDialog.value = true
  }
}

// ===== Edycja =====
const editDialog = ref(false)
const editedParent = ref<Parent | null>(null)
const edit = ref({
  firstName: '', lastName: '', email: '', childIds: [] as string[], resetPassword: false, password: '',
})

const onResetToggle = (on: boolean | null) => {
  if (on && !edit.value.password) edit.value.password = generatePassword()
}

const openEdit = (parent: Parent) => {
  editedParent.value = parent
  edit.value = {
    firstName: parent.firstName,
    lastName: parent.lastName,
    email: parent.email,
    childIds: children.value.filter((c) => c.parentIds?.includes(parent.id)).map((c) => c.id),
    resetPassword: false,
    password: '',
  }
  error.value = ''
  editDialog.value = true
}

// Login, imię, nazwisko i hasło zmienia Cloud Function (Auth wymaga Admin SDK),
// przypisanie dzieci – zapis w children.parentIds
const saveEdit = async () => {
  const parent = editedParent.value
  if (!parent) return
  const e = edit.value
  if (!e.firstName.trim() || !e.lastName.trim() || !e.email.trim()) {
    error.value = 'Wypełnij imię, nazwisko i login'
    return
  }
  if (e.resetPassword && e.password.length < 6) {
    error.value = 'Hasło musi mieć min. 6 znaków'
    return
  }
  saving.value = true
  error.value = ''
  try {
    const data = {
      parentId: parent.id,
      firstName: e.firstName.trim(),
      lastName: e.lastName.trim(),
      email: e.email.trim().toLowerCase(),
      ...(e.resetPassword ? { password: e.password } : {}),
    }
    await httpsCallable(functions, 'updateParentAccount')(data)

    const before = children.value.filter((c) => c.parentIds?.includes(parent.id)).map((c) => c.id)
    const added = e.childIds.filter((id) => !before.includes(id))
    const removed = before.filter((id) => !e.childIds.includes(id))
    if (added.length || removed.length) {
      const batch = writeBatch(db)
      added.forEach((id) => batch.update(doc(db, 'children', id), { parentIds: arrayUnion(parent.id) }))
      removed.forEach((id) => batch.update(doc(db, 'children', id), { parentIds: arrayRemove(parent.id) }))
      await batch.commit()
    }

    editDialog.value = false
    if (e.resetPassword) {
      created.value = [{ firstName: data.firstName, lastName: data.lastName, email: data.email, password: e.password }]
      copied.value = false
      resultDialog.value = true
    }
  } catch (err: any) {
    error.value = err.message || 'Nie udało się zapisać zmian'
  } finally {
    saving.value = false
  }
}

const copyCredentials = async () => {
  const text = created.value
    .map((c) => `${c.firstName} ${c.lastName}\nLogin: ${c.email}\nHasło: ${c.password}`)
    .join('\n\n')
  await navigator.clipboard.writeText(text)
  copied.value = true
}

const remove = async (parent: Parent) => {
  if (!confirm(`Usunąć konto ${parent.firstName} ${parent.lastName}?`)) return
  deletingId.value = parent.id
  try {
    await httpsCallable(functions, 'deleteParentAccount')({ parentId: parent.id })
  } catch (e: any) {
    alert(e.message || 'Nie udało się usunąć konta')
  } finally {
    deletingId.value = null
  }
}
</script>

<style scoped>
/* Przełącznik "Jeden / Oboje" mieści się na wąskim ekranie */
.mode-toggle {
  max-width: 100%;
}
.mode-toggle .v-btn {
  flex: 1 1 0;
  min-width: 0;
}
.parent-form {
  padding: 16px 16px 4px;
  margin-bottom: 16px;
  border: 2px solid #f3e6d3;
  border-radius: 20px;
}
.parent-form-title {
  font-weight: 800;
  margin-bottom: 12px;
}
.mono :deep(input),
.credentials code {
  font-family: ui-monospace, 'JetBrains Mono', monospace;
  letter-spacing: 0.04em;
}
.credentials {
  padding: 16px;
  margin-bottom: 12px;
  border-radius: 20px;
  background: #f7f1e8;
}
.cred-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 4px 0;
}
.cred-row span {
  width: 56px;
  flex-shrink: 0;
  color: #78716c;
  font-size: 0.85rem;
}
.cred-row code {
  font-size: 1rem;
  font-weight: 700;
  background: #ffffff;
  padding: 2px 10px;
  border-radius: 8px;
  word-break: break-all;
}
</style>
