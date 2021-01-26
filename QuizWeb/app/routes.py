from flask import render_template, flash, redirect, url_for, request
from app import app, db
from app.forms import LoginForm, RegistrationForm, addQuestionForm, Quiz, completedQuestionForm
from flask_login import current_user, login_user, logout_user, login_required
from app.models import User, Question,Answer
from werkzeug.urls import url_parse

@app.route('/')
@app.route('/index')
@login_required
def index():
    questions = Question.query.all()
    quizzesactive = 0
    for num in questions:
        quizzesactive = quizzesactive +1

    return render_template('index.html', quizzesactive=quizzesactive)

@app.route('/login', methods=['GET', 'POST'])

def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user is None or not user.check_password(form.password.data):
            flash('Invalid username or password')
            return redirect(url_for('login'))
        login_user(user, remember=form.remember_me.data)
        next_page = request.args.get('next')
        if not next_page or url_parse(next_page).netloc != '':
            next_page = url_for('index')
        return redirect(next_page)
    return render_template('login.html', title='Sign In', form=form)

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('index'))

@app.route('/register', methods=['GET', 'POST'])

def register():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(username=form.username.data, admin=False)
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash('Congratulations, you are now a registered user!')
        return redirect(url_for('login'))
    return render_template('register.html', title='Register', form=form)

@app.route('/questions',methods=['GET', 'POST'])
@login_required
def questions():
    
    questions = Question.query.all()
    questions = list(questions)
    setid     = []

    for q in questions:
        setid.append(q.set_id)

    setid = list(set(setid))
    length=len(setid)


    return render_template('questions.html',data=setid, length = length)

@app.route('/deleteQuestionSet/<setid>/', methods=['GET', 'POST'])
@login_required
def deleteQuestionSet(setid):
    question = Question.query.filter_by(set_id=setid).all()
    
    for q in question:
        answer=Answer.query.filter_by(question_id=q.id).all()
        for a in answer:
            db.session.delete(a)
        
    for q in question:
        db.session.delete(q)
    db.session.commit()
    flash(" Deleted Successfully.")
    return redirect(url_for('questions'))


@app.route('/addQuestions',methods=['GET', 'POST'])
@login_required
def addQuestions():
    form = addQuestionForm()
    if form.validate_on_submit():
        question = Question(body=form.question.data, set_id=form.set_id.data)

        db.session.add(question)
        db.session.commit()
        flash('Congratulations, you have added one question into the data set!')
        return redirect(url_for('addQuestions'))
    return render_template('addQuestions.html',title="AddQuesion",form=form)

@app.route('/allquestions/<id>/', methods=['GET', 'POST'])
@login_required
def allquestions(id):
    question = Question.query.filter_by(set_id=id).all()
    setid=id

    return render_template('allquestions.html', question = question, setid=setid)


@app.route('/feedback')
@login_required
def feedback():
    userid=current_user.id
    answer=Answer.query.filter_by(answered_by=userid).all()
    answers=list(answer)
    qid=[]
    for q in answers:
        qid.append(q.question_id)

    question=[]
    for qi in qid:
        ques=Question.query.get(qi)
        question.append(ques)

    totalscore=0
    for q in answer:
        if not q.score:
            pass
        else:
            totalscore += q.score

    return render_template('feedback.html', qalist=zip(question,answers), totalscore=totalscore)



@app.route('/quiz',methods=['GET', 'POST'])
@login_required
def quiz():
    questions = Question.query.all()
    questions = list(questions)
    setid     = []

    for q in questions:
        setid.append(q.set_id)

    setid = list(set(setid))
    length=len(setid)

    return render_template('quiz.html', data=setid, length = length)



@app.route('/doQuiz/<id>/',methods=['GET', 'POST'])
@login_required
def doQuiz(id):
    data= Question.query.filter_by(set_id=id).all()
    userid=current_user.id
    answers=Answer.query.filter_by(answered_by=userid).all()
    answer=request.form.getlist('answer')

    if answers:
        for an in answers:
            db.session.delete(an)
        for qid, ans in zip(data, answer):
            answ=Answer(question_id=qid.id, answered_by=userid, body=ans)
            db.session.add(answ)
    else:
        for qid, ans in zip(data, answer):
            answ=Answer(question_id=qid.id, answered_by=userid, body=ans)
            db.session.add(answ)
    db.session.commit()
    
    return render_template('doQuiz.html',data=data)


@app.route('/completed', methods = ['GET', 'POST'])
@login_required
def completed():
    
    answer = Answer.query.all()
    user =[]
    
    for a in answer:
        u=User.query.get(a.answered_by)
        user.append(u)
    
    users=list(set(user))

    return render_template('completed.html', users=users)


@app.route('/answered/<id>/', methods = ['GET', 'POST'])
@login_required
def answered(id):

    user=User.query.get(id)
    answer=User.query.get(id).questions_answered.all()
    answer=list(answer)
    qid=[]
    for q in answer:
        qid.append(q.question_id)

    question=[]
    for qi in qid:
        ques=Question.query.get(qi)
        question.append(ques)
    
    feedback=request.form.getlist('feedback')
    score=request.form.getlist('score')

    for fb, an in zip(feedback,answer):
        an.feedback=fb
        an.graded=True
    
    for sc, an in zip(score,answer):
        an.score=sc
        an.graded=True
    
    db.session.commit()

    return render_template('answered.html',user=user, qalist=zip(question,answer))


@app.route('/users')
@login_required
def users():
    if not current_user.admin:
        return redirect(url_for('index'))

    users=User.query.filter_by(admin=False).all()

    return render_template('users.html',  users=users)


@app.route('/deleteUser/<id>/', methods=['GET', 'POST'])
@login_required
def deleteUser(id):
    my_data = User.query.get(id)
    answer=Answer.query.filter_by(answered_by=id).all()
    
    if not answer:
        db.session.delete(my_data)
    else:
        for an in answer:
            db.session.delete(an)
        db.session.delete(my_data)
        
    db.session.commit()

    flash(" Deleted Successfully.")

    return redirect(url_for('users'))


@app.route('/deleteAnswer/<id>/', methods=['GET', 'POST'])
@login_required
def deleteAnswer(id):

    answer=User.query.get(id).questions_answered.all()
    for an in answer:
        db.session.delete(an)
        db.session.commit()

    flash(" Deleted Successfully.")
    return redirect(url_for('users'))
