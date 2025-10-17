import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAudioControlStore = defineStore('audioControl', () => {
  // Modal visibility
  const isModalVisible = ref(false)
  
  // Track management
  const selectedTrackId = ref(1)
  const isTrackLoading = ref(false)
  
  // Playback state
  const isPlaying = ref(false)
  const playbackStatus = ref('stopped') // 'stopped', 'playing', 'paused', 'loading'
  const isFallbackMode = ref(false) // Indicates if using fallback audio
  
  // Volume control
  const outputGain = ref(-10) // dB level
  
  // Audio service reference (set by VUMeter)
  const audioServiceRef = ref(null)
  
  // Track library - using local audio files
  const availableTracks = ref([
    {
      id: 1,
      name: "Background Rich",
      url: "/audio/Background Rich.mp3",
      genre: "Ambient",
      bpm: 120,
      duration: "Unknown",
      isLoaded: false
    }
  ])
  
  // Computed properties (getters)
  const currentTrack = computed(() => availableTracks.value.find(t => t.id === selectedTrackId.value))
  const isAnyTrackLoaded = computed(() => availableTracks.value.some(t => t.isLoaded))
  const volumePercentage = computed(() => ((outputGain.value + 60) / 66) * 100) // Convert dB to %
  const canPlay = computed(() => currentTrack.value?.isLoaded && !isTrackLoading.value)
  
  // Actions
  const toggleModal = () => { 
    isModalVisible.value = !isModalVisible.value 
    console.log('🎛️ Audio Modal:', isModalVisible.value ? 'OPEN' : 'CLOSED')
  }
  
  const showModal = () => { isModalVisible.value = true }
  const hideModal = () => { isModalVisible.value = false }
  
  const selectTrack = (trackId) => { 
    console.log('🎵 Track selected:', trackId)
    selectedTrackId.value = trackId
    
    // Reset track loaded status for new selection
    const track = availableTracks.value.find(t => t.id === trackId)
    if (track) {
      track.isLoaded = false
    }
    
    // Reset fallback mode when selecting new track
    isFallbackMode.value = false
  }
  
  const markTrackLoaded = (trackId, fallbackMode = false) => { 
    const track = availableTracks.value.find(t => t.id === trackId)
    if (track) {
      track.isLoaded = true
      isFallbackMode.value = fallbackMode
      console.log('✅ Track loaded:', track.name, fallbackMode ? '(fallback mode)' : '')
    }
  }
  
  const play = () => { 
    if (audioServiceRef.value) {
      const success = audioServiceRef.value.play()
      if (success) {
        isPlaying.value = true
        playbackStatus.value = 'playing'
        console.log('▶️ Playback started')
      }
    } else {
      console.warn('⚠️ Audio service not available')
    }
  }
  
  const pause = () => { 
    if (audioServiceRef.value) {
      audioServiceRef.value.pause()
    }
    isPlaying.value = false
    playbackStatus.value = 'paused'
    console.log('⏸️ Playback paused')
  }
  
  const stop = () => { 
    if (audioServiceRef.value) {
      audioServiceRef.value.stop()
    }
    isPlaying.value = false
    playbackStatus.value = 'stopped'
    console.log('⏹️ Playback stopped')
  }
  
  const setLoading = (loading) => { 
    isTrackLoading.value = loading 
    console.log('🔄 Track loading:', loading)
  }
  
  const setOutputGain = (dbValue) => { 
    outputGain.value = Math.max(-60, Math.min(6, dbValue))
    
    // Apply volume to audio service if available
    if (audioServiceRef.value) {
      audioServiceRef.value.setVolume(outputGain.value)
    }
    
    console.log('🔊 Volume set to:', outputGain.value, 'dB')
  }
  
  const adjustVolume = (delta) => { 
    setOutputGain(outputGain.value + delta) 
  }
  
  const setFallbackMode = (fallback) => {
    isFallbackMode.value = fallback
    console.log('🔄 Fallback mode:', fallback)
  }
  
  const setAudioService = (audioService) => {
    audioServiceRef.value = audioService
    console.log('🔌 Audio service connected to store')
  }
  
  // Return public API
  return {
    // State
    isModalVisible,
    selectedTrackId,
    isTrackLoading,
    isPlaying,
    playbackStatus,
    outputGain,
    availableTracks,
    isFallbackMode,
    
    // Computed
    currentTrack,
    isAnyTrackLoaded,
    volumePercentage,
    canPlay,
    
    // Actions
    toggleModal,
    showModal,
    hideModal,
    selectTrack,
    markTrackLoaded,
    play,
    pause,
    stop,
    setLoading,
    setOutputGain,
    adjustVolume,
    setFallbackMode,
    setAudioService
  }
}) 