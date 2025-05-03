from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify, abort
from flask_login import login_required, current_user
from sqlalchemy import desc
import json
from datetime import datetime

from app import db
from models import Turf, Review, User, Booking, NotificationType, Notification
from forms import ReviewForm, OwnerReviewResponseForm
from .auth import token_required

reviews_bp = Blueprint('reviews', __name__)

@reviews_bp.route('/turf/<int:turf_id>/reviews')
def turf_reviews(turf_id):
    """View all reviews for a specific turf"""
    turf = Turf.query.get_or_404(turf_id)
    reviews = Review.query.filter_by(turf_id=turf_id).order_by(desc(Review.created_at)).all()
    
    return render_template('turf/reviews.html', 
        turf=turf, 
        reviews=reviews,
        avg_rating=turf.get_average_rating(),
        rating_count=turf.get_rating_count(),
        rating_distribution=turf.get_rating_distribution()
    )

@reviews_bp.route('/turf/<int:turf_id>/review', methods=['GET', 'POST'])
@login_required
def add_review(turf_id):
    """Add a review for a turf"""
    turf = Turf.query.get_or_404(turf_id)
    
    # Check if user has already reviewed this turf
    existing_review = Review.query.filter_by(user_id=current_user.id, turf_id=turf_id).first()
    if existing_review:
        flash('You have already reviewed this turf. You can edit your existing review instead.', 'warning')
        return redirect(url_for('reviews.edit_review', review_id=existing_review.id))
    
    # Check if user has booked this turf before (optional validation)
    has_booking = Booking.query.filter_by(
        user_id=current_user.id, turf_id=turf_id
    ).first() is not None
    
    form = ReviewForm()
    if form.validate_on_submit():
        review = Review(
            rating=form.rating.data,
            comment=form.comment.data,
            user_id=current_user.id,
            turf_id=turf_id
        )
        db.session.add(review)
        
        # Create notification for turf owner
        owner_notification = Notification(
            type=NotificationType.NEW_REVIEW,
            title='New review for your turf',
            message=f'Your turf "{turf.name}" has received a new {review.rating}-star review',
            user_id=turf.owner_id,
            turf_id=turf_id,
            review_id=review.id
        )
        db.session.add(owner_notification)
        
        db.session.commit()
        flash('Your review has been submitted!', 'success')
        return redirect(url_for('reviews.turf_reviews', turf_id=turf_id))
    
    return render_template('turf/add_review.html', form=form, turf=turf, has_booking=has_booking)

@reviews_bp.route('/review/<int:review_id>/edit', methods=['GET', 'POST'])
@login_required
def edit_review(review_id):
    """Edit a review"""
    review = Review.query.get_or_404(review_id)
    
    # Check if user is the author of the review
    if review.user_id != current_user.id:
        abort(403)  # Forbidden
    
    form = ReviewForm()
    if form.validate_on_submit():
        review.rating = form.rating.data
        review.comment = form.comment.data
        db.session.commit()
        flash('Your review has been updated!', 'success')
        return redirect(url_for('reviews.turf_reviews', turf_id=review.turf_id))
    
    # Pre-populate form with existing review data
    if request.method == 'GET':
        form.rating.data = review.rating
        form.comment.data = review.comment
    
    return render_template('turf/edit_review.html', form=form, review=review, turf=review.turf)

@reviews_bp.route('/review/<int:review_id>/delete', methods=['POST'])
@login_required
def delete_review(review_id):
    """Delete a review"""
    review = Review.query.get_or_404(review_id)
    
    # Check if user is the author of the review or an admin
    if review.user_id != current_user.id and not current_user.is_admin():
        abort(403)  # Forbidden
    
    turf_id = review.turf_id
    db.session.delete(review)
    db.session.commit()
    flash('Review has been deleted!', 'success')
    return redirect(url_for('reviews.turf_reviews', turf_id=turf_id))

@reviews_bp.route('/owner/review/<int:review_id>/respond', methods=['GET', 'POST'])
@login_required
def owner_respond(review_id):
    """Respond to a review as a turf owner"""
    review = Review.query.get_or_404(review_id)
    turf = review.turf
    
    # Check if user is the owner of the turf
    if turf.owner_id != current_user.id:
        abort(403)  # Forbidden
    
    form = OwnerReviewResponseForm()
    if form.validate_on_submit():
        review.owner_response = form.response.data
        review.owner_response_date = db.func.now()
        db.session.commit()
        flash('Your response has been submitted!', 'success')
        return redirect(url_for('reviews.turf_reviews', turf_id=turf.id))
    
    # Pre-populate form with existing response
    if request.method == 'GET' and review.owner_response:
        form.response.data = review.owner_response
    
    return render_template('owner/respond_review.html', form=form, review=review, turf=turf)

# ----- API Endpoints for Mobile App -----

def serialize_review(review):
    """Helper function to serialize a review object to JSON"""
    return {
        'id': review.id,
        'rating': review.rating,
        'comment': review.comment,
        'user_id': review.user_id,
        'username': review.user.username,
        'turf_id': review.turf_id,
        'turfName': review.turf.name,
        'created_at': review.created_at.strftime('%Y-%m-%d %H:%M'),
        'owner_response': review.owner_response,
        'owner_response_date': review.owner_response_date.strftime('%Y-%m-%d %H:%M') if review.owner_response_date else None
    }

