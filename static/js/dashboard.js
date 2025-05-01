document.addEventListener('DOMContentLoaded', function() {
  // Owner Dashboard Charts
  const revenueChartEl = document.getElementById('revenue-chart');
  const bookingsTrendEl = document.getElementById('bookings-trend');
  const weeklyDistributionEl = document.getElementById('weekly-distribution');
  
  // Admin Dashboard Charts
  const userRegistrationChartEl = document.getElementById('user-registration-chart');
  const bookingsByStatusEl = document.getElementById('bookings-by-status');

  // Render owner dashboard charts if elements exist
  if (revenueChartEl) {
    renderRevenueChart(revenueChartEl);
  }
  
  if (bookingsTrendEl && typeof chartData !== 'undefined') {
    renderBookingsTrendChart(bookingsTrendEl, chartData);
  }
  
  if (weeklyDistributionEl && typeof chartData !== 'undefined') {
    renderWeeklyDistributionChart(weeklyDistributionEl, chartData);
  }
  
  // Render admin dashboard charts if elements exist
  if (userRegistrationChartEl && typeof chartData !== 'undefined') {
    renderUserRegistrationChart(userRegistrationChartEl, chartData);
  }
  
  if (bookingsByStatusEl) {
    renderBookingsByStatusChart(bookingsByStatusEl);
  }

  // Handle turf selection change in owner analytics
  const turfSelect = document.getElementById('turf-select');
  if (turfSelect) {
    turfSelect.addEventListener('change', function() {
      window.location.href = `/owner/analytics?turf_id=${this.value}`;
    });
  }
});

// Chart rendering functions

function renderRevenueChart(canvas) {
  // Mock data - in a real app, this would be passed from the server
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  const revenue = [5000, 7000, 6500, 8000, 9500, 12000];
  
  new Chart(canvas, {
    type: 'line',
    data: {
      labels: months,
      datasets: [{
        label: 'Revenue (₹)',
        data: revenue,
        borderColor: '#2e86de',
        backgroundColor: 'rgba(46, 134, 222, 0.1)',
        borderWidth: 2,
        tension: 0.3,
        fill: true
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        tooltip: {
          callbacks: {
            label: function(context) {
              return '₹' + context.parsed.y.toLocaleString();
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            callback: function(value) {
              return '₹' + value.toLocaleString();
            }
          }
        }
      }
    }
  });
}

function renderBookingsTrendChart(canvas, data) {
  new Chart(canvas, {
    type: 'line',
    data: {
      labels: data.dates,
      datasets: [{
        label: 'Bookings',
        data: data.counts,
        borderColor: '#27ae60',
        backgroundColor: 'rgba(39, 174, 96, 0.1)',
        borderWidth: 2,
        tension: 0.2,
        fill: true
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            precision: 0
          }
        }
      }
    }
  });
}

function renderWeeklyDistributionChart(canvas, data) {
  new Chart(canvas, {
    type: 'bar',
    data: {
      labels: data.weekly_labels,
      datasets: [{
        label: 'Bookings',
        data: data.weekly_data,
        backgroundColor: [
          'rgba(52, 152, 219, 0.7)',
          'rgba(46, 204, 113, 0.7)',
          'rgba(155, 89, 182, 0.7)',
          'rgba(230, 126, 34, 0.7)',
          'rgba(241, 196, 15, 0.7)',
          'rgba(231, 76, 60, 0.7)',
          'rgba(149, 165, 166, 0.7)'
        ],
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            precision: 0
          }
        }
      }
    }
  });
}

function renderUserRegistrationChart(canvas, data) {
  new Chart(canvas, {
    type: 'line',
    data: {
      labels: data.dates,
      datasets: [
        {
          label: 'Players',
          data: data.user_counts,
          borderColor: '#3498db',
          backgroundColor: 'rgba(52, 152, 219, 0.1)',
          borderWidth: 2,
          tension: 0.3,
          fill: true
        },
        {
          label: 'Turf Owners',
          data: data.owner_counts,
          borderColor: '#e74c3c',
          backgroundColor: 'rgba(231, 76, 60, 0.1)',
          borderWidth: 2,
          tension: 0.3,
          fill: true
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            precision: 0
          }
        }
      }
    }
  });
}

function renderBookingsByStatusChart(canvas) {
  // Mock data - in a real app, this would be passed from the server
  new Chart(canvas, {
    type: 'doughnut',
    data: {
      labels: ['Confirmed', 'Pending', 'Cancelled', 'Completed'],
      datasets: [{
        data: [65, 20, 10, 35],
        backgroundColor: [
          'rgba(46, 204, 113, 0.7)',
          'rgba(241, 196, 15, 0.7)',
          'rgba(231, 76, 60, 0.7)',
          'rgba(52, 152, 219, 0.7)'
        ],
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'right'
        }
      }
    }
  });
}
