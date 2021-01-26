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
        
            u = User( username='Alex', admin=True)
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



    def test_login_admin(self):
        self.driver.get('http://localhost:5000')
        time.sleep(1)
        user_field = self.driver.find_element_by_id('username')
        password_field = self.driver.find_element_by_id('password')
        submit = self.driver.find_element_by_id('submit')

        user_field.send_keys('Alex')
        password_field.send_keys('pw')
        submit.click()
        time.sleep(1)

        greeting = self.driver.find_element_by_id('greetingadmin').get_attribute('innerHTML')

        self.assertEqual(greeting, 'A brief introduction to the administrator page:')

    def test_question_admin(self):
        self.driver.get('http://localhost:5000')
        time.sleep(1)
        user_field = self.driver.find_element_by_id('username')
        password_field = self.driver.find_element_by_id('password')
        submit = self.driver.find_element_by_id('submit')

        user_field.send_keys('Alex')
        password_field.send_keys('pw')
        submit.click()
        self.driver.find_element_by_link_text('Question').click()
        time.sleep(1)

        testquestion = self.driver.find_element_by_id('testquestion').get_attribute('innerHTML')
        self.assertEqual(testquestion, 'Manage Questions')

    def test_addquestion_admin(self):
        self.driver.get('http://localhost:5000')
        time.sleep(1)
        user_field = self.driver.find_element_by_id('username')
        password_field = self.driver.find_element_by_id('password')
        submit = self.driver.find_element_by_id('submit')

        user_field.send_keys('Alex')
        password_field.send_keys('pw')
        submit.click()
        self.driver.find_element_by_link_text('Add Question').click()
        time.sleep(1)

        testaddquestion = self.driver.find_element_by_id('testaddquestion').get_attribute('innerHTML')
        self.assertEqual(testaddquestion, 'Add Question')

    def test_mark_admin(self):
        self.driver.get('http://localhost:5000')
        time.sleep(1)
        user_field = self.driver.find_element_by_id('username')
        password_field = self.driver.find_element_by_id('password')
        submit = self.driver.find_element_by_id('submit')

        user_field.send_keys('Alex')
        password_field.send_keys('pw')
        submit.click()
        self.driver.find_element_by_link_text('Mark Questions').click()
        time.sleep(1)

        testmark = self.driver.find_element_by_id('testmark').get_attribute('innerHTML')
        self.assertEqual(testmark, 'Mark Questions')

    def test_users_admin(self):
        self.driver.get('http://localhost:5000')
        time.sleep(1)
        user_field = self.driver.find_element_by_id('username')
        password_field = self.driver.find_element_by_id('password')
        submit = self.driver.find_element_by_id('submit')

        user_field.send_keys('Alex')
        password_field.send_keys('pw')
        submit.click()
        self.driver.find_element_by_link_text('Users').click()
        time.sleep(1)

        testusers = self.driver.find_element_by_id('testusers').get_attribute('innerHTML')
        self.assertEqual(testusers, 'Registered Users')

if __name__ == '__main__':
    unittest.main(verbosity=2)