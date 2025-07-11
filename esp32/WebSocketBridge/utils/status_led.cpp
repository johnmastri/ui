#include "status_led.h"

/*
 * Status LED Implementation
 */

StatusLED::StatusLED() :
    ledPin(-1),
    currentPattern(PATTERN_OFF),
    ledState(false),
    lastUpdate(0),
    lastPatternChange(0),
    blinkCounter(0),
    brightness(255),
    blinkRateMs(STATUS_BLINK_RATE_MS),
    pulseRateMs(2000)
{
}

bool StatusLED::begin(int pin) {
    ledPin = pin;
    pinMode(ledPin, OUTPUT);
    setOff();
    return true;
}

void StatusLED::setPattern(Pattern pattern) {
    if (currentPattern != pattern) {
        currentPattern = pattern;
        lastPatternChange = millis();
        blinkCounter = 0;
        
        // Immediate state change for some patterns
        switch (pattern) {
            case PATTERN_OFF:
                setOff();
                break;
            case PATTERN_ON:
                setOn();
                break;
            default:
                // Let update() handle pattern-specific behavior
                break;
        }
    }
}

void StatusLED::update() {
    unsigned long now = millis();
    
    switch (currentPattern) {
        case PATTERN_OFF:
            setOff();
            break;
            
        case PATTERN_ON:
            setOn();
            break;
            
        case PATTERN_STARTUP:
            updateStartupPattern();
            break;
            
        case PATTERN_READY:
            updateReadyPattern();
            break;
            
        case PATTERN_USB_CONNECTED:
            updateSingleBlinkPattern();
            break;
            
        case PATTERN_WEBSOCKET_CONNECTED:
            updateDoubleBlinkPattern();
            break;
            
        case PATTERN_PI_CONNECTED:
            updateTripleBlinkPattern();
            break;
            
        case PATTERN_FULLY_CONNECTED:
            updateFullyConnectedPattern();
            break;
            
        case PATTERN_ERROR:
            updateErrorPattern();
            break;
            
        case PATTERN_WARNING:
            updateWarningPattern();
            break;
            
        case PATTERN_HEARTBEAT:
            updateHeartbeatPattern();
            break;
    }
    
    lastUpdate = now;
}

void StatusLED::setOn() {
    setLED(true);
    brightness = 255;
}

void StatusLED::setOff() {
    setLED(false);
    brightness = 0;
}

void StatusLED::setBrightness(int newBrightness) {
    brightness = constrain(newBrightness, 0, 255);
    setLEDPWM(brightness);
}

void StatusLED::updateStartupPattern() {
    // Fast blink: 200ms on, 200ms off
    unsigned long interval = 200;
    unsigned long elapsed = millis() - lastPatternChange;
    
    if ((elapsed / interval) % 2 == 0) {
        setOn();
    } else {
        setOff();
    }
}

void StatusLED::updateReadyPattern() {
    // Slow pulse: breathing effect over 2 seconds
    unsigned long elapsed = millis() - lastPatternChange;
    int pulse = calculatePulse(pulseRateMs);
    setLEDPWM(pulse);
}

void StatusLED::updateSingleBlinkPattern() {
    // Single blink every 2 seconds: 200ms on, 1800ms off
    unsigned long cycle = 2000;
    unsigned long elapsed = (millis() - lastPatternChange) % cycle;
    
    if (elapsed < 200) {
        setOn();
    } else {
        setOff();
    }
}

void StatusLED::updateDoubleBlinkPattern() {
    // Double blink every 2 seconds: 200ms on, 200ms off, 200ms on, 1400ms off
    unsigned long cycle = 2000;
    unsigned long elapsed = (millis() - lastPatternChange) % cycle;
    
    if ((elapsed < 200) || (elapsed >= 400 && elapsed < 600)) {
        setOn();
    } else {
        setOff();
    }
}

void StatusLED::updateTripleBlinkPattern() {
    // Triple blink every 2 seconds
    unsigned long cycle = 2000;
    unsigned long elapsed = (millis() - lastPatternChange) % cycle;
    
    if ((elapsed < 200) || (elapsed >= 400 && elapsed < 600) || (elapsed >= 800 && elapsed < 1000)) {
        setOn();
    } else {
        setOff();
    }
}

void StatusLED::updateFullyConnectedPattern() {
    // Mostly on with a brief off every 3 seconds
    unsigned long cycle = 3000;
    unsigned long elapsed = (millis() - lastPatternChange) % cycle;
    
    if (elapsed < 2800) {
        setOn();
    } else {
        setOff();
    }
}

void StatusLED::updateErrorPattern() {
    // Fast blink: 100ms on, 100ms off (very urgent)
    unsigned long interval = 100;
    unsigned long elapsed = millis() - lastPatternChange;
    
    if ((elapsed / interval) % 2 == 0) {
        setOn();
    } else {
        setOff();
    }
}

void StatusLED::updateWarningPattern() {
    // Medium blink: 300ms on, 300ms off
    unsigned long interval = 300;
    unsigned long elapsed = millis() - lastPatternChange;
    
    if ((elapsed / interval) % 2 == 0) {
        setOn();
    } else {
        setOff();
    }
}

void StatusLED::updateHeartbeatPattern() {
    // Heartbeat: two quick pulses followed by pause
    unsigned long cycle = 1500;
    unsigned long elapsed = (millis() - lastPatternChange) % cycle;
    
    // First pulse: 0-150ms
    // Gap: 150-250ms
    // Second pulse: 250-400ms
    // Long gap: 400-1500ms
    
    if ((elapsed < 150) || (elapsed >= 250 && elapsed < 400)) {
        int pulse = calculatePulse(300); // Fast pulse
        setLEDPWM(pulse);
    } else {
        setOff();
    }
}

void StatusLED::setLED(bool state) {
    ledState = state;
    digitalWrite(ledPin, state ? HIGH : LOW);
}

void StatusLED::setLEDPWM(int brightness) {
    this->brightness = constrain(brightness, 0, 255);
    analogWrite(ledPin, this->brightness);
}

int StatusLED::calculatePulse(unsigned long period) {
    // Calculate a sine-wave-like pulse over the given period
    unsigned long elapsed = (millis() - lastPatternChange) % period;
    float phase = (float)elapsed / period * 2.0 * PI;
    float sine = sin(phase);
    
    // Convert sine wave (-1 to 1) to brightness (0 to 255)
    // Make it always positive and scaled appropriately
    int pulse = (int)((sine * 0.5 + 0.5) * 255);
    return constrain(pulse, 0, 255);
}

bool StatusLED::isBlinkPhase(int phase, int totalPhases) {
    unsigned long cycle = 2000; // 2 second total cycle
    unsigned long phaseLength = cycle / totalPhases;
    unsigned long elapsed = (millis() - lastPatternChange) % cycle;
    
    unsigned long phaseStart = phase * phaseLength;
    unsigned long phaseEnd = phaseStart + (phaseLength / 2); // 50% duty cycle
    
    return (elapsed >= phaseStart && elapsed < phaseEnd);
} 