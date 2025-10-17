#ifndef UART_HANDLER_H
#define UART_HANDLER_H

#include "Arduino.h"
#include "HardwareSerial.h"
#include "../config.h"

/*
 * UART Handler for Pi Communication
 * Manages low-level serial communication with message framing
 */

class UARTHandler {
public:
    UARTHandler();
    ~UARTHandler();
    
    // Initialize UART
    bool begin(int txPin, int rxPin, long baudRate, int uartNum = 2);
    
    // Connection status
    bool isConnected() const { return connected; }
    
    // Message transmission
    bool sendMessage(const String& message);
    bool sendRaw(const uint8_t* data, size_t length);
    
    // Message reception
    bool hasMessage() const;
    bool receiveMessage(String& message);
    String receiveMessage(); // Alternative that returns String directly
    
    // Low-level operations
    void update();
    void flush();
    void clear();
    
    // Configuration
    void setTimeout(unsigned long timeoutMs) { timeout = timeoutMs; }
    void setMaxMessageSize(size_t maxSize) { maxMessageSize = maxSize; }
    
    // Statistics
    unsigned long getBytesSent() const { return bytesSent; }
    unsigned long getBytesReceived() const { return bytesReceived; }
    unsigned long getMessagesTransmitted() const { return messagesTransmitted; }
    unsigned long getMessagesReceived() const { return messagesReceived; }
    unsigned long getErrors() const { return errorCount; }
    
    // Buffer status
    size_t getReceiveBufferSize() const { return receiveBuffer.length(); }
    size_t getAvailableBytes() const;
    
private:
    HardwareSerial* serial;
    int serialNumber;
    bool connected;
    
    // Message framing
    String receiveBuffer;
    size_t maxMessageSize;
    unsigned long timeout;
    char messageDelimiter;
    
    // Statistics
    unsigned long bytesSent;
    unsigned long bytesReceived;
    unsigned long messagesTransmitted;
    unsigned long messagesReceived;
    unsigned long errorCount;
    
    // Internal methods
    void processReceiveBuffer();
    bool extractMessage(String& message);
    bool validateMessage(const String& message);
    void handleError(const String& error);
    void resetBuffers();
};

#endif // UART_HANDLER_H 