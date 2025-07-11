#ifndef GPIO_COMM_H
#define GPIO_COMM_H

#include "Arduino.h"
#include "../config.h"
#include "uart_handler.h"
#include "message_queue.h"

/*
 * GPIO Communication Manager
 * Handles high-level communication with the Pi via UART
 */

class GPIOComm {
public:
    enum Status {
        STATUS_DISCONNECTED,
        STATUS_CONNECTING,
        STATUS_CONNECTED,
        STATUS_ERROR
    };
    
    GPIOComm();
    ~GPIOComm();
    
    // Initialize communication
    bool begin(int txPin, int rxPin, long baudRate);
    
    // Communication status
    bool isConnected() const { return status == STATUS_CONNECTED; }
    Status getStatus() const { return status; }
    
    // Message handling
    bool sendMessage(const String& message);
    bool getNextMessage(String& message);
    bool hasMessages() const;
    
    // Connection management
    void update();
    void disconnect();
    void reconnect();
    
    // Statistics
    unsigned long getMessagesSent() const { return messagesSent; }
    unsigned long getMessagesReceived() const { return messagesReceived; }
    unsigned long getErrors() const { return errorCount; }
    
    // Configuration
    void setTimeout(unsigned long timeoutMs) { communicationTimeout = timeoutMs; }
    void setHeartbeatInterval(unsigned long intervalMs) { heartbeatInterval = intervalMs; }
    
private:
    UARTHandler uartHandler;
    MessageQueue incomingQueue;
    MessageQueue outgoingQueue;
    
    Status status;
    unsigned long lastHeartbeat;
    unsigned long lastMessageTime;
    unsigned long communicationTimeout;
    unsigned long heartbeatInterval;
    
    // Statistics
    unsigned long messagesSent;
    unsigned long messagesReceived;
    unsigned long errorCount;
    
    // Internal methods
    void processIncomingData();
    void processOutgoingMessages();
    void checkConnection();
    void sendHeartbeat();
    bool validateMessage(const String& message);
    void handleError(const String& error);
    void updateStatus(Status newStatus);
};

#endif // GPIO_COMM_H 