// ============================================
// VUETIFY CONFIGURATION - MOTYW "PRZEDSZKOLE"
// Fioletowy sidebar, kremowe tło, rdzawy akcent, font Nunito – wspólny z aplikacją mobilną
// ============================================

import 'vuetify/styles'
import '@mdi/font/css/materialdesignicons.css'
import '@fontsource-variable/nunito'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { pl } from 'vuetify/locale'

export default createVuetify({
  components,
  directives,
  // Polskie teksty wbudowane (tabele: sortowanie, paginacja, brak danych…)
  locale: { locale: 'pl', fallback: 'en', messages: { pl } },
  theme: {
    defaultTheme: 'light',
    themes: {
      light: {
        colors: {
          primary: '#c2410c',        // Rdzawy pomarańcz (przyciski)
          secondary: '#4c1d95',      // Ciemny fiolet (tekst marki, jak w aplikacji mobilnej)
          accent: '#fcd34d',         // Żółty (logo, aktywne menu)

          error: '#dc2626',
          warning: '#f59e0b',
          info: '#7c3aed',
          success: '#16a34a',

          background: '#fdf5ea',     // Kremowe tło
          surface: '#ffffff',
          'on-background': '#1c1917',
          'on-surface': '#1c1917',
        },
      },
    },
  },
  defaults: {
    VCard: {
      elevation: 0,
      rounded: 'xl',
    },
    VBtn: {
      elevation: 0,
      rounded: 'pill',
      class: 'text-none font-weight-bold',
    },
    VTextField: {
      variant: 'outlined',
      density: 'comfortable',
      rounded: 'lg',
    },
    VSelect: {
      variant: 'outlined',
      density: 'comfortable',
      rounded: 'lg',
    },
    VAutocomplete: {
      variant: 'outlined',
      density: 'comfortable',
      rounded: 'lg',
    },
    VTextarea: {
      variant: 'outlined',
      rounded: 'lg',
    },
    // Na telefonie (< 600 px) wiersze tabel wyświetlają się jako karty
    VDataTable: {
      mobileBreakpoint: 'sm',
    },
  },
})
