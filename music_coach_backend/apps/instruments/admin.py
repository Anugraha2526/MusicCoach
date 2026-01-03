from django.contrib import admin
from .models import Instrument


@admin.register(Instrument)
class InstrumentAdmin(admin.ModelAdmin):
    list_display = ('name', 'type', 'image_url', 'created_at', 'updated_at')
    list_filter = ('type', 'created_at')
    search_fields = ('name', 'type')
    readonly_fields = ('created_at', 'updated_at')

