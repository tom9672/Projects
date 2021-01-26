from app import db, login
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin


# Create User table in the database
class User(UserMixin,db.Model):
    id = db.Column(db.Integer, primary_key = True)
    username = db.Column(db.String(64), index = True, unique = True)
    password_hash = db.Column(db.String(128))
    admin = db.Column(db.Boolean)
    questions_answered = db.relationship('Answer', backref='author', lazy='dynamic')

    def __repr__(self):
        return '<User {}>'.format(self.username)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)



#Create Question table
class Question(db.Model):
    id = db.Column(db.Integer, primary_key = True)
    body = db.Column(db.Text)
    set_id= db.Column(db.Integer)

    def set_body(self, body):
        self.body = body



    def __repr__(self):
        return '{}'.format(self.body)

# Create answers table
class Answer(db.Model):
    id = db.Column(db.Integer, primary_key = True)
    question_id = db.Column(db.Integer, db.ForeignKey('question.id'))
    answered_by = db.Column(db.Integer, db.ForeignKey('user.id'))
    body = db.Column(db.Text)
    feedback = db.Column(db.Text)
    score = db.Column(db.Integer)
    
    def set_feedback(self, feedback):
        self.feedback = feedback



    def __repr__(self):
        return '<Answer {}>'.format(self.body)

@login.user_loader
def load_user(id):
    return User.query.get(int(id))
