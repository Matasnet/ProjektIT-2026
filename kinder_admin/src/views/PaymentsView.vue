<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="text-h4 font-weight-bold">Płatności</h1>
        <div class="text-body-2 text-grey">Miesięczna opłata za przedszkole i status wpłat</div>
      </div>
      <v-spacer />
      <v-btn color="primary" prepend-icon="mdi-cog-outline" @click="openSettings">Ustawienia opłaty</v-btn>
    </div>

    <v-alert v-if="!settingsLoading && !settings" type="warning" variant="tonal" rounded="xl" class="mb-6">
      Nie ustawiono jeszcze kwoty opłaty – rodzice nie zobaczą jej w aplikacji.
      <template #append>
        <v-btn variant="flat" color="warning" @click="openSettings">Ustaw</v-btn>
      </template>
    </v-alert>

    <!-- Wybór miesiąca + opłata -->
    <div class="month-bar">
      <div class="month-switch">
        <v-btn icon="mdi-chevron-left" variant="text" aria-label="Poprzedni miesiąc" @click="shiftMonth(-1)" />
        <div class="month-label">{{ monthLabel(month) }}</div>
        <v-btn icon="mdi-chevron-right" variant="text" aria-label="Następny miesiąc" @click="shiftMonth(1)" />
      </div>
      <div v-if="settings" class="fee-info">
        <span><b>{{ money(settings.monthlyFee) }}</b> / dziecko</span>
        <span class="dot-sep">·</span>
        <span>termin {{ dueDateLabel }}</span>
      </div>
    </div>

    <!-- Podsumowanie -->
    <div class="stats">
      <div class="stat stat-paid">
        <v-icon>mdi-check-circle-outline</v-icon>
        <div>
          <div class="stat-value">{{ paidCount }} / {{ children.length }}</div>
          <div class="stat-label">opłacone</div>
        </div>
      </div>
      <div class="stat stat-due">
        <v-icon>mdi-clock-outline</v-icon>
        <div>
          <div class="stat-value">{{ children.length - paidCount }}</div>
          <div class="stat-label">{{ isOverdue ? 'po terminie' : 'do zapłaty' }}</div>
        </div>
      </div>
      <div class="stat stat-sum">
        <v-icon>mdi-cash-multiple</v-icon>
        <div>
          <div class="stat-value">{{ money(paidCount * fee) }}</div>
          <div class="stat-label">wpłacono z {{ money(children.length * fee) }}</div>
        </div>
      </div>
    </div>

    <!-- Filtry -->
    <div class="filters">
      <v-btn-toggle v-model="filter" mandatory color="primary" variant="outlined" rounded="pill" density="comfortable">
        <v-btn value="all">Wszystkie</v-btn>
        <v-btn value="due">Do zapłaty</v-btn>
        <v-btn value="paid">Opłacone</v-btn>
      </v-btn-toggle>
      <v-spacer />
      <v-text-field
        v-model="search"
        placeholder="Szukaj dziecka…"
        prepend-inner-icon="mdi-magnify"
        density="compact"
        hide-details
        bg-color="white"
        class="search"
      />
    </div>

    <v-card>
      <v-data-table
        :headers="headers"
        :items="visibleChildren"
        :loading="loading"
        :items-per-page="25"
        items-per-page-text="Na stronie:"
        no-data-text="Brak dzieci"
      >
        <template #item.name="{ item }">
          <div class="d-flex align-center ga-3 py-2">
            <div class="avatar" :style="{ background: colorOf(item.groupId).avatar, color: colorOf(item.groupId).text }">
              {{ item.firstName[0] }}{{ item.lastName[0] }}
            </div>
            <span class="font-weight-bold">{{ item.firstName }} {{ item.lastName }}</span>
          </div>
        </template>
        <template #item.group="{ item }">
          <span class="chip" :style="{ background: colorOf(item.groupId).bg, color: colorOf(item.groupId).text }">
            {{ groupName(item.groupId) }}
          </span>
        </template>
        <template #item.amount>{{ money(fee) }}</template>
        <template #item.status="{ item }">
          <span class="status" :class="statusOf(item).cls">
            <v-icon size="16">{{ statusOf(item).icon }}</v-icon>
            {{ statusOf(item).label }}
          </span>
        </template>
        <template #item.actions="{ item }">
          <v-btn
            :variant="isPaid(item) ? 'text' : 'flat'"
            :color="isPaid(item) ? undefined : 'primary'"
            size="small"
            :loading="savingId === item.id"
            @click="togglePaid(item)"
          >
            {{ isPaid(item) ? 'Cofnij' : 'Oznacz jako opłacone' }}
          </v-btn>
        </template>
      </v-data-table>
    </v-card>

    <!-- Ustawienia opłaty -->
    <v-dialog v-model="settingsDialog" max-width="520">
      <v-card class="pa-2">
        <v-card-title class="font-weight-bold">Ustawienia opłaty</v-card-title>
        <v-card-text>
          <div class="text-body-2 text-grey-darken-1 mb-4">
            Rodzice widzą te dane w aplikacji (zakładka Płatności) razem z gotowym tytułem przelewu.
          </div>
          <v-row dense>
            <v-col cols="12" sm="6">
              <v-text-field v-model.number="form.monthlyFee" label="Kwota miesięczna" type="number" min="0" suffix="zł" />
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field v-model.number="form.dueDay" label="Termin (dzień miesiąca)" type="number" min="1" max="28" />
            </v-col>
          </v-row>
          <v-text-field v-model="form.recipient" label="Odbiorca przelewu" prepend-inner-icon="mdi-domain" />
          <v-text-field v-model="form.accountNumber" label="Numer konta" prepend-inner-icon="mdi-bank-outline" class="mono" />
          <v-alert v-if="error" type="error" variant="tonal" density="compact">{{ error }}</v-alert>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="settingsDialog = false">Anuluj</v-btn>
          <v-btn color="primary" variant="flat" :loading="saving" @click="saveSettings">Zapisz</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import {
  collection, doc, onSnapshot, orderBy, query, setDoc, updateDoc, arrayUnion, arrayRemove, serverTimestamp,
} from 'firebase/firestore'
import { db } from '../firebase'
import { groupColor } from '../groupColors'

