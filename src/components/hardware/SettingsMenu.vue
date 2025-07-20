<template>
  <g @wheel="handleWheel" @mousedown="handleMouseDown">
        <!-- 2x2 Grid of Settings Buttons -->
    <g 
      v-for="(btn, idx) in hardwareSettingsStore.buttons" 
      :key="btn.id" 
      :ref="el => setButtonRef(el, btn.id)"
      :transform="`translate(${btn.x}, ${btn.y})`"
      @mouseenter="handleMouseEnter(btn.id)"
      @mouseleave="handleMouseLeave"
      style="opacity: 0; pointer-events: auto;"
    >
      <SettingsButton 
        :label="btn.label"
        :button-id="btn.id"
        :is-selected="isButtonSelected(btn.id)"
        :is-animating="isAnimating"
        :expanded-button-id="expandedButtonId"
        @click="handleButtonClick(btn.id)"
        :ref="el => setSettingsButtonRef(el, btn.id)"
      />
    </g>
    
        <!-- Close Button -->
    <g :ref="el => closeButtonWrapper = el" style="opacity: 0; pointer-events: auto;">
      <CloseButton 
        :is-selected="isButtonSelected('close')"
        :is-expanded="isAnimating"
        @close="emitClose"
        @mouseenter="handleMouseEnter('close')"
        @mouseleave="handleMouseLeave"
      />
    </g>
 
      <SettingsHolder ref="SettingsHolder" />
      <BackButton 
        ref="BackButton" 
        :is-selected="hardwareSettingsStore.isBackButtonSelected"
        @back="handleBack" 
      />
  
    
  </g>
</template>

<script>
import SettingsButton from './SettingsButton.vue'
import CloseButton from './CloseButton.vue'
import BackButton from './settings/BackButton.vue'
import SettingsHolder from './settings/SettingsHolder.vue'
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
    SettingsHolder
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
      expandedButtonId: null
    }
  },
  methods: {
    handleMouseEnter(buttonId) {
      // Don't set hover state for any button when animation is active, if it's the expanded button, or if any button is expanded
      if (this.isAnimating || buttonId === this.expandedButtonId || this.expandedButtonId) {
        return
      }
      this.hardwareSettingsStore.setHoveredButton(buttonId)
    },
    
    handleMouseLeave() {
      // Don't clear hover state if we're animating or have an expanded button
      if (this.isAnimating || this.expandedButtonId) {
        return
      }
      this.hardwareSettingsStore.clearHoveredButton()
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
      // If there's an expanded button, do nothing - no mouse events should work
      if (this.expandedButtonId) {
        return
      }
      
      if (this.isAnimating) return // Prevent multiple animations
      
      // Set the current selected button in the store
      console.log('SettingsMenu: Setting selected button to:', buttonId)
      this.hardwareSettingsStore.setHoveredButton(buttonId)
      console.log('SettingsMenu: Current selected button is now:', this.hardwareSettingsStore.currentSelectedButton)
      
      this.isAnimating = true
      this.animatingButtonId = buttonId
      this.animateButtonToFullScreen(buttonId)
      // Set navigation mode to parameters when a category is expanded
      this.hardwareSettingsStore.setNavigationMode('parameters');
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
            console.log('SettingsMenu: Calling fadeIn on SettingsHolder')
            console.log('SettingsMenu: SettingsHolder ref:', this.$refs.SettingsHolder)
            if (this.$refs.SettingsHolder && typeof this.$refs.SettingsHolder.fadeIn === 'function') {
              this.$refs.SettingsHolder.fadeIn();
            } else {
              console.error('SettingsMenu: SettingsHolder ref or fadeIn method not found')
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
      console.log('SettingsMenu: handleBack called')
      console.log('SettingsMenu: expandedButtonId:', this.expandedButtonId)
      
      // If there's an expanded button, do nothing - no mouse events should work
      // if (this.expandedButtonId) {
      //   return
      // }
      
      // Call the animate function to return the expanded button to original state
      this.animateButtonBackToOriginal(this.expandedButtonId)
      // Set navigation mode back to menu when returning
      this.hardwareSettingsStore.setNavigationMode('menu');
    },
    
    handleWheel(event) {
      event.preventDefault();
      const mode = this.hardwareSettingsStore.navigationMode;
      if (mode === 'menu') {
        this.cycleCategories(event.deltaY);
      } else if (mode === 'parameters') {
        this.cycleParameters(event.deltaY);
      }
    },
    cycleCategories(deltaY) {
      // Define clockwise order: device → network → midi → display → close → device...
      const clockwiseOrder = ['device', 'network', 'midi', 'display', 'close']
      const currentButtonId = this.hardwareSettingsStore.currentSelectedButton
      const currentIndex = clockwiseOrder.indexOf(currentButtonId)
      
      let nextIndex
      if (deltaY > 0) {
        // Scroll down - move clockwise
        nextIndex = currentIndex === -1 ? 0 : (currentIndex + 1) % clockwiseOrder.length
      } else {
        // Scroll up - move counter-clockwise
        nextIndex = currentIndex === -1 ? clockwiseOrder.length - 1 : (currentIndex - 1 + clockwiseOrder.length) % clockwiseOrder.length
      }
      
      const nextButton = clockwiseOrder[nextIndex]
      
      // Set the new selected button
      this.hardwareSettingsStore.setHoveredButton(nextButton)
    },
    cycleParameters(deltaY) {
      const dir = deltaY > 0 ? 1 : -1;
      const currentIdx = this.hardwareSettingsStore.selectedParameterIndex;
      const paramCount = this.hardwareSettingsStore.currentParameters.length;
      const isBackSelected = this.hardwareSettingsStore.isBackButtonSelected;
      
      console.log('SettingsMenu: cycleParameters - currentIdx:', currentIdx, 'paramCount:', paramCount, 'isBackSelected:', isBackSelected, 'dir:', dir)
      
      if (isBackSelected) {
        // Currently on back button
        if (dir < 0) {
          // Scroll up: go to last parameter
          console.log('SettingsMenu: going from back button to last parameter')
          this.hardwareSettingsStore.setBackButtonSelected(false);
          this.hardwareSettingsStore.setSelectedParameterIndex(paramCount - 1);
        }
        // Scroll down: stay on back button (do nothing)
      } else {
        // Currently on a parameter
        const newIdx = currentIdx + dir;
        console.log('SettingsMenu: newIdx would be:', newIdx)
        if (newIdx >= 0 && newIdx < paramCount) {
          // Valid parameter index
          console.log('SettingsMenu: setting selectedParameterIndex to:', newIdx)
          this.hardwareSettingsStore.setSelectedParameterIndex(newIdx);
        } else if (newIdx >= paramCount && dir > 0) {
          // Scrolled past last parameter: select back button
          console.log('SettingsMenu: selecting back button, setting selectedParameterIndex to:', paramCount - 1)
          this.hardwareSettingsStore.setBackButtonSelected(true);
          // Keep the marker at the last parameter position
          this.hardwareSettingsStore.setSelectedParameterIndex(paramCount - 1);
        }
        // Scrolled before first parameter: do nothing (stay at 0)
      }
    },
    handleMouseDown(event) {
      // If there's an expanded button, do nothing - no mouse events should work
      if (this.expandedButtonId) {
        event.preventDefault()
        return
      }
      
      // Check if it's a middle mouse click (button 1)
      if (event.button === 1) {
        event.preventDefault()
        
        // Get the currently selected button
        const currentButtonId = this.hardwareSettingsStore.currentSelectedButton
        
        // Don't trigger animation for the close button
        if (currentButtonId !== 'close') {
          this.handleButtonClick(currentButtonId)
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