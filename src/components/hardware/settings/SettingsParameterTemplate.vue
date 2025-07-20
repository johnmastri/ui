<template>
  <g id="SettingsParameterTemplate">
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
        <tspan x="148" y="182.8">{{ label }}</tspan>
      </text>
      <ToggleButton 
        v-model="isEnabled"
        :x="540.5" 
        :y="158"
        @change="handleToggleChange"
      />
      <SettingsParameterValue :value="value" />
    </g>
    <path id="Vector 3" d="M148 204H736" stroke="#792929"/>
  </g>
</template>

<script>
import ToggleButton from './ToggleButton.vue'
import SettingsParameterValue from './SettingsParameterValue.vue'

export default {
  name: 'SettingsParameterTemplate',
  components: {
    ToggleButton,
    SettingsParameterValue
  },
  props: {
    label: {
      type: String,
      default: 'Large Parameter Display'
    },
    value: {
      type: String,
      default: '1 SEC'
    },
    enabled: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      isEnabled: this.enabled
    }
  },
  methods: {
    handleToggleChange(newValue) {
      this.isEnabled = newValue
      this.$emit('toggle-change', {
        label: this.label,
        enabled: newValue
      })
    }
  },
  watch: {
    enabled(newValue) {
      this.isEnabled = newValue
    }
  }
}
</script> 