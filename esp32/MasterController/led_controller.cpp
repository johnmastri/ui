#include "led_controller.h"

// Global instance
LEDController ledController;

void LEDController::begin() {
    // Initialize FastLED for DotStar/APA102 with slower timing
    FastLED.addLeds<LED_TYPE, LED_DATA_PIN, LED_CLOCK_PIN, COLOR_ORDER>(leds, TOTAL_LEDS).setCorrection(TypicalLEDStrip);
    
    // More conservative settings for troubleshooting
    FastLED.setBrightness(LED_BRIGHTNESS);
    FastLED.setMaxPowerInVoltsAndMilliamps(5, 1000);  // Increased current limit
    FastLED.setTemperature(Tungsten40W); // Warmer color temperature
    
    // Longer stabilization time for better compatibility
    #ifdef SAFE_MODE
    delay(500);  // Extra time for level shifters to stabilize
    #endif
    
    // Multiple clear cycles to ensure clean start
    for(int i = 0; i < 3; i++) {
        FastLED.clear();
        FastLED.show();
        delay(100);
    }
    
    Serial.println("[LED] LED strip cleared and stabilized");
    
    // Initialize encoder rings
    for (int i = 0; i < NUM_ENCODERS; i++) {
        encoderRings[i].startIndex = i * LEDS_PER_ENCODER;
        encoderRings[i].color = CRGB::Black;
        encoderRings[i].pattern = PATTERN_OFF;
        encoderRings[i].value = 0.0;
        encoderRings[i].active = false;
        encoderRings[i].lastUpdate = 0;
        encoderRings[i].animationPhase = 0.0;
    }
    
    lastFrameUpdate = 0;
    initialized = true;
    
    Serial.printf("[LED] FastLED initialized - DotStar/APA102 strips ready\n");
    Serial.printf("[LED] Type: %s, Pins: DATA=%d CLOCK=%d, LEDs: %d\n", 
                  "APA102", LED_DATA_PIN, LED_CLOCK_PIN, TOTAL_LEDS);
    
    // Show startup sequence
    showStartupSequence();
}

void LEDController::update() {
    if (!initialized) return;
    
    unsigned long currentTime = millis();
    
    // Use the configurable update rate for 3.3V compatibility
    if (currentTime - lastFrameUpdate < LED_UPDATE_RATE_MS) {
        return;
    }
    
    // Update animation phases
    updateAnimationPhases();
    
    // Render all encoder rings
    for (int i = 0; i < NUM_ENCODERS; i++) {
        renderEncoder(i);
    }
    
    // Add small delay before show() for signal stability
    delayMicroseconds(10);
    
    // Update LED strip with error recovery
    static int errorCount = 0;
    FastLED.show();
    
    // Periodic refresh to combat data corruption
    static unsigned long lastRefresh = 0;
    if (currentTime - lastRefresh > 5000) { // Every 5 seconds
        // Clear and re-render to fix any corruption
        FastLED.clear();
        FastLED.show();
        delay(10);
        
        for (int i = 0; i < NUM_ENCODERS; i++) {
            renderEncoder(i);
        }
        FastLED.show();
        
        lastRefresh = currentTime;
        Serial.println("[LED] Periodic refresh completed");
    }
    
    lastFrameUpdate = currentTime;
}

void LEDController::renderEncoder(int encoderId) {
    if (!isValidEncoderId(encoderId)) return;
    
    EncoderRing& ring = encoderRings[encoderId];
    
    switch (ring.pattern) {
        case PATTERN_OFF:
            renderOff(encoderId);
            break;
        case PATTERN_SOLID:
            renderSolid(encoderId);
            break;
        case PATTERN_RING_FILL:
            renderRingFill(encoderId);
            break;
        case PATTERN_PULSE:
            renderPulse(encoderId);
            break;
        case PATTERN_RAINBOW:
            renderRainbow(encoderId);
            break;
        case PATTERN_ERROR:
            renderPulse(encoderId); // Use pulse for error indication
            break;
        default:
            renderOff(encoderId);
            break;
    }
}

void LEDController::renderOff(int encoderId) {
    int start = getEncoderStartIndex(encoderId);
    int end = getEncoderEndIndex(encoderId);
    
    for (int i = start; i < end; i++) {
        leds[i] = CRGB::Black;
    }
}

void LEDController::renderSolid(int encoderId) {
    EncoderRing& ring = encoderRings[encoderId];
    int start = getEncoderStartIndex(encoderId);
    int end = getEncoderEndIndex(encoderId);
    
    for (int i = start; i < end; i++) {
        leds[i] = ring.color;
    }
}

