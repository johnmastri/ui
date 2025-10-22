# Implementation Guide - VST Master Controller

This document provides step-by-step implementation instructions for completing the VST Master Controller plugin.

## **Prerequisites**

### **Development Environment**
- **Visual Studio 2019/2022** (Windows) or **Xcode** (macOS)
- **CMake 3.22+** for build system
- **JUCE Framework** (will be downloaded automatically)
- **WebView2 Runtime** (Windows) or **WebKit** (macOS)

### **Project Structure Verification**
Ensure these directories exist:
```
VSTMastrCtrl/
├── docs/                    # This documentation
├── mastrctrl/plugin/ui/backend/  # Header files (✓ exists)
├── mastrctrl/plugin/ui/src/      # Vue.js app (✓ exists)
├── mastrctrl/plugin/ui/dist/     # Vue.js build output
└── mastrctrl/vs-build/           # Build artifacts
```

## **Phase 1: Core C++ Implementation**

### **Step 1.1: Create Plugin CMakeLists.txt**

Create: `/mastrctrl/plugin/CMakeLists.txt`
```cmake
cmake_minimum_required(VERSION 3.22)
project(VSTMasterController VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find JUCE
find_package(JUCE CONFIG REQUIRED)

# Create plugin target
juce_add_plugin(VSTMasterController
    COMPANY_NAME "Mastri Design Engineering"
    PLUGIN_MANUFACTURER_CODE "MSTR"
    PLUGIN_CODE "MCTL"
    FORMATS VST3 Standalone
    PRODUCT_NAME "MastrCtrl"
    PLUGIN_NAME "MastrCtrl"
    PLUGIN_DESCRIPTION "VST Master Controller with WebView"
    NEEDS_WEB_BROWSER TRUE
    NEEDS_MIDI_INPUT FALSE
    NEEDS_MIDI_OUTPUT FALSE
    IS_SYNTH FALSE
    IS_MIDI_EFFECT FALSE
    COPY_PLUGIN_AFTER_BUILD TRUE
)

# Source files
target_sources(VSTMasterController
    PRIVATE
        ui/backend/PluginProcessor.cpp
        ui/backend/PluginProcessor.h
        ui/backend/PluginEditor.cpp
        ui/backend/PluginEditor.h
        ui/backend/WebViewComponent.cpp
        ui/backend/WebViewComponent.h
        ui/backend/VSTHostManager.cpp
        ui/backend/VSTHostManager.h
        ui/backend/ParameterManager.cpp
        ui/backend/ParameterManager.h
)

# Link JUCE modules
target_link_libraries(VSTMasterController
    PRIVATE
        juce::juce_audio_basics
        juce::juce_audio_devices
        juce::juce_audio_formats
        juce::juce_audio_processors
        juce::juce_audio_utils
        juce::juce_core
        juce::juce_data_structures
        juce::juce_events
        juce::juce_graphics
        juce::juce_gui_basics
        juce::juce_gui_extra
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags
)

# Include directories
target_include_directories(VSTMasterController
    PRIVATE
        ui/backend
)

# Compiler definitions
target_compile_definitions(VSTMasterController
    PRIVATE
        JUCE_WEB_BROWSER=1
        JUCE_USE_CURL=0
        JUCE_VST3_CAN_REPLACE_VST2=0
)

# Copy Vue.js assets
add_custom_command(TARGET VSTMasterController POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/ui/dist
        ${CMAKE_CURRENT_BINARY_DIR}/ui/dist
)
```

### **Step 1.2: Implement PluginProcessor.cpp**

