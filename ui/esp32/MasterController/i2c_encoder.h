#ifndef I2C_ENCODER_H
#define I2C_ENCODER_H

#include <Arduino.h>
#include <Wire.h>
#include "config.h"

// ============================================================================
// I2C Encoder Manager
// Handles communication with I2C encoder boards (Phase 2)
// ============================================================================

struct I2CEncoder {
    uint8_t address;        // I2C address
    int32_t position;       // Raw encoder position
    float normalizedValue;  // Normalized value (0.0 - 1.0)
    bool connected;         // Is this encoder connected?
    unsigned long lastUpdate; // Last successful read time
    int lastDirection;      // Last movement direction (-1, 0, 1)
};

class I2CEncoderManager {
private:
    I2CEncoder encoders[NUM_ENCODERS];
    unsigned long lastScanTime;
    bool initialized;
    uint8_t connectedCount;

public:
    // Initialization
    void begin();
    
    // Main update (call in main loop)
    void update();
    
    // Encoder access
    float getEncoderValue(int encoderId) const;
    int getEncoderDirection(int encoderId) const;
    bool isEncoderConnected(int encoderId) const;
    uint8_t getConnectedCount() const { return connectedCount; }
    
    // I2C management
    void scanForEncoders();
    bool isInitialized() const { return initialized; }

private:
    // I2C operations
    bool readEncoder(int encoderId);
    bool isI2CDevicePresent(uint8_t address);
    void updateNormalizedValue(int encoderId);
    
    // Utilities
    uint8_t getEncoderAddress(int encoderId) const;
    bool isValidEncoderId(int encoderId) const;
    void detectEncoderChanges(int encoderId, int32_t newPosition);
};

// Global instance (defined in .cpp file)
extern I2CEncoderManager i2cEncoders;

// Callback function (implemented in main .ino file)
extern void onEncoderChanged(int encoderId, float value, int direction);

#endif // I2C_ENCODER_H 