void LEDController::renderRingFill(int encoderId) {
    EncoderRing& ring = encoderRings[encoderId];
    int start = getEncoderStartIndex(encoderId);
    int activeLEDs = (int)(ring.value * LEDS_PER_ENCODER);
    
    for (int i = 0; i < LEDS_PER_ENCODER; i++) {
        int ledIndex = start + i;
        if (i < activeLEDs) {
            leds[ledIndex] = ring.color;
        } else {
            // Dim background
            leds[ledIndex] = CRGB(ring.color.r / 8, ring.color.g / 8, ring.color.b / 8);
        }
    }
}

void LEDController::renderPulse(int encoderId) {
    EncoderRing& ring = encoderRings[encoderId];
    int start = getEncoderStartIndex(encoderId);
    int end = getEncoderEndIndex(encoderId);
    
    float pulseValue = getPulseValue(ring.animationPhase);
    CRGB pulseColor = CRGB(
        scaleBrightness(ring.color.r, pulseValue),
        scaleBrightness(ring.color.g, pulseValue),
        scaleBrightness(ring.color.b, pulseValue)
    );
    
    for (int i = start; i < end; i++) {
        leds[i] = pulseColor;
    }
}

void LEDController::renderRainbow(int encoderId) {
    int start = getEncoderStartIndex(encoderId);
    
    for (int i = 0; i < LEDS_PER_ENCODER; i++) {
        int ledIndex = start + i;
        float hueOffset = (float)i / LEDS_PER_ENCODER;
        CRGB rainbowColor = getRainbowColor(encoderRings[encoderId].animationPhase + hueOffset);
        leds[ledIndex] = rainbowColor;
    }
}

void LEDController::updateEncoderRing(int encoderId, uint8_t r, uint8_t g, uint8_t b, LEDPattern pattern, float value) {
    if (!isValidEncoderId(encoderId)) return;
    
    EncoderRing& ring = encoderRings[encoderId];
    ring.color = CRGB(r, g, b);
    ring.pattern = pattern;
    ring.value = constrain(value, 0.0, 1.0);
    ring.active = true;
    ring.lastUpdate = millis();
    
    Serial.printf("[LED] Updated encoder %d: RGB(%d,%d,%d) pattern=%d value=%.2f\n", 
                  encoderId, r, g, b, pattern, value);
}

void LEDController::setEncoderColor(int encoderId, uint8_t r, uint8_t g, uint8_t b) {
    if (!isValidEncoderId(encoderId)) return;
    encoderRings[encoderId].color = CRGB(r, g, b);
}

void LEDController::setEncoderPattern(int encoderId, LEDPattern pattern) {
    if (!isValidEncoderId(encoderId)) return;
    encoderRings[encoderId].pattern = pattern;
}

void LEDController::setEncoderValue(int encoderId, float value) {
    if (!isValidEncoderId(encoderId)) return;
    encoderRings[encoderId].value = constrain(value, 0.0, 1.0);
}

void LEDController::setBrightness(uint8_t brightness) {
    FastLED.setBrightness(brightness);
    Serial.printf("[LED] Brightness set to %d\n", brightness);
}

void LEDController::clearAll() {
    FastLED.clear();
    FastLED.show();
    
    // Reset all encoder rings
    for (int i = 0; i < NUM_ENCODERS; i++) {
        encoderRings[i].pattern = PATTERN_OFF;
        encoderRings[i].value = 0.0;
        encoderRings[i].active = false;
    }
}

void LEDController::showTestPattern() {
    // Cycle through all encoder rings with different colors
    CRGB testColors[] = {
        CRGB::Red, CRGB::Green, CRGB::Blue, CRGB::Yellow,
        CRGB::Purple, CRGB::Cyan, CRGB::Orange, CRGB::White
    };
    
    for (int i = 0; i < NUM_ENCODERS; i++) {
        updateEncoderRing(i, testColors[i].r, testColors[i].g, testColors[i].b, 
                         PATTERN_RING_FILL, 0.5);
    }
    
    Serial.println("[LED] Test pattern displayed");
}

void LEDController::showErrorPattern() {
    // Flash all rings red
    for (int i = 0; i < NUM_ENCODERS; i++) {
        updateEncoderRing(i, 255, 0, 0, PATTERN_PULSE, 1.0);
    }
    Serial.println("[LED] Error pattern displayed");
}

void LEDController::showStartupSequence() {
    // Sequential startup animation
    for (int i = 0; i < NUM_ENCODERS; i++) {
        updateEncoderRing(i, 0, 255, 128, PATTERN_SOLID, 1.0);
        FastLED.show();
        delay(100);
        updateEncoderRing(i, 0, 0, 0, PATTERN_OFF, 0.0);
    }
    
    // Brief all-on
    for (int i = 0; i < NUM_ENCODERS; i++) {
        updateEncoderRing(i, 0, 128, 255, PATTERN_SOLID, 1.0);
    }
    FastLED.show();
    delay(200);
    
    clearAll();
    Serial.println("[LED] Startup sequence complete");
}

