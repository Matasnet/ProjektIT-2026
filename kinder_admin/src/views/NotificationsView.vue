<template>
  <div>
    <div class="mb-6">
      <h1 class="text-h4 font-weight-bold">Powiadomienia</h1>
      <div class="text-body-2 text-grey">Wyślij powiadomienie push na telefony rodziców</div>
    </div>

    <v-row>
      <v-col cols="12" md="5">
        <v-card class="pa-4">
          <v-card-title class="px-0">Nowe powiadomienie</v-card-title>
          <v-select
            v-model="form.groupId"
            :items="targets"
            item-title="name"
            item-value="id"
            label="Odbiorcy"
          />
          <v-text-field v-model="form.title" label="Tytuł" counter="60" maxlength="60" />
          <v-textarea v-model="form.body" label="Treść" rows="4" counter="300" maxlength="300" />
          <v-alert v-if="error" type="error" variant="tonal" density="compact" class="mb-4">{{ error }}</v-alert>
          <v-alert v-if="success" type="success" variant="tonal" density="compact" class="mb-4">
            Powiadomienie zapisane – wysyłka w toku
          </v-alert>
          <v-btn color="primary" prepend-icon="mdi-send" block :loading="sending" @click="send">Wyślij</v-btn>
        </v-card>
      </v-col>

      <v-col cols="12" md="7">
        <v-card>
          <v-card-title>Historia</v-card-title>
          <v-list v-if="notifications.length" lines="three">
            <v-list-item v-for="n in notifications" :key="n.id" :title="n.title" :subtitle="n.body">
              <template #append>
                <div class="text-right">
                  <v-chip size="small" :color="statusColor(n.status)" variant="tonal">
                    {{ statusLabel(n.status) }}
                  </v-chip>
                  <div class="text-caption text-grey mt-1">{{ targetName(n.groupId) }}</div>
                  <div class="text-caption text-grey">{{ formatDate(n.createdAt) }}</div>
                </div>
              </template>
            </v-list-item>
          </v-list>
          <v-card-text v-else class="text-grey">Brak wysłanych powiadomień</v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import {
  collection, onSnapshot, addDoc, query, orderBy, limit, serverTimestamp, Timestamp,
} from 'firebase/firestore'
import { auth, db } from '../firebase'

type Group = { id: string; name: string }
type Notification = {
  id: string
  title: string
  body: string
  groupId: string
  status?: 'pending' | 'sent' | 'error'
  createdAt?: Timestamp
}

const groups = ref<Group[]>([])
const notifications = ref<Notification[]>([])

const form = ref({ groupId: 'all', title: '', body: '' })
const sending = ref(false)
const error = ref('')
const success = ref(false)

const targets = computed(() => [{ id: 'all', name: 'Wszyscy rodzice' }, ...groups.value])

const targetName = (groupId: string) => targets.value.find((t) => t.id === groupId)?.name ?? groupId
const statusLabel = (s?: string) => ({ sent: 'Wysłane', error: 'Błąd' } as Record<string, string>)[s ?? ''] ?? 'Wysyłanie…'
const statusColor = (s?: string) => ({ sent: 'success', error: 'error' } as Record<string, string>)[s ?? ''] ?? 'grey'
const formatDate = (t?: Timestamp) => (t ? t.toDate().toLocaleString('pl-PL') : '')

const unsubs: (() => void)[] = []
onMounted(() => {
  unsubs.push(onSnapshot(query(collection(db, 'groups'), orderBy('name')), (snap) => {
    groups.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Group, 'id'>) }))
  }))
  unsubs.push(onSnapshot(query(collection(db, 'notifications'), orderBy('createdAt', 'desc'), limit(50)), (snap) => {
    notifications.value = snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Notification, 'id'>) }))
  }))
})
onUnmounted(() => unsubs.forEach((u) => u()))

// Zapis do kolekcji notifications/ uruchamia Cloud Function sendNotification (FCM)
const send = async () => {
  error.value = ''
  success.value = false
  if (!form.value.title.trim() || !form.value.body.trim()) {
    error.value = 'Podaj tytuł i treść'
    return
  }
  sending.value = true
  try {
    await addDoc(collection(db, 'notifications'), {
      title: form.value.title.trim(),
      body: form.value.body.trim(),
      groupId: form.value.groupId,
      status: 'pending',
      createdBy: auth.currentUser?.uid ?? null,
      createdAt: serverTimestamp(),
    })
    form.value.title = ''
    form.value.body = ''
    success.value = true
  } catch (e: any) {
    error.value = e.message
  } finally {
    sending.value = false
  }
}
</script>
