from django.db import models


class Instrument(models.Model):
    name = models.CharField(max_length=100, unique=True)
    type = models.CharField(max_length=50)  # e.g., 'piano', 'guitar', 'vocals', 'pitch'
    image_url = models.URLField(max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'instruments'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.type})"

