<template>
  <div>
    <div class="header">
      <div>
        <h1 class="title">Pulpit</h1>
        <div class="subtitle">{{ today }}</div>
      </div>
    </div>

    <div v-if="loading" class="d-flex justify-center pa-12">
      <v-progress-circular indeterminate color="primary" />
    </div>

    <template v-else>
      <!-- Baner powitalny -->
      <div class="hero">
        <div class="hero-text">
          <span class="hero-badge"><v-icon size="16">mdi-white-balance-sunny</v-icon> Kinder Info</span>
          <h2 class="hero-title">{{ greeting }}</h2>
          <p class="hero-desc">
            W przedszkolu jest <b>{{ children.length }} {{ plural(children.length, 'dziecko', 'dzieci', 'dzieci') }}</b>
            w <b>{{ groups.length }} {{ plural(groups.length, 'grupie', 'grupach', 'grupach') }}</b>.
            <template v-if="childrenWithoutParent">
              <br /><b>{{ childrenWithoutParent }}</b>
              {{ plural(childrenWithoutParent, 'dziecko czeka', 'dzieci czekają', 'dzieci czeka') }} na przypisanie rodzica.
            </template>
          </p>
          <div class="d-flex flex-wrap ga-3">
            <v-btn color="primary" size="large" prepend-icon="mdi-send" to="/notifications">Wyślij powiadomienie</v-btn>
            <v-btn variant="flat" color="white" size="large" prepend-icon="mdi-plus" to="/children">Dodaj dziecko</v-btn>
          </div>
        </div>

        <!-- Dekoracja: klocki ABC i słońce -->
        <div class="hero-art" aria-hidden="true">
          <div class="sun" />
          <div class="block b1">A</div>
          <div class="block b2">B</div>
          <div class="block b3">C</div>
          <div class="block b4"><v-icon size="30">mdi-heart</v-icon></div>
        </div>
      </div>

      <!-- Kafelki ze statystykami -->
      <div class="stats">
        <router-link v-for="s in stats" :key="s.label" :to="s.to" class="stat" :style="{ background: s.bg }">
          <div class="d-flex align-center">
            <div class="stat-icon" :style="{ background: s.iconBg, color: s.color }">
              <v-icon size="22">{{ s.icon }}</v-icon>
            </div>
            <v-spacer />
            <v-icon size="20" color="grey-darken-1">mdi-arrow-top-right</v-icon>
          </div>
          <div class="stat-label">{{ s.label }}</div>
          <div class="stat-value">{{ s.value }}</div>
          <div class="stat-hint" :class="{ warn: s.warn }">{{ s.hint }}</div>
        </router-link>
      </div>

      <div class="bottom">
        <!-- Dzieci w grupach -->
        <div class="panel">
          <div class="panel-head">
            <div class="panel-title">Dzieci w grupach</div>
            <router-link to="/groups" class="panel-link">Grupy</router-link>
          </div>
          <div v-if="!groupBars.length" class="empty">Brak grup</div>
          <div v-for="g in groupBars" :key="g.id" class="bar-row" :title="`${g.name}: ${g.count}`">
            <div class="bar-label">
              <span class="dot" :style="{ background: g.color }" />
              <span>{{ g.name }}</span>
              <v-spacer />
              <b>{{ g.count }}</b>
            </div>
            <div class="bar-track">
              <div class="bar-fill" :style="{ width: `${g.percent}%`, background: g.color }" />
            </div>
          </div>
        </div>

        <!-- Ostatnie powiadomienia -->
        <div class="panel">
          <div class="panel-head">
            <div class="panel-title">Ostatnie powiadomienia</div>
            <router-link to="/notifications" class="panel-link">Wszystkie</router-link>
          </div>
          <div v-if="!notifications.length" class="empty">Brak wysłanych powiadomień</div>
          <div v-for="n in notifications.slice(0, 4)" :key="n.id" class="notif">
            <div class="notif-icon"><v-icon size="20">mdi-bell-outline</v-icon></div>
            <div class="notif-body">
              <div class="notif-title">{{ n.title }}</div>
              <div class="notif-meta">{{ targetName(n.groupId) }} · {{ formatDate(n.createdAt) }}</div>
            </div>
            <v-chip size="small" :color="statusColor(n.status)" variant="tonal">{{ statusLabel(n.status) }}</v-chip>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { collection, onSnapshot, query, where, orderBy, Timestamp } from 'firebase/firestore'
import { auth, db } from '../firebase'
import { groupColor } from '../groupColors'

type Child = { id: string; groupId: string | null; parentIds?: string[] }
type Group = { id: string; name: string }
type Parent = { id: string }
type Notification = {
  id: string
  title: string
  groupId: string
  status?: 'pending' | 'sent' | 'error'
  createdAt?: Timestamp
}

