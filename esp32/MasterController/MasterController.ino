/*
 * MIDI Master Controller - ESP32 Firmware
 * Hardware: Seeed Studio XIAO ESP32-S3
 * 
 * Phase 1: Basic UART communication and LED control
 * Phase 2: I2C encoder integration
 * 
 * Pin Assignment:
 * D0 (GPIO44) - LED Data (APA102)
 * D1 (GPIO43) - LED Clock (APA102)  
 * SDA (GPIO6) - I2C Data (Encoders)
 * SCL (GPIO7) - I2C Clock (Encoders)
 * TX/RX       - UART (Pi Communication)
 */

#include "config.h"
#include "uart_comm.h"
#include "led_controller.h"
#include "i2c_encoder.h"

// ============================================================================
// Global Variables
// ============================================================================

// System state
unsigned long systemStartTime;
bool systemReady = false;

// Test mode variables (for Phase 1 development)
bool testMode = true;
unsigned long lastTestUpdate = 0;
int testEncoderIndex = 0;
float testValue = 0.0;
bool testDirection = true;

// ============================================================================
// Setup Function
// ============================================================================

void setup() {
  systemStartTime = millis();
  
  Serial.begin(UART_BAUD);
  delay(100); // Allow serial to stabilize
  
  Serial.println("=====================================");
  Serial.println("MIDI Master Controller - ESP32");
  Serial.println("Hardware: XIAO ESP32-S3");
  Serial.println("Firmware: v" FIRMWARE_VERSION);
  Serial.println("=====================================");
  
  // Initialize all modules
  Serial.println("[MAIN] Initializing system modules...");
  
  // 1. Initialize UART communication first
  uart.begin();
  Serial.println("[MAIN] UART communication initialized");
  
  // 2. Initialize LED controller
  ledController.begin();
  Serial.println("[MAIN] LED controller initialized");
  
  // 3. Initialize I2C encoder manager
  i2cEncoders.begin();
  Serial.println("[MAIN] I2C encoder manager initialized");
  
  // System ready
  systemReady = true;
  Serial.println("[MAIN] System initialization complete!");
  Serial.printf("[MAIN] Free memory: %d bytes\n", ESP.getFreeHeap());
  
  // Show test pattern if in test mode
  if (testMode) {
    Serial.println("[MAIN] Entering test mode - LED patterns will cycle automatically");
    ledController.showTestPattern();
  }
}

// ============================================================================
// Main Loop
// ============================================================================

void loop() {
  if (!systemReady) return;
  
  // Simple heartbeat for debugging
  static unsigned long lastHeartbeat = 0;
  if (millis() - lastHeartbeat > 1000) {
    Serial.println("HEARTBEAT - ESP32 is running");
    lastHeartbeat = millis();
  }
  
  // Update all modules
  uart.update();           // Process UART messages
  ledController.update();  // Update LED animations
  i2cEncoders.update();    // Read I2C encoders
  
  // Run test mode if enabled (Phase 1 development)
  if (testMode) {
    runTestMode();
  }
  
  // Small delay to prevent overwhelming the system
  delay(MAIN_LOOP_DELAY_MS);
}

// ============================================================================
// Test Mode for Phase 1 Development
// ============================================================================

void runTestMode() {
  unsigned long currentTime = millis();
  
  // Test patterns every 3 seconds
  if (currentTime - lastTestUpdate > 3000) {
    static int testStep = 0;
    
    Serial.printf("[LED CONTROLLER TEST] Step %d - Time: %lu\n", testStep, currentTime);
    
    switch(testStep) {
      case 0:
        Serial.println("All LEDs OFF");
        ledController.clearAll();
        break;
        
      case 1:
        Serial.println("All LEDs RED SOLID");
        ledController.updateEncoderRing(0, 255, 0, 0, PATTERN_SOLID, 1.0);
        break;
        
      case 2:
        Serial.println("All LEDs GREEN SOLID");
        ledController.updateEncoderRing(0, 0, 255, 0, PATTERN_SOLID, 1.0);
        break;
        
      case 3:
        Serial.println("All LEDs BLUE SOLID");
        ledController.updateEncoderRing(0, 0, 0, 255, PATTERN_SOLID, 1.0);
        break;
        
      case 4:
        Serial.println("Ring Fill Pattern");
        ledController.updateEncoderRing(0, 255, 128, 0, PATTERN_RING_FILL, 0.7);
        break;
        
      case 5:
        Serial.println("Pulse Pattern");
        ledController.updateEncoderRing(0, 128, 0, 255, PATTERN_PULSE, 1.0);
        break;
        
      case 6:
        Serial.println("Rainbow Pattern");
        ledController.updateEncoderRing(0, 255, 255, 255, PATTERN_RAINBOW, 1.0);
        break;
    }
    
    delay(100);
    Serial.printf("Pattern set! Free memory: %d bytes\n", ESP.getFreeHeap());
    
    testStep = (testStep + 1) % 7;
    lastTestUpdate = currentTime;
  }
}

