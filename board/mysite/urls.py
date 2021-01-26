from django.contrib import admin
from django.urls import path
from boards import views
from accounts import views as accounts_views
from django.contrib.auth import views as auth_views
from django.conf.urls import url

urlpatterns = [
    path('', views.BoardListView.as_view(), name='home'),
    path('test/', accounts_views.test, name="test"),
    path('login/', auth_views.LoginView.as_view(template_name='login.html'), name='login'),
    path('signup/', accounts_views.signup, name='signup'),
    path('logout/', auth_views.LogoutView.as_view(), name='logout'),
    path('boards/<int:pk>', views.TopicListView.as_view(), name='board_topics'),
    path('boards/<int:pk>/new', views.new_topic, name='new_topic'),
    path('admin/', admin.site.urls),

path('reset/',
    auth_views.PasswordResetView.as_view(
        template_name='password_reset.html',
        email_template_name='password_reset_email.html',
        subject_template_name='password_reset_subject.txt'
    ),
    name='password_reset'),
path('reset/<uidb64>/<token>/', 
    auth_views.PasswordResetConfirmView.as_view(template_name='password_reset_confirm.html'),
    name='password_reset_confirm'),
path('reset/done/', auth_views.PasswordResetDoneView.as_view(template_name='password_reset_done.html'),
    name='password_reset_done'),
path('reset/complete/',
    auth_views.PasswordResetCompleteView.as_view(template_name='password_reset_complete.html'),
    name='password_reset_complete'),

path('board/<pk>/topics/<topic_pk>/posts/<post_pk>/edit/', views.PostUpdateView.as_view(), name='edit_post'),

path('settings/account/' , accounts_views.UserUpdateView.as_view(), name='my_account'),

url(r'^settings/password/$', auth_views.PasswordChangeView.as_view(template_name='password_change.html'),
    name='password_change'),
url(r'^settings/password/done/$', auth_views.PasswordChangeDoneView.as_view(template_name='password_change_done.html'),
    name='password_change_done'),

url(r'^boards/(?P<pk>\d+)/topics/(?P<topic_pk>\d+)/$', views.PostListView.as_view(), name='topic_posts'),
url(r'^boards/(?P<pk>\d+)/topics/(?P<topic_pk>\d+)/reply/$', views.reply_topic, name='reply_topic'),
]

