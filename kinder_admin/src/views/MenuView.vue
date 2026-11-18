<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="text-h4 font-weight-bold">Jadłospis</h1>
        <div class="text-body-2 text-grey">Posiłki na każdy dzień – rodzice widzą je w aplikacji</div>
      </div>
      <v-spacer />
      <v-btn variant="tonal" prepend-icon="mdi-content-copy" :loading="copying" @click="copyPreviousWeek">
        Kopiuj poprzedni tydzień
      </v-btn>
    </div>

    <!-- Wybór tygodnia -->
    <div class="week-bar">
      <div class="week-switch">
        <v-btn icon="mdi-chevron-left" variant="text" aria-label="Poprzedni tydzień" @click="shiftWeek(-1)" />
        <div class="week-label">{{ weekLabel }}</div>
        <v-btn icon="mdi-chevron-right" variant="text" aria-label="Następny tydzień" @click="shiftWeek(1)" />
      </div>
      <v-btn v-if="!isCurrentWeek" variant="text" color="primary" @click="goToday">Bieżący tydzień</v-btn>
      <v-spacer />
      <div class="filled-info">
        <v-icon size="18">mdi-calendar-check-outline</v-icon>
        Uzupełnione dni: <b>{{ filledCount }} / 5</b>
      </div>
    </div>

    <div v-if="loading" class="d-flex justify-center pa-12">
      <v-progress-circular indeterminate color="primary" />
    </div>

    <!-- Dni tygodnia -->
    <div v-else class="days">
      <div v-for="d in weekDays" :key="d.key" class="day" :class="{ today: d.key === todayKey, empty: !menu[d.key] }">
        <div class="day-head">
          <div>
            <div class="day-name">{{ d.name }}</div>
            <div class="day-date">{{ d.label }}</div>
          </div>
          <v-spacer />
          <span v-if="d.key === todayKey" class="today-badge">Dziś</span>
          <v-menu v-if="menu[d.key]" location="bottom end">
            <template #activator="{ props }">
              <v-btn v-bind="props" icon="mdi-dots-horizontal" size="small" variant="text" aria-label="Opcje dnia" />
            </template>
            <v-list density="compact" rounded="lg">
              <v-list-item prepend-icon="mdi-pencil-outline" title="Edytuj" @click="openEdit(d.key)" />
              <v-list-item prepend-icon="mdi-delete-outline" title="Usuń dzień" base-color="error" @click="removeDay(d.key)" />
            </v-list>
          </v-menu>
        </div>

        <template v-if="menu[d.key]">
          <div v-for="m in MEALS" :key="m.key" class="meal" @click="openEdit(d.key)">
            <div class="meal-icon" :style="{ background: m.bg, color: m.fg }">
              <v-icon size="18">{{ m.icon }}</v-icon>
            </div>
            <div class="meal-body">
              <div class="meal-label" :style="{ color: m.fg }">{{ m.label }}</div>
              <div class="meal-name">{{ menu[d.key]?.[m.key]?.name || '—' }}</div>
              <div v-if="menu[d.key]?.[m.key]?.allergens?.length" class="allergens">
                <span v-for="a in menu[d.key]?.[m.key]?.allergens" :key="a">{{ a }}</span>
              </div>
            </div>
          </div>
        </template>
        <button v-else class="add-day" @click="openEdit(d.key)">
          <v-icon size="28">mdi-plus</v-icon>
          Dodaj jadłospis
        </button>
      </div>
    </div>

    <!-- Edycja dnia -->
    <v-dialog v-model="dialog" max-width="640" scrollable>
      <v-card class="pa-2">
        <v-card-title class="font-weight-bold">
          Jadłospis – {{ editedLabel }}
        </v-card-title>
        <v-card-text>
          <div v-for="m in MEALS" :key="m.key" class="meal-form">
            <div class="meal-form-title" :style="{ color: m.fg }">
              <v-icon size="18">{{ m.icon }}</v-icon>
              {{ m.label }}
            </div>
            <v-text-field v-model="form[m.key].name" :label="`Nazwa (${m.label.toLowerCase()})`" hide-details="auto" class="mb-3" />
            <v-autocomplete
              v-model="form[m.key].allergens"
              :items="ALLERGENS"
              label="Alergeny"
              multiple
              chips
              closable-chips
              hide-details
              density="compact"
            />
          </div>
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
import { ref, computed, watch, onUnmounted } from 'vue'
import {
  collection, doc, onSnapshot, query, where, orderBy, setDoc, deleteDoc, getDocs, writeBatch, serverTimestamp,
} from 'firebase/firestore'
import { db } from '../firebase'