void LEDController::simpleColorTest(int step) {
    // Simple color test for debugging
    switch(step) {
        case 0:
            // All LEDs OFF
            Serial.println("[LED] All LEDs OFF");
            FastLED.clear();
            FastLED.show();
            break;
            
        case 1:
            // First 5 LEDs RED
            Serial.println("[LED] First 5 LEDs RED");
            FastLED.clear();
            for(int i = 0; i < 5 && i < TOTAL_LEDS; i++) {
                leds[i] = CRGB::Red;
            }
            FastLED.show();
            break;
            
        case 2:
            // LEDs 5-9 GREEN  
            Serial.println("[LED] LEDs 5-9 GREEN");
            FastLED.clear();
            for(int i = 5; i < 10 && i < TOTAL_LEDS; i++) {
                leds[i] = CRGB::Green;
            }
            FastLED.show();
            break;
            
        case 3:
            // LEDs 10-14 BLUE
            Serial.println("[LED] LEDs 10-14 BLUE");
            FastLED.clear();
            for(int i = 10; i < 15 && i < TOTAL_LEDS; i++) {
                leds[i] = CRGB::Blue;
            }
            FastLED.show();
            break;
            
        case 4:
            // All LEDs dim white (test if color order is wrong)
            Serial.println("[LED] All LEDs dim white");
            for(int i = 0; i < TOTAL_LEDS; i++) {
                leds[i] = CRGB(32, 32, 32);  // Dim white
            }
            FastLED.show();
            break;
    }
}

// NEW: Comprehensive diagnostic functions
void LEDController::runFullDiagnostics() {
    Serial.println("=== LED STRIP DIAGNOSTICS ===");
    Serial.printf("Configured LEDs: %d\n", TOTAL_LEDS);
    Serial.printf("Current brightness: %d\n", FastLED.getBrightness());
    Serial.printf("LED Type: APA102, Pins: DATA=%d, CLOCK=%d\n", LED_DATA_PIN, LED_CLOCK_PIN);
    
    // Test 1: Clear all
    Serial.println("\nTest 1: Clear all LEDs");
    FastLED.clear();
    FastLED.show();
    delay(1000);
    
    // Test 2: Single LED sweep
    Serial.println("Test 2: Single LED sweep (first 20)");
    for(int i = 0; i < min(20, TOTAL_LEDS); i++) {
        FastLED.clear();
        leds[i] = CRGB::Red;
        FastLED.show();
        Serial.printf("LED %d ON\n", i);
        delay(200);
    }
    FastLED.clear();
    FastLED.show();
    
    // Test 3: Range tests
    Serial.println("Test 3: Range tests");
    testLEDRange(0, 10, CRGB::Green);
    delay(1000);
    testLEDRange(10, 20, CRGB::Blue);
    delay(1000);
    testLEDRange(20, 30, CRGB::Yellow);
    delay(1000);
    
    // Test 4: Auto-detect strip length
    Serial.println("Test 4: Auto-detecting strip length...");
    findLEDCount();
    
    Serial.println("=== DIAGNOSTICS COMPLETE ===");
}

void LEDController::testLEDRange(int startLED, int endLED, CRGB color) {
    FastLED.clear();
    Serial.printf("Testing LEDs %d to %d with color RGB(%d,%d,%d)\n", 
                  startLED, endLED-1, color.r, color.g, color.b);
    
    for(int i = startLED; i < endLED && i < TOTAL_LEDS; i++) {
        leds[i] = color;
    }
    FastLED.show();
}

void LEDController::sequentialTest(int delayMs) {
    Serial.println("Sequential LED test starting...");
    FastLED.clear();
    
    for(int i = 0; i < TOTAL_LEDS; i++) {
        leds[i] = CRGB(255, 0, 0); // Red
        FastLED.show();
        Serial.printf("LED %d\n", i);
        delay(delayMs);
        
        // Also turn on as green to make a trail
        if(i > 0) leds[i-1] = CRGB(0, 128, 0);
    }
    
    delay(1000);
    FastLED.clear();
    FastLED.show();
    Serial.println("Sequential test complete");
}

void LEDController::findLEDCount() {
    Serial.println("Auto-detecting actual LED strip length...");
    FastLED.clear();
    
    // Method: Light up LEDs one by one and assume user will report last working one
    Serial.println("Watch your strip and note the LAST LED that lights up correctly");
    Serial.println("(Ignore any that flash white or act strange)");
    
    for(int i = 0; i < TOTAL_LEDS; i++) {
        FastLED.clear();
        leds[i] = CRGB::Blue;
        FastLED.show();
        
        Serial.printf("Testing LED %d - Is this LED working properly? (Press any key to continue)\n", i);
        delay(500);
        
        // Light up all previous LEDs dimly to show progress
        for(int j = 0; j <= i; j++) {
            leds[j] = CRGB(0, 0, 64); // Dim blue
        }
        leds[i] = CRGB::Blue; // Current LED bright
        FastLED.show();
        delay(1000);
    }
    
    FastLED.clear();
    FastLED.show();
    Serial.println("Auto-detection complete. Please update LEDS_PER_ENCODER in config.h with the correct count.");
}

