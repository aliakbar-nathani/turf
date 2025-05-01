document.addEventListener('DOMContentLoaded', function() {
  console.log("Negotiation.js loaded");
  
  // Get elements
  const priceSlider = document.getElementById('counter-slider');
  const priceInput = document.getElementById('proposed_price');
  const savingsEl = document.getElementById('savings');
  const actionInput = document.getElementById('action');
  const negotiationForm = document.getElementById('negotiation-form');
  const maxPriceEl = document.getElementById('max-price');
  const minPriceEl = document.getElementById('min-price');
  
  // Debug which elements were found
  console.log("Elements found:", {
    priceSlider: !!priceSlider,
    priceInput: !!priceInput,
    savingsEl: !!savingsEl,
    actionInput: !!actionInput,
    negotiationForm: !!negotiationForm
  });
  
  if (priceSlider && priceInput) {
    console.log("Initializing slider interaction");
    
    // Get original price
    let originalPrice = parseFloat(priceSlider.getAttribute('max'));
    let minPrice = parseFloat(priceSlider.getAttribute('min'));
    
    console.log("Price range:", { originalPrice, minPrice });
    
    // Initialize price input if empty
    if (!priceInput.value) {
      priceInput.value = originalPrice.toFixed(2);
    }
    
    // Initialize slider to match input
    priceSlider.value = priceInput.value;
    
    // Update input when slider changes
    priceSlider.addEventListener('input', function() {
      console.log("Slider changed:", this.value);
      priceInput.value = parseFloat(this.value).toFixed(2);
      updateSavings();
    });
    
    // Update slider when input changes
    priceInput.addEventListener('input', function() {
      console.log("Input changed:", this.value);
      let value = parseFloat(this.value);
      
      if (!isNaN(value)) {
        // Keep within range
        value = Math.max(minPrice, Math.min(originalPrice, value));
        this.value = value.toFixed(2);
        priceSlider.value = value;
        updateSavings();
      }
    });
    
    // Calculate savings
    function updateSavings() {
      if (savingsEl) {
        const currentPrice = parseFloat(priceInput.value);
        if (!isNaN(currentPrice)) {
          const savings = originalPrice - currentPrice;
          const savingsPercent = (savings / originalPrice) * 100;
          
          savingsEl.textContent = `Save ₹${savings.toFixed(2)} (${savingsPercent.toFixed(1)}%)`;
          
          // Update color based on savings amount
          if (savingsPercent >= 20) {
            savingsEl.className = 'text-danger fw-bold';
          } else if (savingsPercent >= 10) {
            savingsEl.className = 'text-warning fw-bold';
          } else if (savingsPercent > 0) {
            savingsEl.className = 'text-success';
          } else {
            savingsEl.className = 'text-muted';
          }
        }
      }
    }
    
    // Initialize savings display
    updateSavings();
  }
  
  // Handle form submission actions
  if (negotiationForm && actionInput) {
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
        
        // Validate price
        const price = parseFloat(priceInput.value);
        if (isNaN(price) || price <= 0) {
          alert('Please enter a valid price.');
          return;
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
        
        if (confirm('Are you sure you want to cancel this booking?')) {
          actionInput.value = 'cancel';
          negotiationForm.submit();
        }
      });
    }
  }
});