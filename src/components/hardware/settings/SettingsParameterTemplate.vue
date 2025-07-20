<template>
  <g :transform="`translate(0, ${yPosition})`">
    <g id="ParameterLabelAndValue">
      <text 
        id="SettingsLabel" 
        fill="#3ED72A" 
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