type Child = { id: string; firstName: string; lastName: string; groupId: string | null; paidMonths?: string[] }
type Group = { id: string; name: string }
type Settings = { monthlyFee: number; dueDay: number; recipient: string; accountNumber: string }

const children = ref<Child[]>([])
const groups = ref<Group[]>([])
const settings = ref<Settings | null>(null)
const loading = ref(true)
const settingsLoading = ref(true)
const savingId = ref<string | null>(null)
const filter = ref<'all' | 'due' | 'paid'>('all')
const search = ref('')

// Miesiąc jako "RRRR-MM" – ten sam format zapisuje children.paidMonths
const monthKey = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
// "RRRR-MM" → pierwszy dzień miesiąca (+ przesunięcie o delta miesięcy, opcjonalnie konkretny dzień)
const monthDate = (key: string, delta = 0, day = 1) => {
  const [y = 1970, m = 1] = key.split('-').map(Number)
  return new Date(y, m - 1 + delta, day)
}
const month = ref(monthKey(new Date()))
const shiftMonth = (delta: number) => {
  month.value = monthKey(monthDate(month.value, delta))
}
const monthLabel = (key: string) => {
  const label = monthDate(key).toLocaleDateString('pl-PL', { month: 'long', year: 'numeric' })
  return label.charAt(0).toUpperCase() + label.slice(1)
}

const fee = computed(() => settings.value?.monthlyFee ?? 0)
const money = (v: number) => v.toLocaleString('pl-PL', { style: 'currency', currency: 'PLN', maximumFractionDigits: 0 })

const dueDate = computed(() => {
  const d = monthDate(month.value, 0, settings.value?.dueDay ?? 10)
  d.setHours(23, 59)
  return d
})
const dueDateLabel = computed(() => dueDate.value.toLocaleDateString('pl-PL', { day: 'numeric', month: 'long' }))
const isOverdue = computed(() => new Date() > dueDate.value)

const isPaid = (c: Child) => c.paidMonths?.includes(month.value) ?? false
const paidCount = computed(() => children.value.filter(isPaid).length)
const statusOf = (c: Child) =>
  isPaid(c)
    ? { label: 'Opłacone', icon: 'mdi-check', cls: 'paid' }
    : isOverdue.value
      ? { label: 'Po terminie', icon: 'mdi-alert-circle-outline', cls: 'overdue' }
      : { label: 'Do zapłaty', icon: 'mdi-clock-outline', cls: 'due' }

const groupName = (id: string | null) => groups.value.find((g) => g.id === id)?.name ?? 'Bez grupy'
const colorOf = (id: string | null) => groupColor(groups.value, id)

const visibleChildren = computed(() => {
  const q = search.value.trim().toLowerCase()
  return children.value
    .filter((c) => (filter.value === 'paid' ? isPaid(c) : filter.value === 'due' ? !isPaid(c) : true))
    .filter((c) => !q || `${c.firstName} ${c.lastName}`.toLowerCase().includes(q))
})

const headers = [
  { title: 'Dziecko', key: 'name', value: (c: Child) => `${c.lastName} ${c.firstName}` },
  { title: 'Grupa', key: 'group', value: (c: Child) => groupName(c.groupId) },
  { title: 'Kwota', key: 'amount', sortable: false },
  { title: 'Status', key: 'status', value: (c: Child) => (isPaid(c) ? 1 : 0) },
  { title: '', key: 'actions', sortable: false, align: 'end' as const },
]

