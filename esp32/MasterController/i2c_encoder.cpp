#include "i2c_encoder.h"
#include "uart_comm.h"

// Global instance
I2CEncoderManager i2cEncoders;

void I2CEncoderManager::begin() {
    // Initialize I2C with custom pins
    Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
    Wire.setClock(I2C_FREQUENCY);
    
    // Initialize encoder structs
    for (int i = 0; i < NUM_ENCODERS; i++) {
        encoders[i].address = getEncoderAddress(i);
        encoders[i].position = 0;
        encoders[i].normalizedValue = 0.0;
        encoders[i].connected = false;
        encoders[i].lastUpdate = 0;
        encoders[i].lastDirection = 0;
    }
    
    lastScanTime = 0;
    connectedCount = 0;
    initialized = true;
    
    Serial.println("[I2C] I2C Encoder Manager initialized");
    
    // Initial scan for connected devices
    scanForEncoders();
}

void I2CEncoderManager::update() {
    if (!initialized) return;
    
    unsigned long currentTime = millis();
    
    // Periodic scan for new devices
    if (currentTime - lastScanTime > 5000) { // Scan every 5 seconds
        scanForEncoders();
        lastScanTime = currentTime;
    }
    
    // Read all connected encoders
    for (int i = 0; i < NUM_ENCODERS; i++) {
        if (encoders[i].connected) {
            readEncoder(i);
        }
    }
}

void I2CEncoderManager::scanForEncoders() {
    Serial.println("[I2C] Scanning for encoder devices...");
    
    connectedCount = 0;
    
    for (int i = 0; i < NUM_ENCODERS; i++) {
        uint8_t address = getEncoderAddress(i);
        bool wasConnected = encoders[i].connected;
        bool isConnected = isI2CDevicePresent(address);
        
        encoders[i].connected = isConnected;
        
        if (isConnected) {
            connectedCount++;
            if (!wasConnected) {
                Serial.printf("[I2C] Encoder %d found at address 0x%02X\n", i, address);
            }
        } else if (wasConnected) {
            Serial.printf("[I2C] Encoder %d disconnected from address 0x%02X\n", i, address);
        }
        
        // Send scan result via UART
        uart.sendI2CScanResult(address, isConnected);
    }
    
    Serial.printf("[I2C] Scan complete - %d encoders connected\n", connectedCount);
}

bool I2CEncoderManager::isI2CDevicePresent(uint8_t address) {
    Wire.beginTransmission(address);
    uint8_t error = Wire.endTransmission();
    
    // error = 0: success
    // error = 2: received NACK on transmit of address
    // error = 3: received NACK on transmit of data
    // error = 4: other error
    return (error == 0);
}

bool I2CEncoderManager::readEncoder(int encoderId) {
    if (!isValidEncoderId(encoderId) || !encoders[encoderId].connected) {
        return false;
    }
    
    // TODO: Implement actual encoder reading based on specific I2C encoder board
    // This is a placeholder for Phase 2 implementation
    
    // For now, just update the timestamp to show we "tried" to read
    encoders[encoderId].lastUpdate = millis();
    
    return true;
}

void I2CEncoderManager::updateNormalizedValue(int encoderId) {
    if (!isValidEncoderId(encoderId)) return;
    
    // TODO: Convert raw position to normalized 0.0-1.0 range
    // This depends on the specific encoder hardware characteristics
    
    // Placeholder implementation
    I2CEncoder& encoder = encoders[encoderId];
    encoder.normalizedValue = constrain((float)encoder.position / 1000.0, 0.0, 1.0);
}

void I2CEncoderManager::detectEncoderChanges(int encoderId, int32_t newPosition) {
    if (!isValidEncoderId(encoderId)) return;
    
    I2CEncoder& encoder = encoders[encoderId];
    int32_t oldPosition = encoder.position;
    
    if (newPosition != oldPosition) {
        encoder.position = newPosition;
        
        // Determine direction
        if (newPosition > oldPosition) {
            encoder.lastDirection = 1;  // Clockwise
        } else {
            encoder.lastDirection = -1; // Counter-clockwise
        }
        
        // Update normalized value
        updateNormalizedValue(encoderId);
        
        // Call callback function
        onEncoderChanged(encoderId, encoder.normalizedValue, encoder.lastDirection);
        
        Serial.printf("[I2C] Encoder %d changed: pos=%d, value=%.3f, dir=%d\n", 
                      encoderId, newPosition, encoder.normalizedValue, encoder.lastDirection);
    }
}

// Public accessor methods
float I2CEncoderManager::getEncoderValue(int encoderId) const {
    if (!isValidEncoderId(encoderId)) return 0.0;
    return encoders[encoderId].normalizedValue;
}

int I2CEncoderManager::getEncoderDirection(int encoderId) const {
    if (!isValidEncoderId(encoderId)) return 0;
    return encoders[encoderId].lastDirection;
}

bool I2CEncoderManager::isEncoderConnected(int encoderId) const {
    if (!isValidEncoderId(encoderId)) return false;
    return encoders[encoderId].connected;
}

// Utility methods
uint8_t I2CEncoderManager::getEncoderAddress(int encoderId) const {
    return I2C_ENCODER_BASE_ADDR + encoderId; // 0x20 + encoderId
}

bool I2CEncoderManager::isValidEncoderId(int encoderId) const {
    return encoderId >= 0 && encoderId < NUM_ENCODERS;
} 