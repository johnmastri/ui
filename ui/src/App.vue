<template>
  <div id="app">
    <!-- Development Navigation (hidden on hardware route) -->
    <Navigation v-if="isDevelopment && !isHardwareRoute" />
    <router-view />
  </div>
</template>

<script>
import Navigation from './components/Navigation.vue'

export default {
  name: 'App',
  components: {
    Navigation
  },
  computed: {
    isDevelopment() {
      return !window.__JUCE__ || import.meta.env.DEV
    },
    isHardwareRoute() {
      return this.$route?.name === 'Hardware'
    }
  }
}
</script>

<style>
#app {
  width: 100%;
  height: 100vh;
  margin: 0;
  padding: 0;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  padding: 0;
  background: #f5f5f5;
}
</style>
