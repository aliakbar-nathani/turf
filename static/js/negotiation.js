document.addEventListener('DOMContentLoaded', function() {
  // Elements for negotiation
  const priceSlider = document.getElementById('counter-slider');
  const counterPriceInput = document.getElementById('proposed_price');
  const originalPriceEl = document.getElementById('original-price');
  const savingsEl = document.getElementById('savings');
  const actionInput = document.getElementById('action');
  const negotiationForm = document.getElementById('negotiation-form');
  
  // If negotiation form elements exist
  if (priceSlider && counterPriceInput && originalPriceEl) {
    const originalPrice = parseFloat(originalPriceEl.dataset.price);
    const minPrice = originalPrice * 0.7; // Limit to 70% of original price
    
    // Initialize slider
    priceSlider.min = minPrice.toFixed(2);
    priceSlider.max = originalPrice.toFixed(2);
    priceSlider.value = originalPrice.toFixed(2);
    counterPriceInput.value = originalPrice.toFixed(2);
    
    // Update counter price input when slider changes
    priceSlider.addEventListener('input', function() {
      counterPriceInput.value = parseFloat(this.value).toFixed(2);
      updateSavingsText();
    });
    
    // Update slider when counter price input changes
    counterPriceInput.addEventListener('input', function() {
      let value = parseFloat(this.value);
      if (isNaN(value)) value = originalPrice;
      
      // Keep within min/max range
      value = Math.max(minPrice, Math.min(originalPrice, value));
      this.value = value.toFixed(2);
      priceSlider.value = value;
      
      updateSavingsText();
    });
    
    // Update savings text
    function updateSavingsText() {
      if (savingsEl) {
        const proposed = parseFloat(counterPriceInput.value);
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
          if (counterPrice === originalPrice) {
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
});
