class CompressionService {
  constructor() {
    // VU ballistics timing
    this.integrationTime = 300 // ms (adjustable)
    this.lastUpdateTime = performance.now()
    this.currentNeedlePosition = 0
    
    // Overshoot tracking
    this.previousTargetPosition = 0
    this.currentOvershoot = 0
    
    // Note: smoothingFactor now comes from hardwareStore
  }

  /**
   * Calculate needle position based on audio level and peak reduction
   * @param {number} dbLevel - Audio level in dB from AudioAnalysisService (-60 to +6)
   * @param {number} peakReduction - Peak reduction knob value (0-100)
   * @param {number} reactivityMultiplier - Visual amplification factor (0-2)
   * @param {number} overshootMultiplier - Transient overshoot factor (0-10)
   * @returns {number} Needle rotation in degrees (0 to -62.1)
   */
  calculateNeedlePosition(dbLevel, peakReduction, reactivityMultiplier = 1, overshootMultiplier = 0) {
    // Silence threshold
    if (dbLevel < -40) {
      this.previousTargetPosition = 0
      this.currentOvershoot = 0
      return 0 // Needle at rest
    }
    
    // Calculate sensitivity based on peak reduction
    const sensitivity = this.calculateSensitivity(peakReduction)
    
    // For gain reduction mode, we need to calculate how many dB of reduction
    // Real LA-2A at PR=20 shows -2 to -5 dB reduction on typical signals
    
    // Calculate gain reduction in dB based on input level and sensitivity
    // Higher input levels + higher sensitivity = more gain reduction
    const inputStrength = Math.max(0, (dbLevel + 20) / 26) // Normalize -20 to +6 dB range
    const gainReductionDB = -inputStrength * sensitivity * 45 // Increased to 45 for aggressive LA-2A compression
    
    // Debug logging
    // console.log('🎚️ GR Calculation:', {
    //   dbLevel,
    //   peakReduction,
    //   sensitivity: sensitivity.toFixed(3),
    //   inputStrength: inputStrength.toFixed(3),
    //   gainReductionDB: gainReductionDB.toFixed(1),
    // })
    
    // Convert dB to degrees
    // VU meter: -20dB = -62.1°, 0dB = 0°, +3dB = 33.3°
    // For gain reduction: 1 dB ≈ 3.1° (62.1° / 20 dB)
    const degreesPerDB = 3.105
    let targetPosition = gainReductionDB * degreesPerDB * reactivityMultiplier
    
    // console.log('🎯 Final rotation:', {
    //   gainReductionDB: gainReductionDB.toFixed(1),
    //   degreesPerDB,
    //   reactivityMultiplier,
    //   targetPosition: targetPosition.toFixed(1) + '°'
    // })
    
    // Detect transient (rapid increase in compression)
    const delta = Math.abs(targetPosition) - Math.abs(this.previousTargetPosition)
    const isTransient = delta > 1 // More than 1 degree sudden change
    
    // Apply overshoot on transients
    if (isTransient && delta > 0 && overshootMultiplier > 0) {
      // Calculate overshoot based on transient size
      this.currentOvershoot = delta * overshootMultiplier
    }
    
    // Store for next comparison
    this.previousTargetPosition = targetPosition
    
    // Apply overshoot and clamp
    return Math.max(-62.1, targetPosition - this.currentOvershoot)
  }

  /**
   * Calculate sensitivity from peak reduction with exponential curve
   * @param {number} peakReduction - Peak reduction value (0-100)
   * @returns {number} Sensitivity value (0-1)
   */
  calculateSensitivity(peakReduction) {
    // Aggressive exponential curve for realistic LA-2A behavior
    // Real LA-2A has dramatic compression at higher settings
    const normalized = peakReduction / 100
    
    // Use more aggressive exponential curve
    // Power of 1.3 gives much stronger compression
    const exponential = Math.pow(normalized, 1.3)
    
    // This gives us approximately:
    // At PR=20: 0.2^1.3 = 0.13 (moderate compression ~3-7 dB)
    // At PR=50: 0.5^1.3 = 0.41 (heavy compression ~15-20 dB)  
    // At PR=80: 0.8^1.3 = 0.75 (very heavy ~20+ dB)
    // At PR=100: 1.0^1.3 = 1.0 (maximum compression)
    
    return exponential
  }

  /**
   * Smooth needle movement with adjustable ballistics
   * @param {number} targetPosition - Target needle position
   * @param {number} smoothingFactor - Smoothing factor from store (0-1)
   * @param {number} deltaTime - Time since last update in ms
   * @returns {number} Smoothed needle position
   */
  smoothNeedleMovement(targetPosition, smoothingFactor = 0.15, deltaTime = 16) {
    // Decay overshoot over time
    if (this.currentOvershoot > 0) {
      this.currentOvershoot *= 0.85 // Decay factor (adjust for speed)
      if (this.currentOvershoot < 0.5) {
        this.currentOvershoot = 0
      }
    }
    
    // VU-style ballistics with different attack/release times
    const isAttacking = Math.abs(targetPosition) > Math.abs(this.currentNeedlePosition)
    
    // Faster attack, slower release for authentic VU behavior
    const smoothing = isAttacking ? smoothingFactor * 1.5 : smoothingFactor * 0.7
    
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