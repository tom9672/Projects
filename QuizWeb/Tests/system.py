import unittest, os, time 
from app import app,db
from app.models import User,Question,Answer
from selenium import webdriver
basedir = os.path.abspath(os.path.dirname(__file__))


class SystemTest(unittest.TestCase):
    driver = None

    def setUp(self):
        self.driver = webdriver.Firefox(executable_path=os.path.join(basedir,'geckodriver'))
        if not self.driver:
            self.skipTest
        else:
            db.init_app(app)
            db.create_all()
            db.session.query(User).delete()
            db.session.query(Question).delete()
            db.session.query(Answer).delete()
        
            u = User( username='Alex')
            u.set_password('pw')
            db.session.add(u)
            db.session.commit()
            self.driver.maximize_window()
            self.driver.get('http://localhost:5000')

    def tearDown(self):
        if self.driver:
            self.driver.close()
            db.session.query(User).delete()
            db.session.query(Question).delete()
            db.session.query(Answer).delete()
            db.session.commit()
            db.session.remove()

    def test_login(self):
        self.driver.get('http://localhost:5000')
        time.sleep(1)
        user_field = self.driver.find_element_by_id('username')
        password_field = self.driver.find_element_by_id('password')
        submit = self.driver.find_element_by_id('submit')

        user_field.send_keys('Alex')
        password_field.send_keys('pw')
        submit.click()
        time.sleep(1)

        greeting = self.driver.find_element_by_id('greeting').get_attribute('innerHTML')

        self.assertEqual(greeting, 'Welcome, Alex.')

    def test_quiz(self):
        self.driver.get('http://localhost:5000')
        time.sleep(1)
        user_field = self.driver.find_element_by_id('username')
        password_field = self.driver.find_element_by_id('password')
        submit = self.driver.find_element_by_id('submit')

        user_field.send_keys('Alex')
        password_field.send_keys('pw')
        submit.click()
        self.driver.find_element_by_link_text('Quiz').click()
        time.sleep(1)

        quiztest = self.driver.find_element_by_id('quiztest').get_attribute('innerHTML')
        self.assertEqual(quiztest, 'Related Actions:')

    def test_feedback(self):
        self.driver.get('http://localhost:5000')
        time.sleep(1)
        user_field = self.driver.find_element_by_id('username')
        password_field = self.driver.find_element_by_id('password')
        submit = self.driver.find_element_by_id('submit')

        user_field.send_keys('Alex')
        password_field.send_keys('pw')
        submit.click()
        self.driver.find_element_by_link_text('Feedback').click()
        time.sleep(1)

        testfb = self.driver.find_element_by_id('testfb').get_attribute('innerHTML')
        self.assertEqual(testfb, 'Hi Alex, your results are below!')



if __name__ == '__main__':
    unittest.main(verbosity=2)