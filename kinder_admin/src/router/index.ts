import { createRouter, createWebHistory } from 'vue-router'
import { onAuthStateChanged, signOut, type User } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from '../firebase'

const routes = [
  { path: '/login', name: 'Login', component: () => import('../views/LoginView.vue') },
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', name: 'Dashboard', component: () => import('../views/DashboardView.vue'), meta: { requiresAuth: true } },
  { path: '/groups', name: 'Groups', component: () => import('../views/GroupsView.vue'), meta: { requiresAuth: true } },
  { path: '/children', name: 'Children', component: () => import('../views/ChildrenView.vue'), meta: { requiresAuth: true } },
  { path: '/parents', name: 'Parents', component: () => import('../views/ParentsView.vue'), meta: { requiresAuth: true } },
  { path: '/notifications', name: 'Notifications', component: () => import('../views/NotificationsView.vue'), meta: { requiresAuth: true } },
  { path: '/menu', name: 'Menu', component: () => import('../views/MenuView.vue'), meta: { requiresAuth: true } },
  { path: '/payments', name: 'Payments', component: () => import('../views/PaymentsView.vue'), meta: { requiresAuth: true } },
  { path: '/directors', name: 'Directors', component: () => import('../views/DirectorsView.vue'), meta: { requiresAuth: true, adminOnly: true } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

const getCurrentUser = () =>
  new Promise<User | null>((resolve, reject) => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      unsubscribe()
      resolve(user)
    }, reject)
  })

export const getRoles = async (uid: string): Promise<string[]> => {
  try {
    const userDoc = await getDoc(doc(db, 'users', uid))
    return userDoc.data()?.roles ?? []
  } catch {
    return []
  }
}

// Do panelu wchodzi admin i dyrektor (dyrektor bez zakładki Dyrektorzy)
export const isStaff = (roles: string[]) => roles.includes('admin') || roles.includes('director')

// Navigation Guard – to tylko UX, prawdziwa ochrona to firestore.rules
router.beforeEach(async (to) => {
  if (!to.meta.requiresAuth) return true

  const user = await getCurrentUser()
  if (!user) return '/login'

  const roles = await getRoles(user.uid)
  if (!isStaff(roles)) {
    await signOut(auth)
    return '/login'
  }
  if (to.meta.adminOnly && !roles.includes('admin')) return '/dashboard'
  return true
})

export default router
