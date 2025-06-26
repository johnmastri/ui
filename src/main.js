import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import MainView from './views/MainView.vue'
import VirtualHardwareView from './views/VirtualHardwareView.vue'
import './style.css'

// Mock JUCE for development
if (!window.__JUCE__) {
  console.log('JUCE not detected - creating development mock')
  window.__JUCE__ = {
    initialisationData: {
      vendor: 'WolfSound',
      pluginName: 'JuceWebViewPlugin (Dev)',
      pluginVersion: '1.0.0-dev',
      devicePixelRatio: window.devicePixelRatio || 1
    },
    backend: {
      addEventListener: (event, callback) => {
        console.log(`Mock: addEventListener for ${event}`)
      },
      emitEvent: (event, data) => {
        console.log(`Mock: emitEvent ${event}`, data)
      }
    }
  }
}

// Router configuration
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

// Initialize Vue app
console.log('Initializing Vue app...')
const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
app.mount('#app')
console.log('Vue app mounted!')
