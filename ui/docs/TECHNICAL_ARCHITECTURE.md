# Technical Architecture - VST Master Controller

This document provides detailed technical specifications for all components and their relationships.

## **Component Diagram**

```
┌─────────────────────────────────────────────────────────────────┐
│                        VST Plugin Process                       │
│                                                                 │
│  ┌─────────────────────┐    ┌─────────────────────────────────┐ │
│  │  PluginProcessor    │    │         PluginEditor            │ │
│  │                     │    │                                 │ │
│  │  - VST Host Logic   │    │  ┌─────────────────────────────┐ │ │
│  │  - Audio Processing │    │  │      WebViewComponent      │ │ │
│  │  - Parameter Mgmt   │    │  │                             │ │ │
│  │                     │    │  │  ┌─────────────────────────┐ │ │ │
│  │  ┌─────────────────┐│    │  │  │      Vue.js App        │ │ │ │
│  │  │ VSTHostManager  ││    │  │  │                         │ │ │ │
│  │  │                 ││    │  │  │  - Parameter Controls  │ │ │ │
│  │  │ - Plugin Loading││    │  │  │  - WebSocket Client    │ │ │ │
│  │  │ - Audio Chain   ││    │  │  │  - Hardware Interface  │ │ │ │
│  │  │ - Parameter Fwd ││    │  │  └─────────────────────────┘ │ │ │
│  │  └─────────────────┘│    │  │                             │ │ │
│  │                     │    │  │  JavaScript Bridge          │ │ │
│  │  ┌─────────────────┐│    │  │  - Parameter Methods       │ │ │
│  │  │ParameterManager ││◄──►│  │  - File Loading Methods    │ │ │
│  │  │                 ││    │  │  - Status Methods           │ │ │
│  │  │ - Parameter Info││    │  └─────────────────────────────┘ │ │
│  │  │ - Value Mapping ││    │                                 │ │
│  │  │ - Change Events ││    │                                 │ │
│  │  └─────────────────┘│    └─────────────────────────────────┘ │
│  └─────────────────────┘                                        │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌─────────────────────┐
                        │   External Hardware │
                        │   via WebSocket     │
                        └─────────────────────┘
```

## **Class Specifications**

### **VSTHostPluginAudioProcessor**
```cpp
class VSTHostPluginAudioProcessor : public juce::AudioProcessor
{
    // Core JUCE plugin interface
    // - Standard AudioProcessor methods
    // - State management (getStateInformation/setStateInformation)
    // - Audio processing chain
    
    // VST Host functionality
    // - loadVSTPlugin(path) → bool
    // - unloadVSTPlugin() → void
    // - getVSTParameters() → std::vector<ParameterInfo>
    // - setVSTParameter(index, value) → void
    
    // Parameter change notification
    // - ParameterChangeListener interface
    // - addParameterChangeListener(listener) → void
    // - notifyParameterChange(index, value) → void
    
    // Dependencies
    VSTHostManager vstHostManager;
    ParameterManager parameterManager;
    std::vector<ParameterChangeListener*> listeners;
};
```

### **VSTHostPluginAudioProcessorEditor**
```cpp
class VSTHostPluginAudioProcessorEditor : public juce::AudioProcessorEditor,
                                         public juce::Timer
{
    // JUCE Editor interface
    // - paint(Graphics&) → void
    // - resized() → void
    // - Component lifecycle management
    
    // WebView integration
    // - WebViewComponent container
    // - JavaScript interface setup
    // - File loading dialog management
    
    // Periodic updates
    // - timerCallback() → void (parameter synchronization)
    // - Update frequency: 60Hz for UI responsiveness
    
    // Dependencies
    VSTHostPluginAudioProcessor& audioProcessor;
    std::unique_ptr<WebViewComponent> webViewComponent;
};
```

