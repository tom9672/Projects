from django.contrib import admin
from django.urls import path
from limin import views
urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.products, name='products'),
    path('equipments/', views.equipments, name='equipments'),
    path('company/', views.company, name='company'),
    path('purchase/', views.purchase, name='purchase'),
    path('contact/', views.contact, name='contact'),
    path('product1/', views.product1, name="product1"),
    path('product2/', views.product2, name="product2"),
    path('product3/', views.product3, name="product3"),
    path('product4/', views.product4, name="product4"),
    path('product5/', views.product5, name="product5"),
    path('product6/', views.product6, name="product6"),
    path('product7/', views.product7, name="product7"),
    path('product8/', views.product8, name="product8"),
    path('product9/', views.product9, name="product9"),
    path('company/topics/<pk>', views.topics, name='topics'),
]
