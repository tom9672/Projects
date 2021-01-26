from django.shortcuts import render
from .models import Topic

def products(request):
    return render(request, 'products.html')

def equipments(request):
    return render(request, 'equipments.html')

def company(request):
    topics = Topic.objects.all()
    return render(request, 'company.html',  {'topics': topics})

def purchase(request):
    return render(request, 'purchase.html')

def contact(request):
    return render(request, 'contact.html')

def product1(request):
    return render(request, 'product1.html')


def product2(request):
    return render(request, 'product2.html')

def product3(request):
    return render(request, 'product3.html')

def product4(request):
    return render(request, 'product4.html')

def product5(request):
    return render(request, 'product5.html')

def product6(request):
    return render(request, 'product6.html')

def product7(request):
    return render(request, 'product7.html')

def product8(request):
    return render(request, 'product8.html')

def product9(request):
    return render(request, 'product9.html')


def topics(request, pk):
    topic = Topic.objects.get(pk=pk)
    return render(request, 'topics.html', {'topic': topic})