#include "led_controller.h"

// Global instance
LEDController ledController;

void LEDController::begin() {
    // Initialize FastLED
    FastLED.addLeds<LED_TYPE, LED_DATA_PIN, LED_CLOCK_PIN, COLOR_ORDER>(leds, TOTAL_LEDS);
    FastLED.setBrightness(LED_BRIGHTNESS);
    FastLED.clear();
    FastLED.show();
    
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
    
    Serial.println("[LED] FastLED initialized - APA102 strips ready");
    
    // Show startup sequence
    showStartupSequence();
}

void LEDController::update() {
    if (!initialized) return;
    
    unsigned long currentTime = millis();
    
    // Limit update rate to ~60 FPS
    if (currentTime - lastFrameUpdate < LED_UPDATE_RATE_MS) {
        return;
    }
    
    // Update animation phases
    updateAnimationPhases();
    
    // Render all encoder rings
    for (int i = 0; i < NUM_ENCODERS; i++) {
        renderEncoder(i);
    }
    
    // Update LED strip
    FastLED.show();
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