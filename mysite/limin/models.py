from django.db import models

# Create your models here.
class Topic(models.Model):
    subject = models.CharField(max_length=255)
    message = models.TextField(max_length=4000)
    created_at = models.DateTimeField(auto_now_add=True)