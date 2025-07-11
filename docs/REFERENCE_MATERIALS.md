# Reference Materials - VST Master Controller

This document contains all reference materials, links, and integration details needed for implementation.

## **Original JUCE WebView Tutorial**

### **GitHub Repository**
- **URL**: https://github.com/JanWilczek/juce-webview-tutorial
- **Purpose**: Foundation for WebView integration pattern
- **Key Files**:
  - `plugin/source/PluginProcessor.cpp` - Basic audio processor
  - `plugin/source/PluginEditor.cpp` - WebView component integration
  - `plugin/CMakeLists.txt` - Build configuration
  - `plugin/ui/public/index.html` - Basic web interface

### **Key Concepts from Original Tutorial**
1. **WebView Integration**: Using JUCE's WebBrowserComponent
2. **JavaScript Bridge**: Native function binding for C++ ↔ JS communication
3. **Resource Provider**: Serving embedded web assets
4. **Parameter Binding**: Connecting web UI to audio parameters

### **Original Tutorial Analysis**

#### **PluginProcessor Pattern**
```cpp
// Basic audio processor with parameters
class PluginProcessor : public juce::AudioProcessor
{
    // Standard JUCE AudioProcessor implementation
    // Parameters: GAIN, BYPASS, DISTORTION_TYPE
    // Simple audio effects processing
};
```

#### **PluginEditor Pattern**
```cpp
// WebView container with JavaScript bridge
class PluginEditor : public juce::AudioProcessorEditor
{
    std::unique_ptr<juce::WebBrowserComponent> webView;
    // JavaScript bridge setup
    // Resource provider for embedded assets
    // Parameter synchronization
};
```

#### **JavaScript Bridge Pattern**
```javascript
// Original tutorial JavaScript interface
window.juce = {
    // Native function calls
    backend: {
        emitEvent: function(eventName, data) { },
        getNativeFunction: function(name) { }
    },
    // Parameter access
    getSliderState: function(paramId) { },
    getToggleState: function(paramId) { }
};
```

## **Vue.js Integration Analysis**

### **Current Vue.js Application Structure**
```
src/
├── App.vue                 # Main application component
├── main.js                 # Application entry point
├── components/             # UI components
│   ├── Header.vue         # Plugin header with info
│   ├── ParameterKnob.vue  # Rotary parameter controls
│   ├── MockDisplay.vue    # Large parameter display
│   └── SettingsPanel.vue  # User settings
├── composables/           # Vue.js composables
│   ├── useJuceIntegration.js  # JUCE bridge integration
│   └── useWebSocket.js        # WebSocket communication
├── stores/                # State management
│   ├── parameterStore.js  # Parameter state
│   ├── hardwareStore.js   # Hardware integration
│   └── websocketStore.js  # WebSocket state
└── views/                 # Main views
    ├── MainView.vue       # Primary interface
    └── VirtualHardwareView.vue  # Hardware simulation
```

### **Vue.js JUCE Integration Points**

#### **Current useJuceIntegration.js**
```javascript
export function useJuceIntegration(state = null) {
    // Expects these JUCE methods:
    // - Juce.getSliderState("GAIN")
    // - Juce.getToggleState("BYPASS")
    // - Juce.getComboBoxState("DISTORTION_TYPE")
    // - Juce.getNativeFunction("nativeFunction")
    
    // Handles parameter binding and change events
    // Provides development mode fallbacks
    // Integrates with Vue.js reactive system
}
```

#### **Required JavaScript Bridge Methods**
```javascript
// Methods Vue.js expects from JUCE
window.juce = {
    // Plugin management
    loadVSTPlugin: function(path) { },
    unloadVSTPlugin: function() { },
    getPluginState: function() { },
    
    // Parameter control
    setParameter: function(index, value) { },
    getParameter: function(index) { },
    getParameterList: function() { },
    
    // File operations
    showFileDialog: function() { },
    
    // Status queries
    isPluginLoaded: function() { },
    getPluginName: function() { }
};

// Methods JUCE calls on Vue.js
window.onParameterChanged = function(index, value) { };
window.onPluginStateChanged = function(isLoaded, name, params) { };
window.onStatusUpdate = function(status) { };
```

## **WebSocket Integration**

### **Current WebSocket Implementation**
The Vue.js application already has complete WebSocket integration:

#### **WebSocket Store** (`websocketStore.js`)
```javascript
// Handles connection to hardware/external systems
// Manages connection state and reconnection
// Provides message sending/receiving interface
```

#### **Hardware Store** (`hardwareStore.js`)
```javascript
// Manages hardware controller state
// Provides parameter change detection
// Handles display timing and animations
```

### **WebSocket Message Protocol**
```json
// Parameter update message
{
    "type": "parameter_update",
    "plugin_id": "loaded_vst",
    "parameter_index": 0,
    "value": 0.75,
    "timestamp": 1234567890
}

// Hardware control message
{
    "type": "hardware_control",
    "device_id": "esp32_master",
    "control_type": "encoder",
    "control_id": 0,
    "value": 0.5
}
```

## **Build System Integration**

### **Vue.js Build Configuration**
```javascript
// vite.config.js
export default defineConfig({
    plugins: [vue()],
    server: {
        port: 3000,
        host: '0.0.0.0',
        cors: true
    },
    build: {
        outDir: 'dist',
        rollupOptions: {
            output: {
                entryFileNames: 'js/[name].js',
                chunkFileNames: 'js/[name].js',
                assetFileNames: 'assets/[name][extname]'
            }
        }
    }
});
```

