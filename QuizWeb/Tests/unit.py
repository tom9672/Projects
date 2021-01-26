import unittest, os, time
from app import app,db
from app.models import User,Question,Answer
from selenium import webdriver
basedir = os.path.abspath(os.path.dirname(__file__))


class UserModelTest(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        #make sure database is empty
        db.session.query(User).delete()
        db.create_all()
        u = User(id=99, username='Tom')
        db.session.add(u)
        db.session.commit()

    def tearDown(self):
        db.session.remove()
        
    def test_set_pw_true(self):
        u = User.query.get(99)
        u.set_password('pw')
        self.assertFalse(u.check_password('passw0rd'))
        self.assertTrue(u.check_password('pw'))

    def test_set_pw_false(self):
        u = User.query.get(99)
        u.set_password('pw2')
        self.assertFalse(u.check_password('pw2'))
        self.assertTrue(u.check_password('pw'))

class QuestionModelTest(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        db.session.query(Question).delete()
        db.create_all()
        q = Question(id=100)
        db.session.add(q)
        db.session.commit()

    def tearDown(self):
        db.session.remove()

    def test_set_body_true(self):
        q = Question.query.get(100)
        q.set_body('What is your favourite food?')
        self.assertEqual(q.body, 'What is your favourite food?')

    def test_set_body_false(self):
        q = Question.query.get(100)
        q.set_body('What is your favourite game?')
        self.assertEqual(q.body,'What is your favourite food?')

class AnswerModelTest(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        # make sure database is empty
        db.session.query(Answer).delete()
        db.create_all()
        a = Answer(id=98)
        db.session.add(a)
        db.session.commit()

    def tearDown(self):
        db.session.remove()

    def test_set_answer_true(self):
        a = Answer.query.get(98)
        a.set_feedback('You make a good answer.')
        self.assertEqual(a.feedback, 'You make a good answer.')

    def test_set_answer_flase(self):
        a = Answer.query.get(98)
        a.set_feedback('You make a good answer.')
        self.assertEqual(a.feedback, 'You make a incorrect answer.')


if __name__ == '__main__':
    unittest.main(verbosity=2)