from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify, abort
from flask_login import login_required, current_user
from sqlalchemy import desc

from app import db
from models import Turf, Favorite, TurfImage

favorites_bp = Blueprint('favorites', __name__)

@favorites_bp.route('/favorites')
@login_required
def list_favorites():
    """View all favorited turfs for the current user"""
    favorites = current_user.favorites.all()
    favorited_turfs = []
    
    for favorite in favorites:
        primary_image = TurfImage.query.filter_by(
            turf_id=favorite.turf_id, is_primary=True
        ).first()
        
        turf_data = favorite.turf.to_dict()
        turf_data['image_url'] = primary_image.url if primary_image else None
        turf_data['favorited_at'] = favorite.created_at
        
        favorited_turfs.append(turf_data)
    
    return render_template('user/favorites.html', favorited_turfs=favorited_turfs)

@favorites_bp.route('/turf/<int:turf_id>/favorite', methods=['POST'])
@login_required
def toggle_favorite(turf_id):
    """Add or remove a turf from favorites"""
    turf = Turf.query.get_or_404(turf_id)
    favorite = Favorite.query.filter_by(user_id=current_user.id, turf_id=turf_id).first()
    
    if favorite:
        # Remove from favorites
        db.session.delete(favorite)
        db.session.commit()
        is_favorite = False
        message = f'"{turf.name}" removed from your favorites'
    else:
        # Add to favorites
        favorite = Favorite(user_id=current_user.id, turf_id=turf_id)
        db.session.add(favorite)
        db.session.commit()
        is_favorite = True
        message = f'"{turf.name}" added to your favorites'
    
    # If this is an Ajax request, return JSON response
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return jsonify({
            'status': 'success',
            'is_favorite': is_favorite,
            'message': message
        })
    
    # For regular form submissions
    flash(message, 'success')
    return redirect(url_for('booking.view_turf', turf_id=turf_id))

@favorites_bp.route('/api/turf/<int:turf_id>/is_favorite')
@login_required
def check_favorite_status(turf_id):
    """Check if a turf is in the user's favorites (for AJAX calls)"""
    is_favorite = Favorite.query.filter_by(
        user_id=current_user.id, turf_id=turf_id
    ).first() is not None
    
    return jsonify({
        'is_favorite': is_favorite
    })