### **CMake Integration Pattern**
```cmake
# From original tutorial - adapted for Vue.js
# Copy Vue.js build output to plugin assets
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/ui/dist
        ${CMAKE_CURRENT_BINARY_DIR}/ui/dist
)

# Create ZIP file of web assets
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E tar "cf" "webview_files.zip" --format=zip
        ${CMAKE_CURRENT_BINARY_DIR}/ui/dist
)

# Embed as binary data
juce_add_binary_data(WebViewFiles
    SOURCES ${CMAKE_CURRENT_BINARY_DIR}/webview_files.zip
)
```

## **Hardware Integration**

### **ESP32 Firmware**
Located in `/esp32/` directory:
- **MasterController**: Main ESP32 firmware
- **WebSocketBridge**: WebSocket communication bridge
- **Communication Protocol**: JSON messages over UART/WebSocket

### **Python Scripts**
Located in `/python_scripts/` directory:
- **Kivy GUI**: Native Python interface (mirrors Vue.js)
- **WebSocket Server**: Mock server for testing
- **Bridge Scripts**: Hardware communication utilities

## **JUCE Framework Reference**

### **Required JUCE Modules**
```cmake
juce::juce_audio_basics      # Audio processing
juce::juce_audio_devices     # Audio device management
juce::juce_audio_formats     # Audio file formats
juce::juce_audio_processors  # Plugin framework
juce::juce_audio_utils       # Audio utilities
juce::juce_core              # Core functionality
juce::juce_data_structures   # Data structures
juce::juce_events            # Event handling
juce::juce_graphics          # Graphics rendering
juce::juce_gui_basics        # Basic GUI components
juce::juce_gui_extra         # Extended GUI (WebView)
```

### **WebView Classes**
```cpp
// JUCE WebView components
juce::WebBrowserComponent    # Main WebView container
juce::WebBrowserComponent::Options  # WebView configuration
juce::WebBrowserComponent::ResourceProvider  # Resource serving
```

### **Plugin Hosting Classes**
```cpp
// JUCE plugin hosting
juce::AudioPluginFormatManager  # Plugin format management
juce::KnownPluginList           # Plugin discovery
juce::AudioPluginInstance       # Plugin instance wrapper
juce::AudioProcessorEditor      # Plugin editor management
```

## **Development Tools**

### **Debug Console Access**
```javascript
// Enable WebView developer console
// For debugging JavaScript bridge communication
if (window.juce) {
    window.juce.backend.emitEvent("debug", {
        message: "JavaScript bridge active",
        timestamp: Date.now()
    });
}
```

### **Development Mode Detection**
```javascript
// Vue.js development mode detection
const isDevelopment = import.meta.env.DEV || !window.juce;

// JUCE development mode detection
const isJuceDevelopment = !window.__JUCE__ || window.location.hostname === 'localhost';
```

### **Testing Utilities**
```javascript
// Mock JUCE interface for browser testing
if (!window.juce) {
    window.juce = {
        loadVSTPlugin: (path) => {
            console.log('Mock: Loading plugin', path);
            return true;
        },
        setParameter: (index, value) => {
            console.log('Mock: Setting parameter', index, value);
        }
    };
}
```

## **Performance Considerations**

### **WebView Performance**
- **Hardware acceleration**: Enabled by default in JUCE
- **Memory management**: Proper cleanup of JavaScript objects
- **Update frequency**: 60Hz for parameter updates
- **Resource optimization**: Minimized Vue.js build size

### **Audio Thread Safety**
- **Parameter updates**: Atomic operations for thread safety
- **Message passing**: Async dispatch to main thread
- **Buffer management**: Lock-free parameter access
- **Real-time constraints**: No allocations in audio thread

## **Error Handling Patterns**

### **Plugin Loading Errors**
```cpp
// Graceful plugin loading error handling
bool VSTHostManager::loadPlugin(const juce::String& pluginPath)
{
    try {
        // Plugin loading logic
        return true;
    }
    catch (const std::exception& e) {
        // Log error and notify UI
        notifyError("Plugin loading failed: " + juce::String(e.what()));
        return false;
    }
}
```

### **JavaScript Bridge Errors**
```javascript
// Robust JavaScript bridge error handling
window.juce = {
    setParameter: function(index, value) {
        try {
            return nativeSetParameter(index, value);
        } catch (error) {
            console.error('Parameter update failed:', error);
            return false;
        }
    }
};
```

## **Cross-Platform Considerations**

### **Windows (WebView2)**
- **WebView2 Runtime**: Required for WebView functionality
- **Edge WebView2**: Modern Chromium-based WebView
- **Installation**: Automatic via setup script

### **macOS (WebKit)**
- **WebKit**: System WebView framework
- **Security**: App sandbox considerations
- **Permissions**: Network access for WebSocket

### **Linux (WebKit)**
- **WebKitGTK**: GTK-based WebView
- **Dependencies**: System WebKit libraries
- **Package management**: Distribution-specific requirements

## **Security Considerations**

### **WebView Security**
- **Content Security Policy**: Restrict resource loading
- **JavaScript isolation**: Sandboxed execution
- **Resource validation**: Verify embedded assets
- **Input validation**: Sanitize all user inputs

### **Plugin Security**
- **Plugin validation**: Verify plugin integrity
- **Sandboxing**: Isolate plugin execution
- **Permission model**: Minimal required permissions
- **Error boundaries**: Graceful failure handling