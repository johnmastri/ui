#ifndef LED_CONTROLLER_H
#define LED_CONTROLLER_H

#include <Arduino.h>
#include <FastLED.h>
#include "config.h"

// ============================================================================
// LED Controller for APA102 Strips
// Manages 8 encoder rings with 28 LEDs each
// ============================================================================

struct EncoderRing {
    int startIndex;          // Starting LED index for this encoder
    CRGB color;             // Current color
    LEDPattern pattern;     // Current pattern
    float value;            // Current value (0.0 - 1.0)
    bool active;            // Is this encoder ring active?
    unsigned long lastUpdate; // Last update time for animations
    float animationPhase;   // Animation phase for pulse/rainbow effects
};

class LEDController {
private:
    CRGB leds[TOTAL_LEDS];
    EncoderRing encoderRings[NUM_ENCODERS];
    unsigned long lastFrameUpdate;
    bool initialized;

public:
    // Initialization
    void begin();
    
    // Main update (call in main loop)
    void update();
    
    // Encoder ring control
    void setEncoderColor(int encoderId, uint8_t r, uint8_t g, uint8_t b);
    void setEncoderPattern(int encoderId, LEDPattern pattern);
    void setEncoderValue(int encoderId, float value);
    void updateEncoderRing(int encoderId, uint8_t r, uint8_t g, uint8_t b, LEDPattern pattern, float value);
    
    // System control
    void setBrightness(uint8_t brightness);
    void clearAll();
    void showTestPattern();
    void showErrorPattern();
    void showStartupSequence();
    void simpleColorTest(int step);  // Add this for debugging
    
    // NEW: Diagnostic functions for troubleshooting
    void runFullDiagnostics();
    void testLEDRange(int startLED, int endLED, CRGB color);
    void sequentialTest(int delayMs);
    void findLEDCount(); // Auto-detect actual strip length
    void testSignalIntegrity(); // Test for level shifting issues
    
    // Status
    bool isInitialized() const { return initialized; }
    CRGB getEncoderColor(int encoderId) const;
    float getEncoderValue(int encoderId) const;

private:
    // Pattern implementations
    void renderRingFill(int encoderId);
    void renderSolid(int encoderId);
    void renderPulse(int encoderId);
    void renderRainbow(int encoderId);
    void renderOff(int encoderId);
    
    // Utilities
    void renderEncoder(int encoderId);
    int getEncoderStartIndex(int encoderId) const;
    int getEncoderEndIndex(int encoderId) const;
    bool isValidEncoderId(int encoderId) const;
    CRGB blendColors(CRGB color1, CRGB color2, float ratio);
    uint8_t scaleBrightness(uint8_t value, float scale);
    
    // Animation helpers
    void updateAnimationPhases();
    float getPulseValue(float phase);
    CRGB getRainbowColor(float phase);
};

// Global instance (defined in .cpp file)
extern LEDController ledController;

#endif // LED_CONTROLLER_H 