type MealKey = 'breakfast' | 'soup' | 'main' | 'snack'
type Meal = { name: string; allergens: string[] }
type MenuDay = { date: string } & Record<MealKey, Meal>

// Te same posiłki, godziny i kolory co w aplikacji mobilnej (menu_tab.dart)
const MEALS: { key: MealKey; label: string; icon: string; bg: string; fg: string }[] = [
  { key: 'breakfast', label: 'Śniadanie', icon: 'mdi-white-balance-sunny', bg: '#fef9c3', fg: '#854d0e' },
  { key: 'soup', label: 'Zupa', icon: 'mdi-pot-steam-outline', bg: '#dcfce7', fg: '#166534' },
  { key: 'main', label: 'Drugie danie', icon: 'mdi-silverware-fork-knife', bg: '#ffedd5', fg: '#9a3412' },
  { key: 'snack', label: 'Podwieczorek', icon: 'mdi-cupcake', bg: '#fce7f3', fg: '#9d174d' },
]

// 14 alergenów z rozporządzenia UE (nazwy jak w scripts/seed-demo.js)
const ALLERGENS = [
  'gluten', 'mleko', 'jaja', 'seler', 'ryby', 'orzechy', 'orzeszki ziemne', 'soja',
  'gorczyca', 'sezam', 'skorupiaki', 'mięczaki', 'łubin', 'siarczyny',
]

const WEEKDAYS = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek']

// Data jako RRRR-MM-DD (ID dokumentu w menu/)
const iso = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
const addDays = (d: Date, n: number) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n)
const mondayOf = (d: Date) => addDays(d, -((d.getDay() + 6) % 7))
const dayMonth = (d: Date) => d.toLocaleDateString('pl-PL', { day: 'numeric', month: 'long' })

const todayKey = iso(new Date())
const currentMonday = mondayOf(new Date())
const monday = ref(currentMonday)
const isCurrentWeek = computed(() => iso(monday.value) === iso(currentMonday))

const weekDays = computed(() =>
  WEEKDAYS.map((name, i) => {
    const date = addDays(monday.value, i)
    return { key: iso(date), name, label: dayMonth(date) }
  }),
)
const weekLabel = computed(() => `${dayMonth(monday.value)} – ${dayMonth(addDays(monday.value, 4))}`)

const menu = ref<Record<string, MenuDay>>({})
const loading = ref(true)
const filledCount = computed(() => weekDays.value.filter((d) => menu.value[d.key]).length)

// Subskrypcja wybranego tygodnia (to samo zapytanie co w aplikacji: date między pon a pt)
let unsub: (() => void) | undefined
watch(
  monday,
  (m) => {
    unsub?.()
    loading.value = true
    const q = query(
      collection(db, 'menu'),
      where('date', '>=', iso(m)),
      where('date', '<=', iso(addDays(m, 4))),
      orderBy('date'),
    )
    unsub = onSnapshot(q, (snap) => {
      menu.value = Object.fromEntries(snap.docs.map((d) => [d.id, d.data() as MenuDay]))
      loading.value = false
    })
  },
  { immediate: true },
)
onUnmounted(() => unsub?.())

const shiftWeek = (delta: number) => (monday.value = addDays(monday.value, 7 * delta))
const goToday = () => (monday.value = currentMonday)

// ===== Edycja dnia =====
const emptyMeal = (): Meal => ({ name: '', allergens: [] })
const dialog = ref(false)
const editedKey = ref('')
const form = ref<Record<MealKey, Meal>>({ breakfast: emptyMeal(), soup: emptyMeal(), main: emptyMeal(), snack: emptyMeal() })
const saving = ref(false)
const error = ref('')

const editedLabel = computed(() => {
  const d = weekDays.value.find((x) => x.key === editedKey.value)
  return d ? `${d.name.toLowerCase()}, ${d.label}` : editedKey.value
})

const openEdit = (key: string) => {
  const day = menu.value[key]
  editedKey.value = key
  form.value = Object.fromEntries(
    MEALS.map((m) => [m.key, { name: day?.[m.key]?.name ?? '', allergens: [...(day?.[m.key]?.allergens ?? [])] }]),
  ) as Record<MealKey, Meal>
  error.value = ''
  dialog.value = true
}

