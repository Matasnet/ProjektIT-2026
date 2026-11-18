<template>
  <div>
    <div class="header">
      <div>
        <h1 class="title">Dzieci</h1>
        <div class="subtitle">Przypisz dziecko do grupy i rodziców</div>
      </div>
      <v-spacer />
      <div class="search">
        <v-icon size="20" color="grey-darken-1">mdi-magnify</v-icon>
        <input v-model="search" type="text" placeholder="Szukaj dziecka…" />
      </div>
      <v-btn color="primary" size="x-large" prepend-icon="mdi-plus" @click="openDialog()">Dodaj dziecko</v-btn>
    </div>

    <div class="filters">
      <button class="filter filter-all" :class="{ active: !groupFilter }" @click="groupFilter = null">
        Wszystkie <span class="count">{{ children.length }}</span>
      </button>
      <button
        v-for="g in groups"
        :key="g.id"
        class="filter"
        :class="{ active: groupFilter === g.id }"
        :style="{ background: colorOf(g.id).bg, color: colorOf(g.id).text }"
        @click="groupFilter = groupFilter === g.id ? null : g.id"
      >
        {{ g.name }} <span class="count">{{ countIn(g.id) }}</span>
      </button>
      <v-spacer />
      <div class="view-toggle" role="group" aria-label="Widok">
        <button :class="{ active: view === 'table' }" title="Tabela" @click="view = 'table'">
          <v-icon size="20">mdi-format-list-bulleted</v-icon>
        </button>
        <button :class="{ active: view === 'cards' }" title="Kafelki" @click="view = 'cards'">
          <v-icon size="20">mdi-view-grid-outline</v-icon>
        </button>
      </div>
    </div>

    <div v-if="loading" class="d-flex justify-center pa-12">
      <v-progress-circular indeterminate color="primary" />
    </div>
    <div v-else-if="!visibleChildren.length" class="empty">
      {{ children.length ? 'Brak dzieci pasujących do filtra' : 'Brak dzieci – dodaj pierwsze dziecko' }}
    </div>

    <!-- Widok: tabela -->
    <div v-else-if="view === 'table'" class="table-card">
      <v-data-table
        :headers="headers"
        :items="visibleChildren"
        :items-per-page="25"
        items-per-page-text="Na stronie:"
        hover
      >
        <template #item.name="{ item }">
          <div class="d-flex align-center ga-3 py-2">
            <div class="avatar avatar-sm" :style="{ background: colorOf(item.groupId).avatar, color: colorOf(item.groupId).text }">
              {{ initials(item) }}
            </div>
            <span class="font-weight-bold">{{ item.firstName }} {{ item.lastName }}</span>
          </div>
        </template>
        <template #item.group="{ item }">
          <span class="group-chip mt-0" :style="{ background: colorOf(item.groupId).bg, color: colorOf(item.groupId).text }">
            {{ item.groupId ? groupName(item.groupId) : 'Bez grupy' }}
          </span>
        </template>
        <template #item.parents="{ item }">
          <span class="parents" :class="{ missing: !item.parentIds?.length }">
            <v-icon v-if="!item.parentIds?.length" size="18">mdi-alert-circle-outline</v-icon>
            {{ parentsLabel(item) }}
          </span>
        </template>
        <template #item.actions="{ item }">
          <v-btn icon="mdi-pencil-outline" size="small" variant="text" title="Edytuj" @click="openDialog(item)" />
          <v-btn icon="mdi-delete-outline" size="small" variant="text" color="error" title="Usuń" @click="remove(item)" />
        </template>
      </v-data-table>
    </div>

    <!-- Widok: kafelki -->
    <div v-else class="grid">
      <!-- Przerywana ramka = dziecko bez przypisanego rodzica -->
      <div v-for="child in visibleChildren" :key="child.id" class="child-card" :class="{ warn: !child.parentIds?.length }">
        <div class="d-flex align-start">
          <div class="avatar" :style="{ background: colorOf(child.groupId).avatar, color: colorOf(child.groupId).text }">
            {{ initials(child) }}
          </div>
          <v-spacer />
          <v-menu location="bottom end">
            <template #activator="{ props }">
              <button class="more" v-bind="props" aria-label="Opcje"><v-icon size="20">mdi-dots-horizontal</v-icon></button>
            </template>
            <v-list density="compact" rounded="lg">
              <v-list-item prepend-icon="mdi-pencil-outline" title="Edytuj" @click="openDialog(child)" />
              <v-list-item prepend-icon="mdi-delete-outline" title="Usuń" base-color="error" @click="remove(child)" />
            </v-list>
          </v-menu>
        </div>

        <div class="name">{{ child.firstName }} {{ child.lastName }}</div>
        <span
          class="group-chip"
          :style="{ background: colorOf(child.groupId).bg, color: colorOf(child.groupId).text }"
        >
          {{ child.groupId ? groupName(child.groupId) : 'Bez grupy' }}
        </span>

        <div class="divider" />
        <div class="parents" :class="{ missing: !child.parentIds?.length }">
          <v-icon size="18">mdi-account-multiple-outline</v-icon>
          <span>{{ parentsLabel(child) }}</span>
        </div>
      </div>
    </div>

    <v-dialog v-model="dialog" max-width="520">
      <v-card class="pa-2">
        <v-card-title class="font-weight-bold">{{ editedId ? 'Edytuj dziecko' : 'Nowe dziecko' }}</v-card-title>
        <v-card-text>
          <v-text-field v-model="form.firstName" label="Imię" />
          <v-text-field v-model="form.lastName" label="Nazwisko" />
          <v-select
            v-model="form.groupId"
            :items="groups"
            item-title="name"
            item-value="id"
            label="Grupa"
            no-data-text="Najpierw dodaj grupę"
          />
          <v-autocomplete
            v-model="form.parentIds"
            :items="parentItems"
            item-title="label"
            item-value="id"
            label="Rodzice"
            multiple
            chips
            closable-chips
            no-data-text="Najpierw dodaj rodzica"
          />
          <v-alert v-if="error" type="error" variant="tonal" density="compact">{{ error }}</v-alert>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="dialog = false">Anuluj</v-btn>
          <v-btn color="primary" variant="flat" :loading="saving" @click="save">Zapisz</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import {
  collection, onSnapshot, addDoc, updateDoc, deleteDoc, doc, query, where, orderBy, serverTimestamp,
} from 'firebase/firestore'
import { db } from '../firebase'
import { groupColor } from '../groupColors'

