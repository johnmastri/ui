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
  
  // Update test pattern every 2 seconds
  if (currentTime - lastTestUpdate > 2000) {
    
    // Cycle through different test patterns
    static int testPattern = 0;
    
    switch (testPattern) {
      case 0:
        // Ring fill test
        Serial.println("[TEST] Testing ring fill pattern");
        for (int i = 0; i < NUM_ENCODERS; i++) {
          float value = (float)(i + 1) / NUM_ENCODERS;
          ledController.updateEncoderRing(i, 0, 255, 128, PATTERN_RING_FILL, value);
        }
        break;
        
      case 1:
        // Pulse test
        Serial.println("[TEST] Testing pulse pattern");
        for (int i = 0; i < NUM_ENCODERS; i++) {
          ledController.updateEncoderRing(i, 255, 100, 0, PATTERN_PULSE, 1.0);
        }
        break;
        
      case 2:
        // Rainbow test
        Serial.println("[TEST] Testing rainbow pattern");
        for (int i = 0; i < NUM_ENCODERS; i++) {
          ledController.updateEncoderRing(i, 255, 255, 255, PATTERN_RAINBOW, 1.0);
        }
        break;
        
      case 3:
        // Individual encoder test
        Serial.println("[TEST] Testing individual encoders");
        ledController.clearAll();
        ledController.updateEncoderRing(testEncoderIndex, 255, 0, 255, PATTERN_SOLID, 1.0);
        testEncoderIndex = (testEncoderIndex + 1) % NUM_ENCODERS;
        break;
        
      default:
        // Reset test cycle
        testPattern = -1;
        ledController.clearAll();
        break;
    }
    
    testPattern = (testPattern + 1) % 5;
    lastTestUpdate = currentTime;
    
    // Send test encoder message via UART
    uart.sendEncoderUpdate(testEncoderIndex, testValue, testDirection ? 1 : -1);
    testValue += 0.1;
    if (testValue > 1.0) {
      testValue = 0.0;
      testDirection = !testDirection;
    }
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