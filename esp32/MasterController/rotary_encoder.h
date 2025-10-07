#ifndef ROTARY_ENCODER_H
#define ROTARY_ENCODER_H

#include <Arduino.h>
#include "config.h"

class RotaryEncoder {
private:
    int pinA;
    int pinB;
    int pinButton;
    
    volatile int ledCount;
    volatile int lastEncoded;
    
    bool lastButtonState;
    bool buttonPressed;
    unsigned long lastButtonChangeTime;
    unsigned long lastDebounceTime;
    static const unsigned long debounceDelay = 5;
    static const unsigned long buttonDebounceDelay = 50;
    
    static RotaryEncoder* instance;
    
    static void IRAM_ATTR handleEncoderISR();
    
public:
    RotaryEncoder();
    
    void begin();
    void update();
    
    int getLEDCount() const { return ledCount; }
    bool isButtonPressed();
    
    void reset() { ledCount = 0; }
};

extern RotaryEncoder rotaryEncoder;

#endif

