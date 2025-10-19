import { onMounted, onUnmounted } from 'vue'

export function useModalBlocker(isActive) {
  const blockEvent = (event) => {
    if (isActive.value) {
      event.stopPropagation()
    }
  }
  
  onMounted(() => {
    if (isActive.value) {
      document.addEventListener('mousedown', blockEvent, true)
      document.addEventListener('wheel', blockEvent, true)
      document.addEventListener('click', blockEvent, true)
    }
  })
  
  onUnmounted(() => {
    document.removeEventListener('mousedown', blockEvent, true)
    document.removeEventListener('wheel', blockEvent, true)
    document.removeEventListener('click', blockEvent, true)
  })
  
  return {
    blockEvent
  }
}

