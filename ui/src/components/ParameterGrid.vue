<template>
  <div class="parameter-grid-container">
    <!-- No Parameters State -->
    <div v-if="parameters.length === 0" class="no-parameters">
      <div class="no-parameters-icon">🎛️</div>
      <div class="no-parameters-text">No VST loaded</div>
      <div class="no-parameters-subtext">Load a VST plugin to see its parameters</div>
      <button @click="loadMockData" class="mock-data-button">
        🎯 Load Mock Data
      </button>
    </div>
    
    <!-- Parameters Grid -->
    <div v-else class="parameters-grid">
      <ParameterKnob
        v-for="param in parameters"
        :key="param.id"
        :paramId="param.id"
        @value-changed="handleValueChanged"
        @color-changed="handleColorChanged"
      />
    </div>
  </div>
</template>

<script>
import { useParameterStore } from '../stores/parameterStore.js'
import ParameterKnob from './ParameterKnob.vue'

export default {
  name: 'ParameterGrid',
  components: {
    ParameterKnob
  },
  data() {
    return {
      store: useParameterStore()
    }
  },
  computed: {
    parameters() {
      return this.store.parameters
    }
  },
  methods: {
    loadMockData() {
      this.store.loadMockData()
      this.$emit('mock-data-loaded')
    },
    
    handleValueChanged(value) {
      this.$emit('value-changed', value)
    },
    
    handleColorChanged(color) {
      this.$emit('color-changed', color)
    }
  }
}
</script>

<style scoped>
.parameter-grid-container {
  width: 100%;
}

.no-parameters {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
  color: #666;
}

.no-parameters-icon {
  font-size: 48px;
  margin-bottom: 16px;
  opacity: 0.5;
}

.no-parameters-text {
  font-size: 18px;
  font-weight: 500;
  margin-bottom: 8px;
  color: #333;
}

.no-parameters-subtext {
  font-size: 14px;
  color: #888;
}

.mock-data-button {
  margin-top: 20px;
  padding: 12px 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 25px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.mock-data-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
}

.mock-data-button:active {
  transform: translateY(0);
  box-shadow: 0 2px 10px rgba(102, 126, 234, 0.4);
}

.parameters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 20px;
  padding: 20px;
  background: #f8f8f8;
  border-radius: 8px;
  border: 1px solid #e0e0e0;
}
</style> 