<template>
  <div class="navigation">
    <router-link to="/" class="nav-link" active-class="active">
      Main VST GUI
    </router-link>
    <router-link to="/virtual" class="nav-link" active-class="active">
      Virtual Hardware
    </router-link>
  </div>
</template>

<script setup>
// No additional logic needed
</script>

<style scoped>
.navigation {
  position: fixed;
  top: 10px;
  right: 10px;
  display: flex;
  gap: 10px;
  z-index: 1000;
}

.nav-link {
  padding: 8px 16px;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  text-decoration: none;
  border-radius: 4px;
  font-size: 12px;
  transition: all 0.2s ease;
}

.nav-link:hover {
  background: rgba(0, 0, 0, 0.9);
  transform: translateY(-1px);
}

.nav-link.active {
  background: #007bff;
  box-shadow: 0 2px 8px rgba(0, 123, 255, 0.3);
}
</style> 