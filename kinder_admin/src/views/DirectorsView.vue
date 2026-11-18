<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="text-h4 font-weight-bold">Dyrektorzy</h1>
        <div class="text-body-2 text-grey">Zarządzają grupami, dziećmi, rodzicami i powiadomieniami</div>
      </div>
      <v-spacer />
      <v-btn color="primary" prepend-icon="mdi-plus" @click="openCreate">Dodaj dyrektora</v-btn>
    </div>

    <v-card>
      <v-data-table
        :headers="headers"
        :items="directors"
        :loading="loading"
        no-data-text="Brak dyrektorów"
      >
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

    <!-- Dodawanie i edycja dyrektora -->
    <v-dialog v-model="dialog" max-width="560">
      <v-card class="pa-2">
        <v-card-title class="font-weight-bold">{{ editedId ? 'Edytuj dyrektora' : 'Nowe konto dyrektora' }}</v-card-title>
        <v-card-text>
          <v-row dense>
            <v-col cols="12" sm="6"><v-text-field v-model="form.firstName" label="Imię" @update:model-value="syncEmail" /></v-col>
            <v-col cols="12" sm="6"><v-text-field v-model="form.lastName" label="Nazwisko" @update:model-value="syncEmail" /></v-col>
          </v-row>
          <v-text-field
            v-model="form.email"
            label="Login (email)"
            prepend-inner-icon="mdi-email-outline"
            @update:model-value="form.emailEdited = true"
          >
            <template #append-inner>
              <v-btn icon="mdi-refresh" size="small" variant="text" title="Wygeneruj z imienia i nazwiska" @click="regenerateEmail" />
            </template>
          </v-text-field>

          <div v-if="editedId" class="d-flex align-center mb-3">
            <div class="text-body-2 text-grey-darken-1">
              Obecnego hasła nie da się odczytać. Możesz ustawić nowe.
            </div>
            <v-switch v-model="form.resetPassword" color="primary" hide-details inset class="ml-4 flex-grow-0" @update:model-value="onResetToggle" />
          </div>
          <v-text-field
            v-if="!editedId || form.resetPassword"
            v-model="form.password"
            :label="editedId ? 'Nowe hasło' : 'Hasło startowe'"
            prepend-inner-icon="mdi-lock-outline"
            class="mono"
          >
            <template #append-inner>
              <v-btn icon="mdi-dice-5-outline" size="small" variant="text" title="Wylosuj nowe hasło" @click="form.password = generatePassword()" />
            </template>
          </v-text-field>

          <v-alert v-if="error" type="error" variant="tonal" density="compact">{{ error }}</v-alert>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="dialog = false">Anuluj</v-btn>
          <v-btn color="primary" variant="flat" :loading="saving" @click="save">
            {{ editedId ? 'Zapisz' : 'Utwórz konto' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dane logowania do przekazania dyrektorowi -->
    <v-dialog v-model="resultDialog" max-width="520">
      <v-card v-if="credentials" class="pa-2">
        <v-card-title class="font-weight-bold">Dane logowania</v-card-title>
        <v-card-text>
          <div class="text-body-2 text-grey-darken-1 mb-4">
            Przekaż je dyrektorowi – loguje się nimi do tego panelu. Hasło nie będzie już nigdzie widoczne.
          </div>
          <div class="credentials">
            <div class="font-weight-bold mb-2">{{ credentials.firstName }} {{ credentials.lastName }}</div>
            <div class="cred-row"><span>Login</span><code>{{ credentials.email }}</code></div>
            <div class="cred-row"><span>Hasło</span><code>{{ credentials.password }}</code></div>
          </div>
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
import { ref, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot, query, where } from 'firebase/firestore'
import { httpsCallable } from 'firebase/functions'
import { db, functions } from '../firebase'
import { generatePassword, uniqueEmail } from '../accounts'

type Director = { id: string; firstName: string; lastName: string; email: string }
type Credentials = { firstName: string; lastName: string; email: string; password: string }

const directors = ref<Director[]>([])
const loading = ref(true)
const deletingId = ref<string | null>(null)

const dialog = ref(false)
const editedId = ref<string | null>(null)
const form = ref({ firstName: '', lastName: '', email: '', password: '', emailEdited: false, resetPassword: false })
const saving = ref(false)
const error = ref('')

const resultDialog = ref(false)
const credentials = ref<Credentials | null>(null)
const copied = ref(false)

const headers = [
  { title: 'Imię', key: 'firstName' },
  { title: 'Nazwisko', key: 'lastName' },
  { title: 'Email', key: 'email' },
  { title: '', key: 'actions', sortable: false, align: 'end' as const },
]

let unsub: (() => void) | undefined
onMounted(() => {
  unsub = onSnapshot(query(collection(db, 'users'), where('roles', 'array-contains', 'director')), (snap) => {
    directors.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Director, 'id'>) }))
    loading.value = false
  })
})
onUnmounted(() => unsub?.())

