from django.contrib import admin
from .models import Module, Lesson, PracticeSequence


class PracticeSequenceInline(admin.TabularInline):
    model = PracticeSequence
    extra = 1


@admin.register(Module)
class ModuleAdmin(admin.ModelAdmin):
    list_display = ('title', 'order', 'created_at')
    search_fields = ('title',)
    ordering = ('order',)


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = ('title', 'module', 'lesson_type', 'order')
    list_filter = ('module', 'lesson_type')
    search_fields = ('title',)
    inlines = [PracticeSequenceInline]


@admin.register(PracticeSequence)
class PracticeSequenceAdmin(admin.ModelAdmin):
    list_display = ('lesson', 'order', 'short_notes')
    ordering = ('lesson', 'order')

    def short_notes(self, obj):
        return str(obj.notes)[:50]
