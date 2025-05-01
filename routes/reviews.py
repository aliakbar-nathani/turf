from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify, abort
from flask_login import login_required, current_user
from sqlalchemy import desc

from app import db
from models import Turf, Review, User, Booking, NotificationType, Notification
from forms import ReviewForm, OwnerReviewResponseForm

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