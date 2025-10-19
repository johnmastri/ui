import { onMounted, onUnmounted } from 'vue'

export function useHardwareInput() {
  const handleMiddleClick = (callback, element = null) => {
    const handler = (event) => {
      if (event.button === 1) {
        event.preventDefault()
        event.stopPropagation()
        callback(event)
      }
    }
    
    const target = element || window
    target.addEventListener('mousedown', handler)
    
    return () => target.removeEventListener('mousedown', handler)
  }
  
  const handleWheelScroll = (callback, element = null) => {
    const handler = (event) => {
      event.preventDefault()
      event.stopPropagation()
      const direction = event.deltaY > 0 ? 1 : -1
      callback(direction, event)
    }
    
    const target = element || window
    target.addEventListener('wheel', handler, { passive: false })
    
    return () => target.removeEventListener('wheel', handler)
  }
  
  return {
    handleMiddleClick,
    handleWheelScroll
  }
}