// ============================================================================
// Callback Functions (Called by modules)
// ============================================================================

// Called when LED update message received from Pi
void onLEDUpdateReceived(int encoderId, uint8_t r, uint8_t g, uint8_t b, LEDPattern pattern, float value) {
  Serial.printf("[CALLBACK] LED update: encoder=%d, RGB(%d,%d,%d), pattern=%d, value=%.2f\n", 
                encoderId, r, g, b, pattern, value);
  
  // Update the LED controller
  ledController.updateEncoderRing(encoderId, r, g, b, pattern, value);
}

// Called when system command received from Pi
void onSystemCommandReceived(const String& command, const String& parameter) {
  Serial.printf("[CALLBACK] System command: %s = %s\n", command.c_str(), parameter.c_str());
  
  if (command == "test_mode") {
    testMode = (parameter == "true");
    Serial.printf("[MAIN] Test mode %s\n", testMode ? "ENABLED" : "DISABLED");
    
    if (!testMode) {
      ledController.clearAll();
    }
  }
  else if (command == "brightness") {
    int brightness = parameter.toInt();
    if (brightness >= 0 && brightness <= 255) {
      ledController.setBrightness(brightness);
    }
  }
  else if (command == "test_pattern") {
    ledController.showTestPattern();
  }
  else if (command == "clear_leds") {
    ledController.clearAll();
  }
  else if (command == "scan_i2c") {
    i2cEncoders.scanForEncoders();
  }
  else if (command == "run_diagnostics") {
    Serial.println("[MAIN] Running LED diagnostics...");
    ledController.runFullDiagnostics();
  }
  else if (command == "sequential_test") {
    int delayMs = parameter.toInt();
    if (delayMs <= 0) delayMs = 200;
    ledController.sequentialTest(delayMs);
  }
  else if (command == "find_led_count") {
    ledController.findLEDCount();
  }
  else if (command == "test_range") {
    // Format: "start,end,r,g,b" e.g. "0,10,255,0,0"
    int commaIndex1 = parameter.indexOf(',');
    int commaIndex2 = parameter.indexOf(',', commaIndex1 + 1);
    int commaIndex3 = parameter.indexOf(',', commaIndex2 + 1);
    int commaIndex4 = parameter.indexOf(',', commaIndex3 + 1);
    
    if (commaIndex1 > 0 && commaIndex2 > 0 && commaIndex3 > 0 && commaIndex4 > 0) {
      int start = parameter.substring(0, commaIndex1).toInt();
      int end = parameter.substring(commaIndex1 + 1, commaIndex2).toInt();
      int r = parameter.substring(commaIndex2 + 1, commaIndex3).toInt();
      int g = parameter.substring(commaIndex3 + 1, commaIndex4).toInt();
      int b = parameter.substring(commaIndex4 + 1).toInt();
      
      ledController.testLEDRange(start, end, CRGB(r, g, b));
    } else {
      uart.sendError("test_range format: start,end,r,g,b");
    }
  }
  else if (command == "test_signal_integrity") {
    Serial.println("[MAIN] Running signal integrity test...");
    ledController.testSignalIntegrity();
  }
  else {
    uart.sendError("Unknown system command: " + command);
  }
}

// Called when I2C encoder changes (Phase 2)
void onEncoderChanged(int encoderId, float value, int direction) {
  Serial.printf("[CALLBACK] Encoder %d changed: value=%.3f, direction=%d\n", 
                encoderId, value, direction);
  
  // Send encoder update via UART
  uart.sendEncoderUpdate(encoderId, value, direction);
  
  // Update local LED ring for immediate feedback
  CRGB currentColor = ledController.getEncoderColor(encoderId);
  ledController.updateEncoderRing(encoderId, currentColor.r, currentColor.g, currentColor.b, 
                                 PATTERN_RING_FILL, value);
} 