const save = async () => {
  if (MEALS.some((m) => !form.value[m.key].name.trim())) {
    error.value = 'Uzupełnij nazwy wszystkich posiłków'
    return
  }
  saving.value = true
  error.value = ''
  try {
    const meals = Object.fromEntries(
      MEALS.map((m) => [m.key, { name: form.value[m.key].name.trim(), allergens: form.value[m.key].allergens }]),
    )
    await setDoc(doc(db, 'menu', editedKey.value), { date: editedKey.value, ...meals, updatedAt: serverTimestamp() })
    dialog.value = false
  } catch (e: any) {
    error.value = e.message || 'Nie udało się zapisać'
  } finally {
    saving.value = false
  }
}

const removeDay = async (key: string) => {
  if (!confirm('Usunąć jadłospis na ten dzień?')) return
  try {
    await deleteDoc(doc(db, 'menu', key))
  } catch (e: any) {
    alert(e.message || 'Nie udało się usunąć')
  }
}

// ===== Kopiowanie poprzedniego tygodnia =====
const copying = ref(false)
const copyPreviousWeek = async () => {
  const prevMonday = addDays(monday.value, -7)
  const snap = await getDocs(
    query(collection(db, 'menu'), where('date', '>=', iso(prevMonday)), where('date', '<=', iso(addDays(prevMonday, 4)))),
  )
  if (snap.empty) {
    alert('Poprzedni tydzień nie ma jadłospisu do skopiowania')
    return
  }
  if (filledCount.value > 0 && !confirm('Ten tydzień ma już jadłospis. Nadpisać go poprzednim tygodniem?')) return

  copying.value = true
  try {
    const batch = writeBatch(db)
    snap.docs.forEach((d) => {
      const data = d.data() as MenuDay
      const [y = 1970, m = 1, day = 1] = data.date.split('-').map(Number)
      const target = iso(addDays(new Date(y, m - 1, day), 7))
      batch.set(doc(db, 'menu', target), { ...data, date: target, updatedAt: serverTimestamp() })
    })
    await batch.commit()
  } catch (e: any) {
    alert(e.message || 'Nie udało się skopiować')
  } finally {
    copying.value = false
  }
}
</script>

<style scoped>
.week-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
}
.week-switch {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px;
  background: #ffffff;
  border: 2px solid #f3e6d3;
  border-radius: 999px;
}
.week-label {
  min-width: 220px;
  text-align: center;
  font-weight: 800;
}
.filled-info {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #57534e;
}

.days {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(240px, 100%), 1fr));
  gap: 16px;
}
.day {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 16px;
  background: #ffffff;
  border: 2px solid #f3e6d3;
  border-radius: 24px;
}
.day.today {
  border-color: #c4b5fd;
  box-shadow: 0 8px 20px rgba(76, 29, 149, 0.08);
}
.day.empty {
  border-style: dashed;
}
.day-head {
  display: flex;
  align-items: center;
  gap: 8px;
}
.day-name {
  font-weight: 900;
  font-size: 1.05rem;
}
.day-date {
  color: #57534e;
  font-size: 0.85rem;
}
.today-badge {
  padding: 2px 10px;
  border-radius: 999px;
  background: #ede9fe;
  color: #4c1d95;
  font-weight: 800;
  font-size: 0.75rem;
}

.meal {
  display: flex;
  gap: 10px;
  padding: 8px;
  margin: 0 -8px;
  border-radius: 14px;
  cursor: pointer;
  transition: background 0.15s;
}
.meal:hover {
  background: #fdf5ea;
}
.meal-icon {
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.meal-body {
  min-width: 0;
}
.meal-label {
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}
.meal-name {
  font-weight: 700;
  font-size: 0.9rem;
  line-height: 1.3;
}
.allergens {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: 4px;
}
.allergens span {
  padding: 0 8px;
  border-radius: 999px;
  background: #f7f1e8;
  color: #57534e;
  font-size: 0.72rem;
  font-weight: 700;
}
.add-day {
  flex: 1;
  min-height: 200px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  border-radius: 18px;
  background: #fdf5ea;
  color: #9a3412;
  font-weight: 800;
  cursor: pointer;
  font-family: inherit;
}
.add-day:hover {
  background: #ffedd5;
}

.meal-form {
  padding: 16px 16px 12px;
  margin-bottom: 14px;
  border: 2px solid #f3e6d3;
  border-radius: 20px;
}
.meal-form-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 800;
  margin-bottom: 12px;
}
</style>
