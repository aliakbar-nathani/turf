from flask import Blueprint, render_template, request, jsonify, flash, redirect, url_for
from flask_login import login_required, current_user
from sqlalchemy import desc

from app import db
from models import Favorite, Turf, User

favorites = Blueprint('favorites', __name__, url_prefix='/favorites')

@favorites.route('/')
@login_required
def list_favorites():
    """Display user's favorite turfs"""
    favorites = Favorite.query.filter_by(user_id=current_user.id) \
        .join(Favorite.turf) \
        .order_by(desc(Favorite.created_at)) \
        .all()
    
    return render_template('user/favorites.html', favorites=favorites)

@favorites.route('/turf/<int:turf_id>/favorite', methods=['POST'])
@login_required
def toggle_favorite(turf_id):
    """Toggle favorite status for a turf"""
    turf = Turf.query.get_or_404(turf_id)
    
    # Check if the turf is already favorited
    favorite = Favorite.query.filter_by(user_id=current_user.id, turf_id=turf_id).first()
    
    if favorite:
        # Remove from favorites
        db.session.delete(favorite)
        db.session.commit()
        is_favorite = False
        message = f"{turf.name} removed from favorites"
    else:
        # Add to favorites
        favorite = Favorite(user_id=current_user.id, turf_id=turf_id)
        db.session.add(favorite)
        db.session.commit()
        is_favorite = True
        message = f"{turf.name} added to favorites"
    
    # Check if it's an AJAX request
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return jsonify({
            'status': 'success',
            'is_favorite': is_favorite,
            'message': message
        })
    
    # If not AJAX, redirect with flash message
    flash(message, 'success')
    return redirect(url_for('booking.view_turf', turf_id=turf_id))

@favorites.route('/api/count')
@login_required
def get_favorites_count():
    """Return the count of user's favorites for API usage"""
    count = Favorite.query.filter_by(user_id=current_user.id).count()
    return jsonify({'count': count})