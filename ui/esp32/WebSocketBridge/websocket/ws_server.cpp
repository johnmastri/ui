#include "ws_server.h"
#include "../utils/debug_utils.h"

// Static instance for callback
WebSocketServer* WebSocketServer::instance = nullptr;

WebSocketServer::WebSocketServer() :
    server(nullptr),
    serverPort(0),
    maxClients(MAX_WEBSOCKET_CLIENTS),
    connectedClients(0),
    totalConnections(0),
    totalMessagesSent(0),
    totalMessagesReceived(0),
    lastStatsUpdate(0),
    clientConnectedCallback(nullptr),
    clientDisconnectedCallback(nullptr),
    messageReceivedCallback(nullptr),
    errorCallback(nullptr)
{
    // Initialize client array
    for (int i = 0; i < MAX_WEBSOCKET_CLIENTS; i++) {
        clients[i].id = i;
        clients[i].connected = false;
        clients[i].connectedTime = 0;
        clients[i].lastActivity = 0;
        clients[i].messagesSent = 0;
        clients[i].messagesReceived = 0;
    }
    
    instance = this; // Set static instance for callbacks
}

WebSocketServer::~WebSocketServer() {
    stop();
    instance = nullptr;
}

bool WebSocketServer::begin(uint16_t port, uint8_t maxClientsCount) {
    debugPrintWS("Starting WebSocket server on port " + String(port));
    
    serverPort = port;
    maxClients = min(maxClientsCount, (uint8_t)MAX_WEBSOCKET_CLIENTS);
    
    // Create WebSocket server
    server = new WebSocketsServer(port);
    
    if (!server) {
        DEBUG_ERROR("WebSocketServer", "Failed to create server instance");
        return false;
    }
    
    // Set event handler
    server->onEvent(staticWebSocketEvent);
    
    // Start server
    server->begin();
    
    debugPrintWS("WebSocket server started successfully");
    return true;
}

void WebSocketServer::stop() {
    if (server) {
        debugPrintWS("Stopping WebSocket server");
        server->close();
        delete server;
        server = nullptr;
        
        // Reset all clients
        for (int i = 0; i < MAX_WEBSOCKET_CLIENTS; i++) {
            clients[i].connected = false;
        }
        connectedClients = 0;
    }
}

void WebSocketServer::handleClients() {
    if (server) {
        server->loop();
        updateStatistics();
        checkClientTimeouts();
    }
}

bool WebSocketServer::isClientConnected(uint8_t clientId) const {
    return validateClientId(clientId) && clients[clientId].connected;
}

WebSocketServer::ClientInfo WebSocketServer::getClientInfo(uint8_t clientId) const {
    if (validateClientId(clientId)) {
        return clients[clientId];
    }
    
    // Return empty client info
    ClientInfo empty = {};
    empty.id = 255; // Invalid ID
    return empty;
}

bool WebSocketServer::sendMessage(uint8_t clientId, const String& message) {
    if (!server || !isClientConnected(clientId)) {
        return false;
    }
    
    bool success = server->sendTXT(clientId, message);
    
    if (success) {
        clients[clientId].messagesSent++;
        totalMessagesSent++;
        updateClientActivity(clientId);
        debugPrintWS("Sent to client " + String(clientId) + ": " + message.substring(0, 50));
    } else {
        DEBUG_WARNING("WebSocketServer", "Failed to send message to client " + String(clientId));
    }
    
    return success;
}

bool WebSocketServer::broadcastMessage(const String& message) {
    if (!server) {
        return false;
    }
    
    server->broadcastTXT(message);
    totalMessagesSent += connectedClients;
    
    // Update activity for all connected clients
    for (int i = 0; i < MAX_WEBSOCKET_CLIENTS; i++) {
        if (clients[i].connected) {
            clients[i].messagesSent++;
            updateClientActivity(i);
        }
    }
    
    debugPrintWS("Broadcast: " + message.substring(0, 50));
    return true;
}

bool WebSocketServer::getNextMessage(String& message, int& clientId) {
    if (incomingQueue.isEmpty()) {
        return false;
    }
    
    String queuedMessage = incomingQueue.dequeue();
    
    // Extract client ID from message (format: "clientId:message")
    int separatorIndex = queuedMessage.indexOf(':');
    if (separatorIndex > 0) {
        clientId = queuedMessage.substring(0, separatorIndex).toInt();
        message = queuedMessage.substring(separatorIndex + 1);
        return true;
    }
    
    return false;
}

bool WebSocketServer::sendJSON(uint8_t clientId, const JsonDocument& doc) {
    String jsonString;
    serializeJson(doc, jsonString);
    return sendMessage(clientId, jsonString);
}

bool WebSocketServer::broadcastJSON(const JsonDocument& doc) {
    String jsonString;
    serializeJson(doc, jsonString);
    return broadcastMessage(jsonString);
}

bool WebSocketServer::parseMessage(const String& message, JsonDocument& doc) {
    DeserializationError error = deserializeJson(doc, message);
    
    if (error) {
        DEBUG_WARNING("WebSocketServer", "JSON parse error: " + String(error.c_str()));
        return false;
    }
    
    return true;
}

void WebSocketServer::onClientConnected(void (*callback)(uint8_t clientId)) {
    clientConnectedCallback = callback;
}

