from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField,TextAreaField
from wtforms.validators import DataRequired, EqualTo, ValidationError
from app.models import User


class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    remember_me = BooleanField('Remember Me')
    submit = SubmitField('Sign In')

class RegistrationForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    password2 = PasswordField(
        'Repeat Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register')

    def validate_username(self, username):
        user = User.query.filter_by(username=username.data).first()
        if user is not None:
            raise ValidationError('Please use a different username.')

class addQuestionForm(FlaskForm):
    
    question = TextAreaField('Question', validators=[DataRequired()])
    set_id = TextAreaField('Set_id', validators=[DataRequired()])
    submit = SubmitField('Add Question')

class completedQuestionForm(FlaskForm):
    
    feedback = TextAreaField('Feedback')
    submit = SubmitField('Submit')

class Quiz(FlaskForm):
    
    answer = TextAreaField('Your Answer')
    submit = SubmitField('Submit Answer')