### **WebViewComponent**
```cpp
class WebViewComponent : public juce::Component,
                        public VSTHostPluginAudioProcessor::ParameterChangeListener
{
    // WebView management
    // - juce::WebBrowserComponent integration
    // - HTML/CSS/JS resource generation
    // - URL handling (localhost:3000 vs embedded)
    
    // JavaScript Bridge
    // - setupJavaScriptInterface() → void
    // - handleNativeCall(url) → void
    // - Native method registration
    
    // Parameter synchronization
    // - parameterChanged(index, value) → void
    // - sendParameterUpdate(index, value) → void
    // - updateParameterList() → void
    
    // Web asset management
    // - generateHTML() → juce::String
    // - createWebAssets() → void
    // - Resource serving for embedded mode
    
    // Dependencies
    VSTHostPluginAudioProcessor& audioProcessor;
    std::unique_ptr<juce::WebBrowserComponent> webView;
};
```

### **VSTHostManager**
```cpp
class VSTHostManager
{
    // Plugin lifecycle
    // - loadPlugin(path) → bool
    // - unloadPlugin() → void
    // - Plugin format detection and loading
    
    // Audio processing
    // - prepareToPlay(sampleRate, bufferSize) → void
    // - processBlock(AudioBuffer&, MidiBuffer&) → void
    // - Audio chain management
    
    // Parameter management
    // - setParameter(index, value) → void
    // - getParameter(index) → float
    // - Parameter validation and forwarding
    
    // Editor management
    // - showEditor() → void
    // - hideEditor() → void
    // - Separate window for loaded plugin GUI
    
    // Dependencies
    std::unique_ptr<juce::AudioProcessor> loadedPlugin;
    juce::AudioPluginFormatManager formatManager;
    std::unique_ptr<juce::AudioProcessorEditor> pluginEditor;
};
```

### **ParameterManager**
```cpp
class ParameterManager
{
    // Parameter discovery
    // - updateParameters(AudioProcessor*) → void
    // - Dynamic parameter introspection
    // - Parameter metadata extraction
    
    // Parameter access
    // - getParameters() → const std::vector<ParameterInfo>&
    // - getParameterInfo(index) → ParameterInfo*
    // - isValidParameterIndex(index) → bool
    
    // Parameter tracking
    // - updateParameterValue(index, value) → void
    // - Parameter change detection
    // - Value caching and comparison
    
    // Data structures
    std::vector<ParameterInfo> parameters;
    
    struct ParameterInfo {
        int index;
        juce::String name;
        juce::String label;
        float defaultValue;
        float currentValue;
        bool isAutomatable;
    };
};
```

## **Communication Protocols**

### **JavaScript Bridge API**

#### **C++ → JavaScript (Parameter Updates)**
```javascript
// Called when loaded plugin parameters change
function onParameterChanged(parameterIndex, newValue) {
    // Update Vue.js reactive state
    parameterStore.updateParameter(parameterIndex, newValue);
}

// Called when plugin is loaded/unloaded
function onPluginStateChanged(isLoaded, pluginName, parameters) {
    // Update Vue.js plugin state
    parameterStore.setPluginState(isLoaded, pluginName, parameters);
}

// Called periodically with current state
function onStatusUpdate(cpuUsage, memoryUsage, audioLevels) {
    // Update Vue.js performance metrics
    statusStore.updateMetrics(cpuUsage, memoryUsage, audioLevels);
}
```

#### **JavaScript → C++ (Control Commands)**
```javascript
// Vue.js calls these methods on native plugin
window.juce = {
    // Parameter control
    setParameter: function(index, value) {
        // → VSTHostManager.setParameter(index, value)
    },
    
    // Plugin management
    loadPlugin: function(path) {
        // → VSTHostManager.loadPlugin(path)
    },
    
    // File operations
    showFileDialog: function() {
        // → PluginEditor.loadVSTFile()
    },
    
    // Status queries
    getPluginState: function() {
        // → Returns current plugin status
    }
};
```

### **Parameter Flow Architecture**

