#include "debug_utils.h"
#include <stdarg.h>

/*
 * Debug Utilities Implementation
 */

void DebugUtils::print(const String& message) {
    if (DEBUG_SERIAL) {
        Serial.print(getTimestamp() + " " + message);
    }
}

void DebugUtils::println(const String& message) {
    if (DEBUG_SERIAL) {
        Serial.println(getTimestamp() + " " + message);
    }
}

void DebugUtils::printf(const char* format, ...) {
    if (DEBUG_SERIAL) {
        char buffer[256];
        va_list args;
        va_start(args, format);
        vsnprintf(buffer, sizeof(buffer), format, args);
        va_end(args);
        Serial.print(getTimestamp() + " " + String(buffer));
    }
}

void DebugUtils::printWebSocket(const String& message) {
    if (DEBUG_WEBSOCKET) {
        printWithPrefix("WS", message);
    }
}

void DebugUtils::printPiComm(const String& message) {
    if (DEBUG_PI_COMM) {
        printWithPrefix("PI", message);
    }
}

void DebugUtils::printUSBNetwork(const String& message) {
    if (DEBUG_USB_NETWORK) {
        printWithPrefix("USB", message);
    }
}

void DebugUtils::printMemoryUsage() {
    if (DEBUG_SERIAL) {
        size_t freeHeap = ESP.getFreeHeap();
        size_t totalHeap = ESP.getHeapSize();
        size_t usedHeap = totalHeap - freeHeap;
        
        Serial.println(getTimestamp() + " 💾 Memory Usage:");
        Serial.println("  Free: " + formatBytes(freeHeap));
        Serial.println("  Used: " + formatBytes(usedHeap));
        Serial.println("  Total: " + formatBytes(totalHeap));
        Serial.println("  Usage: " + String((usedHeap * 100) / totalHeap) + "%");
    }
}

void DebugUtils::printSystemInfo() {
    if (DEBUG_SERIAL) {
        Serial.println(getTimestamp() + " 🔧 System Info:");
        Serial.println("  Chip Model: " + String(ESP.getChipModel()));
        Serial.println("  Chip Revision: " + String(ESP.getChipRevision()));
        Serial.println("  CPU Frequency: " + String(ESP.getCpuFreqMHz()) + " MHz");
        Serial.println("  Flash Size: " + formatBytes(ESP.getFlashChipSize()));
        Serial.println("  SDK Version: " + String(ESP.getSdkVersion()));
    }
}

void DebugUtils::printHexDump(const uint8_t* data, size_t length) {
    if (DEBUG_SERIAL && data && length > 0) {
        Serial.println(getTimestamp() + " 🔍 Hex Dump (" + String(length) + " bytes):");
        
        for (size_t i = 0; i < length; i += 16) {
            // Print address
            Serial.printf("  %04X: ", i);
            
            // Print hex values
            for (size_t j = 0; j < 16; j++) {
                if (i + j < length) {
                    Serial.printf("%02X ", data[i + j]);
                } else {
                    Serial.print("   ");
                }
            }
            
            // Print ASCII representation
            Serial.print(" |");
            for (size_t j = 0; j < 16 && i + j < length; j++) {
                uint8_t c = data[i + j];
                Serial.print((c >= 32 && c <= 126) ? (char)c : '.');
            }
            Serial.println("|");
        }
    }
}

String DebugUtils::getTimestamp() {
    unsigned long ms = millis();
    unsigned long seconds = ms / 1000;
    unsigned long minutes = seconds / 60;
    unsigned long hours = minutes / 60;
    
    ms %= 1000;
    seconds %= 60;
    minutes %= 60;
    hours %= 24;
    
    char timestamp[16];
    snprintf(timestamp, sizeof(timestamp), "[%02lu:%02lu:%02lu.%03lu]", 
             hours, minutes, seconds, ms);
    
    return String(timestamp);
}

String DebugUtils::formatBytes(size_t bytes) {
    if (bytes < 1024) {
        return String(bytes) + " B";
    } else if (bytes < 1024 * 1024) {
        return String(bytes / 1024.0, 1) + " KB";
    } else {
        return String(bytes / (1024.0 * 1024.0), 1) + " MB";
    }
}

void DebugUtils::printError(const String& component, const String& error) {
    printWithPrefix("ERROR", "[" + component + "] " + error);
}

void DebugUtils::printWarning(const String& component, const String& warning) {
    printWithPrefix("WARN", "[" + component + "] " + warning);
}

void DebugUtils::printInfo(const String& component, const String& info) {
    printWithPrefix("INFO", "[" + component + "] " + info);
}

const char* DebugUtils::getLogPrefix(const String& level) {
    if (level == "ERROR") return "❌";
    if (level == "WARN") return "⚠️";
    if (level == "INFO") return "ℹ️";
    if (level == "WS") return "📡";
    if (level == "PI") return "🔗";
    if (level == "USB") return "🔌";
    return "📝";
}

void DebugUtils::printWithPrefix(const String& prefix, const String& message) {
    if (DEBUG_SERIAL) {
        Serial.println(getTimestamp() + " " + getLogPrefix(prefix) + " " + message);
    }
} 