@reviews_bp.route('/api/turf/<int:turf_id>/reviews', methods=['GET'])
def api_turf_reviews(turf_id):
    """API endpoint to get all reviews for a turf"""
    try:
        turf = Turf.query.get_or_404(turf_id)
        reviews = Review.query.filter_by(turf_id=turf_id).order_by(desc(Review.created_at)).all()
        
        serialized_reviews = [serialize_review(review) for review in reviews]
        
        return jsonify({
            'success': True,
            'reviews': serialized_reviews,
            'average_rating': turf.get_average_rating(),
            'review_count': turf.get_rating_count(),
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@reviews_bp.route('/api/user/reviews', methods=['GET'])
@token_required
def api_user_reviews(current_user):
    """API endpoint to get all reviews by the current user"""
    try:
        reviews = Review.query.filter_by(user_id=current_user.id).order_by(desc(Review.created_at)).all()
        serialized_reviews = [serialize_review(review) for review in reviews]
        
        return jsonify({
            'success': True,
            'reviews': serialized_reviews
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@reviews_bp.route('/api/turf/<int:turf_id>/review', methods=['POST'])
@token_required
def api_add_review(current_user, turf_id):
    """API endpoint to add a review for a turf"""
    try:
        turf = Turf.query.get_or_404(turf_id)
        
        # Check if user has already reviewed this turf
        existing_review = Review.query.filter_by(user_id=current_user.id, turf_id=turf_id).first()
        if existing_review:
            return jsonify({
                'success': False,
                'message': 'You have already reviewed this turf. You can edit your existing review instead.'
            }), 400
        
        # Get data from request
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'message': 'No data provided'
            }), 400
        
        rating = data.get('rating')
        comment = data.get('comment', '')
        
        if not rating or not isinstance(rating, int) or rating < 1 or rating > 5:
            return jsonify({
                'success': False,
                'message': 'Rating is required and must be between 1 and 5'
            }), 400
        
        # Create new review
        review = Review(
            rating=rating,
            comment=comment,
            user_id=current_user.id,
            turf_id=turf_id
        )
        db.session.add(review)
        
        # Create notification for turf owner
        owner_notification = Notification(
            type=NotificationType.NEW_REVIEW,
            title='New review for your turf',
            message=f'Your turf "{turf.name}" has received a new {review.rating}-star review',
            user_id=turf.owner_id,
            turf_id=turf_id,
            review_id=review.id
        )
        db.session.add(owner_notification)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Review submitted successfully',
            'review': serialize_review(review)
        }), 201
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@reviews_bp.route('/api/review/<int:review_id>', methods=['PUT'])
@token_required
def api_update_review(current_user, review_id):
    """API endpoint to update a review"""
    try:
        review = Review.query.get_or_404(review_id)
        
        # Check if user is the author of the review
        if review.user_id != current_user.id:
            return jsonify({
                'success': False,
                'message': 'You are not authorized to edit this review'
            }), 403
        
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'message': 'No data provided'
            }), 400
        
        rating = data.get('rating')
        comment = data.get('comment')
        
        if rating is not None:
            if not isinstance(rating, int) or rating < 1 or rating > 5:
                return jsonify({
                    'success': False,
                    'message': 'Rating must be between 1 and 5'
                }), 400
            review.rating = rating
        
        if comment is not None:
            review.comment = comment
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Review updated successfully',
            'review': serialize_review(review)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@reviews_bp.route('/api/review/<int:review_id>', methods=['DELETE'])
@token_required
def api_delete_review(current_user, review_id):
    """API endpoint to delete a review"""
    try:
        review = Review.query.get_or_404(review_id)
        
        # Check if user is the author of the review or an admin
        if review.user_id != current_user.id and not current_user.is_admin():
            return jsonify({
                'success': False,
                'message': 'You are not authorized to delete this review'
            }), 403
        
        db.session.delete(review)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Review deleted successfully'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@reviews_bp.route('/api/owner/review/<int:review_id>/respond', methods=['POST'])
@token_required
def api_owner_respond(current_user, review_id):
    """API endpoint for a turf owner to respond to a review"""
    try:
        review = Review.query.get_or_404(review_id)
        turf = review.turf
        
        # Check if user is the owner of the turf
        if turf.owner_id != current_user.id:
            return jsonify({
                'success': False,
                'message': 'You are not authorized to respond to this review'
            }), 403
        
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'message': 'No data provided'
            }), 400
        
        response = data.get('response')
        if not response:
            return jsonify({
                'success': False,
                'message': 'Response is required'
            }), 400
        
        review.owner_response = response
        review.owner_response_date = datetime.now()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Response submitted successfully',
            'review': serialize_review(review)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@reviews_bp.route('/api/turf/<int:turf_id>/can_review', methods=['GET'])
@token_required
def api_can_review_turf(current_user, turf_id):
    """API endpoint to check if a user can review a turf"""
    try:
        # Check if user has already reviewed this turf
        existing_review = Review.query.filter_by(user_id=current_user.id, turf_id=turf_id).first()
        if existing_review:
            return jsonify({
                'success': True,
                'can_review': False,
                'message': 'You have already reviewed this turf.'
            })
        
        # Check if user has a completed booking for this turf
        completed_booking = Booking.query.filter_by(
            user_id=current_user.id, 
            turf_id=turf_id,
            status='completed'
        ).first()
        
        if completed_booking:
            return jsonify({
                'success': True,
                'can_review': True,
                'message': 'You can review this turf.'
            })
        else:
            return jsonify({
                'success': True,
                'can_review': False,
                'message': 'You can only review turfs you have booked and played on.'
            })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e),
            'can_review': False
        }), 500