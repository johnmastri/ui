#include "uart_comm.h"
#include "led_controller.h"
#include <WiFi.h>

UARTComm uart;
extern LEDController ledController;

void UARTComm::begin() {
    Serial.begin(USB_SERIAL_BAUD);
    
    piSerial.begin(PI_UART_BAUD, SERIAL_8N1, PI_UART_RX_PIN, PI_UART_TX_PIN);
    
    usbInputBuffer.reserve(UART_BUFFER_SIZE);
    piInputBuffer.reserve(UART_BUFFER_SIZE);
    lastHeartbeat = 0;
    lastStatusUpdate = 0;
    isUsbConnected = false;
    isPiConnected = false;
    messagesSent = 0;
    messagesReceived = 0;
    usbMessagesReceived = 0;
    piMessagesReceived = 0;
    errors = 0;
    
    delay(100);
    
    Serial.println("\n");
    Serial.println("========================================");
    Serial.println("ESP32-S3 WebSocket-to-Pi Bridge");
    Serial.println("========================================");
    Serial.println("Firmware: " FIRMWARE_VERSION);
    Serial.println("Device ID: " DEVICE_ID);
    Serial.print("MAC Address: ");
    Serial.println(getMacAddress());
    Serial.println("----------------------------------------");
    Serial.println("USB Serial: ACTIVE (115200 baud)");
    Serial.println("  Purpose: Receive WebSocket data");
    Serial.println("Pi UART: ACTIVE (115200 baud)");
    Serial.print("  TX Pin: D");
    Serial.println(PI_UART_TX_PIN);
    Serial.print("  RX Pin: D");
    Serial.println(PI_UART_RX_PIN);
    Serial.println("========================================");
    Serial.println();
    
    delay(100);
    sendStartup();
}

void UARTComm::update() {
    processUSBData();
    processPiData();
    
    if (shouldSendHeartbeat()) {
        sendHeartbeat();
    }
    
    if (shouldSendStatus()) {
        sendStatus();
    }
}

void UARTComm::processUSBData() {
    while (Serial.available()) {
        char c = Serial.read();
        
        if (c == '\n') {
            if (usbInputBuffer.length() > 0) {
                usbMessagesReceived++;
                
                processUSBMessage(usbInputBuffer);
                
                forwardMessageToPi(usbInputBuffer);
                
                usbInputBuffer = "";
            }
        } else if (c != '\r') {
            usbInputBuffer += c;
            
            if (usbInputBuffer.length() >= UART_BUFFER_SIZE - 1) {
                Serial.println("[ERROR] USB buffer overflow - clearing");
                usbInputBuffer = "";
                incrementErrorCount();
            }
        }
    }
}

void UARTComm::processPiData() {
    while (piSerial.available()) {
        char c = piSerial.read();
        
        if (c == '\n') {
            if (piInputBuffer.length() > 0) {
                piMessagesReceived++;
                
                processPiMessage(piInputBuffer);
                
                Serial.println(piInputBuffer);
                
                piInputBuffer = "";
            }
        } else if (c != '\r') {
            piInputBuffer += c;
            
            if (piInputBuffer.length() >= UART_BUFFER_SIZE - 1) {
                Serial.println("[ERROR] Pi buffer overflow - clearing");
                piInputBuffer = "";
                incrementErrorCount();
            }
        }
    }
}

void UARTComm::processUSBMessage(const String& message) {
    isUsbConnected = true;
    
    DynamicJsonDocument doc(JSON_BUFFER_SIZE);
    DeserializationError error = deserializeJson(doc, message);
    
    if (error) {
        incrementErrorCount();
        return;
    }
    
    if (!doc.containsKey("type")) {
        incrementErrorCount();
        return;
    }
    
    String messageType = doc["type"];
    
    if (messageType == MSG_TYPE_LED_UPDATE) {
        handleLEDUpdate(doc);
    } else if (messageType == "system_command") {
        handleSystemCommand(doc);
    }
}

void UARTComm::processPiMessage(const String& message) {
    isPiConnected = true;
    
    DynamicJsonDocument doc(JSON_BUFFER_SIZE);
    DeserializationError error = deserializeJson(doc, message);
    
    if (error) {
        Serial.print("│ [ERROR] Pi JSON parse failed: ");
        Serial.println(error.c_str());
        incrementErrorCount();
        return;
    }
    
    if (!doc.containsKey("type")) {
        Serial.println("│ [WARNING] Pi message missing 'type' field");
        return;
    }
    
    String messageType = doc["type"];
    Serial.print("│ Parsed Type: ");
    Serial.println(messageType);
    
    if (messageType == MSG_TYPE_ENCODER) {
        int encoderId = doc["encoder_id"];
        float value = doc["value"];
        Serial.print("│ Encoder ");
        Serial.print(encoderId);
        Serial.print(" Value: ");
        Serial.println(value);
    }
}