void WebSocketServer::onClientDisconnected(void (*callback)(uint8_t clientId)) {
    clientDisconnectedCallback = callback;
}

void WebSocketServer::onMessageReceived(void (*callback)(uint8_t clientId, const String& message)) {
    messageReceivedCallback = callback;
}

void WebSocketServer::onError(void (*callback)(const String& error)) {
    errorCallback = callback;
}

void WebSocketServer::webSocketEvent(uint8_t clientId, WStype_t type, uint8_t* payload, size_t length) {
    switch (type) {
        case WStype_DISCONNECTED:
            debugPrintWS("Client " + String(clientId) + " disconnected");
            removeClient(clientId);
            if (clientDisconnectedCallback) {
                clientDisconnectedCallback(clientId);
            }
            break;
            
        case WStype_CONNECTED: {
            IPAddress ip = server->remoteIP(clientId);
            debugPrintWS("Client " + String(clientId) + " connected from " + ip.toString());
            addClient(clientId, ip);
            if (clientConnectedCallback) {
                clientConnectedCallback(clientId);
            }
            break;
        }
        
        case WStype_TEXT: {
            String message = String((char*)payload);
            debugPrintWS("Received from client " + String(clientId) + ": " + message.substring(0, 50));
            
            if (processIncomingMessage(clientId, message)) {
                if (messageReceivedCallback) {
                    messageReceivedCallback(clientId, message);
                }
            }
            break;
        }
        
        case WStype_ERROR:
            DEBUG_ERROR("WebSocketServer", "WebSocket error on client " + String(clientId));
            if (errorCallback) {
                errorCallback("WebSocket error on client " + String(clientId));
            }
            break;
            
        default:
            // Handle other event types if needed
            break;
    }
}

void WebSocketServer::addClient(uint8_t clientId, IPAddress remoteIP) {
    if (validateClientId(clientId)) {
        clients[clientId].connected = true;
        clients[clientId].remoteIP = remoteIP;
        clients[clientId].connectedTime = millis();
        clients[clientId].lastActivity = millis();
        clients[clientId].messagesSent = 0;
        clients[clientId].messagesReceived = 0;
        
        connectedClients++;
        totalConnections++;
    }
}

void WebSocketServer::removeClient(uint8_t clientId) {
    if (validateClientId(clientId) && clients[clientId].connected) {
        clients[clientId].connected = false;
        connectedClients--;
    }
}

void WebSocketServer::updateClientActivity(uint8_t clientId) {
    if (validateClientId(clientId)) {
        clients[clientId].lastActivity = millis();
    }
}

bool WebSocketServer::validateClientId(uint8_t clientId) const {
    return clientId < MAX_WEBSOCKET_CLIENTS;
}

bool WebSocketServer::processIncomingMessage(uint8_t clientId, const String& message) {
    if (!validateMessage(message)) {
        return false;
    }
    
    // Update client statistics
    if (validateClientId(clientId)) {
        clients[clientId].messagesReceived++;
        totalMessagesReceived++;
        updateClientActivity(clientId);
    }
    
    // Check for heartbeat messages
    JsonDocument doc;
    if (parseMessage(message, doc)) {
        if (doc["type"] == "heartbeat") {
            handleHeartbeat(clientId);
            return true; // Don't queue heartbeat messages
        }
    }
    
    // Queue message for processing
    String queuedMessage = String(clientId) + ":" + message;
    return incomingQueue.enqueue(queuedMessage);
}

bool WebSocketServer::validateMessage(const String& message) {
    return message.length() > 0 && message.length() <= MAX_MESSAGE_SIZE;
}

void WebSocketServer::handleHeartbeat(uint8_t clientId) {
    // Respond to heartbeat
    JsonDocument response;
    response["type"] = "heartbeat_ack";
    response["timestamp"] = millis();
    sendJSON(clientId, response);
}

void WebSocketServer::updateStatistics() {
    unsigned long now = millis();
    
    if (now - lastStatsUpdate >= 10000) { // Update every 10 seconds
        debugPrintWS("Statistics - Clients: " + String(connectedClients) + 
                    ", Total Connections: " + String(totalConnections) +
                    ", Messages Sent: " + String(totalMessagesSent) +
                    ", Messages Received: " + String(totalMessagesReceived));
        lastStatsUpdate = now;
    }
}

void WebSocketServer::checkClientTimeouts() {
    unsigned long now = millis();
    const unsigned long TIMEOUT_MS = 60000; // 60 seconds timeout
    
    for (int i = 0; i < MAX_WEBSOCKET_CLIENTS; i++) {
        if (clients[i].connected && (now - clients[i].lastActivity) > TIMEOUT_MS) {
            DEBUG_WARNING("WebSocketServer", "Client " + String(i) + " timed out");
            server->disconnect(i);
        }
    }
}

void WebSocketServer::handleError(const String& error) {
    DEBUG_ERROR("WebSocketServer", error);
    if (errorCallback) {
        errorCallback(error);
    }
}

void WebSocketServer::staticWebSocketEvent(uint8_t clientId, WStype_t type, uint8_t* payload, size_t length) {
    if (instance) {
        instance->webSocketEvent(clientId, type, payload, length);
    }
} 