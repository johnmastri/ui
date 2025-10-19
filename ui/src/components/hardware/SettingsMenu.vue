<template>
  <g @wheel.stop.prevent="handleWheel" @mousedown="handleMouseDown">
    <!-- 2x2 Grid of Settings Buttons -->
    <g 
      v-for="(btn, idx) in hardwareSettingsStore.buttons" 
      :key="btn.id" 
      :ref="el => setButtonRef(el, btn.id)"
      :transform="`translate(${btn.x}, ${btn.y})`"
      style="opacity: 0; pointer-events: auto;"
    >
      <SettingsButton 
        :label="btn.label"
        :button-id="btn.id"
        :is-selected="isButtonSelected(btn.id)"
        :is-animating="isAnimating"
        :expanded-button-id="expandedButtonId"
        @click="handleButtonClick(btn.id)"
        @mouseenter="handleButtonMouseEnter(btn.id)"
        @mouseleave="handleButtonMouseLeave"
        :ref="el => setSettingsButtonRef(el, btn.id)"
      />
    </g>
    
    <!-- Close Button -->
    <g :ref="el => closeButtonWrapper = el" style="opacity: 0; pointer-events: auto;">
      <CloseButton 
        :is-selected="isButtonSelected('close')"
        :is-expanded="isAnimating || hardwareSettingsStore.navigationMode === 'parameters'"
        @close="emitClose"
        @mouseenter="handleCloseMouseEnter"
        @mouseleave="handleCloseMouseLeave"
      />
    </g>
 
    <SettingsHolder 
      ref="SettingsHolder" 
      @button-click="handleSettingsButtonClick" 
    />
    <BackButton 
      ref="BackButton" 
      :is-selected="hardwareSettingsStore.isBackButtonSelected"
      @back="handleBack" 
    />
  
    <UpdatePanel 
      v-if="showUpdatePanel" 
      @close="closeUpdatePanel"
    />
  </g>
</template>

<script>
import SettingsButton from './SettingsButton.vue'
import CloseButton from './CloseButton.vue'
import BackButton from './settings/BackButton.vue'
import SettingsHolder from './settings/SettingsHolder.vue'
import UpdatePanel from './settings/UpdatePanel.vue'
import { useHardwareSettingsStore } from '../../stores/hardwareSettingsStore'
import { gsap } from 'gsap'
import { CSSPlugin } from 'gsap/CSSPlugin'

// Register the CSSPlugin
gsap.registerPlugin(CSSPlugin)

