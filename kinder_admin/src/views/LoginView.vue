<template>
  <div class="login-page">
    <!-- Panel marki – motyw "klocki ABC", taki sam jak ekran powitalny w aplikacji mobilnej -->
    <section class="brand-panel" aria-hidden="true">
      <div class="brand-head">
        <img src="/logo.png" alt="" class="brand-logo" />
        <span class="brand-name">Kinder Info</span>
      </div>

      <div class="brand-body">
        <h1 class="brand-title">Wszystko o&nbsp;przedszkolu w&nbsp;jednym miejscu</h1>
        <p class="brand-desc">Grupy, dzieci, konta rodziców i&nbsp;powiadomienia push – w&nbsp;jednym panelu.</p>

        <div class="blocks">
          <div class="sun" />
          <div class="block b1">A</div>
          <div class="block b2">B</div>
          <div class="block b3">C</div>
          <div class="block b4"><v-icon size="30">mdi-heart</v-icon></div>
        </div>
      </div>

      <ul class="features">
        <li><v-icon size="20">mdi-account-multiple-outline</v-icon> Grupy i dzieci</li>
        <li><v-icon size="20">mdi-account-key-outline</v-icon> Konta rodziców</li>
        <li><v-icon size="20">mdi-bell-ring-outline</v-icon> Powiadomienia na telefon</li>
      </ul>
    </section>

    <!-- Formularz -->
    <section class="form-panel">
      <div class="form-wrap">
        <div class="mobile-brand">
          <img src="/logo.png" alt="" class="brand-logo" />
          <span class="brand-name">Kinder Info</span>
        </div>

        <h2 class="form-title">Zaloguj się</h2>
        <p class="form-subtitle">Panel dla administratora i dyrektora przedszkola</p>

        <v-alert
          v-if="loggedOut"
          type="success"
          variant="tonal"
          density="compact"
          rounded="lg"
          class="mb-5"
          closable
          @click:close="loggedOut = false"
        >
          Wylogowano. Do zobaczenia!
        </v-alert>

        <v-form @submit.prevent="login">
          <v-text-field
            v-model="email"
            label="Email"
            type="email"
            autocomplete="username"
            prepend-inner-icon="mdi-email-outline"
            bg-color="white"
            :rules="[required]"
            :disabled="loading"
            class="mb-2"
          />
          <v-text-field
            v-model="password"
            label="Hasło"
            autocomplete="current-password"
            prepend-inner-icon="mdi-lock-outline"
            bg-color="white"
            :type="showPassword ? 'text' : 'password'"
            :append-inner-icon="showPassword ? 'mdi-eye-outline' : 'mdi-eye-off-outline'"
            @click:append-inner="showPassword = !showPassword"
            :rules="[required]"
            :disabled="loading"
          />

          <v-alert v-if="error" type="error" variant="tonal" density="compact" rounded="lg" class="mb-4">
            {{ error }}
          </v-alert>

          <v-btn type="submit" color="primary" size="x-large" block :loading="loading" append-icon="mdi-arrow-right">
            Zaloguj
          </v-btn>
        </v-form>

        <div class="parent-hint">
          <v-icon size="18">mdi-cellphone</v-icon>
          Rodzice logują się w aplikacji mobilnej Kinder Info.
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { signInWithEmailAndPassword, signOut } from 'firebase/auth'
import { auth } from '../firebase'
import { getRoles, isStaff } from '../router'

const router = useRouter()
const route = useRoute()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)
const error = ref('')
// Po wylogowaniu App.vue przekierowuje na /login?wylogowano=1
const loggedOut = ref(route.query.wylogowano === '1')

const required = (v: string) => !!v || 'Pole wymagane'

const errorMessages: Record<string, string> = {
  'auth/invalid-credential': 'Nieprawidłowy email lub hasło',
  'auth/invalid-email': 'Nieprawidłowy format emaila',
  'auth/too-many-requests': 'Zbyt wiele prób. Spróbuj później',
  'auth/network-request-failed': 'Brak połączenia z internetem',
}

