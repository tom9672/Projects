-----------------------------------------------------------------------------
CITS3403/ CITS5503 Agile Web Development

Quiz/ Survey Platform.

Students in Group:
----------------------------------------------------------------------
22691968 Aaron Donetta - Frontend
----------------------------------------------------------------------
21325617 Phoenix Chua - Frontend
----------------------------------------------------------------------
21463227 Shengxin Zhuang - Backend
----------------------------------------------------------------------
22634156 Limin Zhou - Backend
----------------------------------------------------------------------
-----------------------------------------------------------------------------
Design and Development of Application

Design goal:
Our design goal regarding this project was to create a multifunctional web app that allowed for Administrators to create question sets (both quizzes and surveys) for Users to answer and receive feedback on. We wanted to create a web app that would give different access levels to both the administrators and the users in a non-frustrating and easy to operate fashion. By creating the question system as we did, it allows for both surveys (with no clear answer, instead a data gathering tool) and quizzes (manually marked by someone with an external answer sheet, allowing for questions of any length) to be created on the same system. It also allows the Administrators to give feedback on questions, delete entire sets of user answers and also delete users as a whole.

We created the web app by following the agile development model in different stages. Initially, we discussed what we wanted the app to do, and gradually broke the process down into more manageable chunks that we discussed at each stage within our own pairs (Frontend and Backend), and then as a whole group.

Frontend process of development:
1. Frontend structure discussed and planned alongside backend process.
2. HTML page basic structures built.
3. HTML page structures expanded to include navigation links, basic page layout, login and register pages begun, basic addQuestions page started.
4. Page validation JS begun, initial stylesheet created. Both of these integrated into base template.
5. base.html reordered to aid in design of page.
6. quiz.html updated to display questions, page logic altered to aid in redirection between pages.
7. Reformatted webpage layout and initial settings menu.
8. Merged master with backend, resolved conflicts, interface design and notification system implemented on each applicable page.
9. Page layouts improved and icons added to the navigation bar. Help messages added to most pages in Admin mode.
10. Overhaul of interface, updated arrangement of pages, updated spelling and grammar, more polished look. Reformatted web app in both User and Admin.
11. Further frontend visual design changes and quality of use tweaks.
12. README updated with Instructions and Description, as well as group details.



Backend process of development:

1. Backend structure planning, mainly about database schema and relationship between tables.
2. Initialized __init__.py, pj.py and config.py to start the project.
3. Index, login and register routes established to work the html pages.
4. addQuestion routes is for add question in addQuestions.html. Which take two input, question body and set id.
5. question and allquestions routes will display all set number in questions.html and questions group by set id in allquestions.html.
6. deleteQuestionSet will delete all question with same set id in the database. If the questions have been answer by a user. The answers will be delete alongside with questions.
7. quiz and doQuiz routes are design to display number of set in quiz.html and questions in doQuiz.html.
8. doQuiz will store user's answer as body in Answer table, question id and user id in the Answer table.
9. completed routes will allow Admin to see the stored answer for each user. And admin can select user to view user's answers in answered.html.
10. answered routes will get all stored data from Answer table and Admin can give feedback and score in this page and it will be stored in the Answer tables. 
11. feedback routes will allow user to view their answers with feedback and score.
12. user routes will return all users except Admin, in user.html Admin can choose to delete a user or delete a user's answer.
-----------------------------------------------------------------------------
Instructions to launch from localhost:

1. Check to see if your version of python has pip.  $ pip -h
2. Set up your pip package manager.   If you don't have pip, download get-pip.py to a folder on your computer and install it.
3. Install the virtualenv package.  
$ pip install virtualenv
4. Create your virtual environment.  
$ virtualenv yourpathname
5. Activate the virtual environment.  	
Mac OS/ Linux :$ yourpathname/bin/activate
Windows: yourpathname\Scripts\activate
6. Install required module:
$ pip install -r requirements.txt
7. Ensure that you have flask installed.
8. Ensure that you are in the directory where your flask files are located.   
9. Your next commands will be:
	$ flask db init
	$ flask db migrate
	$ flask db upgrade
	$ flask run
10. As long as this is all successful (it will tell you in the console if there are any errors), you can open up the page.
11. Type localhost:5000 into your browser and press enter.
12. You should now be on the webpage. Your logins will be:
For admin account:
Username: admin
Password: admin
For user account: You can create your own account to use on the webpage.
13. For user doing quiz. Only 1 quiz is allowed for each user. Mupltiple attempt will erase old answers.
-----------------------------------------------------------------------------

Will need the below saved to the submitted database for demonstration:
-At least one Admin account and one User account.
-The below 6 Survey and Quiz question sets.
.
-----------------------------------------------------------------------------

Sample Questions:
(Add whole name ie Survey - Gaming to distinguish between the survey version.)

Sample Survey Questions to be added to database:

Topic: Survey - Gaming

What is your favourite type of video game? (FPS, MOBA, MMORPG etc...)

What is your favourite game?

What is your most played game of all time?

Do you prefer single player or multiplayer games?

What game are you most looking forward to in 2020?



Topic: Survey - Film and Television

What is your favourite genre of film?

Who is your favourite actor?

Which is better, The Office or Parks and Recreation?

Who is cooler, Neo or Morpheus?

Who is your favourite Marvel superhero and why?



Topic: Survey - Music

What is your favourite type of music?

Who is your favourite band?

Why is this your favourite band?

What is your favourite song of 2020?

Which artists would you recommend to someone who hasn't listened to your type of music before?



Sample Quiz short answer questions: (manually marked)
(Only add questions, not answers. Marker will have an external answer sheet. Add whole name ie Quiz - Gaming to distinguish between the survey version.)


Topic: Quiz - Gaming

Q What is the name of the main protagonist from the hit game: Half-Life?
A Gordon Freeman

Q What is the name of the most powerful sniper rifle in Counter Strike: Global Offensive?
A AWP

Q What is the name of Call of Duty: Modern Warfare's new battle royale game mode?
A Warzone

Q The latest Zelda game is called The Legend of Zelda: Breath of the ____.
A Wild

Q In what year was the original DOOM game released?
A 1993



Topic: Quiz - Film and Television

Q Who is undoubtedly, and without question, the coolest character in the Matrix?
A Morpheus

Q According to Ghostbusters, you must never cross the _______!
A Streams

Q Finish this quote from Game of Thrones: "You know nothing Jon ____!"
A Snow

Q What is the name of the island that Jurassic Park was build upon?
A Isla Nublar

Q Which actor played Ronon Dex, Khal Drogo and Aquaman?
A Jason Momoa



Topic: Quiz - Music

Q TRUE or FALSE: James Hetfield is the lead vocalist for heavy metal band, Metallica.
A TRUE

Q TRUE or FALSE: The Beatles produced a hit song named: "Lucy and the Stars Alignment"
A FALSE

Q Which band wrote the song "Stairway to Heaven"?
A Led Zeppelin

Q In "Tribute" by Tenacious D, what was the name of the narrators brother?
A Kyle

Q TRUE or FALSE: In Queen's "Bohemian Rhapsody", the narrator did, in fact, kill a man.
A TRUE
