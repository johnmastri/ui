#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// MIDI Controller ESP32 Configuration
// Hardware: Seeed Studio XIAO ESP32-S3
// ============================================================================

// Pin Assignments (LOCKED)
// ============================================================================

// LED Strip (APA102) - D0/D1
#define LED_DATA_PIN D0        // D0 on XIAO ESP32-S3  
#define LED_CLOCK_PIN D1       // D1 on XIAO ESP32-S3

// I2C Encoders - SDA/SCL  
#define I2C_SDA_PIN 6      // SDA on XIAO ESP32-S3
#define I2C_SCL_PIN 7      // SCL on XIAO ESP32-S3

// UART Communication (Pi) - TX/RX (built-in USB-Serial)
#define UART_BAUD 115200

// Hardware Configuration
// ============================================================================

// Encoder Setup
#define NUM_ENCODERS 1
#define I2C_ENCODER_BASE_ADDR 0x20  // Addresses 0x20-0x27

// LED Configuration  
#define LEDS_PER_ENCODER 72    // 144 LEDs/meter × 0.5 meters = 72 LEDs
#define TOTAL_LEDS (NUM_ENCODERS * LEDS_PER_ENCODER)  // 72 LEDs total
#define LED_BRIGHTNESS 12      // LOWER brightness for better 3.3V compatibility
#define LED_TYPE APA102        // DotStar uses APA102
#define COLOR_ORDER RGB        // Test RGB first

// Debugging Options
#define ENABLE_LED_DIAGNOSTICS true
#define SAFE_MODE true         // Slower timing, more conservative power
#define LED_UPDATE_RATE_MS 50  // SLOWER updates for 3.3V compatibility (20 FPS)

// I2C Configuration
#define I2C_FREQUENCY 400000  // 400kHz standard speed
#define I2C_TIMEOUT_MS 100

// Timing Configuration
// ============================================================================

#define MAIN_LOOP_DELAY_MS 1
#define HEARTBEAT_INTERVAL_MS 5000      // 5 seconds
#define STATUS_UPDATE_INTERVAL_MS 10000 // 10 seconds
#define I2C_SCAN_INTERVAL_MS 50         // 20Hz encoder scanning

// Communication Protocol
// ============================================================================

#define UART_BUFFER_SIZE 1024
#define JSON_BUFFER_SIZE 1024
#define MAX_MESSAGE_LENGTH 512

// System Configuration
// ============================================================================

#define FIRMWARE_VERSION "1.0.0"
#define DEVICE_ID "esp32_master"
#define DEBUG_SERIAL true

// LED Patterns
// ============================================================================
enum LEDPattern {
  PATTERN_OFF,
  PATTERN_SOLID,
  PATTERN_RING_FILL,
  PATTERN_PULSE,
  PATTERN_RAINBOW,
  PATTERN_ERROR
};

// Message Types
// ============================================================================
#define MSG_TYPE_STARTUP "startup"
#define MSG_TYPE_HEARTBEAT "heartbeat" 
#define MSG_TYPE_STATUS "status"
#define MSG_TYPE_ENCODER "encoder"
#define MSG_TYPE_LED_UPDATE "led_update"
#define MSG_TYPE_ERROR "error"
#define MSG_TYPE_I2C_SCAN "i2c_scan"

#endif // CONFIG_H 