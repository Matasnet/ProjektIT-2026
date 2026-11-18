<template>
  <v-app>
    <!-- Telefon/tablet: górny pasek z przyciskiem menu, sidebar wysuwany -->
    <v-app-bar v-if="showChrome && mobile" flat class="topbar" height="60">
      <v-app-bar-nav-icon aria-label="Menu" @click="drawer = !drawer" />
      <img class="topbar-logo" src="/logo.png" alt="" />
      <span class="brand-name">Kinder Info</span>
    </v-app-bar>

    <v-navigation-drawer
      v-if="showChrome"
      v-model="drawer"
      :permanent="!mobile"
      :temporary="mobile"
      width="240"
      class="sidebar"
      :class="{ 'sidebar-mobile': mobile }"
      border="0"
    >
      <div class="brand">
        <img class="brand-logo" src="/logo.png" alt="Kinder Info" />
        <div class="brand-text">
          <div class="brand-name">Kinder Info</div>
          <div class="brand-email">{{ currentUser?.email }}</div>
          <div v-if="roleLabel" class="brand-role">{{ roleLabel }}</div>
        </div>
      </div>

      <nav class="menu">
        <router-link
          v-for="item in visibleMenuItems"
          :key="item.path"
          :to="item.path"
          class="menu-item"
          @click="mobile && (drawer = false)"
        >
          <v-icon size="20">{{ item.icon }}</v-icon>
          <span>{{ item.title }}</span>
        </router-link>
      </nav>

      <template #append>
        <div class="menu pb-4">
          <a class="menu-item" href="#" @click.prevent="logoutDialog = true">
            <v-icon size="20">mdi-logout</v-icon>
            <span>Wyloguj się</span>
          </a>
        </div>
      </template>
    </v-navigation-drawer>

    <v-main>
      <!-- Ekran logowania zajmuje całe okno, pozostałe widoki mają marginesy strony -->
      <div :class="{ page: showChrome }">
        <router-view />
      </div>
    </v-main>

    <!-- Potwierdzenie wylogowania – ten sam układ co w aplikacji mobilnej -->
    <v-dialog v-model="logoutDialog" max-width="400">
      <v-card class="logout-card">
        <div class="logout-avatar">{{ initials }}</div>
        <div class="logout-title">Wylogować się?</div>
        <div class="logout-email">{{ currentUser?.email }}</div>
        <p class="logout-text">Zakończysz sesję w panelu Kinder Info na tym urządzeniu.</p>
        <div class="logout-actions">
          <v-btn variant="tonal" size="large" @click="logoutDialog = false">Anuluj</v-btn>
          <v-btn color="primary" size="large" prepend-icon="mdi-logout" :loading="loggingOut" @click="logout">
            Wyloguj się
          </v-btn>
        </div>
      </v-card>
    </v-dialog>
  </v-app>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useDisplay } from 'vuetify'
import { signOut, onAuthStateChanged, type User } from 'firebase/auth'
import { auth } from './firebase'
import { getRoles } from './router'

const router = useRouter()
const route = useRoute()
// Poniżej 960 px sidebar chowa się pod przyciskiem ☰
const { smAndDown: mobile } = useDisplay()
const currentUser = ref<User | null>(null)
const roles = ref<string[]>([])
const drawer = ref(!mobile.value)
const showChrome = computed(() => !!currentUser.value && route.name !== 'Login')
watch(mobile, (m) => (drawer.value = !m))

const menuItems = [
  { title: 'Pulpit', icon: 'mdi-view-dashboard-outline', path: '/dashboard' },
  { title: 'Dzieci', icon: 'mdi-emoticon-happy-outline', path: '/children' },
  { title: 'Grupy', icon: 'mdi-account-multiple-outline', path: '/groups' },
  { title: 'Rodzice', icon: 'mdi-account-outline', path: '/parents' },
  { title: 'Powiadomienia', icon: 'mdi-bell-outline', path: '/notifications' },
  { title: 'Jadłospis', icon: 'mdi-silverware-fork-knife', path: '/menu' },
  { title: 'Płatności', icon: 'mdi-cash-multiple', path: '/payments' },
  { title: 'Dyrektorzy', icon: 'mdi-account-tie-outline', path: '/directors', adminOnly: true },
]

// Zakładka Dyrektorzy tylko dla admina (dostęp i tak sprawdzają router, reguły i Cloud Functions)
const isAdmin = computed(() => roles.value.includes('admin'))
const visibleMenuItems = computed(() => menuItems.filter((item) => !item.adminOnly || isAdmin.value))
const roleLabel = computed(() =>
  isAdmin.value ? 'Administrator' : roles.value.includes('director') ? 'Dyrektor' : '',
)

