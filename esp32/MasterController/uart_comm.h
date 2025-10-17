#ifndef UART_COMM_H
#define UART_COMM_H

#include <Arduino.h>
#include <ArduinoJson.h>
#include <HardwareSerial.h>
#include "config.h"

// ============================================================================
// UART Communication Manager
// Handles JSON messaging between ESP32 and Raspberry Pi
// ============================================================================

class UARTComm {
private:
    String usbInputBuffer;
    String piInputBuffer;
    unsigned long lastHeartbeat;
    unsigned long lastStatusUpdate;
    bool isUsbConnected;
    bool isPiConnected;
    
    HardwareSerial piSerial = HardwareSerial(1);
    
    unsigned long messagesSent;
    unsigned long messagesReceived;
    unsigned long usbMessagesReceived;
    unsigned long piMessagesReceived;
    unsigned long errors;

public:
    void begin();
    
    void update();
    
    void sendMessageToUSB(const String& message);
    void sendMessageToPi(const String& message);
    void forwardMessageToPi(const String& message);
    
    void sendJSON(DynamicJsonDocument& doc);
    void sendStartup();
    void sendHeartbeat();
    void sendStatus();
    void sendError(const String& errorMsg);
    void sendEncoderUpdate(int encoderId, float value, int direction);
    void sendButtonPress(int encoderId);
    void sendI2CScanResult(int address, bool found);
    
    bool getConnectionStatus() const { return isUsbConnected || isPiConnected; }
    
    unsigned long getMessagesSent() const { return messagesSent; }
    unsigned long getMessagesReceived() const { return messagesReceived; }
    unsigned long getErrors() const { return errors; }

private:
    void processUSBData();
    void processPiData();
    void processUSBMessage(const String& message);
    void processPiMessage(const String& message);
    
    void handleLEDUpdate(DynamicJsonDocument& doc);
    void handleSystemCommand(DynamicJsonDocument& doc);
    
    bool shouldSendHeartbeat();
    bool shouldSendStatus();
    
    void debugPrint(const String& message);
    void incrementErrorCount();
    
    String getMacAddress();
};

// Global instance (defined in .cpp file)
extern UARTComm uart;

// Callback function declarations (implemented in main .ino file)
extern void onLEDUpdateReceived(int encoderId, uint8_t r, uint8_t g, uint8_t b, LEDPattern pattern, float value);
extern void onSystemCommandReceived(const String& command, const String& parameter);

#endif // UART_COMM_H 