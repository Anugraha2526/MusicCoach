from django.test import TestCase
from .models import Module, Lesson

class ModuleModelTest(TestCase):
    def test_module_string_representation(self):
        """Test Case ID: UT-MOD-01 - Module String Representation"""
        # 1. Create module
        module = Module.objects.create(title="Basics", order=1)
        
        # 2. Call str()
        # Expected Result: "Module 1: Basics"
        self.assertEqual(str(module), "Module 1: Basics")


class LessonModelTest(TestCase):
    def test_lesson_ordering_logic(self):
        """Test Case ID: UT-LES-01 - Lesson Ordering Logic"""
        # Create a parent module
        module = Module.objects.create(title="Basics", order=1)
        
        # 1. Create lessons out of order
        Lesson.objects.create(module=module, title="Lesson C", order=3)
        Lesson.objects.create(module=module, title="Lesson A", order=1)
        Lesson.objects.create(module=module, title="Lesson B", order=2)
        
        # 2. Query all
        lessons = list(Lesson.objects.all())
        
        # Expected Result: Ordered 1, 2, 3
        self.assertEqual(lessons[0].order, 1)
        self.assertEqual(lessons[0].title, "Lesson A")
        self.assertEqual(lessons[1].order, 2)
        self.assertEqual(lessons[1].title, "Lesson B")
        self.assertEqual(lessons[2].order, 3)
        self.assertEqual(lessons[2].title, "Lesson C")
