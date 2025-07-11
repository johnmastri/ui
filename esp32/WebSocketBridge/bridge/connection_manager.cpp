#include "connection_manager.h"
#include "../utils/debug_utils.h"

ConnectionManager::ConnectionManager() :
    usbNetwork(nullptr),
    webSocketServer(nullptr),
    piCommunication(nullptr),
    statusLED(nullptr),
    currentState(STATE_INITIALIZING),
    previousState(STATE_INITIALIZING),
    stateChanged(false),
    stateChangeTime(0),
    startTime(0),
    lastUpdate(0),
    lastConnectionCheck(0),
    connectionAttempts(0),
    recoveryAttempts(0),
    errorCount(0),
    recoveryInProgress(false),
    recoveryStartTime(0),
    recoveryStep(0)
{
}

ConnectionManager::~ConnectionManager() {
    // Cleanup if needed
}

void ConnectionManager::begin(USBNetwork* usbNet, WebSocketServer* wsServer, 
                             GPIOComm* piComm, StatusLED* statusLed) {
    usbNetwork = usbNet;
    webSocketServer = wsServer;
    piCommunication = piComm;
    statusLED = statusLed;
    
    startTime = millis();
    lastUpdate = startTime;
    lastConnectionCheck = startTime;
    
    setState(STATE_INITIALIZING);
    
    debugPrint("Connection manager initialized");
}

void ConnectionManager::update() {
    unsigned long now = millis();
    
    // Throttle updates
    if (now - lastUpdate < 100) { // Update every 100ms
        return;
    }
    
    lastUpdate = now;
    
    // Handle recovery if in progress
    if (recoveryInProgress) {
        performRecovery();
        return;
    }
    
    // Regular state updates
    updateState();
    
    // Periodic connection checking
    if (now - lastConnectionCheck >= 5000) { // Check every 5 seconds
        checkConnections();
        lastConnectionCheck = now;
    }
    
    // Update status LED
    updateStatusLED();
}

void ConnectionManager::updateState() {
    State newState = determineCurrentState();
    
    if (newState != currentState) {
        setState(newState);
    }
}

void ConnectionManager::setState(State newState) {
    if (currentState != newState) {
        logStateChange(currentState, newState);
        
        previousState = currentState;
        currentState = newState;
        stateChanged = true;
        stateChangeTime = millis();
        
        // Handle state-specific actions
        switch (newState) {
            case STATE_ERROR:
                handleConnectionError();
                break;
            case STATE_FULLY_CONNECTED:
                debugPrint("🎉 System fully connected and operational!");
                break;
            default:
                break;
        }
    }
}

ConnectionManager::State ConnectionManager::determineCurrentState() {
    // If recovery is in progress, maintain current state
    if (recoveryInProgress) {
        return currentState;
    }
    
    // Check component status
    bool usbOk = isUSBConnected();
    bool wsOk = isWebSocketConnected();
    bool piOk = isPiConnected();
    
    // Determine state based on connections
    if (!usbOk) {
        return STATE_USB_CONNECTING;
    } else if (usbOk && !wsOk && !piOk) {
        return STATE_USB_CONNECTED;
    } else if (usbOk && wsOk && !piOk) {
        return STATE_WEBSOCKET_CONNECTED;
    } else if (usbOk && piOk && !wsOk) {
        return STATE_PI_CONNECTED;
    } else if (usbOk && wsOk && piOk) {
        return STATE_FULLY_CONNECTED;
    } else {
        return STATE_ERROR;
    }
}

void ConnectionManager::checkConnections() {
    bool usbStatus = isUSBConnected();
    bool wsStatus = isWebSocketConnected();
    bool piStatus = isPiConnected();
    
    debugPrint("🔍 Connection Check - USB:" + String(usbStatus ? "✓" : "✗") + 
               " WS:" + String(wsStatus ? "✓" : "✗") + 
               " Pi:" + String(piStatus ? "✓" : "✗"));
    
    // Trigger recovery if we were fully connected but now have issues
    if (currentState == STATE_FULLY_CONNECTED && (!usbStatus || !wsStatus || !piStatus)) {
        DEBUG_WARNING("ConnectionManager", "Connection loss detected, triggering recovery");
        triggerRecovery();
    }
}

bool ConnectionManager::isUSBConnected() {
    return usbNetwork && usbNetwork->isConnected();
}

bool ConnectionManager::isWebSocketConnected() {
    return webSocketServer && webSocketServer->getClientCount() > 0;
}

bool ConnectionManager::isPiConnected() {
    return piCommunication && piCommunication->isConnected();
}

void ConnectionManager::triggerRecovery() {
    if (recoveryInProgress) {
        DEBUG_WARNING("ConnectionManager", "Recovery already in progress");
        return;
    }
    
    debugPrint("🔧 Starting connection recovery...");
    
    recoveryInProgress = true;
    recoveryStartTime = millis();
    recoveryStep = 0;
    recoveryAttempts++;
    
    setState(STATE_RECOVERING);
}

