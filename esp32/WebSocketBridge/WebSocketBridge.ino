/*
 * WebSocket Bridge for MIDI Controller
 * ESP32 USB-to-GPIO WebSocket Proxy
 * 
 * This sketch creates a WebSocket bridge that:
 * - Presents as USB network device to PC
 * - Runs WebSocket server on USB interface  
 * - Forwards messages to Pi via GPIO/UART
 * - Enables VST to communicate with isolated Pi
 * 
 * Author: AI Assistant
 * Date: 2024
 */

#include "config.h"
#include "utils/debug_utils.h"
#include "utils/status_led.h"
#include "network/usb_network.h"
#include "websocket/ws_server.h"
#include "communication/gpio_comm.h"
#include "bridge/message_proxy.h"
#include "bridge/connection_manager.h"

// Global component instances
StatusLED statusLED;
USBNetwork usbNetwork;
WebSocketServer wsServer;
GPIOComm piComm;
MessageProxy messageProxy;
ConnectionManager connManager;

// System state
bool systemInitialized = false;
unsigned long lastHeartbeat = 0;
unsigned long lastStatusUpdate = 0;

void setup() {
    // Initialize debug serial
    Serial.begin(DEBUG_BAUD_RATE);
    delay(1000); // Allow serial to initialize
    
    debugPrint("🚀 WebSocket Bridge Starting...");
    debugPrint("Version: 1.0.0 - Phase 1: USB Bridge");
    debugPrint("====================================");
    
    // Initialize status LED
    statusLED.begin(STATUS_LED_PIN);
    statusLED.setPattern(StatusLED::PATTERN_STARTUP);
    debugPrint("✅ Status LED initialized");
    
    // Initialize Pi communication first
    debugPrint("🔗 Initializing Pi communication...");
    if (!piComm.begin(PI_UART_TX_PIN, PI_UART_RX_PIN, PI_UART_BAUD)) {
        debugPrint("❌ Pi communication failed to initialize");
        statusLED.setPattern(StatusLED::PATTERN_ERROR);
        return;
    }
    debugPrint("✅ Pi communication initialized");
    
    // Initialize USB network interface
    debugPrint("🌐 Initializing USB network...");
    if (!usbNetwork.begin(USB_NETWORK_IP, USB_NETWORK_SUBNET, USB_NETWORK_GATEWAY)) {
        debugPrint("❌ USB network failed to initialize");
        statusLED.setPattern(StatusLED::PATTERN_ERROR);
        return;
    }
    debugPrint("✅ USB network initialized");
    
    // Initialize WebSocket server
    debugPrint("📡 Initializing WebSocket server...");
    if (!wsServer.begin(WEBSOCKET_PORT, MAX_WEBSOCKET_CLIENTS)) {
        debugPrint("❌ WebSocket server failed to initialize");
        statusLED.setPattern(StatusLED::PATTERN_ERROR);
        return;
    }
    debugPrint("✅ WebSocket server initialized");
    
    // Initialize message proxy
    debugPrint("🔄 Initializing message proxy...");
    messageProxy.begin(&wsServer, &piComm);
    debugPrint("✅ Message proxy initialized");
    
    // Initialize connection manager
    debugPrint("🔧 Initializing connection manager...");
    connManager.begin(&usbNetwork, &wsServer, &piComm, &statusLED);
    debugPrint("✅ Connection manager initialized");
    
    // System ready
    systemInitialized = true;
    statusLED.setPattern(StatusLED::PATTERN_READY);
    
    debugPrint("🎉 WebSocket Bridge Ready!");
    debugPrint("📍 USB IP: " + String(USB_NETWORK_IP) + ":" + String(WEBSOCKET_PORT));
    debugPrint("🔗 Connect VST to: ws://" + String(USB_NETWORK_IP) + ":" + String(WEBSOCKET_PORT));
    debugPrint("====================================");
}