type Child = { id: string; firstName: string; lastName: string; groupId: string | null; parentIds: string[] }
type Group = { id: string; name: string }
type Parent = { id: string; firstName: string; lastName: string; email: string }

const children = ref<Child[]>([])
const groups = ref<Group[]>([])
const parents = ref<Parent[]>([])
const loading = ref(true)

const search = ref('')
const groupFilter = ref<string | null>(null)

// Widok tabela/kafelki – zapamiętany w przeglądarce
const view = ref<'table' | 'cards'>(localStorage.getItem('childrenView') === 'cards' ? 'cards' : 'table')
watch(view, (v) => localStorage.setItem('childrenView', v))

const headers = [
  { title: 'Dziecko', key: 'name', value: (c: Child) => `${c.lastName} ${c.firstName}` },
  { title: 'Grupa', key: 'group', value: (c: Child) => (c.groupId ? groupName(c.groupId) : '') },
  { title: 'Rodzice', key: 'parents', value: (c: Child) => parentsLabel(c) },
  { title: '', key: 'actions', sortable: false, align: 'end' as const },
]

const dialog = ref(false)
const editedId = ref<string | null>(null)
const form = ref({ firstName: '', lastName: '', groupId: null as string | null, parentIds: [] as string[] })
const saving = ref(false)
const error = ref('')

const colorOf = (groupId: string | null) => groupColor(groups.value, groupId)

const visibleChildren = computed(() => {
  const q = search.value.trim().toLowerCase()
  return children.value.filter((c) =>
    (!groupFilter.value || c.groupId === groupFilter.value) &&
    (!q || `${c.firstName} ${c.lastName}`.toLowerCase().includes(q)),
  )
})

const countIn = (groupId: string) => children.value.filter((c) => c.groupId === groupId).length

const parentItems = computed(() =>
  parents.value.map((p) => ({ id: p.id, label: `${p.firstName} ${p.lastName} (${p.email})` })),
)

const groupName = (id: string) => groups.value.find((g) => g.id === id)?.name ?? '?'
const parentName = (id: string) => {
  const p = parents.value.find((x) => x.id === id)
  return p ? `${p.firstName} ${p.lastName}` : '?'
}
const parentsLabel = (child: Child) =>
  child.parentIds?.length ? child.parentIds.map(parentName).join(' i ') : 'Brak przypisanego rodzica'
const initials = (child: Child) =>
  `${child.firstName.charAt(0)}${child.lastName.charAt(0)}`.toUpperCase()

const unsubs: (() => void)[] = []
onMounted(() => {
  unsubs.push(onSnapshot(query(collection(db, 'children'), orderBy('lastName')), (snap) => {
    children.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Child, 'id'>) }))
    loading.value = false
  }))
  unsubs.push(onSnapshot(query(collection(db, 'groups'), orderBy('name')), (snap) => {
    groups.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Group, 'id'>) }))
  }))
  unsubs.push(onSnapshot(query(collection(db, 'users'), where('roles', 'array-contains', 'parent')), (snap) => {
    parents.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Parent, 'id'>) }))
  }))
})
onUnmounted(() => unsubs.forEach((u) => u()))

