<template>
  <g>
    <rect x="0" y="0" width="800" height="480" fill="#000" />
    
    <text 
      x="400" 
      y="40" 
      text-anchor="middle" 
      fill="#fff" 
      font-size="24" 
      font-family="Arial, sans-serif"
      font-weight="bold"
    >
      SYSTEM UPDATE
    </text>
    
    <g v-if="!updateStore.updateAvailable && !updateStore.isChecking">
      <text x="400" y="150" text-anchor="middle" fill="#888" font-size="18">
        No updates available
      </text>
      
      <text x="400" y="190" text-anchor="middle" fill="#666" font-size="14">
        Current Versions:
      </text>
      
      <text x="200" y="230" text-anchor="middle" fill="#fff" font-size="14">
        UI: {{ updateStore.currentVersions.ui }}
      </text>
      <text x="400" y="230" text-anchor="middle" fill="#fff" font-size="14">
        Server: {{ updateStore.currentVersions.server }}
      </text>
      <text x="600" y="230" text-anchor="middle" fill="#fff" font-size="14">
        Firmware: {{ updateStore.currentVersions.firmware }}
      </text>
      
      <text v-if="updateStore.lastChecked" x="400" y="280" text-anchor="middle" fill="#666" font-size="12">
        Last checked: {{ formatDate(updateStore.lastChecked) }}
      </text>
      
      <g @click="updateStore.checkForUpdates" style="cursor: pointer;">
        <rect x="300" y="320" width="200" height="50" fill="#333" stroke="#666" stroke-width="2" rx="4" />
        <text x="400" y="352" text-anchor="middle" fill="#fff" font-size="16">
          Check for Updates
        </text>
      </g>
    </g>
    
    <g v-else-if="updateStore.isChecking">
      <text x="400" y="240" text-anchor="middle" fill="#fff" font-size="18">
        Checking for updates...
      </text>
    </g>
    
    <g v-else-if="updateStore.updateAvailable && !updateStore.isDownloading && !updateStore.isInstalling">
      <text x="400" y="100" text-anchor="middle" fill="#4CAF50" font-size="18">
        Update Available: v{{ updateStore.availableVersion }}
      </text>
      
      <text x="100" y="140" fill="#888" font-size="14">
        Select components to update:
      </text>
      
      <g 
        v-for="(component, idx) in ['ui', 'server', 'firmware']" 
        :key="component"
        @click="updateStore.toggleComponent(component)"
        style="cursor: pointer;"
      >
        <rect 
          :x="100" 
          :y="160 + idx * 40" 
          width="20" 
          height="20" 
          fill="#222" 
          stroke="#666" 
          stroke-width="2" 
        />
        <text 
          v-if="updateStore.selectedComponents[component]"
          :x="110" 
          :y="177 + idx * 40" 
          text-anchor="middle" 
          fill="#4CAF50" 
          font-size="18"
          font-weight="bold"
        >
          ✓
        </text>
        <text 
          :x="135" 
          :y="177 + idx * 40" 
          fill="#fff" 
          font-size="14"
        >
          {{ component.toUpperCase() }}: {{ updateStore.currentVersions[component] }} → {{ updateStore.availableVersion }}
        </text>
      </g>
      
      <text v-if="updateStore.releaseNotes" x="100" y="310" fill="#888" font-size="12">
        {{ updateStore.releaseNotes.substring(0, 80) }}
      </text>
      
      <g @click="updateStore.downloadUpdates" style="cursor: pointer;">
        <rect x="250" y="360" width="300" height="50" fill="#1976D2" stroke="#2196F3" stroke-width="2" rx="4" />
        <text x="400" y="392" text-anchor="middle" fill="#fff" font-size="16">
          Download Update
        </text>
      </g>
    </g>
    
    <g v-else-if="updateStore.isDownloading">
      <text x="400" y="140" text-anchor="middle" fill="#fff" font-size="18">
        Downloading Updates...
      </text>
      
      <g v-for="(component, idx) in Object.keys(updateStore.selectedComponents).filter(k => updateStore.selectedComponents[k])" :key="component">
        <text :x="100" :y="190 + idx * 60" fill="#fff" font-size="14">
          {{ component.toUpperCase() }}:
        </text>
        
        <rect 
          :x="100" 
          :y="200 + idx * 60" 
          width="600" 
          height="20" 
          fill="#222" 
          stroke="#666" 
          stroke-width="1" 
        />
        <rect 
          :x="100" 
          :y="200 + idx * 60" 
          :width="600 * updateStore.downloadProgress[component].progress" 
          height="20" 
          fill="#1976D2" 
        />
        
        <text 
          :x="400" 
          :y="215 + idx * 60" 
          text-anchor="middle" 
          fill="#fff" 
          font-size="12"
        >
          {{ Math.round(updateStore.downloadProgress[component].progress * 100) }}% 
          ({{ formatBytes(updateStore.downloadProgress[component].bytes_downloaded) }} / {{ formatBytes(updateStore.downloadProgress[component].bytes_total) }})
        </text>
      </g>
      
      <text x="400" y="380" text-anchor="middle" fill="#888" font-size="14">
        Overall: {{ Math.round(updateStore.overallDownloadProgress * 100) }}%
      </text>
    </g>
    
    <g v-else-if="updateStore.isInstalling">
      <text x="400" y="140" text-anchor="middle" fill="#fff" font-size="18">
        Installing Updates...
      </text>
      
      <text x="400" y="180" text-anchor="middle" fill="#FFA726" font-size="14">
        ⚠ Please do not power off
      </text>
      
      <text x="100" y="230" fill="#888" font-size="14">
        Current Step:
      </text>
      
      <g v-for="(step, idx) in updateStore.installSteps" :key="idx">
        <text 
          :x="120" 
          :y="260 + idx * 30" 
          :fill="idx < updateStore.currentStep ? '#4CAF50' : idx === updateStore.currentStep ? '#fff' : '#666'" 
          font-size="12"
        >
          {{ idx < updateStore.currentStep ? '✓' : idx === updateStore.currentStep ? '→' : ' ' }} {{ step }}
        </text>
      </g>
    </g>
    
    <text v-if="updateStore.errorMessage" x="400" y="450" text-anchor="middle" fill="#F44336" font-size="12">
      Error: {{ updateStore.errorMessage }}
    </text>
  </g>
</template>

<script>
import { useUpdateStore } from '../../../stores/updateStore'

export default {
  name: 'UpdatePanel',
  setup() {
    const updateStore = useUpdateStore()
    
    const formatDate = (date) => {
      if (!date) return ''
      const d = new Date(date)
      return d.toLocaleTimeString()
    }
    
    const formatBytes = (bytes) => {
      if (bytes === 0) return '0 B'
      const k = 1024
      const sizes = ['B', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
    }
    
    return {
      updateStore,
      formatDate,
      formatBytes
    }
  }
}
</script>