const children = ref<Child[]>([])
const groups = ref<Group[]>([])
const parents = ref<Parent[]>([])
const notifications = ref<Notification[]>([])
const loading = ref(true)

const today = new Date().toLocaleDateString('pl-PL', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })

const greeting = computed(() => {
  const hour = new Date().getHours()
  const hello = hour < 18 ? 'Dzień dobry' : 'Dobry wieczór'
  const name = auth.currentUser?.displayName?.split(' ')[0]
  return name ? `${hello}, ${name}!` : `${hello}!`
})

// Polska odmiana: 1 dziecko, 2–4 dzieci, 5+ dzieci
const plural = (n: number, one: string, few: string, many: string) => {
  if (n === 1) return one
  const d = n % 10
  const t = n % 100
  return d >= 2 && d <= 4 && (t < 12 || t > 14) ? few : many
}

const childrenWithoutParent = computed(() => children.value.filter((c) => !c.parentIds?.length).length)
const parentsWithoutChild = computed(() => {
  const linked = new Set(children.value.flatMap((c) => c.parentIds ?? []))
  return parents.value.filter((p) => !linked.has(p.id)).length
})
const sentCount = computed(() => notifications.value.filter((n) => n.status === 'sent').length)
const errorCount = computed(() => notifications.value.filter((n) => n.status === 'error').length)

const stats = computed(() => [
  {
    label: 'Dzieci',
    value: children.value.length,
    icon: 'mdi-emoticon-happy-outline',
    to: '/children',
    bg: '#fdf0c4', iconBg: '#fcd34d', color: '#4c1d95',
    hint: childrenWithoutParent.value ? `${childrenWithoutParent.value} bez rodzica` : 'Wszystkie mają rodzica',
    warn: childrenWithoutParent.value > 0,
  },
  {
    label: 'Grupy',
    value: groups.value.length,
    icon: 'mdi-account-multiple-outline',
    to: '/groups',
    bg: '#ede9fe', iconBg: '#c4b5fd', color: '#5b21b6',
    hint: groups.value.length
      ? `Średnio ${(children.value.length / groups.value.length).toLocaleString('pl-PL', { maximumFractionDigits: 1 })} dzieci na grupę`
      : 'Dodaj pierwszą grupę',
    warn: false,
  },
  {
    label: 'Rodzice',
    value: parents.value.length,
    icon: 'mdi-account-outline',
    to: '/parents',
    bg: '#dcfce7', iconBg: '#86efac', color: '#166534',
    hint: parentsWithoutChild.value ? `${parentsWithoutChild.value} bez przypisanego dziecka` : 'Wszyscy mają dziecko',
    warn: parentsWithoutChild.value > 0,
  },
  {
    label: 'Powiadomienia',
    value: sentCount.value,
    icon: 'mdi-bell-outline',
    to: '/notifications',
    bg: '#ffedd5', iconBg: '#fdba74', color: '#9a3412',
    hint: errorCount.value ? `${errorCount.value} z błędem wysyłki` : 'Wysłane do rodziców',
    warn: errorCount.value > 0,
  },
])

const groupBars = computed(() => {
  const max = Math.max(1, ...groups.value.map((g) => children.value.filter((c) => c.groupId === g.id).length))
  return groups.value.map((g) => {
    const count = children.value.filter((c) => c.groupId === g.id).length
    return { id: g.id, name: g.name, count, percent: (count / max) * 100, color: groupColor(groups.value, g.id).avatar }
  })
})

const targetName = (groupId: string) =>
  groupId === 'all' ? 'Wszyscy rodzice' : groups.value.find((g) => g.id === groupId)?.name ?? groupId
const statusLabel = (s?: string) => ({ sent: 'Wysłane', error: 'Błąd' } as Record<string, string>)[s ?? ''] ?? 'Wysyłanie…'
const statusColor = (s?: string) => ({ sent: 'success', error: 'error' } as Record<string, string>)[s ?? ''] ?? 'grey'
const formatDate = (t?: Timestamp) =>
  t ? t.toDate().toLocaleString('pl-PL', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : ''

const unsubs: (() => void)[] = []
onMounted(() => {
  unsubs.push(onSnapshot(collection(db, 'children'), (snap) => {
    children.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Child, 'id'>) }))
    loading.value = false
  }))
  unsubs.push(onSnapshot(query(collection(db, 'groups'), orderBy('name')), (snap) => {
    groups.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Group, 'id'>) }))
  }))
  unsubs.push(onSnapshot(query(collection(db, 'users'), where('roles', 'array-contains', 'parent')), (snap) => {
    parents.value = snap.docs.map((d) => ({ id: d.id }))
  }))
  unsubs.push(onSnapshot(query(collection(db, 'notifications'), orderBy('createdAt', 'desc')), (snap) => {
    notifications.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Notification, 'id'>) }))
  }))
})
onUnmounted(() => unsubs.forEach((u) => u()))
</script>

