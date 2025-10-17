export function usePlotly(addDebugMessage = console.log) {
  const initializePlot = () => {
    // Load Plotly from CDN if not already loaded
    if (!window.Plotly) {
      const script = document.createElement('script')
      script.src = 'https://cdn.plot.ly/plotly-2.33.0.min.js'
      script.onload = () => createPlot()
      document.head.appendChild(script)
    } else {
      createPlot()
    }
  }

  const createPlot = () => {
    const base = -60
    
    if (!window.Plotly) {
      console.warn('Plotly not available')
      return
    }

    window.Plotly.newPlot("outputLevelPlot", {
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
    })

    // Set up real-time updates if JUCE is available
    if (window.__JUCE__) {
      // Import JUCE library for real data
      import('../juce/index.js').then((Juce) => {
        const juceLib = Juce.default || Juce

        window.__JUCE__.backend.addEventListener("outputLevel", () => {
          addDebugMessage('Vue: outputLevel event received')
          // Fetch real output level data from JUCE
          fetch(juceLib.getBackendResourceAddress("outputLevel.json"))
            .then((response) => {
              addDebugMessage(`Vue: fetch response received ${response.status}`)
              return response.text()
            })
            .then((outputLevel) => {
              addDebugMessage(`Vue: raw output level data: ${outputLevel}`)
              const levelData = JSON.parse(outputLevel)
              addDebugMessage(`Vue: parsed level data: ${JSON.stringify(levelData)}`)
              // levelData.left is already in dB from JUCE
              const leftDb = Math.max(-60, Math.min(0, levelData.left || -60))
              const rightDb = Math.max(-60, Math.min(0, levelData.right || leftDb))
              addDebugMessage(`Vue: updating plot with levels: ${leftDb}, ${rightDb}`)
              updatePlotWithRealLevel(leftDb, rightDb)
            })
            .catch((error) => {
              addDebugMessage(`Vue: Failed to fetch output level: ${error}`)
              // Fallback to silent level
              updatePlotWithRealLevel(-60, -60)
            })
        })
      }).catch((error) => {
        console.warn('JUCE library not available:', error)
        // Fallback to development mode
        setInterval(() => {
          updatePlotWithLevel(Math.random() * 60 - 60)
        }, 100)
      })
    } else {
      // Development mode - simulate with random data
      setInterval(() => {
        updatePlotWithLevel(Math.random() * 60 - 60)
      }, 100)
    }
  }

  const updatePlotWithLevel = (level) => {
    if (!window.Plotly) return

    const base = -60
    window.Plotly.animate(
      "outputLevelPlot",
      {
        data: [
          {
            y: [level - base, level - base],
          },
        ],
        traces: [0],
        layout: {},
      },
      {
        transition: { duration: 50, easing: "cubic-in-out" },
        frame: { duration: 50 },
      }
    )
  }

  const updatePlotWithRealLevel = (leftDb, rightDb) => {
    addDebugMessage(`Vue: updatePlotWithRealLevel called with: ${leftDb}, ${rightDb}`)
    if (!window.Plotly) {
      addDebugMessage('Vue: Plotly not available')
      return
    }

    addDebugMessage(`Vue: Animating plot with values: [${leftDb}, ${rightDb}]`)
    window.Plotly.animate(
      "outputLevelPlot",
      {
        data: [
          {
            y: [leftDb, rightDb], // Display actual dB values directly
          },
        ],
        traces: [0],
        layout: {},
      },
      {
        transition: { duration: 50, easing: "cubic-in-out" },
        frame: { duration: 50 },
      }
    )
  }

  return {
    initializePlot,
    updatePlotWithLevel,
    updatePlotWithRealLevel
  }
}
