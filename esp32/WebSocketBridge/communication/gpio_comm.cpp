#include "gpio_comm.h"
#include "../utils/debug_utils.h"

GPIOComm::GPIOComm() :
    status(STATUS_DISCONNECTED),
    lastHeartbeat(0),
    lastMessageTime(0),
    communicationTimeout(PI_COMM_TIMEOUT_MS),
    heartbeatInterval(HEARTBEAT_INTERVAL_MS),
    messagesSent(0),
    messagesReceived(0),
    errorCount(0)
{
}

GPIOComm::~GPIOComm() {
    disconnect();
}

bool GPIOComm::begin(int txPin, int rxPin, long baudRate) {
    debugPrintPi("Initializing GPIO communication...");
    
    status = STATUS_CONNECTING;
    
    // Initialize UART handler
    if (!uartHandler.begin(txPin, rxPin, baudRate)) {
        DEBUG_ERROR("GPIOComm", "Failed to initialize UART handler");
        status = STATUS_ERROR;
        return false;
    }
    
    // Configure timeouts
    uartHandler.setTimeout(communicationTimeout);
    
    // Send initial handshake
    String handshake = "{\"type\":\"handshake\",\"source\":\"esp32\",\"timestamp\":" + String(millis()) + "}";
    if (!uartHandler.sendMessage(handshake)) {
        DEBUG_ERROR("GPIOComm", "Failed to send handshake");
        status = STATUS_ERROR;
        return false;
    }
    
    status = STATUS_CONNECTED;
    lastMessageTime = millis();
    lastHeartbeat = millis();
    
    debugPrintPi("GPIO communication initialized successfully");
    return true;
}

bool GPIOComm::sendMessage(const String& message) {
    if (status != STATUS_CONNECTED) {
        DEBUG_WARNING("GPIOComm", "Not connected, cannot send message");
        return false;
    }
    
    if (uartHandler.sendMessage(message)) {
        messagesSent++;
        lastMessageTime = millis();
        return true;
    } else {
        errorCount++;
        DEBUG_ERROR("GPIOComm", "Failed to send message via UART");
        return false;
    }
}

bool GPIOComm::getNextMessage(String& message) {
    if (status != STATUS_CONNECTED) {
        return false;
    }
    
    if (uartHandler.receiveMessage(message)) {
        messagesReceived++;
        lastMessageTime = millis();
        
        // Process the message
        if (validateMessage(message)) {
            return true;
        } else {
            DEBUG_WARNING("GPIOComm", "Received invalid message");
            errorCount++;
            return false;
        }
    }
    
    return false;
}

bool GPIOComm::hasMessages() const {
    return status == STATUS_CONNECTED && uartHandler.hasMessage();
}

void GPIOComm::update() {
    if (status == STATUS_DISCONNECTED) {
        return;
    }
    
    // Update UART handler
    uartHandler.update();
    
    // Process incoming messages
    processIncomingData();
    
    // Process outgoing messages
    processOutgoingMessages();
    
    // Check connection health
    checkConnection();
    
    // Send periodic heartbeat
    unsigned long now = millis();
    if (now - lastHeartbeat >= heartbeatInterval) {
        sendHeartbeat();
        lastHeartbeat = now;
    }
}

void GPIOComm::disconnect() {
    if (status != STATUS_DISCONNECTED) {
        debugPrintPi("Disconnecting GPIO communication...");
        
        // Send disconnect message
        String disconnect = "{\"type\":\"disconnect\",\"source\":\"esp32\"}";
        uartHandler.sendMessage(disconnect);
        
        status = STATUS_DISCONNECTED;
        debugPrintPi("GPIO communication disconnected");
    }
}

void GPIOComm::reconnect() {
    debugPrintPi("Reconnecting GPIO communication...");
    disconnect();
    delay(1000);
    
    // Attempt to reconnect with previous settings
    // Note: This requires storing the original pin/baud settings
    status = STATUS_CONNECTING;
    
    // Clear buffers and reset
    uartHandler.clear();
    
    // Send new handshake
    String handshake = "{\"type\":\"reconnect\",\"source\":\"esp32\",\"timestamp\":" + String(millis()) + "}";
    if (uartHandler.sendMessage(handshake)) {
        status = STATUS_CONNECTED;
        lastMessageTime = millis();
        debugPrintPi("GPIO communication reconnected successfully");
    } else {
        status = STATUS_ERROR;
        DEBUG_ERROR("GPIOComm", "Failed to reconnect");
    }
}

void GPIOComm::processIncomingData() {
    String message;
    while (uartHandler.receiveMessage(message)) {
        if (validateMessage(message)) {
            messagesReceived++;
            lastMessageTime = millis();
            
            // Add to incoming queue for external processing
            incomingQueue.enqueue(message);
            
            debugPrintPi("Queued incoming message: " + message.substring(0, 50));
        } else {
            errorCount++;
            handleError("Invalid message format received");
        }
    }
}

void GPIOComm::processOutgoingMessages() {
    // Process any queued outgoing messages
    String message;
    while (!outgoingQueue.isEmpty()) {
        if (outgoingQueue.dequeue(message)) {
            if (uartHandler.sendMessage(message)) {
                messagesSent++;
                lastMessageTime = millis();
                debugPrintPi("Sent queued message: " + message.substring(0, 50));
            } else {
                // Re-queue if failed (with retry limit)
                errorCount++;
                handleError("Failed to send queued message");
                break; // Stop processing to avoid infinite loop
            }
        }
    }
}

void GPIOComm::checkConnection() {
    unsigned long now = millis();
    
    // Check for communication timeout
    if (status == STATUS_CONNECTED && 
        (now - lastMessageTime) > communicationTimeout) {
        DEBUG_WARNING("GPIOComm", "Communication timeout detected");
        status = STATUS_ERROR;
        handleError("Communication timeout");
    }
    
    // Check UART handler status
    if (!uartHandler.isConnected()) {
        if (status == STATUS_CONNECTED) {
            DEBUG_WARNING("GPIOComm", "UART handler disconnected");
            status = STATUS_ERROR;
            handleError("UART handler disconnected");
        }
    }
}

void GPIOComm::sendHeartbeat() {
    if (status == STATUS_CONNECTED) {
        String heartbeat = "{\"type\":\"heartbeat\",\"source\":\"esp32\",\"timestamp\":" + String(millis()) + "}";
        if (!uartHandler.sendMessage(heartbeat)) {
            DEBUG_WARNING("GPIOComm", "Failed to send heartbeat");
            errorCount++;
        }
    }
}

bool GPIOComm::validateMessage(const String& message) {
    // Basic validation
    if (message.length() == 0 || message.length() > MAX_MESSAGE_SIZE) {
        return false;
    }
    
    // Check for JSON format
    if (message.startsWith("{") && message.endsWith("}")) {
        return true;
    }
    
    // Allow simple text messages for debugging
    return message.length() < 100;
}

void GPIOComm::handleError(const String& error) {
    DEBUG_ERROR("GPIOComm", error);
    errorCount++;
    
    // Attempt auto-recovery for certain errors
    if (errorCount % 5 == 0) { // Every 5 errors
        debugPrintPi("Attempting auto-recovery...");
        reconnect();
    }
}

void GPIOComm::updateStatus(Status newStatus) {
    if (status != newStatus) {
        debugPrintPi("Status changed: " + String(status) + " -> " + String(newStatus));
        status = newStatus;
    }
} 