document.addEventListener('DOMContentLoaded', function() {
  // Check for notification count updates
  if (document.getElementById('notification-count')) {
    updateNotificationCount();
    // Update every 30 seconds
    setInterval(updateNotificationCount, 30000);
  }
  
  // Enable Bootstrap tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  const tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });
  
  // Enable Bootstrap popovers
  const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
  const popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl);
  });
  
  // Handle responsive navigation
  const navToggler = document.querySelector('.navbar-toggler');
  if (navToggler) {
    navToggler.addEventListener('click', function() {
      const navbarMenu = document.querySelector('#navbarNav');
      navbarMenu.classList.toggle('show');
    });
  }
  
  // Flash message auto-dismiss
  const flashMessages = document.querySelectorAll('.alert.alert-dismissible');
  flashMessages.forEach(function(flash) {
    setTimeout(function() {
      const dismissBtn = flash.querySelector('.btn-close');
      if (dismissBtn) {
        dismissBtn.click();
      }
    }, 5000);
  });
  
  // Handle price negotiation slider if present
  const priceSlider = document.getElementById('priceSlider');
  const proposedPriceInput = document.getElementById('proposed_price');
  
  if (priceSlider && proposedPriceInput) {
    const originalPrice = parseFloat(document.getElementById('original_price').value);
    const minPrice = originalPrice * 0.7; // Allow negotiation down to 70% of original price
    
    priceSlider.min = minPrice.toFixed(2);
    priceSlider.max = originalPrice.toFixed(2);
    priceSlider.value = originalPrice.toFixed(2);
    proposedPriceInput.value = originalPrice.toFixed(2);
    
    // Update proposed price when slider changes
    priceSlider.addEventListener('input', function() {
      proposedPriceInput.value = parseFloat(this.value).toFixed(2);
      updateSavingsText();
    });
    
    // Update slider when input changes
    proposedPriceInput.addEventListener('input', function() {
      let value = parseFloat(this.value);
      if (isNaN(value)) value = originalPrice;
      
      value = Math.max(minPrice, Math.min(originalPrice, value));
      this.value = value.toFixed(2);
      priceSlider.value = value;
      updateSavingsText();
    });
    
    function updateSavingsText() {
      const savingsEl = document.getElementById('savings');
      if (savingsEl) {
        const proposed = parseFloat(proposedPriceInput.value);
        const savings = originalPrice - proposed;
        const percentSavings = (savings / originalPrice) * 100;
        
        savingsEl.textContent = `Save ₹${savings.toFixed(2)} (${percentSavings.toFixed(1)}%)`;
        
        // Color code the savings
        if (percentSavings > 15) {
          savingsEl.className = 'text-danger';
        } else if (percentSavings > 5) {
          savingsEl.className = 'text-warning';
        } else {
          savingsEl.className = 'text-success';
        }
      }
    }
    
    // Initial update
    updateSavingsText();
  }
});

// Function to toggle booking actions menu
function toggleBookingActions(id) {
  const menu = document.getElementById(`booking-actions-${id}`);
  if (menu) {
    menu.classList.toggle('show');
  }
}

// Function to confirm delete/cancel operations
function confirmAction(message) {
  return confirm(message);
}

// Date picker initialization with Flatpickr
function initDatePicker() {
  // Initialize all date pickers with datepicker-modern class
  const modernDatePickers = document.querySelectorAll('.datepicker-modern');
  if (modernDatePickers.length > 0) {
    modernDatePickers.forEach(picker => {
      flatpickr(picker, {
        dateFormat: "Y-m-d",
        minDate: "today",
        maxDate: new Date().fp_incr(30), // 30 days from now
        altInput: true,
        altFormat: "F j, Y", // More readable format (e.g., "January 1, 2023")
        disableMobile: false
      });
    });
  }
  
  // Initialize all date pickers with flatpickr-date class
  const flatpickrDatePickers = document.querySelectorAll('.flatpickr-date');
  if (flatpickrDatePickers.length > 0) {
    flatpickrDatePickers.forEach(picker => {
      if (!picker._flatpickr) { // Only initialize if not already initialized
        flatpickr(picker, {
          dateFormat: "Y-m-d",
          minDate: "today",
          maxDate: new Date().fp_incr(30), // 30 days from now
          altInput: true,
          altFormat: "F j, Y", // More readable format (e.g., "January 1, 2023")
          disableMobile: false
        });
      }
    });
  }
}

// Initialize date pickers
document.addEventListener('DOMContentLoaded', function() {
  initDatePicker();
});

// Function to update notification count in the navbar
function updateNotificationCount() {
  fetch('/notifications/api/count')
    .then(response => response.json())
    .then(data => {
      const notificationBadge = document.getElementById('notification-count');
      if (notificationBadge) {
        if (data.count > 0) {
          notificationBadge.textContent = data.count;
          notificationBadge.classList.remove('d-none');
        } else {
          notificationBadge.classList.add('d-none');
        }
      }
    })
    .catch(error => {
      console.error('Error fetching notification count:', error);
    });
}
