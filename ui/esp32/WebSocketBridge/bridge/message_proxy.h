#ifndef MESSAGE_PROXY_H
#define MESSAGE_PROXY_H

#include "Arduino.h"
#include "../config.h"
#include "../websocket/ws_server.h"
#include "../communication/gpio_comm.h"
#include "ArduinoJson.h"

/*
 * Message Proxy for WebSocket Bridge
 * Handles bidirectional message forwarding between WebSocket clients and Pi
 */

class MessageProxy {
public:
    MessageProxy();
    ~MessageProxy();
    
    // Initialize with WebSocket server and Pi communication
    void begin(WebSocketServer* wsServer, GPIOComm* piComm);
    
    // Main update loop
    void update();
    
    // Message handling
    void handleWebSocketMessage(const String& message, uint8_t clientId);
    void handlePiMessage(const String& message);
    
    // Statistics
    unsigned long getMessageCount() const { return totalMessagesProxied; }
    unsigned long getWebSocketToPiCount() const { return wsTopiMessages; }
    unsigned long getPiToWebSocketCount() const { return piToWsMessages; }
    unsigned long getErrorCount() const { return errorCount; }
    
    // Configuration
    void setMessageFiltering(bool enabled) { filterMessages = enabled; }
    void setHeartbeatForwarding(bool enabled) { forwardHeartbeats = enabled; }
    
private:
    WebSocketServer* webSocketServer;
    GPIOComm* piCommunication;
    
    // Statistics
    unsigned long totalMessagesProxied;
    unsigned long wsTopiMessages;
    unsigned long piToWsMessages;
    unsigned long errorCount;
    unsigned long lastStatsUpdate;
    
    // Configuration
    bool filterMessages;
    bool forwardHeartbeats;
    bool initialized;
    
    // Message processing
    bool processWebSocketToPi(const String& message, uint8_t clientId);
    bool processPiToWebSocket(const String& message);
    
    // Message transformation
    String addClientInfo(const String& message, uint8_t clientId);
    String removeClientInfo(const String& message);
    bool shouldForwardMessage(const String& message);
    
    // JSON helpers
    bool parseJson(const String& message, JsonDocument& doc);
    String serializeJson(const JsonDocument& doc);
    
    // Validation
    bool validateMessage(const String& message);
    bool isHeartbeatMessage(const String& message);
    
    // Error handling
    void handleError(const String& error);
    void updateStatistics();
};

#endif // MESSAGE_PROXY_H 