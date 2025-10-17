import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useWebsocketStore } from './websocketStore'

export const useUpdateStore = defineStore('update', () => {
  const websocketStore = useWebsocketStore()
  
  const updateAvailable = ref(false)
  const availableVersion = ref(null)
  const releaseDate = ref(null)
  const releaseNotes = ref('')
  const componentsToUpdate = ref([])
  
  const downloadProgress = ref({
    ui: { progress: 0, bytes_downloaded: 0, bytes_total: 0 },
    server: { progress: 0, bytes_downloaded: 0, bytes_total: 0 },
    firmware: { progress: 0, bytes_downloaded: 0, bytes_total: 0 }
  })
  
  const isChecking = ref(false)
  const isDownloading = ref(false)
  const isInstalling = ref(false)
  const lastChecked = ref(null)
  const errorMessage = ref(null)
  
  const currentVersions = ref({
    ui: '1.0.0',
    server: '1.0.0',
    firmware: '1.0.0'
  })
  
  const selectedComponents = ref({
    ui: false,
    server: true,
    firmware: false
  })
  
  const installPhase = ref('')
  const installSteps = ref([])
  const currentStep = ref(0)
  
  const overallDownloadProgress = computed(() => {
    const selectedKeys = Object.keys(selectedComponents.value).filter(k => selectedComponents.value[k])
    if (selectedKeys.length === 0) return 0
    
    const totalProgress = selectedKeys.reduce((sum, key) => {
      return sum + (downloadProgress.value[key]?.progress || 0)
    }, 0)
    
    return totalProgress / selectedKeys.length
  })
  
  const totalDownloadSize = computed(() => {
    return Object.values(downloadProgress.value).reduce((sum, item) => {
      return sum + (item.bytes_total || 0)
    }, 0)
  })
  
  const totalDownloaded = computed(() => {
    return Object.values(downloadProgress.value).reduce((sum, item) => {
      return sum + (item.bytes_downloaded || 0)
    }, 0)
  })
  
  function checkForUpdates() {
    isChecking.value = true
    errorMessage.value = null
    
    if (websocketStore.connected) {
      websocketStore.send({
        type: 'check_updates'
      })
    } else {
      errorMessage.value = 'Not connected to server'
      isChecking.value = false
    }
  }
  
  function downloadUpdates() {
    isDownloading.value = true
    errorMessage.value = null
    
    const selected = Object.keys(selectedComponents.value)
      .filter(k => selectedComponents.value[k])
    
    if (websocketStore.connected && selected.length > 0) {
      websocketStore.send({
        type: 'download_updates',
        components: selected
      })
    } else {
      errorMessage.value = selected.length === 0 ? 'No components selected' : 'Not connected to server'
      isDownloading.value = false
    }
  }
  
  function installUpdates() {
    isInstalling.value = true
    errorMessage.value = null
    
    const selected = Object.keys(selectedComponents.value)
      .filter(k => selectedComponents.value[k])
    
    if (websocketStore.connected && selected.length > 0) {
      websocketStore.send({
        type: 'install_updates',
        components: selected
      })
    } else {
      errorMessage.value = selected.length === 0 ? 'No components selected' : 'Not connected to server'
      isInstalling.value = false
    }
  }
  
  function toggleComponent(component) {
    selectedComponents.value[component] = !selectedComponents.value[component]
  }
  
  function selectAllComponents() {
    selectedComponents.value.ui = true
    selectedComponents.value.server = true
    selectedComponents.value.firmware = true
  }
  
  function selectOnlyServer() {
    selectedComponents.value.ui = false
    selectedComponents.value.server = true
    selectedComponents.value.firmware = false
  }
  
  function handleUpdateMessage(message) {
    switch (message.type) {
      case 'update_check_result':
        isChecking.value = false
        lastChecked.value = new Date()
        
        if (message.available) {
          updateAvailable.value = true
          availableVersion.value = message.version
          releaseDate.value = message.release_date
          releaseNotes.value = message.release_notes || ''
          componentsToUpdate.value = Object.keys(message.components)
          
          message.components.forEach((comp, data) => {
            if (downloadProgress.value[comp]) {
              downloadProgress.value[comp].bytes_total = data.size_bytes || 0
            }
          })
        } else {
          updateAvailable.value = false
        }
        break
        
      case 'update_progress':
        if (downloadProgress.value[message.component]) {
          downloadProgress.value[message.component] = {
            progress: message.progress || 0,
            bytes_downloaded: message.bytes_downloaded || 0,
            bytes_total: message.bytes_total || downloadProgress.value[message.component].bytes_total
          }
        }
        break
        
      case 'update_download_complete':
        isDownloading.value = false
        break
        
      case 'update_install_progress':
        installPhase.value = message.phase || ''
        if (message.steps) {
          installSteps.value = message.steps
        }
        if (message.current_step !== undefined) {
          currentStep.value = message.current_step
        }
        break
        
      case 'update_complete':
        isInstalling.value = false
        updateAvailable.value = false
        
        if (message.components) {
          message.components.forEach(comp => {
            if (message.versions && message.versions[comp]) {
              currentVersions.value[comp] = message.versions[comp]
            }
          })
        }
        break
        
      case 'update_error':
        errorMessage.value = message.error || 'Unknown error occurred'
        isChecking.value = false
        isDownloading.value = false
        isInstalling.value = false
        break
        
      case 'current_versions':
        if (message.versions) {
          currentVersions.value = { ...currentVersions.value, ...message.versions }
        }
        break
    }
  }
  
  function reset() {
    updateAvailable.value = false
    isDownloading.value = false
    isInstalling.value = false
    errorMessage.value = null
    installPhase.value = ''
    installSteps.value = []
    currentStep.value = 0
  }
  
  return {
    updateAvailable,
    availableVersion,
    releaseDate,
    releaseNotes,
    componentsToUpdate,
    downloadProgress,
    isChecking,
    isDownloading,
    isInstalling,
    lastChecked,
    errorMessage,
    currentVersions,
    selectedComponents,
    installPhase,
    installSteps,
    currentStep,
    overallDownloadProgress,
    totalDownloadSize,
    totalDownloaded,
    checkForUpdates,
    downloadUpdates,
    installUpdates,
    toggleComponent,
    selectAllComponents,
    selectOnlyServer,
    handleUpdateMessage,
    reset
  }
})

