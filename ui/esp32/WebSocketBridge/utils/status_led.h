#ifndef STATUS_LED_H
#define STATUS_LED_H

#include "Arduino.h"
#include "../config.h"

/*
 * Status LED Controller
 * Provides visual feedback for system status through LED patterns
 */

class StatusLED {
public:
    // LED patterns for different states
    enum Pattern {
        PATTERN_OFF,                  // LED off
        PATTERN_ON,                   // LED on solid
        PATTERN_STARTUP,              // Fast blink during startup
        PATTERN_READY,                // Slow pulse when ready
        PATTERN_USB_CONNECTED,        // Single blink pattern
        PATTERN_WEBSOCKET_CONNECTED,  // Double blink pattern
        PATTERN_PI_CONNECTED,         // Triple blink pattern
        PATTERN_FULLY_CONNECTED,      // Steady on with occasional blink
        PATTERN_ERROR,                // Fast blink error pattern
        PATTERN_WARNING,              // Medium blink warning pattern
        PATTERN_HEARTBEAT             // Heartbeat pulse pattern
    };
    
    StatusLED();
    
    // Initialize the LED
    bool begin(int pin);
    
    // Set LED pattern
    void setPattern(Pattern pattern);
    
    // Get current pattern
    Pattern getPattern() const { return currentPattern; }
    
    // Update LED state (call from main loop)
    void update();
    
    // Manual control
    void setOn();
    void setOff();
    void setBrightness(int brightness); // 0-255
    
    // Pattern timing control
    void setBlinkRate(unsigned long rate) { blinkRateMs = rate; }
    void setPulseRate(unsigned long rate) { pulseRateMs = rate; }
    
private:
    int ledPin;
    Pattern currentPattern;
    bool ledState;
    unsigned long lastUpdate;
    unsigned long lastPatternChange;
    int blinkCounter;
    int brightness;
    
    // Timing parameters
    unsigned long blinkRateMs;
    unsigned long pulseRateMs;
    
    // Pattern-specific update functions
    void updateStartupPattern();
    void updateReadyPattern();
    void updateSingleBlinkPattern();
    void updateDoubleBlinkPattern();
    void updateTripleBlinkPattern();
    void updateFullyConnectedPattern();
    void updateErrorPattern();
    void updateWarningPattern();
    void updateHeartbeatPattern();
    
    // Utility functions
    void setLED(bool state);
    void setLEDPWM(int brightness);
    int calculatePulse(unsigned long period);
    bool isBlinkPhase(int phase, int totalPhases);
};

#endif // STATUS_LED_H 