export default {
  name: 'SettingsMenu',
  components: {
    SettingsButton,
    CloseButton,
    BackButton,
    SettingsHolder,
    UpdatePanel
  },
  emits: ['close'],
  setup() {
    const hardwareSettingsStore = useHardwareSettingsStore()
    
    return {
      hardwareSettingsStore
    }
  },
  data() {
    return {
      buttonRefs: {},
      settingsButtonRefs: {},
      closeButtonWrapper: null,
      isAnimating: false,
      animatingButtonId: null,
      expandedButtonId: null,
      showUpdatePanel: false
    }
  },
  watch: {
    showUpdatePanel(newVal) {
      console.log('[SETTINGS MENU] showUpdatePanel changed to:', newVal)
      if (newVal) {
        console.log('[SETTINGS MENU] Entering modal navigation mode')
        this.hardwareSettingsStore.setNavigationMode('modal')
      } else {
        console.log('[SETTINGS MENU] Exiting modal, returning to parameters mode')
        this.hardwareSettingsStore.setNavigationMode('parameters')
      }
    },
    'hardwareSettingsStore.navigationMode'(newMode, oldMode) {
      // Only clear expandedButtonId when returning to menu mode
      if (oldMode === 'parameters' && newMode === 'menu') {
        this.expandedButtonId = null
        // Re-enable close button pointer events when returning to menu
        if (this.closeButtonWrapper) {
          this.closeButtonWrapper.style.pointerEvents = 'auto'
        }
      } else if (newMode === 'parameters') {
        // Disable close button pointer events when entering parameters mode
        if (this.closeButtonWrapper) {
          this.closeButtonWrapper.style.pointerEvents = 'none'
        }
      }
    }
  },
  methods: {
    handleButtonMouseEnter(buttonId) {
      if (this.isAnimating || buttonId === this.expandedButtonId || this.expandedButtonId) {
        return
      }
      this.hardwareSettingsStore.setHoveredButton(buttonId)
    },
    
    handleButtonMouseLeave() {
      if (this.isAnimating || this.expandedButtonId) {
        return
      }
      this.hardwareSettingsStore.clearHoveredButton()
    },
    
    handleCloseMouseEnter() {
      if (this.hardwareSettingsStore.navigationMode === 'menu' && !this.isAnimating) {
        this.hardwareSettingsStore.setHoveredButton('close')
      }
    },
    
    handleCloseMouseLeave() {
      if (this.isAnimating || this.expandedButtonId) {
        return
      }
      this.hardwareSettingsStore.clearHoveredButton()
    },
    
    handleSettingsButtonClick(event) {
      console.log('[SETTINGS MENU] Button clicked:', event)
      if (event.parameterId === 'systemUpdate' && event.type === 'update_panel') {
        console.log('[SETTINGS MENU] System Update detected, showing panel')
        this.showUpdatePanel = true
      }
    },
    
    closeUpdatePanel() {
      this.showUpdatePanel = false
    },
    
    isButtonSelected(buttonId) {
      return this.hardwareSettingsStore.currentSelectedButton === buttonId
    },
    
    setButtonRef(el, buttonId) {
      if (el) {
        this.buttonRefs[buttonId] = el
      }
    },
    
    setSettingsButtonRef(el, buttonId) {
      if (el) {
        this.settingsButtonRefs[buttonId] = el
      }
    },
    
    handleButtonClick(buttonId) {
      // Original main menu logic
      this.hardwareSettingsStore.setHoveredButton(buttonId)
      
      // Don't animate if already animating
      if (this.isAnimating) {
        return
      }
      
      // Don't animate if there's already an expanded button
      if (this.expandedButtonId) {
        return
      }
      
      this.animateButtonToFullScreen(buttonId)
    },
    
    animateButtonToFullScreen(buttonId) {
      const buttonElement = this.buttonRefs[buttonId]
      const settingsButtonComponent = this.settingsButtonRefs[buttonId]
      if (!buttonElement || !settingsButtonComponent) return
      
      // Get the button data to know its original position
      const buttonData = this.hardwareSettingsStore.buttons.find(btn => btn.id === buttonId)
      if (!buttonData) return
      
      // Move the button element to be directly above the close button in DOM order
      const parentContainer = buttonElement.parentNode
      const closeButtonElement = this.closeButtonWrapper
      
      if (closeButtonElement && closeButtonElement.parentNode) {
        // Insert the button element right before the close button
        closeButtonElement.parentNode.insertBefore(buttonElement, closeButtonElement)
      }
      
      // Disable pointer events during animation
      buttonElement.style.pointerEvents = 'none'
      
      // Disable pointer events for all other buttons to prevent hover effects
      Object.values(this.buttonRefs).forEach(ref => {
        if (ref && ref !== buttonElement) {
          ref.style.pointerEvents = 'none'
        }
      })
      
      // Disable pointer events on the main container to block all mouse events
      const mainContainer = this.$el
      if (mainContainer) {
        mainContainer.style.pointerEvents = 'none'
        mainContainer.style.cursor = 'pointer'
      }
      
      // Clear any hover state on the close button
      if (this.hardwareSettingsStore.currentSelectedButton === 'close') {
        this.hardwareSettingsStore.clearHoveredButton()
      }
      
      // Immediately hide the text label
      if (settingsButtonComponent.$refs.textElement) {
        gsap.set(settingsButtonComponent.$refs.textElement, {
          opacity: 0
        })
      }
      
      // Animate the parent g element to position (0,0)
      gsap.to(buttonElement, {
        x: 0, // Move to x=0
        y: 0, // Move to y=0
        duration: 0.3,
        ease: "power2.inOut"
      })
      
      // Animate the background rectangle size using refs
      if (settingsButtonComponent.$refs.backgroundRect) {
        gsap.to(settingsButtonComponent.$refs.backgroundRect, {
          width: 800,
          height: 480,
          duration: 0.3,
          ease: "power2.inOut"
        })
        
        // Animate background opacity to 1
        gsap.to(settingsButtonComponent, {
          backgroundOpacity: 1,
          duration: 0.3,
          ease: "power2.inOut"
        })
      }
      
      // Animate the diagonal lines background rectangle size using refs
      if (settingsButtonComponent.$refs.diagonalLines && settingsButtonComponent.$refs.diagonalLines.$refs.background) {
        // Stop any existing diagonal lines animations first
        if (settingsButtonComponent.$refs.diagonalLines.stopAnimations) {
          settingsButtonComponent.$refs.diagonalLines.stopAnimations()
        }
        
        gsap.to(settingsButtonComponent.$refs.diagonalLines.$refs.background, {
          width: 800,
          height: 480,
          duration: 0.3,
          ease: "power2.inOut",
          onComplete: () => {
            // Restart the diagonal lines animation after size change
            if (settingsButtonComponent.$refs.diagonalLines && settingsButtonComponent.$refs.diagonalLines.startAnimations) {
              settingsButtonComponent.$refs.diagonalLines.startAnimations()
            }
          }
        })
      }
      
      // Animate the text position to center of new size using refs
      if (settingsButtonComponent.$refs.textElement) {
        gsap.to(settingsButtonComponent.$refs.textElement, {
         // x: 400, // Center of 800px width
        //  y: 240, // Center of 480px height
          opacity: 0,
          duration: 0.1,
          ease: "power2.inOut",
          onComplete: () => {
            this.isAnimating = false
            this.animatingButtonId = null
            this.expandedButtonId = buttonId // Set the expanded button
            
            // Set navigation mode to parameters after animation completes
            this.hardwareSettingsStore.setNavigationMode('parameters')
            // Set the current menu to the button that was clicked
            this.hardwareSettingsStore.setCurrentMenu(buttonId)
            
            // Don't disable pointer events on main container - be more selective
            const mainContainer = this.$el
            if (mainContainer) {
              mainContainer.style.cursor = 'pointer'
            }


            // Keep the expanded button's pointer events disabled
            buttonElement.style.pointerEvents = 'none'
            // Keep all other buttons disabled
            Object.values(this.buttonRefs).forEach(ref => {
              if (ref) {
                ref.style.pointerEvents = 'none'
              }
            })
            
            // Back button pointer events are handled by CSS !important rule
            
            // Fade in the settings holder and back button after the main animation completes
            if (this.$refs.SettingsHolder && typeof this.$refs.SettingsHolder.fadeIn === 'function') {
              this.$refs.SettingsHolder.fadeIn();
            }
            
            // Fade in the back button
            if (this.$refs.BackButton && typeof this.$refs.BackButton.fadeIn === 'function') {
              this.$refs.BackButton.fadeIn();
            }
          }
        })
      }
      
      // Animate the close button background to full screen with buffer
      if (this.closeButtonWrapper) {
        // Disable mouse events for the close button during animation
        this.closeButtonWrapper.style.pointerEvents = 'none'
        
        // Clear any hover state on the close button
        if (this.hardwareSettingsStore.currentSelectedButton === 'close') {
          this.hardwareSettingsStore.clearHoveredButton()
        }
        
        // Find the CloseButton element within the wrapper
        const closeButtonElement = this.closeButtonWrapper.querySelector('g')
        if (closeButtonElement) {
          // Move the CloseButton to position (55,55)
          gsap.to(closeButtonElement, {
            x: 55,
            y: 55,
            duration: 0.4,
            delay: 0.07,
            ease: "power3.inOut"
          })
        }
        
        // Resize the black square background
        const closeButtonBg = this.closeButtonWrapper.querySelector('#Rectangle\\ 10')
        if (closeButtonBg) {
          gsap.to(closeButtonBg, {
            width: 690, // 800 - 55*2 = 690
            height: 370, // 480 - 55*2 = 370
            duration: 0.4,
            delay: 0.07,
            ease: "power3.inOut",
            onComplete: () => {
              // Re-enable mouse events after animation completes
              this.closeButtonWrapper.style.pointerEvents = 'auto'
            }
          })
        }
        
        // Set the white X icon to 0 opacity
        const xIconPath = this.closeButtonWrapper.querySelector('#Icon')
        if (xIconPath) {
          gsap.to(xIconPath, {
            opacity: 0,
            duration: 0.04,
            ease: "power2.inOut"
          })
        }
      }
    },
    
    animateButtonsIn() {
      // Define the order for sequential animation - close button last
      const buttonOrder = ['device', 'network', 'midi', 'display']
      const delayBetweenButtons = 0.10 // 150ms between each button
      
      // Animate the settings buttons
      buttonOrder.forEach((buttonId, index) => {
        const delay = index * delayBetweenButtons
        const element = this.buttonRefs[buttonId]
        
        if (element) {
          gsap.to(element, {
            opacity: 1,
            duration: 0.5,
            delay: delay,
            ease: "bounce.out"
          })
        }
      })
      
      // Animate the close button last
      const closeButtonDelay = buttonOrder.length * delayBetweenButtons
      
      if (this.closeButtonWrapper) {
        gsap.to(this.closeButtonWrapper, {
          opacity: 1,
          duration: 0.8,
          delay: closeButtonDelay,
          ease: "bounce.out"
        })
      }
    },
    
    animateButtonBackToOriginal(buttonId) {
      const buttonElement = this.buttonRefs[buttonId]
      const settingsButtonComponent = this.settingsButtonRefs[buttonId]
      if (!buttonElement || !settingsButtonComponent) return
      
      // Fade out the settings holder and back button first
      this.$refs.SettingsHolder.fadeOut();
      if (this.$refs.BackButton && typeof this.$refs.BackButton.fadeOut === 'function') {
        this.$refs.BackButton.fadeOut();
      }
      
      this.isAnimating = true
      this.animatingButtonId = buttonId
      
      // Get the button data to know its original position
      const buttonData = this.hardwareSettingsStore.buttons.find(btn => btn.id === buttonId)
      if (!buttonData) return
      
      // Animate the parent g element back to original position
      gsap.to(buttonElement, {
        x: buttonData.x,
        y: buttonData.y,
        duration: 0.3,
        ease: "power2.inOut"
      })
      
      // Animate the background rectangle back to original size
      if (settingsButtonComponent.$refs.backgroundRect) {
        gsap.to(settingsButtonComponent.$refs.backgroundRect, {
          width: 400,
          height: 240,
          duration: 0.3,
          ease: "power2.inOut"
        })
        
        // Animate background opacity back to original
        gsap.to(settingsButtonComponent, {
          backgroundOpacity: 0.6,
          duration: 0.3,
          ease: "power2.inOut"
        })
      }
      
      // Animate the diagonal lines background rectangle back to original size
      if (settingsButtonComponent.$refs.diagonalLines && settingsButtonComponent.$refs.diagonalLines.$refs.background) {
        // Stop any existing diagonal lines animations first
        if (settingsButtonComponent.$refs.diagonalLines.stopAnimations) {
          settingsButtonComponent.$refs.diagonalLines.stopAnimations()
        }
        
        gsap.to(settingsButtonComponent.$refs.diagonalLines.$refs.background, {
          width: 400,
          height: 240,
          duration: 0.3,
          ease: "power2.inOut"
        })
        
        // Also animate the diagonal lines container back to original size
        gsap.to(settingsButtonComponent.$refs.diagonalLines, {
          duration: 0.3,
          ease: "power2.inOut",
          onComplete: () => {
            // Restart the diagonal lines animation after size change
            if (settingsButtonComponent.$refs.diagonalLines && settingsButtonComponent.$refs.diagonalLines.startAnimations) {
              settingsButtonComponent.$refs.diagonalLines.startAnimations()
            }
          }
        })
      }
      
      // Complete the main animation immediately
      this.isAnimating = false
      this.animatingButtonId = null
      this.expandedButtonId = null
      
      // Reset pointer events
      this.resetPointerEvents()
      
      // Move the button back to its original position in the DOM
      const parentContainer = buttonElement.parentNode
      if (parentContainer) {
        // Find the position where this button should be in the original order
        const buttonOrder = ['device', 'network', 'midi', 'display']
        const currentIndex = buttonOrder.indexOf(buttonId)
        const targetIndex = currentIndex
        
        // Move the button to the correct position
        const allButtons = Array.from(parentContainer.children).filter(child => 
          child !== this.closeButtonWrapper
        )
        
        if (targetIndex < allButtons.length) {
          parentContainer.insertBefore(buttonElement, allButtons[targetIndex])
        } else {
          parentContainer.appendChild(buttonElement)
        }
      }
      
      // Ensure text is visible and in correct position (it should never move) - with delay
      if (settingsButtonComponent.$refs.textElement) {
        gsap.to(settingsButtonComponent.$refs.textElement, {
          opacity: 1,
          duration: 0.3,
          delay: .25,
          ease: "power2.inOut"
        })
      }
      
      // Animate the close button back to original state
      if (this.closeButtonWrapper) {
        // Find the CloseButton element within the wrapper
        const closeButtonElement = this.closeButtonWrapper.querySelector('g')
        if (closeButtonElement) {
          // Move the CloseButton back to original position (359, 199)
          gsap.to(closeButtonElement, {
            x: 359,
            y: 199,
            duration: 0.3,
            ease: "power2.inOut"
          })
        }
        
        // Resize the black square background back to original
        const closeButtonBg = this.closeButtonWrapper.querySelector('#Rectangle\\ 10')
        if (closeButtonBg) {
          gsap.to(closeButtonBg, {
            width: 82,
            height: 82,
            duration: 0.3,
            ease: "power2.inOut"
          })
        }
        
        // Show the white X icon again
        const xIconPath = this.closeButtonWrapper.querySelector('#Icon')
        if (xIconPath) {
          gsap.to(xIconPath, {
            opacity: 1,
            duration: 0.3,
            ease: "power2.inOut"
          })
        }
      }
    },
    
    resetPointerEvents() {
      // Re-enable pointer events on the main container
      const mainContainer = this.$el
      if (mainContainer) {
        mainContainer.style.pointerEvents = 'auto'
        mainContainer.style.cursor = 'default'
      }
      
      // Re-enable pointer events for all buttons
      Object.values(this.buttonRefs).forEach(ref => {
        if (ref) {
          ref.style.pointerEvents = 'auto'
        }
      })
      
      // Reset the expanded button state
      this.expandedButtonId = null
    },
    
    emitClose() {
      // If there's an expanded button, do nothing - no mouse events should work
      if (this.expandedButtonId) {
        return
      }
      
      this.hardwareSettingsStore.clearHoveredButton()
      this.$emit('close')
    },
    
    handleBack() {
      // Call the animate function to return the expanded button to original state
      this.animateButtonBackToOriginal(this.expandedButtonId)
      // Set navigation mode back to menu when returning
      this.hardwareSettingsStore.setNavigationMode('menu');
    },
    
    handleWheel(event) {
      event.preventDefault();
      event.stopPropagation();
      const mode = this.hardwareSettingsStore.navigationMode;
      
      if (mode === 'modal') {
        return
      }
      
      if (this.hardwareSettingsStore.isSelectFocused) {
        const dir = event.deltaY > 0 ? 1 : -1;
        this.hardwareSettingsStore.updateHighlightedSelectIndex(dir);
        return
      }
      
      if (mode === 'menu') {
        this.cycleCategories(event.deltaY);
      } else if (mode === 'parameters') {
        this.cycleParameters(event.deltaY);
      }
    },
    
    cycleCategories(deltaY) {
      const clockwiseOrder = ['device', 'network', 'midi', 'display', 'close']
      const currentButtonId = this.hardwareSettingsStore.currentSelectedButton
      const currentIndex = clockwiseOrder.indexOf(currentButtonId)
      
      let nextIndex
      if (deltaY > 0) {
        nextIndex = currentIndex === -1 ? 0 : (currentIndex + 1) % clockwiseOrder.length
      } else {
        nextIndex = currentIndex === -1 ? clockwiseOrder.length - 1 : (currentIndex - 1 + clockwiseOrder.length) % clockwiseOrder.length
      }
      
      const nextButton = clockwiseOrder[nextIndex]
      this.hardwareSettingsStore.setHoveredButton(nextButton)
    },
    
    cycleParameters(deltaY) {
      const dir = deltaY > 0 ? 1 : -1;
      const currentIdx = this.hardwareSettingsStore.selectedParameterIndex;
      const paramCount = this.hardwareSettingsStore.currentParameters.length;
      const isBackSelected = this.hardwareSettingsStore.isBackButtonSelected;
      
      if (isBackSelected) {
        if (dir < 0) {
          this.hardwareSettingsStore.setBackButtonSelected(false);
          this.hardwareSettingsStore.setSelectedParameterIndex(paramCount - 1);
        }
      } else {
        const newIdx = currentIdx + dir;
        if (newIdx >= 0 && newIdx < paramCount) {
          this.hardwareSettingsStore.setSelectedParameterIndex(newIdx);
        } else if (newIdx >= paramCount && dir > 0) {
          this.hardwareSettingsStore.setBackButtonSelected(true);
          this.hardwareSettingsStore.setSelectedParameterIndex(paramCount - 1);
        }
      }
    },
    
    handleMouseDown(event) {
      const mode = this.hardwareSettingsStore.navigationMode
      
      if (mode === 'modal') {
        return
      }
      
      if (event.button === 1) {
        event.preventDefault()
        
        if (mode === 'parameters') {
          if (this.hardwareSettingsStore.isBackButtonSelected) {
            this.handleBack()
            return
          }
          
          const currentParams = this.hardwareSettingsStore.currentParameters
          const currentIndex = this.hardwareSettingsStore.selectedParameterIndex
          
          if (currentIndex >= 0 && currentIndex < currentParams.length) {
            const currentParam = currentParams[currentIndex]
            this.handleParameterInteraction(currentParam)
          }
          return
        }
        
        if (mode === 'menu' && !this.expandedButtonId) {
          const currentButtonId = this.hardwareSettingsStore.currentSelectedButton
          
          if (currentButtonId === 'close') {
            this.emitClose()
          } else if (currentButtonId) {
            this.handleButtonClick(currentButtonId)
          }
        }
        
        return
      }
      
      if (this.expandedButtonId) {
        event.preventDefault()
        return
      }
    },
    
    handleParameterInteraction(parameter) {
      console.log('[SETTINGS MENU] handleParameterInteraction called with:', parameter)
      
      // Check if we're in select focus mode
      if (this.hardwareSettingsStore.isSelectFocused) {
        // Already in focus mode - confirm selection and exit
        this.hardwareSettingsStore.confirmSelectSelection()
      } else {
        if (parameter.type === 'select') {
          // Enter focus mode for this select parameter
          this.hardwareSettingsStore.setSelectFocusMode(true, parameter.id)
        } else if (parameter.type === 'toggle') {
          // Toggle the parameter value
          parameter.value = !parameter.value
        } else if (parameter.type === 'update_panel') {
          console.log('[SETTINGS MENU] Update panel type detected, showing panel')
          this.showUpdatePanel = true
        } else if (parameter.type === 'button') {
          console.log('[SETTINGS MENU] Button type detected:', parameter.id)
          // Handle other button types in the future
        }
      }
    }
  },
  
  mounted() {
    // Start the animation sequence when the component mounts
    this.$nextTick(() => {
      this.animateButtonsIn()
      // Ensure device is selected when menu opens
      this.hardwareSettingsStore.setHoveredButton('device')
    })
  }
}
</script> 