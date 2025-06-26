<template>
  <div id="app">
    <!-- Development Navigation -->
    <Navigation v-if="isDevelopment" />
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
