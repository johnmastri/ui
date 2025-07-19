<template>
  <g id="ParameterOverlay">
    <!-- PARAMETER NAME -->
    <text 
      id="PARAMETER-NAME" 
      x="256.402" 
      y="391.8" 
      fill="#504523" 
      font-family="Barlow" 
      font-size="32" 
      font-weight="bold" 
      letter-spacing="0.04em"
      xml:space="preserve"
      style="white-space: pre"
    >
      {{ hardwareStore.displayText }}
    </text>
    
    <!-- TRACK NAME -->
    <text 
      id="TRACK-NAME" 
      x="563.962" 
      y="113.9" 
      fill="#504523" 
      fill-opacity="0.78"
      font-family="Barlow" 
      font-size="26" 
      font-style="italic"
      font-weight="bold" 
      letter-spacing="0.04em"
      xml:space="preserve"
      style="white-space: pre"
    >
      {{ hardwareStore.trackName }}
    </text>
    
    <!-- PARAMETER VALUE (the big number) -->
    <text 
      id="PARAMETER-VALUE" 
      x="270.187" 
      y="325.106" 
      fill="#504523" 
      font-family="Barlow" 
      font-size="250" 
      font-style="italic"
      font-weight="800" 
      letter-spacing="0em"
      xml:space="preserve"
      style="white-space: pre"
    >
      {{ hardwareStore.displayValue }}
    </text>
    
    <!-- PLUGIN NAME -->
    <text 
      id="PLUGIN-NAME" 
      x="77" 
      y="115.9" 
      fill="#888249" 
      font-family="Barlow" 
      font-size="26" 
      font-style="italic"
      font-weight="bold" 
      letter-spacing="0.04em"
      xml:space="preserve"
      style="white-space: pre"
    >
      {{ hardwareStore.pluginName }}
    </text>
  </g>
</template>

<script setup>
import { useHardwareStore } from '../stores/hardwareStore'

// Get hardware store
const hardwareStore = useHardwareStore()
</script> 