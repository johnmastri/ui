class AudioAnalysisService {
  constructor() {
    // Audio components
    this.audioContext = null
    this.analyserNode = null
    this.audioElement = null
    this.sourceNode = null
    this.gainNode = null
    
    // Analysis data
    this.dataArray = null
    this.isInitialized = false
    this.isAnalyzing = false
    
    // Current volume data
    this.currentVolume = 0 // 0-100 scale
    this.currentDbLevel = -60 // dB scale
    
    // Callbacks
    this.onVolumeUpdate = null
    
    console.log('🎵 AudioAnalysisService created')
  }
  
  async init() {
    try {
      // Create audio context
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
      
      // Create analyser node
      this.analyserNode = this.audioContext.createAnalyser()
      this.analyserNode.fftSize = 2048
      this.analyserNode.smoothingTimeConstant = 0.8
      
      // Create gain node for volume control
      this.gainNode = this.audioContext.createGain()
      
      // Create data array for analysis
      this.dataArray = new Uint8Array(this.analyserNode.frequencyBinCount)
      
      this.isInitialized = true
      console.log('✅ AudioAnalysisService initialized')
      
    } catch (error) {
      console.error('❌ Failed to initialize AudioAnalysisService:', error)
      throw error
    }
  }
  
  async loadTrack(url) {
    if (!this.isInitialized) {
      await this.init()
    }
    
    try {
      console.log('🔄 Loading track:', url)
      
      // Create audio element
      this.audioElement = new Audio()
      this.audioElement.crossOrigin = 'anonymous'
      this.audioElement.src = url
      
      // Set up timeout for loading
      const loadTimeout = 10000 // 10 seconds
      
      // Wait for audio to be loadable with timeout
      await new Promise((resolve, reject) => {
        const timeoutId = setTimeout(() => {
          reject(new Error('Audio loading timeout'))
        }, loadTimeout)
        
        const cleanup = () => {
          clearTimeout(timeoutId)
          this.audioElement.removeEventListener('canplaythrough', onLoad)
          this.audioElement.removeEventListener('error', onError)
          this.audioElement.removeEventListener('loadeddata', onLoad)
        }
        
        const onLoad = () => {
          cleanup()
          resolve()
        }
        
        const onError = (event) => {
          cleanup()
          reject(new Error(`Audio load error: ${event.target.error?.message || 'Unknown error'}`))
        }
        
        this.audioElement.addEventListener('canplaythrough', onLoad)
        this.audioElement.addEventListener('loadeddata', onLoad) // Fallback event
        this.audioElement.addEventListener('error', onError)
        this.audioElement.load()
      })
      
      // Connect audio graph: source -> gain -> analyser -> destination
      if (this.sourceNode) {
        this.sourceNode.disconnect()
      }
      
      this.sourceNode = this.audioContext.createMediaElementSource(this.audioElement)
      this.sourceNode.connect(this.gainNode)
      this.gainNode.connect(this.analyserNode)
      this.analyserNode.connect(this.audioContext.destination)
      
      console.log('✅ Track loaded and connected')
      return true
      
    } catch (error) {
      console.error('❌ Failed to load track:', error.message || error)
      
      // Create fallback oscillator for demo purposes
      await this.createFallbackAudio()
      return false // Indicate fallback mode
    }
  }
  
  async createFallbackAudio() {
    try {
      console.log('🔄 Creating fallback audio source...')
      
      // Disconnect any existing source
      if (this.sourceNode) {
        this.sourceNode.disconnect()
      }
      
      // Create oscillator as fallback
      this.oscillator = this.audioContext.createOscillator()
      this.oscillator.frequency.setValueAtTime(440, this.audioContext.currentTime) // A4 note
      this.oscillator.type = 'sine'
      
      // Connect: oscillator -> gain -> analyser -> destination
      this.oscillator.connect(this.gainNode)
      this.gainNode.connect(this.analyserNode)
      this.analyserNode.connect(this.audioContext.destination)
      
      // Start the oscillator
      this.oscillator.start()
      
      console.log('✅ Fallback audio source created (440Hz tone)')
      return true
      
    } catch (error) {
      console.error('❌ Failed to create fallback audio:', error)
      return false
    }
  }
  
  play() {
    if (!this.audioElement) return false
    
    try {
      // Resume audio context if suspended
      if (this.audioContext.state === 'suspended') {
        this.audioContext.resume()
      }
      
      this.audioElement.play()
      this.startAnalysis()
      console.log('▶️ Audio playback started')
      return true
      
    } catch (error) {
      console.error('❌ Failed to play audio:', error)
      return false
    }
  }
  
  pause() {
    if (!this.audioElement) return false
    
    this.audioElement.pause()
    this.stopAnalysis()
    console.log('⏸️ Audio playback paused')
    return true
  }
  
  stop() {
    if (!this.audioElement) return false
    
    this.audioElement.pause()
    this.audioElement.currentTime = 0
    this.stopAnalysis()
    this.currentVolume = 0
    this.currentDbLevel = -60
    console.log('⏹️ Audio playback stopped')
    return true
  }
  
  setVolume(dbLevel) {
    if (!this.gainNode) return
    
    // Convert dB to linear gain: gain = 10^(dB/20)
    const linearGain = Math.pow(10, dbLevel / 20)
    this.gainNode.gain.setValueAtTime(linearGain, this.audioContext.currentTime)
    
    console.log('🔊 Volume set to:', dbLevel, 'dB (gain:', linearGain.toFixed(3), ')')
  }
  
  startAnalysis() {
    if (this.isAnalyzing) return
    
    this.isAnalyzing = true
    this.analyzeLoop()
    console.log('📊 Audio analysis started')
  }
  
  stopAnalysis() {
    this.isAnalyzing = false
    // Reset to silence
    this.currentVolume = 0
    this.currentDbLevel = -60
    if (this.onVolumeUpdate) {
      this.onVolumeUpdate(this.currentVolume, this.currentDbLevel)
    }
    console.log('📊 Audio analysis stopped')
  }
  
  analyzeLoop() {
    if (!this.isAnalyzing) return
    
    // Get frequency data
    this.analyserNode.getByteFrequencyData(this.dataArray)
    
    // Calculate RMS (Root Mean Square) for overall volume
    let sum = 0
    for (let i = 0; i < this.dataArray.length; i++) {
      sum += this.dataArray[i] * this.dataArray[i]
    }
    const rms = Math.sqrt(sum / this.dataArray.length)
    
    // Convert to dB: 20 * log10(amplitude / max)
    // dataArray values are 0-255, so max is 255
    this.currentDbLevel = rms > 0 ? 20 * Math.log10(rms / 255) : -60
    
    // Clamp to reasonable range
    this.currentDbLevel = Math.max(-60, Math.min(6, this.currentDbLevel))
    
    // Convert dB to 0-100 scale for easier use
    // -60dB = 0, 0dB = 90, +6dB = 100
    this.currentVolume = ((this.currentDbLevel + 60) / 66) * 100
    this.currentVolume = Math.max(0, Math.min(100, this.currentVolume))
    
    // Notify listeners
    if (this.onVolumeUpdate) {
      this.onVolumeUpdate(this.currentVolume, this.currentDbLevel)
    }
    
    // Continue analysis loop
    requestAnimationFrame(() => this.analyzeLoop())
  }
  
  // Get current volume (0-100)
  getCurrentVolume() {
    return this.currentVolume
  }
  
  // Get current dB level  
  getCurrentDbLevel() {
    return this.currentDbLevel
  }
  
  // Set volume update callback
  setVolumeUpdateCallback(callback) {
    this.onVolumeUpdate = callback
  }
  
  // Cleanup
  destroy() {
    this.stopAnalysis()
    
    if (this.audioElement) {
      this.audioElement.pause()
      this.audioElement = null
    }
    
    if (this.oscillator) {
      try {
        this.oscillator.stop()
      } catch (e) {
        // Oscillator may already be stopped
      }
      this.oscillator = null
    }
    
    if (this.sourceNode) {
      this.sourceNode.disconnect()
      this.sourceNode = null
    }
    
    if (this.audioContext && this.audioContext.state !== 'closed') {
      this.audioContext.close()
      this.audioContext = null
    }
    
    console.log('🗑️ AudioAnalysisService destroyed')
  }
}

export default AudioAnalysisService