<template>
  <g ref="SettingsHolder" id="SettingsHolder">
    <!-- Settings Parameter Templates -->
    <SettingsParameterTemplate 
      v-for="(parameter, index) in currentParameters" 
      :key="parameter.id"
      :parameter="parameter"
      :y-position="calculateYPosition(index)"
      @parameter-change="handleParameterChange"
      @button-click="handleButtonClick"
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
      <tspan x="149" y="112">{{ headerText }}</tspan>
    </text>
  </g>
</template>

<script>
import SettingsParameterTemplate from './SettingsParameterTemplate.vue'
import { useHardwareSettingsStore } from '../../../stores/hardwareSettingsStore'
import { gsap } from 'gsap'

export default {
  name: 'SettingsHolder',
  components: {
    SettingsParameterTemplate
  },
  setup() {
    const hardwareSettingsStore = useHardwareSettingsStore()
    return {
      hardwareSettingsStore
    }
  },
  computed: {
    currentParameters() {
      console.log('SettingsHolder: currentSelectedButton:', this.hardwareSettingsStore.currentSelectedButton)
      const currentSetting = this.hardwareSettingsStore.getSettingForButton(
        this.hardwareSettingsStore.currentSelectedButton
      )
      console.log('SettingsHolder: currentSetting:', currentSetting)
      return currentSetting ? currentSetting.parameters : []
    },
    headerText() {
      const currentButton = this.hardwareSettingsStore.buttons.find(
        btn => btn.id === this.hardwareSettingsStore.currentSelectedButton
      )
      return currentButton ? currentButton.label.toLowerCase() : 'settings'
    }
  },
  methods: {

    fadeIn() {

      // gsap.from(this.$refs.SettingsHolder, {
      //   x: -10,
      //   duration: 1,
      //   delay: 0.3,
      //   ease: "power2.out"
      // })
     
      gsap.to(this.$refs.SettingsHolder, {
        opacity: 1,
        duration: 1,
        delay: 0.3,
        ease: "elastic.out(1, 1)"
      })
   
    },

    fadeOut() {
      gsap.to(this.$refs.SettingsHolder, {
        opacity: 0,
        duration: 0.2,
        ease: "power2.in"
      })
    },

    calculateYPosition(index) {
      const baseY = 0 // Base position (no offset needed since we're using transform)
      const spacing = 67 // Spacing between parameters
      return baseY + (index * spacing)
    },
    handleParameterChange({ id, value, type }) {
      // Update the parameter in the store
      const currentSetting = this.hardwareSettingsStore.getSettingForButton(
        this.hardwareSettingsStore.currentSelectedButton
      )
      
      if (currentSetting) {
        const parameter = currentSetting.parameters.find(p => p.id === id)
        if (parameter) {
          parameter.value = value
          
          // Emit the change to parent component
          this.$emit('settings-change', {
            category: this.hardwareSettingsStore.currentSelectedButton,
            parameterId: id,
            value: value,
            type: type
          })
          
          console.log(`Setting "${parameter.label}" changed to: ${value}`)
        }
      }
    },
    handleButtonClick({ id, value, type }) {
      // Handle button clicks (no functions assigned yet)
      const currentSetting = this.hardwareSettingsStore.getSettingForButton(
        this.hardwareSettingsStore.currentSelectedButton
      )
      
      if (currentSetting) {
        const parameter = currentSetting.parameters.find(p => p.id === id)
        if (parameter) {
          // Emit the button click to parent component
          this.$emit('button-click', {
            category: this.hardwareSettingsStore.currentSelectedButton,
            parameterId: id,
            value: value,
            type: type
          })
          
          console.log(`Button "${parameter.label}" clicked: ${value}`)
        }
      }
    }
  }
}
</script>

<style scoped>
#SettingsHolder {
  opacity: 0;
}
</style> 