const openDialog = (child?: Child) => {
  editedId.value = child?.id ?? null
  form.value = {
    firstName: child?.firstName ?? '',
    lastName: child?.lastName ?? '',
    groupId: child?.groupId ?? null,
    parentIds: [...(child?.parentIds ?? [])],
  }
  error.value = ''
  dialog.value = true
}

const save = async () => {
  const data = {
    firstName: form.value.firstName.trim(),
    lastName: form.value.lastName.trim(),
    groupId: form.value.groupId,
    parentIds: form.value.parentIds,
  }
  if (!data.firstName || !data.lastName) {
    error.value = 'Podaj imię i nazwisko'
    return
  }
  saving.value = true
  try {
    if (editedId.value) {
      await updateDoc(doc(db, 'children', editedId.value), data)
    } else {
      await addDoc(collection(db, 'children'), { ...data, createdAt: serverTimestamp() })
    }
    dialog.value = false
  } catch (e: any) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}

const remove = async (child: Child) => {
  if (!confirm(`Usunąć ${child.firstName} ${child.lastName}?`)) return
  try {
    await deleteDoc(doc(db, 'children', child.id))
  } catch (e: any) {
    alert(e.message || 'Nie udało się usunąć dziecka')
  }
}
</script>

<style scoped>
.header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 14px;
  margin-bottom: 28px;
}
.title {
  font-size: 2.4rem;
  font-weight: 900;
  line-height: 1.1;
  color: #1c1917;
}
.subtitle {
  margin-top: 10px;
  color: #57534e;
}
.search {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 300px;
  height: 52px;
  padding: 0 18px;
  background: #ffffff;
  border: 2px solid #f3e6d3;
  border-radius: 999px;
}
.search input {
  flex: 1;
  min-width: 0;
  outline: none;
  font-size: 1rem;
  font-family: inherit;
  color: #1c1917;
}

.view-toggle {
  display: flex;
  gap: 4px;
  padding: 4px;
  background: #ffffff;
  border: 2px solid #f3e6d3;
  border-radius: 999px;
}
.view-toggle button {
  width: 40px;
  height: 36px;
  border-radius: 999px;
  color: #78716c;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.view-toggle button.active {
  background: #1c1917;
  color: #ffffff;
}
.table-card {
  background: #ffffff;
  border: 2px solid #f3e6d3;
  border-radius: 24px;
  overflow: hidden;
}
.table-card :deep(th) {
  font-weight: 800 !important;
  color: #57534e;
}
.avatar.avatar-sm {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  font-size: 0.9rem;
}
.filters {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-bottom: 24px;
}
.filter {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 10px 18px;
  border-radius: 999px;
  font-weight: 800;
  font-size: 0.95rem;
  border: 2px solid transparent;
  cursor: pointer;
  font-family: inherit;
}
.filter.active {
  border-color: currentColor;
}
.filter-all {
  background: #f5ede1;
  color: #1c1917;
}
.filter-all.active {
  background: #1c1917;
  color: #ffffff;
  border-color: #1c1917;
}
.count {
  min-width: 24px;
  height: 24px;
  padding: 0 7px;
  border-radius: 999px;
  background: #ffffff;
  color: inherit;
  font-size: 0.8rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
.filter-all.active .count {
  background: #44403c;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(280px, 100%), 1fr));
  gap: 22px;
}
.child-card {
  background: #ffffff;
  border: 2px solid #f3e6d3;
  border-radius: 24px;
  padding: 20px;
  transition: transform 0.15s, box-shadow 0.15s;
}
.child-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 24px rgba(120, 80, 30, 0.08);
}
.child-card.warn {
  border: 2px dashed #fb923c;
}
.avatar {
  width: 60px;
  height: 60px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 900;
  font-size: 1.25rem;
}
.more {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: #f7f1e8;
  color: #44403c;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.more:hover {
  background: #efe5d6;
}
.name {
  margin-top: 16px;
  font-size: 1.2rem;
  font-weight: 800;
  color: #1c1917;
}
.group-chip {
  display: inline-block;
  margin-top: 8px;
  padding: 3px 12px;
  border-radius: 999px;
  font-size: 0.8rem;
  font-weight: 800;
}
.divider {
  margin: 16px 0 14px;
  border-top: 2px dotted #f0e2c8;
}
.parents {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #44403c;
  font-size: 0.95rem;
}
.parents.missing {
  color: #c2410c;
  font-weight: 700;
}
.empty {
  padding: 48px;
  text-align: center;
  color: #78716c;
}

/* Telefon: wyszukiwarka i przycisk na całą szerokość, mniejszy tytuł */
@media (max-width: 600px) {
  .title {
    font-size: 1.75rem;
  }
  .search,
  .header > .v-btn {
    width: 100%;
  }
  .header > .v-btn {
    height: 52px;
  }
}
</style>
