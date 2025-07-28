<template>
  <g :transform="`translate(0, ${yPosition})`">
    <!-- Highlight background if selected -->
    <rect
      v-if="showBg"
      x="128"
      y="150"
      width="620"
      height="50"
      fill="#222"
      :opacity="bgOpacity"
      rx="8"
    />
    <g id="ParameterLabelAndValue">
      <text 
        id="SettingsLabel" 
        :fill="isSelected ? '#3ED72A' : '#F8F8F8'"
        xml:space="preserve" 
        style="white-space: pre" 
        font-family="Barlow" 
        font-size="32" 
        font-weight="600" 
        letter-spacing="0.04em"
      >
        <tspan x="148" y="182.8">{{ parameter.label }}</tspan>
      </text>
      
      <!-- Toggle Button -->
      <ToggleButton 
        v-if="parameter.type === 'toggle'"
        v-model="parameter.value"
        :x="596" 
        :y="158"
        @change="handleParameterChange"
      />
      
      <!-- Select Component -->
      <SettingsSelect 
        v-else-if="parameter.type === 'select'"
        v-model="parameter.value"
        :options="parameter.options"
        :parameter-id="parameter.id"
        @change="handleParameterChange"
      />
      
      <!-- Display Component -->
      <SettingsParameterValue 
        v-else-if="parameter.type === 'display'"
        :value="parameter.value"
      />
      
      <!-- Button Component -->
      <SettingsButton 
        v-else-if="parameter.type === 'button'"
        :value="parameter.value"
        @click="handleButtonClick"
      />
    </g>
    <path id="Vector 3" d="M148 204H736" stroke="#792929"/>
  </g>
</template>

<script>
import ToggleButton from './ToggleButton.vue'
import SettingsParameterValue from './SettingsParameterValue.vue'
import SettingsSelect from './SettingsSelect.vue'
import SettingsButton from './SettingsButton.vue'
import { gsap } from 'gsap'

export default {
  name: 'SettingsParameterTemplate',
  components: {
    ToggleButton,
    SettingsParameterValue,
    SettingsSelect,
    SettingsButton
  },
  props: {
    parameter: {
      type: Object,
      required: true
    },
    yPosition: {
      type: Number,
      default: 0
    },
    isSelected: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      bgOpacity: 0,
      showBg: false
    }
  },
  watch: {
    isSelected(newVal) {
      if (newVal) {
        this.showBg = true
        gsap.to(this, { bgOpacity: 0.85, duration: 0.25, ease: 'power2.out' })
      } else {
        gsap.to(this, { bgOpacity: 0, duration: 0.2, ease: 'power2.in', onComplete: () => { this.showBg = false } })
      }
    }
  },
  mounted() {
    if (this.isSelected) {
      this.bgOpacity = 0.85
      this.showBg = true
    }
  },
  methods: {
    handleParameterChange(newValue) {
      this.$emit('parameter-change', {
        id: this.parameter.id,
        value: newValue,
        type: this.parameter.type
      })
    },
    handleButtonClick(value) {
      this.$emit('button-click', {
        id: this.parameter.id,
        value: value,
        type: this.parameter.type
      })
    }
  }
}
</script> 