void LEDController::testSignalIntegrity() {
    Serial.println("=== SIGNAL INTEGRITY TEST ===");
    Serial.println("This test checks for level shifting and communication issues");
    Serial.println("Watch for: bright flashes, color corruption, or unstable behavior");
    
    // Test 1: Static patterns (should be rock solid)
    Serial.println("Test 1: Static red pattern (should be stable)");
    FastLED.clear();
    for(int i = 0; i < TOTAL_LEDS; i++) {
        leds[i] = CRGB(128, 0, 0); // Medium red
    }
    FastLED.show();
    delay(3000);
    
    // Test 2: Alternating pattern (tests data integrity)
    Serial.println("Test 2: Alternating red/blue pattern");
    for(int i = 0; i < TOTAL_LEDS; i++) {
        leds[i] = (i % 2 == 0) ? CRGB(128, 0, 0) : CRGB(0, 0, 128);
    }
    FastLED.show();
    delay(3000);
    
    // Test 3: Rapid updates (stress test)
    Serial.println("Test 3: Rapid color changes (stress test)");
    for(int cycle = 0; cycle < 20; cycle++) {
        CRGB colors[] = {CRGB::Red, CRGB::Green, CRGB::Blue, CRGB::Black};
        for(int i = 0; i < TOTAL_LEDS; i++) {
            leds[i] = colors[cycle % 4];
        }
        FastLED.show();
        delay(100);
    }
    
    // Test 4: Individual LED addressing
    Serial.println("Test 4: Individual LED sweep");
    FastLED.clear();
    for(int i = 0; i < min(20, TOTAL_LEDS); i++) {
        FastLED.clear();
        leds[i] = CRGB::White;
        FastLED.show();
        delay(200);
    }
    
    FastLED.clear();
    FastLED.show();
    
    Serial.println("=== SIGNAL INTEGRITY TEST COMPLETE ===");
    Serial.println("If you saw flashes, corruption, or instability, you likely need:");
    Serial.println("1. Level shifter (74HCT245 or 74AHCT125)");
    Serial.println("2. Better power supply");
    Serial.println("3. Shorter/better wiring");
}

// Utility functions
void LEDController::updateAnimationPhases() {
    float timeIncrement = 0.02; // Adjust for animation speed
    
    for (int i = 0; i < NUM_ENCODERS; i++) {
        encoderRings[i].animationPhase += timeIncrement;
        if (encoderRings[i].animationPhase > 1.0) {
            encoderRings[i].animationPhase -= 1.0;
        }
    }
}

float LEDController::getPulseValue(float phase) {
    // Sine wave pulse between 0.1 and 1.0
    return 0.1 + 0.9 * (sin(phase * 2 * PI) + 1) / 2;
}

CRGB LEDController::getRainbowColor(float phase) {
    // Convert phase to HSV and then to RGB
    while (phase > 1.0) phase -= 1.0;
    while (phase < 0.0) phase += 1.0;
    
    CHSV hsv(phase * 255, 255, 255);
    CRGB rgb;
    hsv2rgb_rainbow(hsv, rgb);
    return rgb;
}

int LEDController::getEncoderStartIndex(int encoderId) const {
    return encoderId * LEDS_PER_ENCODER;
}

int LEDController::getEncoderEndIndex(int encoderId) const {
    return (encoderId + 1) * LEDS_PER_ENCODER;
}

bool LEDController::isValidEncoderId(int encoderId) const {
    return encoderId >= 0 && encoderId < NUM_ENCODERS;
}

CRGB LEDController::blendColors(CRGB color1, CRGB color2, float ratio) {
    ratio = constrain(ratio, 0.0, 1.0);
    return CRGB(
        color1.r * (1 - ratio) + color2.r * ratio,
        color1.g * (1 - ratio) + color2.g * ratio,
        color1.b * (1 - ratio) + color2.b * ratio
    );
}

uint8_t LEDController::scaleBrightness(uint8_t value, float scale) {
    scale = constrain(scale, 0.0, 1.0);
    return (uint8_t)(value * scale);
}

CRGB LEDController::getEncoderColor(int encoderId) const {
    if (!isValidEncoderId(encoderId)) return CRGB::Black;
    return encoderRings[encoderId].color;
}

float LEDController::getEncoderValue(int encoderId) const {
    if (!isValidEncoderId(encoderId)) return 0.0;
    return encoderRings[encoderId].value;
} 