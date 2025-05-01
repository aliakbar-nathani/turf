from flask import Blueprint, render_template, redirect, url_for
from flask_login import current_user

home = Blueprint('home', __name__)

@home.route('/')
def index():
    """Home page route - redirects to search if logged in, otherwise shows landing page"""
    if current_user.is_authenticated:
        return redirect(url_for('user.search'))
    return render_template('index.html', title='Welcome to TurfBook')