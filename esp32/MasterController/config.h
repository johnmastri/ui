#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// MIDI Controller ESP32 Configuration
// Hardware: Seeed Studio XIAO ESP32-S3
// ============================================================================

// Pin Assignments (LOCKED)
// ============================================================================

// LED Strip (APA102) - D0/D1
#define LED_DATA_PIN 44    // D0 on XIAO ESP32-S3
#define LED_CLOCK_PIN 43   // D1 on XIAO ESP32-S3

// I2C Encoders - SDA/SCL  
#define I2C_SDA_PIN 6      // SDA on XIAO ESP32-S3
#define I2C_SCL_PIN 7      // SCL on XIAO ESP32-S3

// UART Communication (Pi) - TX/RX (built-in USB-Serial)
#define UART_BAUD 115200

// Hardware Configuration
// ============================================================================

// Encoder Setup
#define NUM_ENCODERS 8
#define I2C_ENCODER_BASE_ADDR 0x20  // Addresses 0x20-0x27

// LED Configuration  
#define LEDS_PER_ENCODER 28
#define TOTAL_LEDS (NUM_ENCODERS * LEDS_PER_ENCODER)
#define LED_BRIGHTNESS 64   // Start conservative (25% brightness)
#define LED_TYPE APA102
#define COLOR_ORDER RGB

// I2C Configuration
#define I2C_FREQUENCY 400000  // 400kHz standard speed
#define I2C_TIMEOUT_MS 100

// Timing Configuration
// ============================================================================

#define MAIN_LOOP_DELAY_MS 1
#define HEARTBEAT_INTERVAL_MS 5000      // 5 seconds
#define STATUS_UPDATE_INTERVAL_MS 10000 // 10 seconds
#define LED_UPDATE_RATE_MS 16           // ~60 FPS
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