onMounted(() => {
  onAuthStateChanged(auth, async (user) => {
    currentUser.value = user
    roles.value = user ? await getRoles(user.uid) : []
  })
})

// Inicjały z loginu imie.nazwisko@… → "IN"
const initials = computed(() => {
  const login = currentUser.value?.email?.split('@')[0] ?? ''
  return login.split(/[.\-_]/).filter(Boolean).slice(0, 2).map((p) => p[0]).join('').toUpperCase() || '?'
})

const logoutDialog = ref(false)
const loggingOut = ref(false)
const logout = async () => {
  loggingOut.value = true
  try {
    await signOut(auth)
    logoutDialog.value = false
    router.push({ path: '/login', query: { wylogowano: '1' } })
  } finally {
    loggingOut.value = false
  }
}
</script>

<style>
/* Font Nunito w całej aplikacji (także w klasach typografii Vuetify) */
.v-application,
.v-application [class*='text-'] {
  font-family: 'Nunito Variable', sans-serif !important;
}
.v-application {
  background: rgb(var(--v-theme-background)) !important;
}

/* ===== Sidebar ===== */
.sidebar.v-navigation-drawer {
  background: #ede9fe !important;
  top: 6px !important;
  left: 6px !important;
  height: calc(100% - 12px) !important;
  border-radius: 28px;
  color: #4c1d95;
}
.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 28px 20px 24px;
}
.brand-logo {
  width: 48px;
  height: 48px;
  flex-shrink: 0;
  /* tło logo ma kolor paska – biała obwódka je odcina */
  border-radius: 11px;
  box-shadow: 0 0 0 2px #ffffff, 0 4px 10px rgba(76, 29, 149, 0.12);
}
.brand-name {
  font-size: 1.15rem;
  font-weight: 800;
  line-height: 1.2;
}
.brand-role {
  display: inline-block;
  margin-top: 4px;
  padding: 1px 8px;
  border-radius: 999px;
  background: #ffffff;
  font-size: 0.7rem;
  font-weight: 800;
}
.brand-email {
  font-size: 0.8rem;
  color: #7c3aed;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 140px;
}
.menu {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 0 14px;
}
.menu-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 16px;
  border-radius: 14px;
  color: #5b21b6;
  font-weight: 700;
  font-size: 0.95rem;
  text-decoration: none;
  transition: background 0.15s;
}
.menu-item:hover {
  background: rgba(255, 255, 255, 0.55);
}
.menu-item.router-link-active {
  background: #ffffff;
  color: #4c1d95;
  box-shadow: 0 4px 12px rgba(76, 29, 149, 0.08);
}

/* Na telefonie sidebar wysuwa się na całą wysokość, bez marginesów */
.sidebar.sidebar-mobile.v-navigation-drawer {
  top: 0 !important;
  left: 0 !important;
  height: 100% !important;
  border-radius: 0 28px 28px 0;
}

/* ===== Górny pasek (telefon/tablet) ===== */
.topbar.v-app-bar {
  background: #ede9fe !important;
  color: #4c1d95 !important;
}
.topbar-logo {
  width: 34px;
  height: 34px;
  margin-right: 10px;
  border-radius: 9px;
}

/* ===== Wylogowanie ===== */
.logout-card {
  padding: 32px 28px 24px;
  text-align: center;
}
.logout-avatar {
  width: 72px;
  height: 72px;
  margin: 0 auto 16px;
  border-radius: 22px;
  background: #ede9fe;
  color: #4c1d95;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.6rem;
  font-weight: 900;
}
.logout-title {
  font-size: 1.4rem;
  font-weight: 900;
}
.logout-email {
  color: #7c3aed;
  font-weight: 700;
  font-size: 0.9rem;
  word-break: break-all;
}
.logout-text {
  margin: 12px 0 24px;
  color: #57534e;
}
.logout-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

/* ===== Treść ===== */
.page {
  padding: 28px 36px;
  max-width: 1280px;
}

/* Nagłówek widoku: tytuł + przyciski, na wąskim ekranie przyciski przechodzą pod tytuł */
.page-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px 14px;
  margin-bottom: 24px;
}

@media (max-width: 600px) {
  .page {
    padding: 18px 14px;
  }
  .page-header > .v-btn {
    width: 100%;
  }
  .v-application .text-h4 {
    font-size: 1.75rem !important;
  }
}
</style>