#### **Parameter Change Flow (User → Plugin)**
```
Vue.js UI Element
    ↓ (user interaction)
Vue.js Event Handler
    ↓ (parameter update)
Vue.js Parameter Store
    ↓ (JavaScript bridge call)
WebViewComponent.handleNativeCall()
    ↓ (method dispatch)
VSTHostPluginAudioProcessor.setVSTParameter()
    ↓ (parameter forwarding)
VSTHostManager.setParameter()
    ↓ (actual parameter change)
Loaded VST Plugin
```

#### **Parameter Change Flow (Plugin → User)**
```
Loaded VST Plugin
    ↓ (parameter automation/change)
VSTHostManager.getParameter()
    ↓ (change detection)
ParameterManager.updateParameterValue()
    ↓ (listener notification)
WebViewComponent.parameterChanged()
    ↓ (JavaScript call)
Vue.js onParameterChanged()
    ↓ (reactive update)
Vue.js UI Element
```

## **Threading Architecture**

### **Main Thread (UI Thread)**
- **WebView rendering** - Vue.js application
- **JavaScript bridge** - All JS ↔ C++ communication
- **Parameter updates** - UI element state changes
- **File operations** - Plugin loading dialogs

### **Audio Thread**
- **Audio processing** - Real-time audio chain
- **Parameter application** - VST parameter changes
- **Buffer processing** - Audio data flow
- **MIDI handling** - MIDI message processing

### **Background Thread**
- **Plugin scanning** - VST discovery and validation
- **File I/O** - Plugin loading and asset management
- **WebSocket communication** - Hardware integration (Vue.js side)

### **Thread Safety**
```cpp
// Parameter changes use atomic operations
std::atomic<bool> parameterChanged{false};
juce::CriticalSection parameterLock;

// WebView calls are dispatched to main thread
juce::MessageManager::callAsync([this, index, value]() {
    handleParameterChange(index, value);
});
```

## **Memory Management**

### **Plugin Lifetime**
- **VST Plugin**: Loaded/unloaded dynamically
- **WebView**: Created once, persists for plugin lifetime
- **Parameter Cache**: Updated on plugin changes
- **Audio Buffers**: Real-time allocation/deallocation

### **Resource Management**
```cpp
// RAII pattern for plugin management
class VSTHostManager {
    std::unique_ptr<juce::AudioProcessor> loadedPlugin;
    // Automatically cleaned up on destruction
};

// Smart pointers for UI components
std::unique_ptr<WebViewComponent> webViewComponent;
std::unique_ptr<juce::FileChooser> fileChooser;
```

## **Error Handling**

### **Plugin Loading Errors**
- **File not found**: User-friendly error dialog
- **Invalid format**: Format validation before loading
- **Loading failure**: Graceful fallback to no-plugin state
- **Crash recovery**: Plugin sandbox/isolation

### **WebView Errors**
- **JavaScript errors**: Console logging and error reporting
- **Resource loading**: Fallback to development mode
- **Communication failures**: Retry mechanisms
- **Bridge timeouts**: Async operation handling

### **Parameter Errors**
- **Invalid indices**: Bounds checking and validation
- **Value ranges**: Parameter range enforcement
- **Type mismatches**: Type validation and conversion
- **Threading issues**: Proper synchronization

## **Performance Considerations**

### **Real-time Audio**
- **Audio thread priority**: Real-time scheduling
- **Buffer size optimization**: Configurable latency
- **CPU usage monitoring**: Performance metrics
- **Memory allocation**: Pre-allocated buffers

### **UI Responsiveness**
- **Parameter updates**: 60Hz refresh rate
- **WebView performance**: Hardware acceleration
- **JavaScript optimization**: Efficient Vue.js patterns
- **Resource loading**: Lazy loading strategies

### **Memory Usage**
- **Plugin memory**: Isolated plugin instances
- **WebView memory**: Controlled resource usage
- **Parameter cache**: Efficient data structures
- **Audio buffers**: Optimal buffer management