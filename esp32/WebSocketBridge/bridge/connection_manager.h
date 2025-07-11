#ifndef CONNECTION_MANAGER_H
#define CONNECTION_MANAGER_H

#include "Arduino.h"
#include "../config.h"
#include "../network/usb_network.h"
#include "../websocket/ws_server.h"
#include "../communication/gpio_comm.h"
#include "../utils/status_led.h"

/*
 * Connection Manager for WebSocket Bridge
 * Coordinates all system connections and manages overall state
 */

class ConnectionManager {
public:
    enum State {
        STATE_INITIALIZING,
        STATE_USB_CONNECTING,
        STATE_USB_CONNECTED,
        STATE_WEBSOCKET_CONNECTED,
        STATE_PI_CONNECTING,
        STATE_PI_CONNECTED,
        STATE_FULLY_CONNECTED,
        STATE_ERROR,
        STATE_RECOVERING
    };
    
    ConnectionManager();
    ~ConnectionManager();
    
    // Initialize with all system components
    void begin(USBNetwork* usbNet, WebSocketServer* wsServer, 
               GPIOComm* piComm, StatusLED* statusLed);
    
    // Main update loop
    void update();
    
    // State management
    State getCurrentState() const { return currentState; }
    bool hasStateChanged() const { return stateChanged; }
    void acknowledgeStateChange() { stateChanged = false; }
    
    // Connection status
    bool isFullyConnected() const { return currentState == STATE_FULLY_CONNECTED; }
    bool hasError() const { return currentState == STATE_ERROR; }
    
    // Recovery operations
    void triggerRecovery();
    void resetConnections();
    
    // Statistics
    unsigned long getUptime() const { return millis() - startTime; }
    unsigned long getConnectionAttempts() const { return connectionAttempts; }
    unsigned long getRecoveryAttempts() const { return recoveryAttempts; }
    
private:
    // Component references
    USBNetwork* usbNetwork;
    WebSocketServer* webSocketServer;
    GPIOComm* piCommunication;
    StatusLED* statusLED;
    
    // State management
    State currentState;
    State previousState;
    bool stateChanged;
    unsigned long stateChangeTime;
    
    // Timing
    unsigned long startTime;
    unsigned long lastUpdate;
    unsigned long lastConnectionCheck;
    
    // Statistics
    unsigned long connectionAttempts;
    unsigned long recoveryAttempts;
    unsigned long errorCount;
    
    // Recovery
    bool recoveryInProgress;
    unsigned long recoveryStartTime;
    int recoveryStep;
    
    // State update methods
    void updateState();
    void setState(State newState);
    State determineCurrentState();
    
    // Connection checking
    void checkConnections();
    bool isUSBConnected();
    bool isWebSocketConnected();
    bool isPiConnected();
    
    // Recovery methods
    void performRecovery();
    void executeRecoveryStep(int step);
    bool isRecoveryComplete();
    void completeRecovery(bool success);
    
    // Error handling
    void handleConnectionError();
    void logStateChange(State oldState, State newState);
    
    // Helper methods
    String stateToString(State state);
    void updateStatusLED();
};

#endif // CONNECTION_MANAGER_H 