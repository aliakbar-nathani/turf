from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_user, current_user, logout_user, login_required
from werkzeug.security import generate_password_hash

from app import db
from models import User, UserRole
from forms import LoginForm, RegisterForm, RegisterOwnerForm

auth = Blueprint('auth', __name__)

@auth.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('user.dashboard'))
    
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        if user and user.check_password(form.password.data):
            login_user(user, remember=form.remember.data)
            next_page = request.args.get('next')
            
            # Redirect based on user role
            if not next_page or next_page == '/':
                if user.role == UserRole.ADMIN:
                    next_page = url_for('admin.dashboard')
                elif user.role == UserRole.OWNER:
                    next_page = url_for('owner.dashboard')
                else:
                    next_page = url_for('user.dashboard')
            
            return redirect(next_page)
        else:
            flash('Login unsuccessful. Please check email and password.', 'danger')
    
    return render_template('auth/login.html', form=form, title='Login')

@auth.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('user.dashboard'))
    
    form = RegisterForm()
    if form.validate_on_submit():
        user = User(
            username=form.username.data,
            email=form.email.data,
            phone_number=form.phone_number.data,
            role=UserRole.USER
        )
        user.set_password(form.password.data)
        
        db.session.add(user)
        db.session.commit()
        
        flash('Your account has been created! You can now log in.', 'success')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/register.html', form=form, title='Register')

@auth.route('/register/owner', methods=['GET', 'POST'])
def register_owner():
    if current_user.is_authenticated:
        return redirect(url_for('user.dashboard'))
    
    form = RegisterOwnerForm()
    if form.validate_on_submit():
        user = User(
            username=form.username.data,
            email=form.email.data,
            phone_number=form.phone_number.data,
            role=UserRole.OWNER
        )
        user.set_password(form.password.data)
        
        db.session.add(user)
        db.session.commit()
        
        flash('Your turf owner account has been created! You can now log in.', 'success')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/register.html', form=form, title='Register as Turf Owner', is_owner=True)

@auth.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('auth.login'))
