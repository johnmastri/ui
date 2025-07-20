<template>
  <g id="SettingsHolder">
    <!-- Settings Parameter Templates -->
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
          <tspan x="148" y="182.8">Large Parameter Display</tspan>
        </text>
        <g id="ToggleButton">
          <rect 
            x="540.5" 
            y="158" 
            width="66" 
            height="24" 
            rx="12" 
            stroke="#DCDCDC"
          />
          <circle 
            id="Ellipse 4" 
            cx="553.5" 
            cy="170" 
            r="9" 
            fill="#EBEBEB" 
            stroke="#D0D0D0"
          />
        </g>
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
            <tspan x="672.49" y="179.6">1 SEC</tspan>
          </text>
        </g>
      </g>
      <path id="Vector 3" d="M148 204H736" stroke="#792929"/>
    </g>

    <g id="SettingsParameterTemplate_2">
      <g id="ParameterLabelAndValue_2">
        <text 
          id="SettingsLabel_2" 
          fill="#3ED72A" 
          xml:space="preserve" 
          style="white-space: pre" 
          font-family="Barlow" 
          font-size="32" 
          font-weight="600" 
          letter-spacing="0.04em"
        >
          <tspan x="148" y="249.8">Large Parameter Display</tspan>
        </text>
        <g id="ToggleButton_2">
          <rect 
            x="540.5" 
            y="225" 
            width="66" 
            height="24" 
            rx="12" 
            stroke="#DCDCDC"
          />
          <circle 
            id="Ellipse 4_2" 
            cx="553.5" 
            cy="237" 
            r="9" 
            fill="#EBEBEB" 
            stroke="#D0D0D0"
          />
        </g>
        <g id="SettingsParameterValue_3">
          <text 
            id="SettingsParameterValue_4" 
            fill="#3ED72A" 
            xml:space="preserve" 
            style="white-space: pre" 
            font-family="Barlow" 
            font-size="24" 
            font-weight="bold" 
            letter-spacing="0.04em"
          >
            <tspan x="672.49" y="246.6">1 SEC</tspan>
          </text>
        </g>
      </g>
      <path id="Vector 3_2" d="M148 271H736" stroke="#792929"/>
    </g>

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
export default {
  name: 'SettingsHolder'
}
</script> 