// Login z imienia i nazwiska – pomija obecny login edytowanego dyrektora
const generateEmail = () => {
  const own = directors.value.find((d) => d.id === editedId.value)?.email.toLowerCase()
  const taken = new Set(directors.value.map((d) => d.email.toLowerCase()).filter((e) => e !== own))
  return uniqueEmail(form.value.firstName, form.value.lastName, taken)
}
const syncEmail = () => {
  if (!form.value.emailEdited) form.value.email = generateEmail()
}
const regenerateEmail = () => {
  form.value.emailEdited = false
  form.value.email = generateEmail()
}

const onResetToggle = (on: boolean | null) => {
  if (on && !form.value.password) form.value.password = generatePassword()
}

const openCreate = () => {
  editedId.value = null
  form.value = { firstName: '', lastName: '', email: '', password: generatePassword(), emailEdited: false, resetPassword: false }
  error.value = ''
  dialog.value = true
}

const openEdit = (d: Director) => {
  editedId.value = d.id
  form.value = { firstName: d.firstName, lastName: d.lastName, email: d.email, password: '', emailEdited: true, resetPassword: false }
  error.value = ''
  dialog.value = true
}

// Konta w Auth tworzy i zmienia Cloud Function (tylko admin)
const save = async () => {
  const f = form.value
  const setsPassword = !editedId.value || f.resetPassword
  if (!f.firstName.trim() || !f.lastName.trim() || !f.email.trim()) {
    error.value = 'Wypełnij imię, nazwisko i login'
    return
  }
  if (setsPassword && f.password.length < 6) {
    error.value = 'Hasło musi mieć min. 6 znaków'
    return
  }
  saving.value = true
  error.value = ''
  const data = {
    firstName: f.firstName.trim(),
    lastName: f.lastName.trim(),
    email: f.email.trim().toLowerCase(),
    ...(setsPassword ? { password: f.password } : {}),
  }
  try {
    if (editedId.value) {
      await httpsCallable(functions, 'updateDirectorAccount')({ directorId: editedId.value, ...data })
    } else {
      await httpsCallable(functions, 'createDirectorAccount')(data)
    }
    dialog.value = false
    if (setsPassword) {
      credentials.value = { firstName: data.firstName, lastName: data.lastName, email: data.email, password: f.password }
      copied.value = false
      resultDialog.value = true
    }
  } catch (e: any) {
    error.value = e.message || 'Nie udało się zapisać'
  } finally {
    saving.value = false
  }
}

const copyCredentials = async () => {
  const c = credentials.value
  if (!c) return
  await navigator.clipboard.writeText(`${c.firstName} ${c.lastName}\nLogin: ${c.email}\nHasło: ${c.password}`)
  copied.value = true
}

const remove = async (d: Director) => {
  if (!confirm(`Usunąć konto dyrektora ${d.firstName} ${d.lastName}?`)) return
  deletingId.value = d.id
  try {
    await httpsCallable(functions, 'deleteDirectorAccount')({ directorId: d.id })
  } catch (e: any) {
    alert(e.message || 'Nie udało się usunąć konta')
  } finally {
    deletingId.value = null
  }
}
</script>

<style scoped>
.mono :deep(input),
.credentials code {
  font-family: ui-monospace, 'JetBrains Mono', monospace;
  letter-spacing: 0.04em;
}
.credentials {
  padding: 16px;
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