Create: `/mastrctrl/plugin/ui/backend/PluginProcessor.cpp`
```cpp
#include "PluginProcessor.h"
#include "PluginEditor.h"

VSTHostPluginAudioProcessor::VSTHostPluginAudioProcessor()
    : AudioProcessor(BusesProperties()
                     .withInput("Input", juce::AudioChannelSet::stereo(), true)
                     .withOutput("Output", juce::AudioChannelSet::stereo(), true))
{
}

VSTHostPluginAudioProcessor::~VSTHostPluginAudioProcessor()
{
    unloadVSTPlugin();
}

const juce::String VSTHostPluginAudioProcessor::getName() const
{
    return "MastrCtrl";
}

bool VSTHostPluginAudioProcessor::acceptsMidi() const
{
    return false;
}

bool VSTHostPluginAudioProcessor::producesMidi() const
{
    return false;
}

bool VSTHostPluginAudioProcessor::isMidiEffect() const
{
    return false;
}

double VSTHostPluginAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int VSTHostPluginAudioProcessor::getNumPrograms()
{
    return 1;
}

int VSTHostPluginAudioProcessor::getCurrentProgram()
{
    return 0;
}

void VSTHostPluginAudioProcessor::setCurrentProgram(int index)
{
}

const juce::String VSTHostPluginAudioProcessor::getProgramName(int index)
{
    return {};
}

void VSTHostPluginAudioProcessor::changeProgramName(int index, const juce::String& newName)
{
}

void VSTHostPluginAudioProcessor::prepareToPlay(double sampleRate, int samplesPerBlock)
{
    vstHostManager.prepareToPlay(sampleRate, samplesPerBlock);
}

void VSTHostPluginAudioProcessor::releaseResources()
{
    vstHostManager.releaseResources();
}

bool VSTHostPluginAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
        && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;

    return true;
}

void VSTHostPluginAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    
    if (vstHostManager.isPluginLoaded())
    {
        vstHostManager.processBlock(buffer, midiMessages);
    }
    else
    {
        // Pass through if no plugin loaded
        buffer.clear();
    }
}

bool VSTHostPluginAudioProcessor::hasEditor() const
{
    return true;
}

juce::AudioProcessorEditor* VSTHostPluginAudioProcessor::createEditor()
{
    return new VSTHostPluginAudioProcessorEditor(*this);
}

void VSTHostPluginAudioProcessor::getStateInformation(juce::MemoryBlock& destData)
{
    // Save current plugin path and state
    juce::XmlElement xml("VSTMasterController");
    xml.setAttribute("pluginPath", vstHostManager.getLoadedPluginPath());
    
    if (vstHostManager.isPluginLoaded())
    {
        juce::MemoryBlock pluginState;
        vstHostManager.getLoadedPlugin()->getStateInformation(pluginState);
        xml.setAttribute("pluginState", juce::Base64::toBase64(pluginState.getData(), pluginState.getSize()));
    }
    
    copyXmlToBinary(xml, destData);
}

void VSTHostPluginAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    // Restore plugin path and state
    std::unique_ptr<juce::XmlElement> xml(getXmlFromBinary(data, sizeInBytes));
    
    if (xml != nullptr)
    {
        auto pluginPath = xml->getStringAttribute("pluginPath");
        if (pluginPath.isNotEmpty())
        {
            if (loadVSTPlugin(pluginPath))
            {
                auto pluginStateString = xml->getStringAttribute("pluginState");
                if (pluginStateString.isNotEmpty())
                {
                    juce::MemoryBlock pluginState;
                    juce::Base64::convertFromBase64(pluginState, pluginStateString);
                    vstHostManager.getLoadedPlugin()->setStateInformation(pluginState.getData(), 
                                                                        static_cast<int>(pluginState.getSize()));
                }
            }
        }
    }
}

// Custom VST hosting methods
bool VSTHostPluginAudioProcessor::loadVSTPlugin(const juce::String& pluginPath)
{
    if (vstHostManager.loadPlugin(pluginPath))
    {
        parameterManager.updateParameters(vstHostManager.getLoadedPlugin());
        notifyParameterChange(-1, 0.0f); // Signal plugin loaded
        return true;
    }
    return false;
}

void VSTHostPluginAudioProcessor::unloadVSTPlugin()
{
    vstHostManager.unloadPlugin();
    parameterManager.clearParameters();
    notifyParameterChange(-1, 0.0f); // Signal plugin unloaded
}

std::vector<ParameterInfo> VSTHostPluginAudioProcessor::getVSTParameters() const
{
    return parameterManager.getParameters();
}

void VSTHostPluginAudioProcessor::setVSTParameter(int parameterIndex, float value)
{
    if (vstHostManager.isPluginLoaded() && parameterManager.isValidParameterIndex(parameterIndex))
    {
        vstHostManager.setParameter(parameterIndex, value);
        parameterManager.updateParameterValue(parameterIndex, value);
        notifyParameterChange(parameterIndex, value);
    }
}

float VSTHostPluginAudioProcessor::getVSTParameter(int parameterIndex) const
{
    if (vstHostManager.isPluginLoaded() && parameterManager.isValidParameterIndex(parameterIndex))
    {
        return vstHostManager.getParameter(parameterIndex);
    }
    return 0.0f;
}

void VSTHostPluginAudioProcessor::showVSTEditor()
{
    vstHostManager.showEditor();
}

void VSTHostPluginAudioProcessor::hideVSTEditor()
{
    vstHostManager.hideEditor();
}

bool VSTHostPluginAudioProcessor::isVSTEditorVisible() const
{
    return vstHostManager.isEditorVisible();
}

void VSTHostPluginAudioProcessor::addParameterChangeListener(ParameterChangeListener* listener)
{
    parameterChangeListeners.push_back(listener);
}

void VSTHostPluginAudioProcessor::removeParameterChangeListener(ParameterChangeListener* listener)
{
    parameterChangeListeners.erase(
        std::remove(parameterChangeListeners.begin(), parameterChangeListeners.end(), listener),
        parameterChangeListeners.end());
}

void VSTHostPluginAudioProcessor::notifyParameterChange(int parameterIndex, float newValue)
{
    for (auto* listener : parameterChangeListeners)
    {
        listener->parameterChanged(parameterIndex, newValue);
    }
}

// Plugin instantiation
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new VSTHostPluginAudioProcessor();
}
```

