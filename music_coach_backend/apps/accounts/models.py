from django.contrib.auth.models import AbstractUser
from django.db import models

ROLE_CHOICES = (
    ('admin', 'Admin'),
    ('user', 'User'),
)

class CustomUser(AbstractUser):
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='user')
    natural_pitch = models.FloatField(null=True, blank=True, help_text="User's natural speaking pitch in Hz")
    current_streak = models.IntegerField(default=0)
    last_active_date = models.DateField(null=True, blank=True)

    # Make email the USERNAME_FIELD for authentication
    email = models.EmailField(unique=True)  # ensure unique
    USERNAME_FIELD = 'email'  # login uses email now
    REQUIRED_FIELDS = ['username']  # still required when creating superuser

    def __str__(self):
        return f"{self.username} ({self.role})"
