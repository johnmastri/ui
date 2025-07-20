<template>
  <g id="SettingsHolder">
    <!-- Settings Parameter Templates -->
    <SettingsParameterTemplate 
      label="Display Brightness"
      value="75%"
      :enabled="settings.displayBrightness"
      @toggle-change="handleSettingChange"
    />
    <SettingsParameterTemplate 
      label="Auto Sleep"
      value="5 MIN"
      :enabled="settings.autoSleep"
      @toggle-change="handleSettingChange"
    />

    <!-- Green marker -->
    <rect 
      id="marker" 
      x="128" 
      y="147" 
      width="9" 
      height="50" 
      fill="#3ED72A"
    />

    <!-- Settings Header -->
    <text 
      id="SettingsHeader" 
      fill="white" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="IBM Plex Sans Condensed" 
      font-size="48" 
      font-style="italic" 
      letter-spacing="0em"
    >
      <tspan x="149" y="112">display</tspan>
    </text>
  </g>
</template>

<script>
import SettingsParameterTemplate from './SettingsParameterTemplate.vue'

export default {
  name: 'SettingsHolder',
  components: {
    SettingsParameterTemplate
  },
  data() {
    return {
      settings: {
        displayBrightness: true,
        autoSleep: false
      }
    }
  },
  methods: {
    handleSettingChange({ label, enabled }) {
      // Update the corresponding setting
      if (label === 'Display Brightness') {
        this.settings.displayBrightness = enabled
      } else if (label === 'Auto Sleep') {
        this.settings.autoSleep = enabled
      }
      
      // Emit the change to parent component
      this.$emit('settings-change', {
        setting: label,
        enabled: enabled,
        allSettings: this.settings
      })
      
      console.log(`Setting "${label}" changed to: ${enabled}`)
    }
  }
}
</script> 