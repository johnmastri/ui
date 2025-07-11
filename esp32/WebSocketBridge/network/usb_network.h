#ifndef USB_NETWORK_H
#define USB_NETWORK_H

#include "Arduino.h"
#include "../config.h"
#include "WiFi.h"
#include "esp_netif.h"
#include "esp_event.h"

/*
 * USB Network Interface
 * Makes ESP32 appear as USB network device to PC
 */

class USBNetwork {
public:
    enum Status {
        STATUS_DISCONNECTED,
        STATUS_CONNECTING,
        STATUS_CONNECTED,
        STATUS_ERROR
    };
    
    USBNetwork();
    ~USBNetwork();
    
    // Initialize USB network interface
    bool begin(const String& ip, const String& subnet, const String& gateway);
    
    // Connection status
    bool isConnected() const { return status == STATUS_CONNECTED; }
    Status getStatus() const { return status; }
    String getIP() const { return ipAddress; }
    String getSubnet() const { return subnetMask; }
    String getGateway() const { return gatewayAddress; }
    
    // Network operations
    void update();
    void disconnect();
    void reconnect();
    
    // Statistics
    unsigned long getPacketsSent() const { return packetsSent; }
    unsigned long getPacketsReceived() const { return packetsReceived; }
    unsigned long getBytesTransferred() const { return bytesTransferred; }
    
    // Event callbacks
    void onConnected(void (*callback)());
    void onDisconnected(void (*callback)());
    void onError(void (*callback)(const String& error));
    
private:
    Status status;
    String ipAddress;
    String subnetMask;
    String gatewayAddress;
    
    // Network interface
    esp_netif_t* netif;
    bool interfaceInitialized;
    
    // Statistics
    unsigned long packetsSent;
    unsigned long packetsReceived;
    unsigned long bytesTransferred;
    unsigned long lastStatsUpdate;
    
    // Callbacks
    void (*connectedCallback)();
    void (*disconnectedCallback)();
    void (*errorCallback)(const String& error);
    
    // Internal methods
    bool initializeInterface();
    bool configureNetwork();
    void cleanupInterface();
    void updateStatistics();
    void handleNetworkEvent(arduino_event_t* event);
    void updateConnectionStatus();
    
    // Network configuration helpers
    bool setStaticIP(const String& ip, const String& subnet, const String& gateway);
    bool validateNetworkConfig();
    
    // Static event handler
    static void networkEventHandler(void* arg, esp_event_base_t event_base, 
                                   int32_t event_id, void* event_data);
};

#endif // USB_NETWORK_H 