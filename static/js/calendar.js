document.addEventListener('DOMContentLoaded', function() {
  // Get turf ID from the data attribute on the calendar container
  const calendarEl = document.getElementById('availability-calendar');
  if (!calendarEl) return;
  
  const turfId = calendarEl.dataset.turfId;
  if (!turfId) return;
  
  // Initialize the calendar
  const calendar = new FullCalendar.Calendar(calendarEl, {
    initialView: 'dayGridMonth',
    headerToolbar: {
      left: 'prev,next today',
      center: 'title',
      right: 'dayGridMonth,timeGridWeek'
    },
    selectable: true,
    select: function(info) {
      // Format date as YYYY-MM-DD for API call
      const selectedDate = info.start.toISOString().split('T')[0];
      loadAvailableSlots(turfId, selectedDate);
      
      // Update the booking form date if it exists
      const bookingDateSelect = document.getElementById('booking_date');
      if (bookingDateSelect) {
        for (let i = 0; i < bookingDateSelect.options.length; i++) {
          if (bookingDateSelect.options[i].value === selectedDate) {
            bookingDateSelect.selectedIndex = i;
            bookingDateSelect.dispatchEvent(new Event('change'));
            break;
          }
        }
      }
    },
    eventClick: function(info) {
      // Show event details
      const startTime = info.event.start.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
      const endTime = info.event.end.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
      
      // Select this time slot in the form if it exists
      const timeSlotSelect = document.getElementById('time_slot');
      if (timeSlotSelect) {
        const slotId = info.event.id;
        timeSlotSelect.value = slotId;
        timeSlotSelect.dispatchEvent(new Event('change'));
      }
      
      // Show selection in UI
      const allEvents = document.querySelectorAll('.fc-event');
      allEvents.forEach(el => el.classList.remove('selected-slot'));
      info.el.classList.add('selected-slot');
    },
    eventContent: function(arg) {
      const timeText = arg.event.start.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) + 
                       ' - ' + 
                       arg.event.end.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
      
      return {
        html: `
          <div class="fc-event-time">${timeText}</div>
          <div class="fc-event-price">₹${arg.event.extendedProps.price}</div>
        `
      };
    }
  });
  
  calendar.render();
  
  // Load slots for the current day on initial load
  const today = new Date().toISOString().split('T')[0];
  loadAvailableSlots(turfId, today);
  
  // Handle booking date change in the form
  const bookingDateSelect = document.getElementById('booking_date');
  if (bookingDateSelect) {
    bookingDateSelect.addEventListener('change', function() {
      const selectedDate = this.value;
      loadAvailableSlots(turfId, selectedDate);
      
      // Update calendar view
      const date = new Date(selectedDate);
      calendar.gotoDate(date);
    });
  }
  
  // Function to load available slots from the API
  function loadAvailableSlots(turfId, date) {
    const url = `/bookings/turfs/${turfId}/availability?date=${date}`;
    const slotsContainer = document.getElementById('available-slots');
    const timeSlotSelect = document.getElementById('time_slot');
    
    // Show loading indicator
    if (slotsContainer) {
      slotsContainer.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>';
    }
    
    // Clear existing events
    calendar.removeAllEvents();
    
    fetch(url)
      .then(response => response.json())
      .then(data => {
        if (data.error) {
          console.error('Error loading slots:', data.error);
          if (slotsContainer) {
            slotsContainer.innerHTML = `<div class="alert alert-danger">${data.error}</div>`;
          }
          return;
        }
        
        // Process available slots
        const slots = data.slots || [];
        
        if (slots.length === 0) {
          if (slotsContainer) {
            slotsContainer.innerHTML = '<div class="alert alert-info">No available slots for this date.</div>';
          }
          
          // Clear time slot select options
          if (timeSlotSelect) {
            timeSlotSelect.innerHTML = '<option value="">No slots available</option>';
            timeSlotSelect.disabled = true;
          }
          
          return;
        }
        
        // Populate select options if form exists
        if (timeSlotSelect) {
          timeSlotSelect.innerHTML = '<option value="">Select a time slot</option>';
          timeSlotSelect.disabled = false;
          
          slots.forEach(slot => {
            const option = document.createElement('option');
            option.value = slot.id;
            option.textContent = `${slot.start_time} - ${slot.end_time} (₹${slot.price})`;
            option.dataset.price = slot.price;
            timeSlotSelect.appendChild(option);
          });
          
          // Add change handler to update price
          timeSlotSelect.addEventListener('change', updateBookingPrice);
        }
        
        // Render slots in calendar
        slots.forEach(slot => {
          const dateObj = new Date(date);
          const startParts = slot.start_time.split(':');
          const endParts = slot.end_time.split(':');
          
          const startDate = new Date(dateObj);
          startDate.setHours(parseInt(startParts[0], 10), parseInt(startParts[1], 10));
          
          const endDate = new Date(dateObj);
          endDate.setHours(parseInt(endParts[0], 10), parseInt(endParts[1], 10));
          
          calendar.addEvent({
            id: slot.id,
            title: `₹${slot.price}`,
            start: startDate,
            end: endDate,
            extendedProps: {
              price: slot.price
            },
            backgroundColor: '#28a745',
            borderColor: '#28a745'
          });
        });
        
        // Display slots in container if it exists
        if (slotsContainer) {
          let html = '<div class="list-group">';
          slots.forEach(slot => {
            html += `
              <a href="#" class="list-group-item list-group-item-action slot-item" data-slot-id="${slot.id}">
                <div class="d-flex w-100 justify-content-between">
                  <h5 class="mb-1">${slot.start_time} - ${slot.end_time}</h5>
                  <span class="badge bg-success">₹${slot.price}</span>
                </div>
              </a>
            `;
          });
          html += '</div>';
          slotsContainer.innerHTML = html;
          
          // Add click handlers for slot items
          const slotItems = document.querySelectorAll('.slot-item');
          slotItems.forEach(item => {
            item.addEventListener('click', function(e) {
              e.preventDefault();
              const slotId = this.dataset.slotId;
              
              // Update select if it exists
              if (timeSlotSelect) {
                timeSlotSelect.value = slotId;
                timeSlotSelect.dispatchEvent(new Event('change'));
              }
              
              // Update UI
              slotItems.forEach(el => el.classList.remove('active'));
              this.classList.add('active');
            });
          });
        }
      })
      .catch(error => {
        console.error('Error fetching available slots:', error);
        if (slotsContainer) {
          slotsContainer.innerHTML = '<div class="alert alert-danger">Failed to load available slots. Please try again.</div>';
        }
      });
  }
  
  // Function to update booking price when time slot changes
  function updateBookingPrice() {
    const timeSlotSelect = document.getElementById('time_slot');
    const originalPriceEl = document.getElementById('original_price');
    const proposedPriceEl = document.getElementById('proposed_price');
    const priceSliderEl = document.getElementById('priceSlider');
    const totalPriceEl = document.getElementById('total-price');
    const minPriceEl = document.getElementById('min-price');
    const maxPriceEl = document.getElementById('max-price');
    
    if (timeSlotSelect && timeSlotSelect.selectedIndex > 0) {
      const selectedOption = timeSlotSelect.options[timeSlotSelect.selectedIndex];
      const price = parseFloat(selectedOption.dataset.price);
      const minPrice = price * 0.7; // Allow up to 30% discount
      
      // Update displayed price
      if (totalPriceEl) {
        totalPriceEl.textContent = `₹${price.toFixed(2)}`;
      }
      
      // Update negotiation elements if they exist
      if (originalPriceEl) {
        originalPriceEl.value = price.toFixed(2);
      }
      
      if (proposedPriceEl) {
        // Only update proposed price if the user hasn't checked the negotiation toggle
        // or if it's equal to the previous original price (not manually changed)
        const negotiationToggle = document.getElementById('negotiation-toggle');
        if (!negotiationToggle || !negotiationToggle.checked) {
          proposedPriceEl.value = price.toFixed(2);
        }
      }
      
      if (priceSliderEl) {
        priceSliderEl.max = price.toFixed(2);
        priceSliderEl.min = minPrice.toFixed(2);
        priceSliderEl.value = price.toFixed(2);
        
        // Update price range labels
        if (minPriceEl) {
          minPriceEl.textContent = `Min: ₹${minPrice.toFixed(2)}`;
        }
        
        if (maxPriceEl) {
          maxPriceEl.textContent = `Max: ₹${price.toFixed(2)}`;
        }
      }
      
      // Update savings text if present
      const savingsEl = document.getElementById('savings');
      if (savingsEl && proposedPriceEl) {
        const proposedPrice = parseFloat(proposedPriceEl.value);
        if (!isNaN(proposedPrice)) {
          const savings = price - proposedPrice;
          const savingsPercent = (savings / price * 100).toFixed(1);
          savingsEl.textContent = `Save ₹${savings.toFixed(2)} (${savingsPercent}%)`;
          
          // Update color based on savings
          if (savings > 0) {
            savingsEl.className = 'text-success';
          } else {
            savingsEl.className = 'text-danger';
          }
        }
      }
    }
  }
});