void loop() {
    if (!systemInitialized) {
        // System failed to initialize, just blink error LED
        statusLED.update();
        delay(100);
        return;
    }
    
    // Update all components
    updateNetworkAndWebSocket();
    updatePiCommunication();
    updateMessageProxy();
    updateConnectionManager();
    updateStatusAndHeartbeat();
    
    // Small delay to prevent overwhelming the system
    delay(MAIN_LOOP_DELAY_MS);
}

void updateNetworkAndWebSocket() {
    // Update USB network interface
    usbNetwork.update();
    
    // Handle WebSocket server
    wsServer.handleClients();
    
    // Check for new WebSocket messages
    String wsMessage;
    int clientId;
    if (wsServer.getNextMessage(wsMessage, clientId)) {
        debugPrintWS("📥 WebSocket: " + wsMessage);
        messageProxy.handleWebSocketMessage(wsMessage, clientId);
    }
}

void updatePiCommunication() {
    // Update Pi communication
    piComm.update();
    
    // Check for messages from Pi
    String piMessage;
    if (piComm.getNextMessage(piMessage)) {
        debugPrintPi("📤 Pi: " + piMessage);
        messageProxy.handlePiMessage(piMessage);
    }
}

void updateMessageProxy() {
    // Process message proxy operations
    messageProxy.update();
}

void updateConnectionManager() {
    // Update connection states and handle errors
    connManager.update();
    
    // Handle connection state changes
    if (connManager.hasStateChanged()) {
        ConnectionManager::State state = connManager.getCurrentState();
        updateStatusForConnectionState(state);
    }
}

void updateStatusAndHeartbeat() {
    unsigned long now = millis();
    
    // Update status LED
    statusLED.update();
    
    // Send periodic heartbeat (if needed)
    if (now - lastHeartbeat >= HEARTBEAT_INTERVAL_MS) {
        sendHeartbeat();
        lastHeartbeat = now;
    }
    
    // Periodic status update
    if (now - lastStatusUpdate >= 10000) { // Every 10 seconds
        printSystemStatus();
        lastStatusUpdate = now;
    }
}

void updateStatusForConnectionState(ConnectionManager::State state) {
    switch (state) {
        case ConnectionManager::STATE_USB_CONNECTED:
            statusLED.setPattern(StatusLED::PATTERN_USB_CONNECTED);
            break;
        case ConnectionManager::STATE_WEBSOCKET_CONNECTED:
            statusLED.setPattern(StatusLED::PATTERN_WEBSOCKET_CONNECTED);
            break;
        case ConnectionManager::STATE_PI_CONNECTED:
            statusLED.setPattern(StatusLED::PATTERN_PI_CONNECTED);
            break;
        case ConnectionManager::STATE_FULLY_CONNECTED:
            statusLED.setPattern(StatusLED::PATTERN_FULLY_CONNECTED);
            break;
        case ConnectionManager::STATE_ERROR:
            statusLED.setPattern(StatusLED::PATTERN_ERROR);
            break;
        default:
            statusLED.setPattern(StatusLED::PATTERN_READY);
            break;
    }
}

void sendHeartbeat() {
    // Send heartbeat to Pi to maintain connection
    String heartbeat = "{\"type\":\"heartbeat\",\"timestamp\":" + String(millis()) + "}";
    piComm.sendMessage(heartbeat);
    
    // Send heartbeat to WebSocket clients
    wsServer.broadcastMessage(heartbeat);
}

void printSystemStatus() {
    debugPrint("📊 System Status:");
    debugPrint("  USB Network: " + String(usbNetwork.isConnected() ? "Connected" : "Disconnected"));
    debugPrint("  WebSocket Clients: " + String(wsServer.getClientCount()));
    debugPrint("  Pi Communication: " + String(piComm.isConnected() ? "Connected" : "Disconnected"));
    debugPrint("  Messages Proxied: " + String(messageProxy.getMessageCount()));
    debugPrint("  Free Heap: " + String(ESP.getFreeHeap()) + " bytes");
    debugPrint("  Uptime: " + String(millis() / 1000) + " seconds");
} 