<template>
  <div class="control-group">
    <h2 class="plugin-title">{{ pluginInfo.pluginName }}</h2>
    <div class="plugin-meta">
      <div><strong>Vendor:</strong> {{ pluginInfo.vendor }}</div>
      <div><strong>Version:</strong> {{ pluginInfo.pluginVersion }}</div>
      <div v-if="isDevelopment" class="dev-badge">🚀 Development Mode</div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useJuceIntegration } from '../composables/useJuceIntegration'

const { pluginInfo, isDevelopment } = useJuceIntegration()
</script>

<style scoped>
.control-group {
  margin-bottom: 20px;
  padding: 15px;
  background: #f5f5f5;
  border-radius: 8px;
  border: 1px solid #ddd;
}

.plugin-title {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 1.5em;
}

.plugin-meta {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  font-size: 0.9em;
  color: #666;
}

.dev-badge {
  background: #ff6b6b;
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.8em;
  font-weight: bold;
}
</style> 