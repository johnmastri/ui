#include "usb_network.h"
#include "../utils/debug_utils.h"

/*
 * USB Network Implementation
 * Note: This uses WiFi AP mode to simulate USB network device behavior
 * For true USB CDC-ECM, additional TinyUSB configuration would be needed
 */

USBNetwork::USBNetwork() :
    status(STATUS_DISCONNECTED),
    netif(nullptr),
    interfaceInitialized(false),
    packetsSent(0),
    packetsReceived(0),
    bytesTransferred(0),
    lastStatsUpdate(0),
    connectedCallback(nullptr),
    disconnectedCallback(nullptr),
    errorCallback(nullptr)
{
}

USBNetwork::~USBNetwork() {
    cleanupInterface();
}

bool USBNetwork::begin(const String& ip, const String& subnet, const String& gateway) {
    debugPrintUSB("Initializing USB network interface...");
    
    ipAddress = ip;
    subnetMask = subnet;
    gatewayAddress = gateway;
    
    if (!validateNetworkConfig()) {
        DEBUG_ERROR("USBNetwork", "Invalid network configuration");
        return false;
    }
    
    if (!initializeInterface()) {
        DEBUG_ERROR("USBNetwork", "Failed to initialize network interface");
        return false;
    }
    
    if (!configureNetwork()) {
        DEBUG_ERROR("USBNetwork", "Failed to configure network");
        cleanupInterface();
        return false;
    }
    
    status = STATUS_CONNECTED;
    debugPrintUSB("USB network initialized: " + ipAddress);
    
    if (connectedCallback) {
        connectedCallback();
    }
    
    return true;
}

void USBNetwork::update() {
    updateConnectionStatus();
    updateStatistics();
}

void USBNetwork::disconnect() {
    if (status == STATUS_CONNECTED) {
        debugPrintUSB("Disconnecting USB network...");
        cleanupInterface();
        status = STATUS_DISCONNECTED;
        
        if (disconnectedCallback) {
            disconnectedCallback();
        }
    }
}

void USBNetwork::reconnect() {
    disconnect();
    delay(1000); // Brief delay before reconnecting
    begin(ipAddress, subnetMask, gatewayAddress);
}

void USBNetwork::onConnected(void (*callback)()) {
    connectedCallback = callback;
}

void USBNetwork::onDisconnected(void (*callback)()) {
    disconnectedCallback = callback;
}

void USBNetwork::onError(void (*callback)(const String& error)) {
    errorCallback = callback;
}

bool USBNetwork::initializeInterface() {
    // Initialize WiFi in AP mode to simulate USB network device
    WiFi.mode(WIFI_AP);
    
    // Configure as access point with USB network settings
    const char* ssid = "ESP32_USB_Bridge";
    const char* password = ""; // Open network for simplicity
    
    bool success = WiFi.softAP(ssid, password, 1, 0, 1); // Channel 1, hidden, max 1 client
    
    if (!success) {
        DEBUG_ERROR("USBNetwork", "Failed to create WiFi AP");
        return false;
    }
    
    interfaceInitialized = true;
    debugPrintUSB("WiFi AP created successfully");
    return true;
}

bool USBNetwork::configureNetwork() {
    // Configure the AP with static IP
    IPAddress ip, subnet, gateway;
    
    if (!ip.fromString(ipAddress) || 
        !subnet.fromString(subnetMask) || 
        !gateway.fromString(gatewayAddress)) {
        DEBUG_ERROR("USBNetwork", "Invalid IP address format");
        return false;
    }
    
    bool success = WiFi.softAPConfig(ip, gateway, subnet);
    
    if (!success) {
        DEBUG_ERROR("USBNetwork", "Failed to configure AP network");
        return false;
    }
    
    debugPrintUSB("Network configured - IP: " + ipAddress + ", Subnet: " + subnetMask);
    return true;
}

void USBNetwork::cleanupInterface() {
    if (interfaceInitialized) {
        WiFi.softAPdisconnect(true);
        WiFi.mode(WIFI_OFF);
        interfaceInitialized = false;
        debugPrintUSB("Network interface cleaned up");
    }
}

void USBNetwork::updateStatistics() {
    unsigned long now = millis();
    
    if (now - lastStatsUpdate >= 5000) { // Update every 5 seconds
        // Get WiFi statistics
        wifi_ap_record_t ap_info;
        esp_wifi_sta_get_ap_info(&ap_info);
        
        // Note: Detailed packet statistics would require additional ESP-IDF APIs
        lastStatsUpdate = now;
    }
}

void USBNetwork::updateConnectionStatus() {
    if (!interfaceInitialized) {
        if (status != STATUS_DISCONNECTED) {
            status = STATUS_DISCONNECTED;
            if (disconnectedCallback) {
                disconnectedCallback();
            }
        }
        return;
    }
    
    // Check if AP is running and accessible
    bool connected = WiFi.softAPgetStationNum() >= 0; // AP is active
    
    Status newStatus = connected ? STATUS_CONNECTED : STATUS_DISCONNECTED;
    
    if (newStatus != status) {
        status = newStatus;
        
        if (status == STATUS_CONNECTED && connectedCallback) {
            connectedCallback();
        } else if (status == STATUS_DISCONNECTED && disconnectedCallback) {
            disconnectedCallback();
        }
    }
}

bool USBNetwork::validateNetworkConfig() {
    // Validate IP address format
    IPAddress testIP;
    if (!testIP.fromString(ipAddress)) {
        DEBUG_ERROR("USBNetwork", "Invalid IP address: " + ipAddress);
        return false;
    }
    
    if (!testIP.fromString(subnetMask)) {
        DEBUG_ERROR("USBNetwork", "Invalid subnet mask: " + subnetMask);
        return false;
    }
    
    if (!testIP.fromString(gatewayAddress)) {
        DEBUG_ERROR("USBNetwork", "Invalid gateway address: " + gatewayAddress);
        return false;
    }
    
    debugPrintUSB("Network configuration validated");
    return true;
}

void USBNetwork::networkEventHandler(void* arg, esp_event_base_t event_base, 
                                    int32_t event_id, void* event_data) {
    USBNetwork* network = static_cast<USBNetwork*>(arg);
    
    if (event_base == WIFI_EVENT) {
        switch (event_id) {
            case WIFI_EVENT_AP_START:
                debugPrintUSB("WiFi AP started");
                break;
            case WIFI_EVENT_AP_STOP:
                debugPrintUSB("WiFi AP stopped");
                break;
            case WIFI_EVENT_AP_STACONNECTED:
                debugPrintUSB("Client connected to AP");
                break;
            case WIFI_EVENT_AP_STADISCONNECTED:
                debugPrintUSB("Client disconnected from AP");
                break;
            default:
                break;
        }
    }
} 