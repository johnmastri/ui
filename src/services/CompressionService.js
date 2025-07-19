class CompressionService {
  constructor() {
    // VU ballistics timing
    this.integrationTime = 300 // ms (adjustable)
    this.lastUpdateTime = performance.now()
    this.currentNeedlePosition = 0
    
    // Smoothing parameters
    this.smoothingFactor = 0.15 // How quickly needle responds
  }

  /**
   * Calculate needle position based on audio level and peak reduction
   * @param {number} dbLevel - Audio level in dB from AudioAnalysisService (-60 to +6)
   * @param {number} peakReduction - Peak reduction knob value (0-100)
   * @returns {number} Needle rotation in degrees (0 to -62.1)
   */
  calculateNeedlePosition(dbLevel, peakReduction) {
    // Silence threshold
    if (dbLevel < -40) {
      return 0 // Needle at rest
    }
    
    // Calculate sensitivity based on peak reduction
    // Non-linear taper for more realistic response
    const sensitivity = this.calculateSensitivity(peakReduction)
    
    // Normalize audio level (-40dB to +6dB) to 0-1 range
    const normalizedLevel = Math.max(0, Math.min(1, (dbLevel + 40) / 46))
    
    // Calculate compression amount
    const compressionAmount = normalizedLevel * sensitivity
    
    // Convert to needle rotation (0 to -62.1 degrees)
    // More peak reduction = more needle movement
    return -compressionAmount * 62.1
  }

  /**
   * Calculate sensitivity from peak reduction with exponential curve
   * @param {number} peakReduction - Peak reduction value (0-100)
   * @returns {number} Sensitivity value (0-1)
   */
  calculateSensitivity(peakReduction) {
    // Exponential curve for more realistic LA-2A behavior
    // First 30% of knob rotation has gentle effect
    // Last 30% has dramatic effect
    const normalized = peakReduction / 100
    const k = 2.5 // Curve factor
    return (Math.exp(k * normalized) - 1) / (Math.exp(k) - 1)
  }

  /**
   * Smooth needle movement with adjustable ballistics
   * @param {number} targetPosition - Target needle position
   * @param {number} deltaTime - Time since last update in ms
   * @returns {number} Smoothed needle position
   */
  smoothNeedleMovement(targetPosition, deltaTime = 16) {
    // VU-style ballistics with different attack/release times
    const isAttacking = Math.abs(targetPosition) > Math.abs(this.currentNeedlePosition)
    
    // Faster attack, slower release for authentic VU behavior
    const smoothing = isAttacking ? this.smoothingFactor * 1.5 : this.smoothingFactor * 0.7
    
    // Exponential smoothing
    this.currentNeedlePosition += (targetPosition - this.currentNeedlePosition) * smoothing
    
    // Clamp to valid range
    this.currentNeedlePosition = Math.max(-62.1, Math.min(0, this.currentNeedlePosition))
    
    return this.currentNeedlePosition
  }

  /**
   * Reset needle to rest position
   */
  reset() {
    this.currentNeedlePosition = 0
  }
}

export default new CompressionService() 