<style scoped>
.header {
  margin-bottom: 24px;
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
  text-transform: capitalize;
}

/* ===== Baner ===== */
.hero {
  position: relative;
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 32px 36px;
  margin-bottom: 24px;
  border-radius: 28px;
  background: linear-gradient(120deg, #fdf0c4 0%, #fde7c8 55%, #fbd9c4 100%);
  border: 2px solid #f3e6d3;
  overflow: hidden;
}
.hero-text {
  flex: 1;
  position: relative;
  z-index: 1;
}
.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.7);
  color: #4c1d95;
  font-size: 0.8rem;
  font-weight: 800;
}
.hero-title {
  margin-top: 12px;
  font-size: 2rem;
  font-weight: 900;
  color: #4c1d95;
}
.hero-desc {
  margin: 8px 0 20px;
  font-size: 1.05rem;
  color: #44403c;
}
.hero-art {
  position: relative;
  width: 260px;
  height: 170px;
  flex-shrink: 0;
}
.sun {
  position: absolute;
  top: 0;
  right: 10px;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: #fcd34d;
  box-shadow: 0 0 0 14px rgba(252, 211, 77, 0.35);
}
.block {
  position: absolute;
  width: 70px;
  height: 70px;
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-weight: 900;
  box-shadow: 0 8px 18px rgba(120, 80, 30, 0.15);
  transition: transform 0.3s;
}
.hero:hover .block {
  transform: translateY(-4px) rotate(0deg);
}
.b1 { left: 10px; bottom: 0; background: #c4b5fd; color: #5b21b6; transform: rotate(-8deg); }
.b2 { left: 88px; bottom: 0; background: #86efac; color: #166534; transform: rotate(4deg); }
.b3 { left: 166px; bottom: 0; background: #fdba74; color: #9a3412; transform: rotate(-3deg); }
.b4 { left: 50px; bottom: 76px; background: #f9a8d4; color: #9d174d; transform: rotate(6deg); }

/* ===== Kafelki ===== */
.stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(220px, 100%), 1fr));
  gap: 20px;
  margin-bottom: 24px;
}
.stat {
  display: block;
  padding: 20px;
  border-radius: 24px;
  border: 2px solid rgba(255, 255, 255, 0.6);
  text-decoration: none;
  color: #1c1917;
  transition: transform 0.15s, box-shadow 0.15s;
}
.stat:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 24px rgba(120, 80, 30, 0.08);
}
.stat-icon {
  width: 44px;
  height: 44px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.stat-label {
  margin-top: 16px;
  font-weight: 700;
  color: #57534e;
}
.stat-value {
  font-size: 2.2rem;
  font-weight: 900;
  line-height: 1.2;
}
.stat-hint {
  font-size: 0.85rem;
  color: #57534e;
}
.stat-hint.warn {
  color: #c2410c;
  font-weight: 700;
}

/* ===== Panele ===== */
.bottom {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(360px, 100%), 1fr));
  gap: 20px;
}
.panel {
  background: #ffffff;
  border: 2px solid #f3e6d3;
  border-radius: 24px;
  padding: 22px 24px;
}
.panel-head {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}
.panel-title {
  flex: 1;
  font-size: 1.15rem;
  font-weight: 800;
}
.panel-link {
  font-size: 0.9rem;
  font-weight: 700;
  color: #c2410c;
  text-decoration: none;
}
.bar-row + .bar-row {
  margin-top: 14px;
}
.bar-label {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
  color: #44403c;
}
.dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}
.bar-track {
  height: 12px;
  border-radius: 999px;
  background: #f7f1e8;
  overflow: hidden;
}
.bar-fill {
  height: 100%;
  border-radius: 999px;
  transition: width 0.4s;
}
.notif {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 0;
}
.notif + .notif {
  border-top: 2px dotted #f0e2c8;
}
.notif-icon {
  width: 40px;
  height: 40px;
  flex-shrink: 0;
  border-radius: 12px;
  background: #f7f1e8;
  color: #c2410c;
  display: flex;
  align-items: center;
  justify-content: center;
}
.notif-body {
  flex: 1;
  min-width: 0;
}
.notif-title {
  font-weight: 700;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.notif-meta {
  font-size: 0.8rem;
  color: #78716c;
}
.empty {
  padding: 24px;
  text-align: center;
  color: #78716c;
}

@media (max-width: 900px) {
  .hero-art {
    display: none;
  }
}
@media (max-width: 600px) {
  .title {
    font-size: 1.75rem;
  }
  .hero {
    padding: 22px 20px;
  }
  .hero-title {
    font-size: 1.5rem;
  }
}
</style>
