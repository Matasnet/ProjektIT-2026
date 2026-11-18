<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="text-h4 font-weight-bold">Grupy</h1>
        <div class="text-body-2 text-grey">Grupy przedszkolne – powiadomienia wysyłane są do grup</div>
      </div>
      <v-spacer />
      <v-btn color="primary" prepend-icon="mdi-plus" @click="openDialog()">Dodaj grupę</v-btn>
    </div>

    <v-card>
      <v-data-table :headers="headers" :items="groups" :loading="loading" no-data-text="Brak grup">
        <template #item.children="{ item }">
          {{ childrenCount[item.id] ?? 0 }}
        </template>
        <template #item.actions="{ item }">
          <v-btn icon="mdi-pencil" size="small" variant="text" @click="openDialog(item)" />
          <v-btn icon="mdi-delete" size="small" variant="text" color="error" @click="remove(item)" />
        </template>
      </v-data-table>
    </v-card>

    <v-dialog v-model="dialog" max-width="420">
      <v-card>
        <v-card-title>{{ editedId ? 'Edytuj grupę' : 'Nowa grupa' }}</v-card-title>
        <v-card-text>
          <v-text-field v-model="name" label="Nazwa grupy" autofocus @keyup.enter="save" />
          <v-alert v-if="error" type="error" variant="tonal" density="compact">{{ error }}</v-alert>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn @click="dialog = false">Anuluj</v-btn>
          <v-btn color="primary" variant="flat" :loading="saving" @click="save">Zapisz</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import {
  collection, onSnapshot, addDoc, updateDoc, deleteDoc, doc, orderBy, query, serverTimestamp,
} from 'firebase/firestore'
import { db } from '../firebase'

type Group = { id: string; name: string }
type Child = { id: string; groupId?: string | null }

const groups = ref<Group[]>([])
const children = ref<Child[]>([])
const loading = ref(true)

const dialog = ref(false)
const editedId = ref<string | null>(null)
const name = ref('')
const saving = ref(false)
const error = ref('')

const headers = [
  { title: 'Nazwa', key: 'name' },
  { title: 'Liczba dzieci', key: 'children', sortable: false },
  { title: '', key: 'actions', sortable: false, align: 'end' as const },
]

const childrenCount = computed(() => {
  const counts: Record<string, number> = {}
  for (const c of children.value) {
    if (c.groupId) counts[c.groupId] = (counts[c.groupId] ?? 0) + 1
  }
  return counts
})

const unsubs: (() => void)[] = []
onMounted(() => {
  unsubs.push(onSnapshot(query(collection(db, 'groups'), orderBy('name')), (snap) => {
    groups.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Group, 'id'>) }))
    loading.value = false
  }))
  unsubs.push(onSnapshot(collection(db, 'children'), (snap) => {
    children.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Child, 'id'>) }))
  }))
})
onUnmounted(() => unsubs.forEach((u) => u()))

const openDialog = (group?: Group) => {
  editedId.value = group?.id ?? null
  name.value = group?.name ?? ''
  error.value = ''
  dialog.value = true
}

const save = async () => {
  if (!name.value.trim()) {
    error.value = 'Podaj nazwę grupy'
    return
  }
  saving.value = true
  try {
    if (editedId.value) {
      await updateDoc(doc(db, 'groups', editedId.value), { name: name.value.trim() })
    } else {
      await addDoc(collection(db, 'groups'), { name: name.value.trim(), createdAt: serverTimestamp() })
    }
    dialog.value = false
  } catch (e: any) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}

const remove = async (group: Group) => {
  if ((childrenCount.value[group.id] ?? 0) > 0) {
    alert('Najpierw przenieś dzieci do innej grupy')
    return
  }
  if (!confirm(`Usunąć grupę "${group.name}"?`)) return
  await deleteDoc(doc(db, 'groups', group.id))
}
</script>
