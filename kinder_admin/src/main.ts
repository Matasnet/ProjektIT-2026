// ============================================
// MAIN.TS - Punkt startowy aplikacji
// ============================================
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'

const app = createApp(App)

app.use(router)   // Nawigacja
app.use(vuetify)  // Komponenty UI

app.mount('#app')