void ConnectionManager::performRecovery() {
    const unsigned long RECOVERY_STEP_DELAY = 2000; // 2 seconds between steps
    unsigned long now = millis();
    
    if (now - recoveryStartTime < RECOVERY_STEP_DELAY * recoveryStep) {
        return; // Wait for step delay
    }
    
    executeRecoveryStep(recoveryStep);
    recoveryStep++;
    
    // Check if recovery is complete
    if (isRecoveryComplete()) {
        bool success = (currentState == STATE_FULLY_CONNECTED);
        completeRecovery(success);
    }
    
    // Timeout recovery after 30 seconds
    if (now - recoveryStartTime > 30000) {
        DEBUG_ERROR("ConnectionManager", "Recovery timeout");
        completeRecovery(false);
    }
}

void ConnectionManager::executeRecoveryStep(int step) {
    debugPrint("🔧 Recovery step " + String(step));
    
    switch (step) {
        case 0:
            // Reset USB network
            if (usbNetwork) {
                debugPrint("  Reconnecting USB network...");
                usbNetwork->reconnect();
            }
            break;
            
        case 1:
            // Restart WebSocket server
            if (webSocketServer) {
                debugPrint("  Restarting WebSocket server...");
                webSocketServer->stop();
                delay(500);
                webSocketServer->begin(WEBSOCKET_PORT);
            }
            break;
            
        case 2:
            // Reconnect Pi communication
            if (piCommunication) {
                debugPrint("  Reconnecting Pi communication...");
                piCommunication->reconnect();
            }
            break;
            
        case 3:
            // Final verification
            debugPrint("  Verifying connections...");
            checkConnections();
            break;
            
        default:
            // Recovery steps complete
            break;
    }
}

bool ConnectionManager::isRecoveryComplete() {
    return recoveryStep >= 4 || currentState == STATE_FULLY_CONNECTED;
}

void ConnectionManager::completeRecovery(bool success) {
    recoveryInProgress = false;
    
    if (success) {
        debugPrint("✅ Recovery completed successfully");
        setState(STATE_FULLY_CONNECTED);
    } else {
        DEBUG_ERROR("ConnectionManager", "Recovery failed");
        setState(STATE_ERROR);
        errorCount++;
    }
}

void ConnectionManager::resetConnections() {
    debugPrint("🔄 Resetting all connections...");
    
    // Stop all components
    if (webSocketServer) {
        webSocketServer->stop();
    }
    
    if (usbNetwork) {
        usbNetwork->disconnect();
    }
    
    if (piCommunication) {
        piCommunication->disconnect();
    }
    
    delay(1000);
    
    // Restart components
    setState(STATE_INITIALIZING);
    connectionAttempts++;
    
    // This would typically be handled by the main setup() function
    debugPrint("Reset complete - restart required");
}

void ConnectionManager::handleConnectionError() {
    errorCount++;
    
    DEBUG_ERROR("ConnectionManager", "Connection error detected");
    
    // Auto-recovery for minor errors
    if (errorCount % 3 == 0) { // Every 3 errors
        triggerRecovery();
    }
    
    // Major recovery for persistent errors
    if (errorCount >= 10) {
        DEBUG_ERROR("ConnectionManager", "Too many errors, resetting system");
        resetConnections();
        errorCount = 0; // Reset error count after major recovery
    }
}

void ConnectionManager::logStateChange(State oldState, State newState) {
    debugPrint("🔄 State: " + stateToString(oldState) + " → " + stateToString(newState));
}

String ConnectionManager::stateToString(State state) {
    switch (state) {
        case STATE_INITIALIZING: return "INITIALIZING";
        case STATE_USB_CONNECTING: return "USB_CONNECTING";
        case STATE_USB_CONNECTED: return "USB_CONNECTED";
        case STATE_WEBSOCKET_CONNECTED: return "WEBSOCKET_CONNECTED";
        case STATE_PI_CONNECTING: return "PI_CONNECTING";
        case STATE_PI_CONNECTED: return "PI_CONNECTED";
        case STATE_FULLY_CONNECTED: return "FULLY_CONNECTED";
        case STATE_ERROR: return "ERROR";
        case STATE_RECOVERING: return "RECOVERING";
        default: return "UNKNOWN";
    }
}

void ConnectionManager::updateStatusLED() {
    if (!statusLED) {
        return;
    }
    
    // Map connection state to LED pattern
    switch (currentState) {
        case STATE_INITIALIZING:
            statusLED->setPattern(StatusLED::PATTERN_STARTUP);
            break;
        case STATE_USB_CONNECTING:
        case STATE_USB_CONNECTED:
            statusLED->setPattern(StatusLED::PATTERN_USB_CONNECTED);
            break;
        case STATE_WEBSOCKET_CONNECTED:
            statusLED->setPattern(StatusLED::PATTERN_WEBSOCKET_CONNECTED);
            break;
        case STATE_PI_CONNECTING:
        case STATE_PI_CONNECTED:
            statusLED->setPattern(StatusLED::PATTERN_PI_CONNECTED);
            break;
        case STATE_FULLY_CONNECTED:
            statusLED->setPattern(StatusLED::PATTERN_FULLY_CONNECTED);
            break;
        case STATE_ERROR:
            statusLED->setPattern(StatusLED::PATTERN_ERROR);
            break;
        case STATE_RECOVERING:
            statusLED->setPattern(StatusLED::PATTERN_WARNING);
            break;
        default:
            statusLED->setPattern(StatusLED::PATTERN_READY);
            break;
    }
} 