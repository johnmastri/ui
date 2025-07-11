#include "uart_handler.h"
#include "../utils/debug_utils.h"

UARTHandler::UARTHandler() :
    serial(nullptr),
    serialNumber(-1),
    connected(false),
    maxMessageSize(MAX_MESSAGE_SIZE),
    timeout(PI_COMM_TIMEOUT_MS),
    messageDelimiter(MESSAGE_DELIMITER),
    bytesSent(0),
    bytesReceived(0),
    messagesTransmitted(0),
    messagesReceived(0),
    errorCount(0)
{
}

UARTHandler::~UARTHandler() {
    if (serial && connected) {
        serial->end();
    }
}

bool UARTHandler::begin(int txPin, int rxPin, long baudRate, int uartNum) {
    debugPrintPi("Initializing UART" + String(uartNum) + " - TX:" + String(txPin) + ", RX:" + String(rxPin) + ", Baud:" + String(baudRate));
    
    serialNumber = uartNum;
    
    // Create HardwareSerial instance
    switch (uartNum) {
        case 0:
            serial = &Serial;
            break;
        case 1:
            serial = &Serial1;
            break;
        case 2:
            serial = &Serial2;
            break;
        default:
            DEBUG_ERROR("UARTHandler", "Invalid UART number: " + String(uartNum));
            return false;
    }
    
    // Initialize serial with custom pins
    serial->begin(baudRate, SERIAL_8N1, rxPin, txPin);
    
    // Wait for serial to initialize
    delay(100);
    
    // Clear any existing data
    clear();
    
    connected = true;
    debugPrintPi("UART initialized successfully");
    
    return true;
}

bool UARTHandler::sendMessage(const String& message) {
    if (!connected || !serial) {
        DEBUG_ERROR("UARTHandler", "UART not connected");
        return false;
    }
    
    if (message.length() > maxMessageSize) {
        DEBUG_ERROR("UARTHandler", "Message too large: " + String(message.length()) + " bytes");
        errorCount++;
        return false;
    }
    
    // Send message with delimiter
    size_t bytesWritten = serial->print(message);
    bytesWritten += serial->print(messageDelimiter);
    
    if (bytesWritten > 0) {
        serial->flush(); // Ensure data is transmitted
        bytesSent += bytesWritten;
        messagesTransmitted++;
        debugPrintPi("Sent (" + String(bytesWritten) + " bytes): " + message.substring(0, 50));
        return true;
    } else {
        DEBUG_ERROR("UARTHandler", "Failed to send message");
        errorCount++;
        return false;
    }
}

bool UARTHandler::sendRaw(const uint8_t* data, size_t length) {
    if (!connected || !serial || !data) {
        return false;
    }
    
    size_t bytesWritten = serial->write(data, length);
    serial->flush();
    
    if (bytesWritten == length) {
        bytesSent += bytesWritten;
        return true;
    } else {
        errorCount++;
        return false;
    }
}

bool UARTHandler::hasMessage() const {
    return receiveBuffer.indexOf(messageDelimiter) >= 0;
}

bool UARTHandler::receiveMessage(String& message) {
    if (!hasMessage()) {
        return false;
    }
    
    return extractMessage(message);
}

String UARTHandler::receiveMessage() {
    String message;
    if (receiveMessage(message)) {
        return message;
    }
    return "";
}

void UARTHandler::update() {
    if (!connected || !serial) {
        return;
    }
    
    // Read available data into buffer
    while (serial->available()) {
        char c = serial->read();
        
        if (c >= 0) {
            receiveBuffer += c;
            bytesReceived++;
            
            // Prevent buffer overflow
            if (receiveBuffer.length() > maxMessageSize * 2) {
                DEBUG_WARNING("UARTHandler", "Receive buffer overflow, clearing");
                receiveBuffer = receiveBuffer.substring(receiveBuffer.length() - maxMessageSize);
                errorCount++;
            }
        }
    }
    
    processReceiveBuffer();
}

void UARTHandler::flush() {
    if (serial && connected) {
        serial->flush();
    }
}

void UARTHandler::clear() {
    receiveBuffer = "";
    if (serial && connected) {
        while (serial->available()) {
            serial->read();
        }
    }
}

size_t UARTHandler::getAvailableBytes() const {
    return serial && connected ? serial->available() : 0;
}

void UARTHandler::processReceiveBuffer() {
    // Process complete messages in buffer
    while (hasMessage()) {
        String message;
        if (extractMessage(message)) {
            if (validateMessage(message)) {
                messagesReceived++;
                debugPrintPi("Received (" + String(message.length()) + " bytes): " + message.substring(0, 50));
            } else {
                DEBUG_WARNING("UARTHandler", "Invalid message received");
                errorCount++;
            }
        }
    }
}

bool UARTHandler::extractMessage(String& message) {
    int delimiterIndex = receiveBuffer.indexOf(messageDelimiter);
    
    if (delimiterIndex >= 0) {
        message = receiveBuffer.substring(0, delimiterIndex);
        receiveBuffer = receiveBuffer.substring(delimiterIndex + 1);
        return true;
    }
    
    return false;
}

bool UARTHandler::validateMessage(const String& message) {
    // Basic validation
    if (message.length() == 0 || message.length() > maxMessageSize) {
        return false;
    }
    
    // Check for valid JSON format (basic check)
    if (message.startsWith("{") && message.endsWith("}")) {
        return true;
    }
    
    // Allow non-JSON messages for debugging
    return true;
}

void UARTHandler::handleError(const String& error) {
    DEBUG_ERROR("UARTHandler", error);
    errorCount++;
}

void UARTHandler::resetBuffers() {
    receiveBuffer = "";
    clear();
    debugPrintPi("UART buffers reset");
} 