const login = async () => {
  if (!email.value || !password.value) return
  error.value = ''
  loggedOut.value = false
  loading.value = true
  try {
    const { user } = await signInWithEmailAndPassword(auth, email.value.trim(), password.value)

    if (!isStaff(await getRoles(user.uid))) {
      await signOut(auth)
      throw new Error('Brak uprawnień do panelu administracyjnego')
    }

    router.push('/')
  } catch (e: any) {
    error.value = errorMessages[e.code] || e.message || 'Błąd logowania'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: grid;
  grid-template-columns: minmax(380px, 1fr) minmax(400px, 1fr);
  padding: 12px;
  gap: 12px;
}

/* ===== Panel marki ===== */
.brand-panel {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 36px 44px;
  border-radius: 32px;
  background: linear-gradient(150deg, #ede9fe 0%, #f5f0ff 55%, #fde7c8 100%);
  color: #4c1d95;
  overflow: hidden;
}
.brand-head,
.mobile-brand {
  display: flex;
  align-items: center;
  gap: 12px;
}
.brand-logo {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  box-shadow: 0 0 0 2px #ffffff, 0 6px 14px rgba(76, 29, 149, 0.12);
}
.brand-name {
  font-size: 1.25rem;
  font-weight: 900;
  color: #4c1d95;
}
.brand-title {
  max-width: 460px;
  font-size: 2.6rem;
  font-weight: 900;
  line-height: 1.12;
  letter-spacing: -0.01em;
}
.brand-desc {
  max-width: 420px;
  margin-top: 14px;
  font-size: 1.1rem;
  color: #5b21b6;
}
.features {
  list-style: none;
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
.features li {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.75);
  font-weight: 700;
  font-size: 0.9rem;
}

/* Klocki ABC i słońce (jak na pulpicie panelu) */
.blocks {
  position: relative;
  width: 260px;
  height: 170px;
  margin-top: 40px;
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
  box-shadow: 0 8px 18px rgba(76, 29, 149, 0.15);
  animation: float 5s ease-in-out infinite;
}
.b1 { left: 10px; bottom: 0; background: #c4b5fd; color: #5b21b6; --r: -8deg; }
.b2 { left: 88px; bottom: 0; background: #86efac; color: #166534; --r: 4deg; animation-delay: 0.6s; }
.b3 { left: 166px; bottom: 0; background: #fdba74; color: #9a3412; --r: -3deg; animation-delay: 1.2s; }
.b4 { left: 50px; bottom: 76px; background: #f9a8d4; color: #9d174d; --r: 6deg; animation-delay: 1.8s; }
@keyframes float {
  0%, 100% { transform: translateY(0) rotate(var(--r)); }
  50% { transform: translateY(-6px) rotate(var(--r)); }
}
@media (prefers-reduced-motion: reduce) {
  .block { animation: none; transform: rotate(var(--r)); }
}

/* ===== Formularz ===== */
.form-panel {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.form-wrap {
  width: 100%;
  max-width: 400px;
}
.mobile-brand {
  display: none;
  margin-bottom: 28px;
}
.form-title {
  font-size: 2rem;
  font-weight: 900;
  color: #1c1917;
}
.form-subtitle {
  margin: 4px 0 28px;
  color: #57534e;
}
.parent-hint {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 28px;
  padding: 12px 16px;
  border-radius: 16px;
  background: #f7f1e8;
  color: #57534e;
  font-size: 0.9rem;
}

/* Tablet i telefon: sam formularz, logo nad nim */
@media (max-width: 960px) {
  .login-page {
    grid-template-columns: 1fr;
    padding: 0;
  }
  .brand-panel {
    display: none;
  }
  .mobile-brand {
    display: flex;
  }
  .form-panel {
    align-items: flex-start;
    padding: 48px 20px;
  }
}
</style>
