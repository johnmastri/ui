# VST Master Controller - Project Overview

This document provides complete context for restoring the VST Master Controller plugin with Vue.js WebView integration.

## **Project Architecture**

### **High-Level System Overview**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   DAW Host      │    │   Your VST       │    │   Loaded VST    │
│   (Reaper,      │───▶│   Plugin         │───▶│   Plugin        │
│    Logic, etc.) │    │   (Host/Wrapper) │    │   (Any VST)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   WebView        │
                       │   (Vue.js App)   │
                       └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   WebSocket      │
                       │   (Hardware)     │
                       └──────────────────┘
```

### **Core Concept**
This is **NOT** a traditional VST plugin. It's a **VST Host Plugin** that:
1. **Loads other VST plugins** dynamically
2. **Wraps them** with a Vue.js web interface
3. **Exposes their parameters** to the web UI
4. **Provides hardware control** via WebSocket integration

## **Technology Stack**

### **C++ (JUCE Framework)**
- **PluginProcessor**: Standard JUCE VST plugin shell
- **PluginEditor**: WebView container and JavaScript bridge
- **VSTHostManager**: Loads and manages other VST plugins
- **ParameterManager**: Handles parameter discovery and forwarding
- **WebViewComponent**: Hosts Vue.js application

### **Vue.js Frontend**
- **Complete web application** with modern UI/UX
- **Real-time parameter control** via JavaScript bridge
- **Hardware integration** via WebSocket
- **Development mode**: Runs on localhost:3000
- **Production mode**: Embedded in plugin as binary data

### **WebView Integration**
- **Platform-specific WebView** (WebView2 on Windows)
- **JavaScript ↔ C++ bridge** for parameter communication
- **Resource provider** for embedded web assets
- **Development/production mode switching**

## **Current State Analysis**

### **What Exists and Works**
✅ **Vue.js Application** - Complete, functional web interface
✅ **WebSocket Integration** - Hardware communication working
✅ **Parameter Store** - Vue.js parameter management
✅ **Build System** - Vue.js build process configured
✅ **Header Files** - All C++ class definitions created
✅ **Backend Application** - Standalone VST host (reference implementation)

### **What's Missing**
❌ **C++ Implementation Files** - .cpp files for all classes
❌ **Plugin CMakeLists.txt** - Build configuration for VST plugin
❌ **JavaScript Bridge** - Native function bindings
❌ **WebView Integration** - HTML/CSS generation and resource loading
❌ **Parameter Forwarding** - Real-time parameter synchronization

### **What Was Working Before**
- **VST plugin loaded** in DAW without errors
- **Vue.js UI displayed** when plugin GUI opened
- **localhost:3000 development server** loaded in WebView
- **Parameter changes** worked bidirectionally
- **Hardware WebSocket** communication functional

## **Key Technical Challenges**

### **1. Parameter System**
**Challenge**: Loaded VST plugins have different parameter sets
**Solution**: Dynamic parameter discovery and mapping
```cpp
// Example: Plugin has 10 parameters, Vue.js discovers them at runtime
std::vector<ParameterInfo> params = vstHostManager.getParameters();
// Vue.js receives: [{"index": 0, "name": "Gain", "value": 0.5}, ...]
```

### **2. Communication Bridge**
**Challenge**: JavaScript ↔ C++ bidirectional communication
**Solution**: JUCE WebView JavaScript bridge pattern
```javascript
// Vue.js → C++
window.juce.setParameter(0, 0.75);

// C++ → Vue.js
window.receiveParameterUpdate(0, 0.75);
```

### **3. Development Workflow**
**Challenge**: Rapid Vue.js development while testing in plugin
**Solution**: Dual-mode WebView loading
```cpp
// Development: Load localhost:3000
webView->goToURL("http://localhost:3000");

// Production: Load embedded resources
webView->goToURL(createResourceURL("index.html"));
```

## **Project Goals**

### **Primary Objective**
Restore the working VST plugin that:
- Loads other VST plugins dynamically
- Provides Vue.js web interface for parameter control
- Maintains hardware integration via WebSocket
- Works in both development and production modes

### **Success Criteria**
1. **Plugin loads** in DAW without crashes
2. **Vue.js interface** displays when plugin GUI opened
3. **Parameter changes** work in both directions
4. **Hardware WebSocket** communication continues working
5. **Development server** (localhost:3000) loads correctly
6. **Production build** embeds Vue.js app successfully

## **Development Approach**

### **Phase 1: Core Implementation**
1. Implement C++ classes (.cpp files)
2. Create plugin CMakeLists.txt
3. Set up basic WebView integration
4. Test plugin loading in DAW

### **Phase 2: JavaScript Bridge**
1. Implement parameter discovery
2. Create JavaScript bridge methods
3. Test Vue.js ↔ C++ communication
4. Verify parameter synchronization

### **Phase 3: Production Integration**
1. Configure Vue.js build embedding
2. Set up resource provider
3. Test production mode
4. Verify all functionality

## **Reference Implementation**

The **backend/** directory contains a standalone VST host application that demonstrates the same functionality. This serves as a reference for:
- VST plugin loading patterns
- Parameter management
- WebSocket server integration
- Audio processing chain

## **Next Steps**

1. **Review header files** - Ensure all class definitions are correct
2. **Implement .cpp files** - Based on reference backend implementation
3. **Create build system** - CMakeLists.txt for plugin compilation
4. **Test basic functionality** - Plugin loading and WebView display
5. **Integrate JavaScript bridge** - Connect Vue.js to C++ parameters
6. **Test complete workflow** - End-to-end functionality verification

This project is **highly feasible** because:
- **Architecture is well-designed** with clear separation of concerns
- **Vue.js app is complete** and working
- **Reference implementation exists** in backend directory
- **JUCE WebView integration** is a proven pattern
- **All hard problems are solved** - just need implementation