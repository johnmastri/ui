<template>
  <g id="SettingsParameterValue">
    <text 
      id="SettingsParameterValue_2" 
      fill="#3ED72A" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="Barlow" 
      font-size="24" 
      font-weight="bold" 
      letter-spacing="0.04em"
    >
      <tspan x="672.49" y="179.6">{{ value }}</tspan>
    </text>
  </g>
</template>

<script>
export default {
  name: 'SettingsParameterValue',
  props: {
    value: {
      type: String,
      default: '1 SEC'
    }
  }
}
</script> 