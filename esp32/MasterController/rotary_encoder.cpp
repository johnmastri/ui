#include "rotary_encoder.h"

RotaryEncoder rotaryEncoder;
RotaryEncoder* RotaryEncoder::instance = nullptr;

RotaryEncoder::RotaryEncoder() 
    : pinA(ROTARY_ENCODER_A_PIN),
      pinB(ROTARY_ENCODER_B_PIN),
      pinButton(ROTARY_ENCODER_BTN_PIN),
      ledCount(0),
      lastEncoded(0),
      lastButtonState(HIGH),
      buttonPressed(false),
      lastButtonChangeTime(0),
      lastDebounceTime(0) {
    instance = this;
}

void RotaryEncoder::begin() {
    pinMode(pinA, INPUT_PULLUP);
    pinMode(pinB, INPUT_PULLUP);
    pinMode(pinButton, INPUT_PULLUP);
    
    delay(100);
    
    int MSB = digitalRead(pinA);
    int LSB = digitalRead(pinB);
    lastEncoded = (MSB << 1) | LSB;
    lastButtonState = digitalRead(pinButton);
    
    attachInterrupt(digitalPinToInterrupt(pinA), handleEncoderISR, CHANGE);
    attachInterrupt(digitalPinToInterrupt(pinB), handleEncoderISR, CHANGE);
    
    Serial.println("[ROTARY] Rotary encoder initialized");
    Serial.printf("[ROTARY] Pins: A=%d (GPIO%d), B=%d (GPIO%d), Button=%d (GPIO%d)\n", 
                  pinA, pinA, pinB, pinB, pinButton, pinButton);
    Serial.printf("[ROTARY] Initial button state: %d (should be HIGH=1)\n", lastButtonState);
}

void IRAM_ATTR RotaryEncoder::handleEncoderISR() {
    if (!instance) return;
    
    unsigned long currentTime = millis();
    if (currentTime - instance->lastDebounceTime < instance->debounceDelay) {
        return;
    }
    instance->lastDebounceTime = currentTime;
    
    int MSB = digitalRead(instance->pinA);
    int LSB = digitalRead(instance->pinB);
    int encoded = (MSB << 1) | LSB;
    int sum = (instance->lastEncoded << 2) | encoded;
    
    if (sum == 0b1101 || sum == 0b0100 || sum == 0b0010 || sum == 0b1011) {
        if (instance->ledCount < 24) {
            instance->ledCount++;
        }
    }
    else if (sum == 0b1110 || sum == 0b0111 || sum == 0b0001 || sum == 0b1000) {
        if (instance->ledCount > 0) {
            instance->ledCount--;
        }
    }
    
    instance->lastEncoded = encoded;
}

void RotaryEncoder::update() {
    bool buttonState = digitalRead(pinButton);
    unsigned long currentTime = millis();
    
    if (buttonState != lastButtonState) {
        if (buttonState == HIGH && (currentTime - lastButtonChangeTime) > buttonDebounceDelay) {
            buttonPressed = true;
        }
        
        lastButtonState = buttonState;
        lastButtonChangeTime = currentTime;
    }
}

bool RotaryEncoder::isButtonPressed() {
    if (buttonPressed) {
        buttonPressed = false;
        return true;
    }
    return false;
}
