#include "message_proxy.h"
#include "../utils/debug_utils.h"

MessageProxy::MessageProxy() :
    webSocketServer(nullptr),
    piCommunication(nullptr),
    totalMessagesProxied(0),
    wsTopiMessages(0),
    piToWsMessages(0),
    errorCount(0),
    lastStatsUpdate(0),
    filterMessages(true),
    forwardHeartbeats(false),
    initialized(false)
{
}

MessageProxy::~MessageProxy() {
    // Cleanup if needed
}

void MessageProxy::begin(WebSocketServer* wsServer, GPIOComm* piComm) {
    webSocketServer = wsServer;
    piCommunication = piComm;
    
    if (webSocketServer && piCommunication) {
        initialized = true;
        debugPrint("Message proxy initialized successfully");
    } else {
        DEBUG_ERROR("MessageProxy", "Invalid WebSocket server or Pi communication");
        initialized = false;
    }
}

void MessageProxy::update() {
    if (!initialized) {
        return;
    }
    
    updateStatistics();
}

void MessageProxy::handleWebSocketMessage(const String& message, uint8_t clientId) {
    if (!initialized || !validateMessage(message)) {
        errorCount++;
        return;
    }
    
    debugPrint("🔄 Proxying WS->Pi: " + message.substring(0, 50));
    
    if (processWebSocketToPi(message, clientId)) {
        wsTopiMessages++;
        totalMessagesProxied++;
    } else {
        errorCount++;
        handleError("Failed to forward WebSocket message to Pi");
    }
}

void MessageProxy::handlePiMessage(const String& message) {
    if (!initialized || !validateMessage(message)) {
        errorCount++;
        return;
    }
    
    debugPrint("🔄 Proxying Pi->WS: " + message.substring(0, 50));
    
    if (processPiToWebSocket(message)) {
        piToWsMessages++;
        totalMessagesProxied++;
    } else {
        errorCount++;
        handleError("Failed to forward Pi message to WebSocket");
    }
}

bool MessageProxy::processWebSocketToPi(const String& message, uint8_t clientId) {
    if (!piCommunication || !piCommunication->isConnected()) {
        DEBUG_WARNING("MessageProxy", "Pi communication not available");
        return false;
    }
    
    // Check if message should be forwarded
    if (!shouldForwardMessage(message)) {
        return true; // Consider it successful but don't forward
    }
    
    // Add client information to message
    String enhancedMessage = addClientInfo(message, clientId);
    
    // Forward to Pi
    return piCommunication->sendMessage(enhancedMessage);
}

bool MessageProxy::processPiToWebSocket(const String& message) {
    if (!webSocketServer) {
        DEBUG_WARNING("MessageProxy", "WebSocket server not available");
        return false;
    }
    
    // Check if message should be forwarded
    if (!shouldForwardMessage(message)) {
        return true; // Consider it successful but don't forward
    }
    
    // Remove any ESP32-specific information
    String cleanMessage = removeClientInfo(message);
    
    // Broadcast to all WebSocket clients
    return webSocketServer->broadcastMessage(cleanMessage);
}

String MessageProxy::addClientInfo(const String& message, uint8_t clientId) {
    JsonDocument doc;
    
    if (parseJson(message, doc)) {
        // Add client ID and ESP32 source info
        doc["client_id"] = clientId;
        doc["source"] = "esp32_bridge";
        doc["bridge_timestamp"] = millis();
        
        return serializeJson(doc);
    }
    
    // If JSON parsing fails, return original message
    return message;
}

String MessageProxy::removeClientInfo(const String& message) {
    JsonDocument doc;
    
    if (parseJson(message, doc)) {
        // Remove ESP32-specific fields
        doc.remove("client_id");
        doc.remove("source");
        doc.remove("bridge_timestamp");
        
        return serializeJson(doc);
    }
    
    // If JSON parsing fails, return original message
    return message;
}

bool MessageProxy::shouldForwardMessage(const String& message) {
    if (!filterMessages) {
        return true; // Forward everything if filtering is disabled
    }
    
    // Check for heartbeat messages
    if (isHeartbeatMessage(message)) {
        return forwardHeartbeats;
    }
    
    // Filter out internal ESP32 messages
    JsonDocument doc;
    if (parseJson(message, doc)) {
        String messageType = doc["type"];
        
        // Don't forward internal ESP32 messages
        if (messageType == "esp32_status" || 
            messageType == "bridge_info" ||
            messageType == "internal_error") {
            return false;
        }
    }
    
    return true; // Forward by default
}

bool MessageProxy::parseJson(const String& message, JsonDocument& doc) {
    DeserializationError error = deserializeJson(doc, message);
    
    if (error) {
        DEBUG_WARNING("MessageProxy", "JSON parse error: " + String(error.c_str()));
        return false;
    }
    
    return true;
}

String MessageProxy::serializeJson(const JsonDocument& doc) {
    String result;
    serializeJson(doc, result);
    return result;
}

bool MessageProxy::validateMessage(const String& message) {
    // Basic validation
    if (message.length() == 0 || message.length() > MAX_MESSAGE_SIZE) {
        return false;
    }
    
    // Allow both JSON and plain text messages
    return true;
}

bool MessageProxy::isHeartbeatMessage(const String& message) {
    JsonDocument doc;
    if (parseJson(message, doc)) {
        String messageType = doc["type"];
        return (messageType == "heartbeat" || messageType == "heartbeat_ack");
    }
    
    return false;
}

void MessageProxy::handleError(const String& error) {
    DEBUG_ERROR("MessageProxy", error);
    errorCount++;
}

void MessageProxy::updateStatistics() {
    unsigned long now = millis();
    
    if (now - lastStatsUpdate >= 15000) { // Update every 15 seconds
        debugPrint("📊 Message Proxy Stats:");
        debugPrint("  Total Messages: " + String(totalMessagesProxied));
        debugPrint("  WS->Pi: " + String(wsTopiMessages));
        debugPrint("  Pi->WS: " + String(piToWsMessages));
        debugPrint("  Errors: " + String(errorCount));
        
        lastStatsUpdate = now;
    }
} 