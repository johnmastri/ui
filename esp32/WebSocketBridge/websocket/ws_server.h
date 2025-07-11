#ifndef WS_SERVER_H
#define WS_SERVER_H

#include "Arduino.h"
#include "../config.h"
#include "WebSocketsServer.h"
#include "ArduinoJson.h"
#include "../communication/message_queue.h"

/*
 * WebSocket Server for MIDI Controller Communication
 * Handles multiple WebSocket clients and message routing
 */

class WebSocketServer {
public:
    struct ClientInfo {
        uint8_t id;
        bool connected;
        IPAddress remoteIP;
        unsigned long connectedTime;
        unsigned long lastActivity;
        unsigned long messagesSent;
        unsigned long messagesReceived;
    };
    
    WebSocketServer();
    ~WebSocketServer();
    
    // Server lifecycle
    bool begin(uint16_t port, uint8_t maxClients = MAX_WEBSOCKET_CLIENTS);
    void stop();
    
    // Client management
    void handleClients();
    uint8_t getClientCount() const { return connectedClients; }
    bool isClientConnected(uint8_t clientId) const;
    ClientInfo getClientInfo(uint8_t clientId) const;
    
    // Message handling
    bool sendMessage(uint8_t clientId, const String& message);
    bool broadcastMessage(const String& message);
    bool getNextMessage(String& message, int& clientId);
    bool hasMessages() const { return !incomingQueue.isEmpty(); }
    
    // JSON message helpers
    bool sendJSON(uint8_t clientId, const JsonDocument& doc);
    bool broadcastJSON(const JsonDocument& doc);
    bool parseMessage(const String& message, JsonDocument& doc);
    
    // Statistics
    unsigned long getTotalConnections() const { return totalConnections; }
    unsigned long getMessagesSent() const { return totalMessagesSent; }
    unsigned long getMessagesReceived() const { return totalMessagesReceived; }
    
    // Event callbacks
    void onClientConnected(void (*callback)(uint8_t clientId));
    void onClientDisconnected(void (*callback)(uint8_t clientId));
    void onMessageReceived(void (*callback)(uint8_t clientId, const String& message));
    void onError(void (*callback)(const String& error));
    
private:
    WebSocketsServer* server;
    uint16_t serverPort;
    uint8_t maxClients;
    uint8_t connectedClients;
    
    // Client management
    ClientInfo clients[MAX_WEBSOCKET_CLIENTS];
    
    // Message queuing
    MessageQueue incomingQueue;
    
    // Statistics
    unsigned long totalConnections;
    unsigned long totalMessagesSent;
    unsigned long totalMessagesReceived;
    unsigned long lastStatsUpdate;
    
    // Callbacks
    void (*clientConnectedCallback)(uint8_t clientId);
    void (*clientDisconnectedCallback)(uint8_t clientId);
    void (*messageReceivedCallback)(uint8_t clientId, const String& message);
    void (*errorCallback)(const String& error);
    
    // WebSocket event handler
    void webSocketEvent(uint8_t clientId, WStype_t type, uint8_t* payload, size_t length);
    
    // Client management helpers
    void addClient(uint8_t clientId, IPAddress remoteIP);
    void removeClient(uint8_t clientId);
    void updateClientActivity(uint8_t clientId);
    bool validateClientId(uint8_t clientId) const;
    
    // Message processing
    bool processIncomingMessage(uint8_t clientId, const String& message);
    bool validateMessage(const String& message);
    void handleHeartbeat(uint8_t clientId);
    
    // Statistics and monitoring
    void updateStatistics();
    void checkClientTimeouts();
    
    // Error handling
    void handleError(const String& error);
    
    // Static event handler wrapper
    static void staticWebSocketEvent(uint8_t clientId, WStype_t type, uint8_t* payload, size_t length);
    static WebSocketServer* instance; // For static callback
};

#endif // WS_SERVER_H 