void UARTComm::handleLEDUpdate(DynamicJsonDocument& doc) {
    if (!doc.containsKey("color") || !doc.containsKey("pattern")) {
        sendError("LED update missing required fields");
        return;
    }
    
    uint8_t r = doc["color"]["r"].as<uint8_t>();
    uint8_t g = doc["color"]["g"].as<uint8_t>();  
    uint8_t b = doc["color"]["b"].as<uint8_t>();
    String patternStr = doc["pattern"];
    float value = doc["value"].as<float>();
    
    if (doc.containsKey("led_start") && doc.containsKey("led_count")) {
        int ledStart = doc["led_start"];
        int ledCount = doc["led_count"];
        
        ledController.setDirectControlMode(true);
        
        for (int i = 0; i < ledCount; i++) {
            int ledIndex = ledStart + i;
            if (ledIndex < TOTAL_LEDS) {
                ledController.setLED(ledIndex, r, g, b);
            }
        }
        ledController.showLEDs();
        
    } else if (doc.containsKey("encoder_id")) {
        int encoderId = doc["encoder_id"];
        
        LEDPattern pattern = PATTERN_SOLID;
        if (patternStr == "off") pattern = PATTERN_OFF;
        else if (patternStr == "ring_fill") pattern = PATTERN_RING_FILL;
        else if (patternStr == "pulse") pattern = PATTERN_PULSE;
        else if (patternStr == "rainbow") pattern = PATTERN_RAINBOW;
        
        onLEDUpdateReceived(encoderId, r, g, b, pattern, value);
    } else {
        sendError("LED update requires either led_start+led_count or encoder_id");
    }
}

void UARTComm::handleSystemCommand(DynamicJsonDocument& doc) {
    String command = doc["command"] | "";
    String parameter = doc["parameter"] | "";
    
    onSystemCommandReceived(command, parameter);
}

void UARTComm::sendMessageToUSB(const String& message) {
    Serial.println(message);
    messagesSent++;
}

void UARTComm::sendMessageToPi(const String& message) {
    piSerial.println(message);
    messagesSent++;
}

void UARTComm::forwardMessageToPi(const String& message) {
    piSerial.println(message);
}

void UARTComm::sendJSON(DynamicJsonDocument& doc) {
    String message;
    serializeJson(doc, message);
    sendMessageToUSB(message);
}

void UARTComm::sendStartup() {
    DynamicJsonDocument doc(JSON_BUFFER_SIZE);
    doc["type"] = MSG_TYPE_STARTUP;
    doc["device_id"] = DEVICE_ID;
    doc["mac_address"] = getMacAddress();
    doc["firmware_version"] = FIRMWARE_VERSION;
    doc["status"] = "ready";
    doc["capabilities"] = "websocket_bridge,dual_uart,led_control,i2c_encoders";
    doc["usb_baud"] = USB_SERIAL_BAUD;
    doc["pi_baud"] = PI_UART_BAUD;
    doc["timestamp"] = millis();
    
    String message;
    serializeJson(doc, message);
    
    Serial.println(">>> Sending Startup Message to USB <<<");
    sendMessageToUSB(message);
    
    delay(100);
    
    Serial.println(">>> Sending Startup Message to Pi <<<");
    sendMessageToPi(message);
}

void UARTComm::sendHeartbeat() {
    DynamicJsonDocument doc(256);
    doc["type"] = MSG_TYPE_HEARTBEAT;
    doc["device_id"] = DEVICE_ID;
    doc["mac_address"] = getMacAddress();
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
    doc["mac_address"] = getMacAddress();
    doc["uptime"] = millis();
    doc["free_memory"] = ESP.getFreeHeap();
    doc["messages_sent"] = messagesSent;
    doc["messages_received"] = messagesReceived;
    doc["usb_messages"] = usbMessagesReceived;
    doc["pi_messages"] = piMessagesReceived;
    doc["usb_connected"] = isUsbConnected;
    doc["pi_connected"] = isPiConnected;
    doc["errors"] = errors;
    doc["timestamp"] = millis();
    
    sendJSON(doc);
    lastStatusUpdate = millis();
}

void UARTComm::sendError(const String& errorMsg) {
    DynamicJsonDocument doc(512);
    doc["type"] = MSG_TYPE_ERROR;
    doc["device_id"] = DEVICE_ID;
    doc["mac_address"] = getMacAddress();
    doc["error"] = errorMsg;
    doc["timestamp"] = millis();
    
    sendJSON(doc);
    incrementErrorCount();
}

void UARTComm::sendEncoderUpdate(int encoderId, float value, int direction) {
    DynamicJsonDocument doc(256);
    doc["type"] = MSG_TYPE_ENCODER;
    doc["device_id"] = DEVICE_ID;
    doc["mac_address"] = getMacAddress();
    doc["encoder_id"] = encoderId;
    doc["value"] = value;
    doc["direction"] = direction;
    doc["timestamp"] = millis();
    
    String message;
    serializeJson(doc, message);
    
    sendMessageToUSB(message);
}

void UARTComm::sendButtonPress(int encoderId) {
    DynamicJsonDocument doc(256);
    doc["type"] = "button_press";
    doc["device_id"] = DEVICE_ID;
    doc["mac_address"] = getMacAddress();
    doc["encoder_id"] = encoderId;
    doc["timestamp"] = millis();
    
    String message;
    serializeJson(doc, message);
    
    sendMessageToUSB(message);
}

void UARTComm::sendI2CScanResult(int address, bool found) {
    DynamicJsonDocument doc(256);
    doc["type"] = MSG_TYPE_I2C_SCAN;
    doc["device_id"] = DEVICE_ID;
    doc["mac_address"] = getMacAddress();
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

String UARTComm::getMacAddress() {
    uint8_t mac[6];
    WiFi.macAddress(mac);
    char macStr[18];
    sprintf(macStr, "%02X:%02X:%02X:%02X:%02X:%02X", 
            mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    return String(macStr);
}