const unsubs: (() => void)[] = []
onMounted(() => {
  unsubs.push(onSnapshot(query(collection(db, 'children'), orderBy('lastName')), (snap) => {
    children.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Child, 'id'>) }))
    loading.value = false
  }))
  unsubs.push(onSnapshot(query(collection(db, 'groups'), orderBy('name')), (snap) => {
    groups.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Group, 'id'>) }))
  }))
  unsubs.push(onSnapshot(doc(db, 'settings', 'payments'), (snap) => {
    settings.value = snap.exists() ? (snap.data() as Settings) : null
    settingsLoading.value = false
  }))
})
onUnmounted(() => unsubs.forEach((u) => u()))

// Status zapisuje się w dokumencie dziecka – rodzic widzi go od razu w aplikacji
const togglePaid = async (c: Child) => {
  savingId.value = c.id
  try {
    await updateDoc(doc(db, 'children', c.id), {
      paidMonths: isPaid(c) ? arrayRemove(month.value) : arrayUnion(month.value),
    })
  } catch (e: any) {
    alert(e.message || 'Nie udało się zapisać statusu')
  } finally {
    savingId.value = null
  }
}

// ===== Ustawienia =====
const settingsDialog = ref(false)
const saving = ref(false)
const error = ref('')
const form = ref<Settings>({ monthlyFee: 0, dueDay: 10, recipient: '', accountNumber: '' })

const openSettings = () => {
  form.value = settings.value
    ? { ...settings.value }
    : { monthlyFee: 850, dueDay: 10, recipient: 'Przedszkole Kinder Info', accountNumber: '' }
  error.value = ''
  settingsDialog.value = true
}

const saveSettings = async () => {
  const f = form.value
  if (!(f.monthlyFee > 0)) {
    error.value = 'Podaj kwotę większą od zera'
    return
  }
  if (!(f.dueDay >= 1 && f.dueDay <= 28)) {
    error.value = 'Termin: dzień od 1 do 28'
    return
  }
  if (!f.recipient.trim() || !f.accountNumber.trim()) {
    error.value = 'Podaj odbiorcę i numer konta'
    return
  }
  saving.value = true
  error.value = ''
  try {
    await setDoc(doc(db, 'settings', 'payments'), {
      monthlyFee: Math.round(f.monthlyFee),
      dueDay: Math.round(f.dueDay),
      recipient: f.recipient.trim(),
      accountNumber: f.accountNumber.trim(),
      updatedAt: serverTimestamp(),
    })
    settingsDialog.value = false
  } catch (e: any) {
    error.value = e.message || 'Nie udało się zapisać'
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.month-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px 20px;
  margin-bottom: 20px;
}
.month-switch {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px;
  background: #ffffff;
  border: 2px solid #f3e6d3;
  border-radius: 999px;
}
.month-label {
  min-width: 150px;
  text-align: center;
  font-weight: 800;
  font-size: 1.05rem;
}
.fee-info {
  color: #57534e;
}
.dot-sep {
  margin: 0 8px;
}

.stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(220px, 100%), 1fr));
  gap: 16px;
  margin-bottom: 24px;
}
.stat {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 18px 20px;
  border-radius: 24px;
}
.stat .v-icon {
  width: 44px;
  height: 44px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.7);
}
.stat-value {
  font-size: 1.6rem;
  font-weight: 900;
  line-height: 1.1;
}
.stat-label {
  font-weight: 700;
  font-size: 0.9rem;
  opacity: 0.8;
}
.stat-paid { background: #dcfce7; color: #166534; }
.stat-due { background: #ffedd5; color: #9a3412; }
.stat-sum { background: #ede9fe; color: #4c1d95; }

.filters {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}
.search {
  max-width: 280px;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 900;
  font-size: 0.9rem;
}
.chip {
  padding: 3px 12px;
  border-radius: 999px;
  font-weight: 800;
  font-size: 0.8rem;
}
.status {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: 999px;
  font-weight: 800;
  font-size: 0.85rem;
}
.status.paid { background: #dcfce7; color: #166534; }
.status.due { background: #ffedd5; color: #9a3412; }
.status.overdue { background: #fee2e2; color: #b91c1c; }
.mono :deep(input) {
  font-family: ui-monospace, 'JetBrains Mono', monospace;
  letter-spacing: 0.04em;
}

@media (max-width: 600px) {
  .search {
    max-width: none;
    width: 100%;
  }
  .filters .v-btn-toggle {
    width: 100%;
  }
  .filters .v-btn-toggle .v-btn {
    flex: 1 1 0;
    min-width: 0;
  }
}
</style>
