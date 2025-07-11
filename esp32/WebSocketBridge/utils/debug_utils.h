#ifndef DEBUG_UTILS_H
#define DEBUG_UTILS_H

#include "Arduino.h"
#include "../config.h"

/*
 * Debug Utilities for WebSocket Bridge
 * Provides consistent logging and debugging functionality
 */

// Debug print macros
#if DEBUG_SERIAL
    #define debugPrint(msg) DebugUtils::print(msg)
    #define debugPrintln(msg) DebugUtils::println(msg)
    #define debugPrintf(format, ...) DebugUtils::printf(format, __VA_ARGS__)
#else
    #define debugPrint(msg)
    #define debugPrintln(msg)  
    #define debugPrintf(format, ...)
#endif

// Conditional debug prints
#if DEBUG_WEBSOCKET
    #define debugPrintWS(msg) DebugUtils::printWebSocket(msg)
#else
    #define debugPrintWS(msg)
#endif

#if DEBUG_PI_COMM
    #define debugPrintPi(msg) DebugUtils::printPiComm(msg)
#else
    #define debugPrintPi(msg)
#endif

#if DEBUG_USB_NETWORK
    #define debugPrintUSB(msg) DebugUtils::printUSBNetwork(msg)
#else
    #define debugPrintUSB(msg)
#endif

class DebugUtils {
public:
    // Basic debug functions
    static void print(const String& message);
    static void println(const String& message);
    static void printf(const char* format, ...);
    
    // Component-specific debug functions
    static void printWebSocket(const String& message);
    static void printPiComm(const String& message);
    static void printUSBNetwork(const String& message);
    
    // Utility functions
    static void printMemoryUsage();
    static void printSystemInfo();
    static void printHexDump(const uint8_t* data, size_t length);
    static String getTimestamp();
    static String formatBytes(size_t bytes);
    
    // Error reporting
    static void printError(const String& component, const String& error);
    static void printWarning(const String& component, const String& warning);
    static void printInfo(const String& component, const String& info);
    
private:
    static const char* getLogPrefix(const String& level);
    static void printWithPrefix(const String& prefix, const String& message);
};

// Error handling macros
#define DEBUG_ERROR(component, msg) DebugUtils::printError(component, msg)
#define DEBUG_WARNING(component, msg) DebugUtils::printWarning(component, msg)
#define DEBUG_INFO(component, msg) DebugUtils::printInfo(component, msg)

#endif // DEBUG_UTILS_H 