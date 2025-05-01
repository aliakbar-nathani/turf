document.addEventListener('DOMContentLoaded', function() {
  try {
    // Elements for negotiation
    const priceSlider = document.getElementById('counter-slider');
    const counterPriceInput = document.getElementById('proposed_price');
    const savingsEl = document.getElementById('savings');
    const actionInput = document.getElementById('action');
    const negotiationForm = document.getElementById('negotiation-form');
    const maxPriceEl = document.getElementById('max-price');
    const minPriceEl = document.getElementById('min-price');
    
    // If negotiation form elements exist
    if (priceSlider && counterPriceInput) {
      // Parse the original price safely
      let originalPrice = parseFloat(priceSlider.max);
      let minPrice = parseFloat(priceSlider.min);
      
      // Fallback if we can't get values from the elements
      if (isNaN(originalPrice) || originalPrice <= 0) {
        // Try to extract from the max-price element
        if (maxPriceEl) {
          const priceText = maxPriceEl.textContent.replace(/[^0-9.]/g, '');
          originalPrice = parseFloat(priceText);
        }
        if (isNaN(originalPrice) || originalPrice <= 0) {
          originalPrice = 1000; // Fallback default
          console.warn("Using fallback original price");
        }
      }
      
      if (isNaN(minPrice) || minPrice <= 0) {
        // Try to extract from the min-price element
        if (minPriceEl) {
          const priceText = minPriceEl.textContent.replace(/[^0-9.]/g, '');
          minPrice = parseFloat(priceText);
        }
        if (isNaN(minPrice) || minPrice <= 0) {
          minPrice = originalPrice * 0.7; // Fallback to 70% of original
          console.warn("Using fallback min price");
        }
      }
      
      console.log("Negotiation slider setup with prices:", {originalPrice, minPrice});
      
      // Initialize counter price input if empty
      if (!counterPriceInput.value) {
        counterPriceInput.value = originalPrice.toFixed(2);
      }
      
      // Update counter price input when slider changes
      priceSlider.addEventListener('input', function() {
        const value = parseFloat(this.value);
        if (!isNaN(value)) {
          counterPriceInput.value = value.toFixed(2);
          updateSavingsText();
        }
      });
      
      // Update slider when counter price input changes
      counterPriceInput.addEventListener('input', function() {
        let value = parseFloat(this.value);
        
        if (isNaN(value)) {
          value = originalPrice;
        } else {
          // Keep within min/max range
          value = Math.max(minPrice, Math.min(originalPrice, value));
        }
        
        this.value = value.toFixed(2);
        priceSlider.value = value;
        
        updateSavingsText();
      });
      
      // Update savings text
      function updateSavingsText() {
        if (savingsEl) {
          try {
            const proposed = parseFloat(counterPriceInput.value);
            if (isNaN(proposed)) return;
            
            const savings = originalPrice - proposed;
            const percentSavings = (savings / originalPrice) * 100;
            
            savingsEl.textContent = `Save ₹${savings.toFixed(2)} (${percentSavings.toFixed(1)}%)`;
            
            // Update color based on savings
            if (percentSavings > 20) {
              savingsEl.className = 'text-danger fw-bold';
            } else if (percentSavings > 10) {
              savingsEl.className = 'text-warning fw-bold';
            } else if (percentSavings > 0) {
              savingsEl.className = 'text-success';
            } else {
              savingsEl.className = 'text-muted';
            }
          } catch (e) {
            console.error("Error updating savings text:", e);
          }
        }
      }
      
      // Initial update
      updateSavingsText();
      
      // Handle form submission for different actions
      if (negotiationForm) {
        // Accept button
        const acceptBtn = document.getElementById('accept-btn');
        if (acceptBtn) {
          acceptBtn.addEventListener('click', function(e) {
            e.preventDefault();
            actionInput.value = 'accept';
            negotiationForm.submit();
          });
        }
        
        // Counter offer button
        const counterBtn = document.getElementById('counter-btn');
        if (counterBtn) {
          counterBtn.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Validate counter price
            const counterPrice = parseFloat(counterPriceInput.value);
            if (isNaN(counterPrice) || counterPrice <= 0) {
              alert('Please enter a valid counter price.');
              return;
            }
            
            // Check if price was changed
            if (Math.abs(counterPrice - originalPrice) < 0.01) {
              if (!confirm('Your counter offer is the same as the original price. Do you want to continue?')) {
                return;
              }
            }
            
            actionInput.value = 'counter';
            negotiationForm.submit();
          });
        }
        
        // Cancel button
        const cancelBtn = document.getElementById('cancel-btn');
        if (cancelBtn) {
          cancelBtn.addEventListener('click', function(e) {
            e.preventDefault();
            
            if (confirm('Are you sure you want to cancel this negotiation?')) {
              actionInput.value = 'cancel';
              negotiationForm.submit();
            }
          });
        }
      }
    }
    
    // Timeline visualization for negotiations
    const timeline = document.querySelector('.negotiation-timeline');
    if (timeline) {
      const items = timeline.querySelectorAll('.timeline-item');
      
      // Animate timeline items on load
      items.forEach((item, index) => {
        setTimeout(() => {
          item.classList.add('visible');
        }, 100 * index);
      });
    }
  } catch (e) {
    console.error("Error in negotiation.js:", e);
  }
});
