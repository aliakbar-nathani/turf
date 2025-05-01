// Favorites.js - Handles favoriting turfs and social sharing

document.addEventListener('DOMContentLoaded', function() {
    // Toggle favorite status
    const favoriteButtons = document.querySelectorAll('.favorite-btn');
    
    favoriteButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            
            const turfId = this.getAttribute('data-turf-id');
            const heartIcon = this.querySelector('i');
            
            fetch(`/turf/${turfId}/favorite`, {
                method: 'POST',
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    // Update heart icon based on favorite status
                    if (data.is_favorite) {
                        heartIcon.classList.remove('bi-heart');
                        heartIcon.classList.add('bi-heart-fill', 'text-danger');
                        this.setAttribute('data-is-favorite', 'true');
                        showToast('Added to favorites!');
                    } else {
                        heartIcon.classList.remove('bi-heart-fill', 'text-danger');
                        heartIcon.classList.add('bi-heart');
                        this.setAttribute('data-is-favorite', 'false');
                        showToast('Removed from favorites');
                    }
                }
            })
            .catch(error => {
                console.error('Error toggling favorite:', error);
                showToast('Could not update favorites. Please try again.', 'error');
            });
        });
    });
    
    // Initialize share buttons if they exist
    const shareButtons = document.querySelectorAll('.share-btn');
    
    shareButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            
            const platform = this.getAttribute('data-platform');
            const url = this.getAttribute('data-url');
            const title = this.getAttribute('data-title');
            
            if (platform === 'copy') {
                // Copy to clipboard
                navigator.clipboard.writeText(url)
                    .then(() => {
                        showToast('Link copied to clipboard!');
                    })
                    .catch(err => {
                        console.error('Could not copy text: ', err);
                        showToast('Failed to copy link', 'error');
                    });
            } else if (platform === 'whatsapp') {
                window.open(`https://wa.me/?text=${encodeURIComponent(title + ' ' + url)}`, '_blank');
            } else if (platform === 'facebook') {
                window.open(`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`, '_blank');
            } else if (platform === 'twitter') {
                window.open(`https://twitter.com/intent/tweet?text=${encodeURIComponent(title)}&url=${encodeURIComponent(url)}`, '_blank');
            } else if (platform === 'email') {
                window.location.href = `mailto:?subject=${encodeURIComponent(title)}&body=${encodeURIComponent('Check out this turf: ' + url)}`;
            }
        });
    });
    
    // Helper function to show toast notifications
    function showToast(message, type = 'success') {
        // Check if the toast container exists
        let toastContainer = document.getElementById('toast-container');
        
        // Create it if it doesn't exist
        if (!toastContainer) {
            toastContainer = document.createElement('div');
            toastContainer.id = 'toast-container';
            toastContainer.className = 'position-fixed bottom-0 end-0 p-3';
            toastContainer.style.zIndex = '5';
            document.body.appendChild(toastContainer);
        }
        
        // Create toast element
        const toastId = 'toast-' + Date.now();
        const toast = document.createElement('div');
        toast.className = `toast align-items-center border-0 ${type === 'success' ? 'bg-success' : 'bg-danger'} text-white`;
        toast.id = toastId;
        toast.setAttribute('role', 'alert');
        toast.setAttribute('aria-live', 'assertive');
        toast.setAttribute('aria-atomic', 'true');
        
        // Toast content
        toast.innerHTML = `
            <div class="d-flex">
                <div class="toast-body">
                    ${message}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        `;
        
        // Add to container
        toastContainer.appendChild(toast);
        
        // Initialize and show the toast
        const bsToast = new bootstrap.Toast(toast, {
            animation: true,
            autohide: true,
            delay: 3000
        });
        bsToast.show();
        
        // Remove toast after it's hidden
        toast.addEventListener('hidden.bs.toast', function() {
            toast.remove();
        });
    }
});