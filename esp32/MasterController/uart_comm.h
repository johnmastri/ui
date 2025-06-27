#ifndef UART_COMM_H
#define UART_COMM_H

#include <Arduino.h>
#include <ArduinoJson.h>
#include "config.h"

// ============================================================================
// UART Communication Manager
// Handles JSON messaging between ESP32 and Raspberry Pi
// ============================================================================

class UARTComm {
private:
    String inputBuffer;
    unsigned long lastHeartbeat;
    unsigned long lastStatusUpdate;
    bool isConnected;
    
    // Statistics
    unsigned long messagesSent;
    unsigned long messagesReceived;
    unsigned long errors;

public:
    // Initialization
    void begin();
    
    // Main processing (call in main loop)
    void update();
    
    // Message sending
    void sendMessage(const String& message);
    void sendJSON(DynamicJsonDocument& doc);
    void sendStartup();
    void sendHeartbeat();
    void sendStatus();
    void sendError(const String& errorMsg);
    void sendEncoderUpdate(int encoderId, float value, int direction);
    void sendI2CScanResult(int address, bool found);
    
    // Connection status
    bool getConnectionStatus() const { return isConnected; }
    
    // Statistics
    unsigned long getMessagesSent() const { return messagesSent; }
    unsigned long getMessagesReceived() const { return messagesReceived; }
    unsigned long getErrors() const { return errors; }

private:
    // Message processing
    void processIncomingData();
    void processMessage(const String& message);
    void handleLEDUpdate(DynamicJsonDocument& doc);
    void handleSystemCommand(DynamicJsonDocument& doc);
    
    // Timing checks
    bool shouldSendHeartbeat();
    bool shouldSendStatus();
    
    // Utilities
    void debugPrint(const String& message);
    void incrementErrorCount();
};

// Global instance (defined in .cpp file)
extern UARTComm uart;

// Callback function declarations (implemented in main .ino file)
extern void onLEDUpdateReceived(int encoderId, uint8_t r, uint8_t g, uint8_t b, LEDPattern pattern, float value);
extern void onSystemCommandReceived(const String& command, const String& parameter);

#endif // UART_COMM_H 