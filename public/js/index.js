import * as Juce from "./juce/index.js";

console.log("JUCE frontend library successfully imported");

// Vue.js Application
const { createApp, ref, onMounted, computed } = Vue;

// JUCE integration setup
window.__JUCE__.backend.addEventListener(
  "exampleEvent",
  (objectFromBackend) => {
    console.log(objectFromBackend);
  }
);

const data = window.__JUCE__.initialisationData;
const nativeFunction = Juce.getNativeFunction("nativeFunction");

// Vue.js App Definition
const app = createApp({
  setup() {
    // Reactive data
    const pluginInfo = ref({
      vendor: data.vendor,
      pluginName: data.pluginName,
      pluginVersion: data.pluginVersion,
      devicePixelRatio: data.devicePixelRatio || window.devicePixelRatio || 1
    });

    const gainValue = ref(0);
    const gainStep = ref(0.01);
    const bypassValue = ref(false);
    const distortionValue = ref(0);
    const distortionChoices = ref([]);
    const emittedCount = ref(0);

    // JUCE state objects
    let sliderState, bypassToggleState, distortionTypeComboBoxState;

    // Methods
    const updateGain = () => {
      if (sliderState) {
        sliderState.setNormalisedValue(gainValue.value);
      }
    };

    const updateBypass = () => {
      if (bypassToggleState) {
        bypassToggleState.setValue(bypassValue.value);
      }
    };

    const updateDistortion = () => {
      if (distortionTypeComboBoxState) {
        distortionTypeComboBoxState.setChoiceIndex(distortionValue.value);
      }
    };

    const callNativeFunction = () => {
      nativeFunction("Vue.js", "calling", "C++").then((result) => {
        console.log("Native function result:", result);
      });
    };

    const emitEvent = () => {
      emittedCount.value++;
      window.__JUCE__.backend.emitEvent("exampleJavaScriptEvent", {
        emittedCount: emittedCount.value,
      });
    };

    // Initialize JUCE states and setup listeners
    const initializeJuceStates = () => {
      // Gain slider
      sliderState = Juce.getSliderState("GAIN");
      gainStep.value = 1 / sliderState.properties.numSteps;
      gainValue.value = sliderState.getNormalisedValue();

      sliderState.valueChangedEvent.addListener(() => {
        gainValue.value = sliderState.getNormalisedValue();
      });

      // Bypass toggle
      bypassToggleState = Juce.getToggleState("BYPASS");
      bypassValue.value = bypassToggleState.getValue();

      bypassToggleState.valueChangedEvent.addListener(() => {
        bypassValue.value = bypassToggleState.getValue();
      });

      // Distortion type combo box
      distortionTypeComboBoxState = Juce.getComboBoxState("DISTORTION_TYPE");

      distortionTypeComboBoxState.propertiesChangedEvent.addListener(() => {
        distortionChoices.value = [...distortionTypeComboBoxState.properties.choices];
      });

      distortionTypeComboBoxState.valueChangedEvent.addListener(() => {
        distortionValue.value = distortionTypeComboBoxState.getChoiceIndex();
      });

      // Initial values
      distortionChoices.value = [...distortionTypeComboBoxState.properties.choices];
      distortionValue.value = distortionTypeComboBoxState.getChoiceIndex();
    };

    // Initialize Plotly chart
    const initializePlot = () => {
      const base = -60;
      Plotly.newPlot("outputLevelPlot", {
        data: [
          {
            x: ["Left", "Right"],
            y: [base, base],
            base: [base, base],
            type: "bar",
            marker: { color: ['#007AFF', '#34C759'] }
          },
        ],
        layout: {
          width: undefined, // Let it be responsive
          height: 180,
          margin: { l: 40, r: 20, t: 20, b: 40 },
          yaxis: { range: [-60, 0], title: 'dB' },
          xaxis: { title: 'Channel' },
          plot_bgcolor: 'rgba(0,0,0,0)',
          paper_bgcolor: 'rgba(0,0,0,0)'
        },
        config: { displayModeBar: false }
      });

      window.__JUCE__.backend.addEventListener("outputLevel", () => {
        fetch(Juce.getBackendResourceAddress("outputLevel.json"))
          .then((response) => response.text())
          .then((outputLevel) => {
            const levelData = JSON.parse(outputLevel);
            // levelData.left is already in dB from JUCE (Decibels::gainToDecibels)
            // Clamp to reasonable range and display correctly
            const leftDb = Math.max(-60, Math.min(0, levelData.left || -60));
            const rightDb = Math.max(-60, Math.min(0, levelData.right || leftDb));

            Plotly.animate(
              "outputLevelPlot",
              {
                data: [
                  {
                    y: [leftDb, rightDb], // Display actual dB values
                  },
                ],
                traces: [0],
                layout: {},
              },
              {
                transition: { duration: 50, easing: "cubic-in-out" },
                frame: { duration: 50 },
              }
            );
          });
      });
    };

    // Vue lifecycle
    onMounted(() => {
      initializeJuceStates();
      initializePlot();
    });

    // Return reactive data and methods for template
    return {
      pluginInfo,
      gainValue,
      gainStep,
      bypassValue,
      distortionValue,
      distortionChoices,
      emittedCount,
      updateGain,
      updateBypass,
      updateDistortion,
      callNativeFunction,
      emitEvent
    };
  }
});

// Mount the Vue app
app.mount('#app');
