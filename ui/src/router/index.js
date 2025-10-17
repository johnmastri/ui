import { createRouter, createWebHistory } from 'vue-router'
import MainView from '../views/MainView.vue'
import VirtualHardwareView from '../views/VirtualHardwareView.vue'

const routes = [
  {
    path: '/',
    name: 'Main',
    component: MainView
  },
  {
    path: '/virtual',
    name: 'VirtualHardware',
    component: VirtualHardwareView
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router 