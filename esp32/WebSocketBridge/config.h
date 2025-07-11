#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// WebSocket Bridge Configuration
// ESP32 USB-to-GPIO WebSocket Proxy for MIDI Controller
// ============================================================================

// Network Configuration
#define USB_NETWORK_IP          "192.168.4.1"      // ESP32 IP on USB interface
#define USB_NETWORK_SUBNET      "255.255.255.0"    // Subnet mask
#define USB_NETWORK_GATEWAY     "192.168.4.1"      // Gateway (self)
#define WEBSOCKET_PORT          8765                // WebSocket server port
#define MAX_WEBSOCKET_CLIENTS   4                   // Maximum concurrent clients

// Pi Communication Configuration  
#define PI_UART_PORT            2                   // UART2 for Pi communication
#define PI_UART_BAUD            115200              // Baud rate for Pi UART
#define PI_UART_TX_PIN          17                  // GPIO pin for TX to Pi
#define PI_UART_RX_PIN          16                  // GPIO pin for RX from Pi
#define PI_COMM_TIMEOUT_MS      5000                // Pi communication timeout

// Message Configuration
#define MAX_MESSAGE_SIZE        2048                // Maximum JSON message size
#define MESSAGE_QUEUE_SIZE      32                  // Message buffer size
#define MESSAGE_DELIMITER       '\n'               // Message delimiter for UART
#define JSON_BUFFER_SIZE        2048                // JSON parsing buffer

// Status LED Configuration
#define STATUS_LED_PIN          2                   // Built-in LED for status
#define STATUS_BLINK_RATE_MS    500                 // Status LED blink rate

// Timing Configuration
#define MAIN_LOOP_DELAY_MS      10                  // Main loop delay
#define HEARTBEAT_INTERVAL_MS   5000                // Heartbeat/keepalive interval
#define CONNECTION_RETRY_MS     2000                // Connection retry interval
#define USB_POLL_INTERVAL_MS    1                   // USB polling interval

// Debug Configuration
#define DEBUG_SERIAL            true                // Enable debug output
#define DEBUG_BAUD_RATE         115200              // Debug serial baud rate
#define DEBUG_WEBSOCKET         true                // Debug WebSocket messages
#define DEBUG_PI_COMM           true                // Debug Pi communication
#define DEBUG_USB_NETWORK       true                // Debug USB network

// Buffer Sizes
#define UART_BUFFER_SIZE        1024                // UART receive buffer
#define WEBSOCKET_BUFFER_SIZE   2048                // WebSocket message buffer
#define TCP_BUFFER_SIZE         1460                // TCP packet buffer (MTU size)

// Error Handling
#define MAX_RETRY_ATTEMPTS      3                   // Maximum retry attempts
#define ERROR_RECOVERY_DELAY_MS 1000                // Delay before retry
#define WATCHDOG_TIMEOUT_MS     30000               // Watchdog timer timeout

// Hardware Configuration (Future)
#define ENCODER_COUNT           16                  // Number of encoders (future)
#define BUTTON_COUNT            16                  // Number of buttons (future)
#define LED_COUNT               448                 // Total LEDs (16 * 28) (future)

// Pin Assignments (Future Hardware)
// Reserved for future encoder/button/LED implementation
#define I2C_SDA_PIN             21                  // I2C SDA for encoders
#define I2C_SCL_PIN             22                  // I2C SCL for encoders
#define LED_DATA_PIN            5                   // FastLED data pin
#define BUTTON_MATRIX_ROWS      4                   // Button matrix rows
#define BUTTON_MATRIX_COLS      4                   // Button matrix columns

#endif // CONFIG_H 