### **Step 1.3: Implement Remaining Classes**

**Continue with similar implementations for:**
- `PluginEditor.cpp`
- `WebViewComponent.cpp`
- `VSTHostManager.cpp`
- `ParameterManager.cpp`

**Each implementation should:**
1. **Follow the header file interface** exactly
2. **Use JUCE best practices** for audio processing
3. **Handle errors gracefully** with user feedback
4. **Maintain thread safety** for parameter changes
5. **Reference the backend/** implementation for patterns

## **Phase 2: JavaScript Bridge Implementation**

### **Step 2.1: WebView HTML Generation**

In `WebViewComponent.cpp`, implement `generateHTML()`:
```cpp
juce::String WebViewComponent::generateHTML()
{
    // Development mode: redirect to localhost:3000
    if (juce::File("/tmp/vue_dev_server").exists()) // Dev server detection
    {
        return R"(
            <!DOCTYPE html>
            <html>
            <head>
                <title>MastrCtrl Development</title>
                <script>
                    window.location.href = 'http://localhost:3000';
                </script>
            </head>
            <body>
                <p>Redirecting to development server...</p>
            </body>
            </html>
        )";
    }
    
    // Production mode: serve embedded Vue.js app
    return R"(
        <!DOCTYPE html>
        <html>
        <head>
            <title>MastrCtrl</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="dist/assets/index.css">
        </head>
        <body>
            <div id="app"></div>
            <script src="dist/assets/index.js"></script>
        </body>
        </html>
    )";
}
```

### **Step 2.2: JavaScript Bridge Methods**

In `WebViewComponent.cpp`, implement `setupJavaScriptInterface()`:
```cpp
void WebViewComponent::setupJavaScriptInterface()
{
    if (webView != nullptr)
    {
        // Register native methods
        webView->bind("loadVSTPlugin", [this](const juce::var::NativeFunctionArgs& args) -> juce::var
        {
            if (args.numArguments > 0)
            {
                auto pluginPath = args.arguments[0].toString();
                bool success = audioProcessor.loadVSTPlugin(pluginPath);
                return juce::var(success);
            }
            return juce::var(false);
        });
        
        webView->bind("setParameter", [this](const juce::var::NativeFunctionArgs& args) -> juce::var
        {
            if (args.numArguments >= 2)
            {
                int index = args.arguments[0];
                float value = args.arguments[1];
                audioProcessor.setVSTParameter(index, value);
                return juce::var(true);
            }
            return juce::var(false);
        });
        
        webView->bind("getPluginState", [this](const juce::var::NativeFunctionArgs& args) -> juce::var
        {
            juce::var state = juce::var(new juce::DynamicObject());
            state.getDynamicObject()->setProperty("isLoaded", audioProcessor.isVSTLoaded());
            state.getDynamicObject()->setProperty("pluginName", audioProcessor.getLoadedVSTName());
            
            // Add parameters array
            auto params = audioProcessor.getVSTParameters();
            juce::Array<juce::var> paramArray;
            for (const auto& param : params)
            {
                juce::var paramObj = juce::var(new juce::DynamicObject());
                paramObj.getDynamicObject()->setProperty("index", param.index);
                paramObj.getDynamicObject()->setProperty("name", param.name);
                paramObj.getDynamicObject()->setProperty("value", param.currentValue);
                paramArray.add(paramObj);
            }
            state.getDynamicObject()->setProperty("parameters", paramArray);
            
            return state;
        });
    }
}
```

## **Phase 3: Vue.js Integration**

### **Step 3.1: Update Vue.js JUCE Integration**

Modify `/mastrctrl/plugin/ui/src/composables/useJuceIntegration.js`:
```javascript
export function useJuceIntegration() {
    const isInWebView = ref(!!window.juce);
    const pluginState = ref({
        isLoaded: false,
        pluginName: '',
        parameters: []
    });
    
    const initializeJuceStates = async () => {
        if (!window.juce) {
            console.warn('JUCE not available - running in development mode');
            return;
        }
        
        // Get initial plugin state
        const state = await window.juce.getPluginState();
        pluginState.value = state;
        
        // Set up parameter change listener
        window.onParameterChanged = (parameterIndex, newValue) => {
            const param = pluginState.value.parameters.find(p => p.index === parameterIndex);
            if (param) {
                param.value = newValue;
            }
        };
        
        // Set up plugin state change listener
        window.onPluginStateChanged = (isLoaded, pluginName, parameters) => {
            pluginState.value = {
                isLoaded,
                pluginName,
                parameters
            };
        };
    };
    
    const loadPlugin = async (pluginPath) => {
        if (window.juce) {
            return await window.juce.loadVSTPlugin(pluginPath);
        }
        return false;
    };
    
    const setParameter = async (index, value) => {
        if (window.juce) {
            return await window.juce.setParameter(index, value);
        }
        return false;
    };
    
    return {
        isInWebView,
        pluginState,
        initializeJuceStates,
        loadPlugin,
        setParameter
    };
}
```

### **Step 3.2: Update Vue.js Components**

Update components to use the new VST host functionality instead of hardcoded parameters.

## **Phase 4: Build System Setup**

### **Step 4.1: Configure Build**

```bash
# Create build directory
mkdir -p /mastrctrl/plugin/build

# Configure CMake
cd /mastrctrl/plugin/build
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build plugin
cmake --build . --config Release
```

### **Step 4.2: Vue.js Build Integration**

Create build script: `/mastrctrl/plugin/build-vue.sh`
```bash
#!/bin/bash
cd ../ui
npm run build
echo "Vue.js build completed"
```

## **Phase 5: Testing and Validation**

### **Step 5.1: Basic Plugin Test**
1. **Load plugin** in DAW
2. **Verify GUI opens** without crashes
3. **Check console** for JavaScript errors
4. **Test parameter loading**

### **Step 5.2: VST Loading Test**
1. **Use file dialog** to load VST plugin
2. **Verify parameters** appear in Vue.js interface
3. **Test parameter changes** bidirectionally
4. **Verify audio processing** works

### **Step 5.3: Production Mode Test**
1. **Build Vue.js** for production
2. **Test embedded resource** loading
3. **Verify all functionality** works without dev server
4. **Test plugin state** saving/loading

## **Common Issues and Solutions**

### **WebView Not Loading**
- Check WebView2 runtime installation
- Verify HTML generation is correct
- Check for JavaScript console errors
- Test with simple HTML first

### **Parameter Communication Issues**
- Verify JavaScript bridge methods are registered
- Check parameter index validation
- Test with console.log debugging
- Verify thread safety of parameter updates

### **Plugin Loading Issues**
- Check plugin format support (VST2/VST3)
- Verify plugin path validity
- Test with known working plugins
- Check audio device initialization

### **Build Issues**
- Verify JUCE version compatibility
- Check CMake configuration
- Ensure all dependencies are linked
- Test with minimal plugin first

## **Success Criteria**

✅ **Plugin loads** in DAW without crashes
✅ **WebView displays** Vue.js interface
✅ **File dialog** allows VST plugin loading
✅ **Parameters appear** in Vue.js interface
✅ **Parameter changes** work bidirectionally
✅ **Audio processing** works correctly
✅ **WebSocket integration** continues functioning
✅ **Development mode** loads localhost:3000
✅ **Production mode** uses embedded resources