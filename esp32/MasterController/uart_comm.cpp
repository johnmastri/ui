#include "uart_comm.h"

// Global instance
UARTComm uart;

void UARTComm::begin() {
    Serial.begin(UART_BAUD);
    
    // Initialize variables
    inputBuffer.reserve(UART_BUFFER_SIZE);
    lastHeartbeat = 0;
    lastStatusUpdate = 0;
    isConnected = false;
    messagesSent = 0;
    messagesReceived = 0;
    errors = 0;
    
    debugPrint("UART Communication initialized");
    
    // Send startup message after brief delay
    delay(100);
    sendStartup();
}

void UARTComm::update() {
    processIncomingData();
    
    // Send periodic messages
    if (shouldSendHeartbeat()) {
        sendHeartbeat();
    }
    
    if (shouldSendStatus()) {
        sendStatus();
    }
}

void UARTComm::processIncomingData() {
    while (Serial.available()) {
        char c = Serial.read();
        
        if (c == '\n') {
            // Process complete message
            if (inputBuffer.length() > 0) {
                processMessage(inputBuffer);
                inputBuffer = "";
            }
        } else if (c != '\r') {
            inputBuffer += c;
            
            // Prevent buffer overflow
            if (inputBuffer.length() >= UART_BUFFER_SIZE - 1) {
                debugPrint("Buffer overflow - clearing");
                inputBuffer = "";
                incrementErrorCount();
            }
        }
    }
}

void UARTComm::processMessage(const String& message) {
    debugPrint("Received: " + message);
    messagesReceived++;
    isConnected = true;  // Mark as connected when we receive messages
    
    DynamicJsonDocument doc(JSON_BUFFER_SIZE);
    DeserializationError error = deserializeJson(doc, message);
    
    if (error) {
        debugPrint("JSON parse error: " + String(error.c_str()));
        sendError("JSON parse failed: " + String(error.c_str()));
        incrementErrorCount();
        return;
    }
    
    // Check for required 'type' field
    if (!doc.containsKey("type")) {
        debugPrint("Message missing 'type' field");
        sendError("Message missing 'type' field");
        incrementErrorCount();
        return;
    }
    
    String messageType = doc["type"];
    
    // Route message to appropriate handler
    if (messageType == MSG_TYPE_LED_UPDATE) {
        handleLEDUpdate(doc);
    } else if (messageType == "system_command") {
        handleSystemCommand(doc);
    } else {
        debugPrint("Unknown message type: " + messageType);
        sendError("Unknown message type: " + messageType);
    }
}

void UARTComm::handleLEDUpdate(DynamicJsonDocument& doc) {
    // Extract LED update parameters
    if (!doc.containsKey("encoder_id") || !doc.containsKey("color") || !doc.containsKey("pattern")) {
        sendError("LED update missing required fields");
        return;
    }
    
    int encoderId = doc["encoder_id"];
    uint8_t r = doc["color"]["r"] | 0;
    uint8_t g = doc["color"]["g"] | 0;  
    uint8_t b = doc["color"]["b"] | 0;
    String patternStr = doc["pattern"];
    float value = doc["value"] | 0.0;
    
    // Convert pattern string to enum
    LEDPattern pattern = PATTERN_SOLID;
    if (patternStr == "off") pattern = PATTERN_OFF;
    else if (patternStr == "ring_fill") pattern = PATTERN_RING_FILL;
    else if (patternStr == "pulse") pattern = PATTERN_PULSE;
    else if (patternStr == "rainbow") pattern = PATTERN_RAINBOW;
    
    // Call callback function
    onLEDUpdateReceived(encoderId, r, g, b, pattern, value);
}

void UARTComm::handleSystemCommand(DynamicJsonDocument& doc) {
    String command = doc["command"] | "";
    String parameter = doc["parameter"] | "";
    
    onSystemCommandReceived(command, parameter);
}

void UARTComm::sendMessage(const String& message) {
    Serial.println(message);
    messagesSent++;
    debugPrint("Sent: " + message);
}

void UARTComm::sendJSON(DynamicJsonDocument& doc) {
    String message;
    serializeJson(doc, message);
    sendMessage(message);
}

void UARTComm::sendStartup() {
    DynamicJsonDocument doc(JSON_BUFFER_SIZE);
    doc["type"] = MSG_TYPE_STARTUP;
    doc["device_id"] = DEVICE_ID;
    doc["firmware_version"] = FIRMWARE_VERSION;
    doc["status"] = "ready";
    doc["capabilities"] = "led_control,i2c_encoders,uart_comm";
    doc["timestamp"] = millis();
    
    sendJSON(doc);
}

void UARTComm::sendHeartbeat() {
    DynamicJsonDocument doc(256);
    doc["type"] = MSG_TYPE_HEARTBEAT;
    doc["device_id"] = DEVICE_ID;
    doc["status"] = "alive";
    doc["uptime"] = millis();
    doc["timestamp"] = millis();
    
    sendJSON(doc);
    lastHeartbeat = millis();
}

void UARTComm::sendStatus() {
    DynamicJsonDocument doc(JSON_BUFFER_SIZE);
    doc["type"] = MSG_TYPE_STATUS;
    doc["device_id"] = DEVICE_ID;
    doc["uptime"] = millis();
    doc["free_memory"] = ESP.getFreeHeap();
    doc["messages_sent"] = messagesSent;
    doc["messages_received"] = messagesReceived;
    doc["errors"] = errors;
    doc["timestamp"] = millis();
    
    sendJSON(doc);
    lastStatusUpdate = millis();
}

void UARTComm::sendError(const String& errorMsg) {
    DynamicJsonDocument doc(512);
    doc["type"] = MSG_TYPE_ERROR;
    doc["device_id"] = DEVICE_ID;
    doc["error"] = errorMsg;
    doc["timestamp"] = millis();
    
    sendJSON(doc);
    incrementErrorCount();
}

void UARTComm::sendEncoderUpdate(int encoderId, float value, int direction) {
    DynamicJsonDocument doc(256);
    doc["type"] = MSG_TYPE_ENCODER;
    doc["device_id"] = DEVICE_ID;
    doc["encoder_id"] = encoderId;
    doc["value"] = value;
    doc["direction"] = direction;
    doc["timestamp"] = millis();
    
    sendJSON(doc);
}

void UARTComm::sendI2CScanResult(int address, bool found) {
    DynamicJsonDocument doc(256);
    doc["type"] = MSG_TYPE_I2C_SCAN;
    doc["device_id"] = DEVICE_ID;
    doc["address"] = address;
    doc["found"] = found;
    doc["timestamp"] = millis();
    
    sendJSON(doc);
}

bool UARTComm::shouldSendHeartbeat() {
    return (millis() - lastHeartbeat) >= HEARTBEAT_INTERVAL_MS;
}

bool UARTComm::shouldSendStatus() {
    return (millis() - lastStatusUpdate) >= STATUS_UPDATE_INTERVAL_MS;
}

void UARTComm::debugPrint(const String& message) {
    if (DEBUG_SERIAL) {
        Serial.println("[DEBUG] " + message);
    }
}

void UARTComm::incrementErrorCount() {
    errors++;
} 