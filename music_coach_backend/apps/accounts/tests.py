from django.test import TestCase
from django.contrib.auth import get_user_model
from django.db import IntegrityError
from .serializers import validate_strong_password, RegisterSerializer
from rest_framework.exceptions import ValidationError

class CustomUserModelTest(TestCase):
    def test_create_user(self):
        """Test Case ID: UT-USR-01 - CustomUser Model Creation"""
        User = get_user_model()
        email = 'unit@test.com'
        username = 'unituser'
        password = 'Test@1234'

        user = User.objects.create_user(
            email=email,
            username=username,
            password=password
        )

        self.assertEqual(User.objects.count(), 1)
        self.assertIsNotNone(user.id)
        self.assertEqual(user.email, email)
        self.assertEqual(user.username, username)
        self.assertTrue(user.check_password(password))
        self.assertNotEqual(user.password, password)

    def test_superuser_creation_flags(self):
        """Test Case ID: UT-USR-02 - Superuser Creation Flags"""
        User = get_user_model()
        email = 'admin@test.com'
        username = 'adminuser'
        password = 'TestAdmin@123'

        superuser = User.objects.create_superuser(
            email=email,
            username=username,
            password=password
        )

        self.assertTrue(superuser.is_staff)
        self.assertTrue(superuser.is_superuser)
        self.assertEqual(superuser.role, 'admin')

    def test_user_string_representation(self):
        """Test Case ID: UT-STR-01 - User String Representation"""
        User = get_user_model()
        user = User.objects.create_user(
            email='testuser@test.com',
            username='testuser',
            password='Password@123'
        )
        self.assertEqual(str(user), "testuser (user)")

    def test_email_uniqueness_constraint(self):
        """Test Case ID: UT-EMAIL-01 - Email Uniqueness Constraint"""
        User = get_user_model()
        email = 'dup@test.com'

        User.objects.create_user(email=email, username='user1', password='Password@123')
        
        with self.assertRaises(IntegrityError):
            User.objects.create_user(email=email, username='user2', password='Password@123')


class AccountsSerializerTest(TestCase):
    def test_password_strength_validator(self):
        """Test Case ID: UT-VAL-01 - Password Strength Validator"""
        # 1. Test weak passwords
        weak_passwords = ['short', 'nouppercase1!', 'NoSpecialChar1', 'N0L0W3RCAS3!']
        for pwd in weak_passwords:
            with self.assertRaises(ValidationError):
                validate_strong_password(pwd)
        
        # 3. Test strong password
        # Expect no error
        self.assertEqual(validate_strong_password('Valid@1234'), 'Valid@1234')

    def test_register_serializer_validation(self):
        """Test Case ID: UT-SER-01 - RegisterSerializer Validation"""
        # 1. Missing email
        invalid_data = {
            'username': 'newuser',
            'password': 'StrongPassword@123'
            # Missing email
        }
        serializer = RegisterSerializer(data=invalid_data)
        # 2. Validate false
        self.assertFalse(serializer.is_valid())
        self.assertIn('email', serializer.errors)
        
        # 3. Valid data
        valid_data = {
            'username': 'newuser',
            'email': 'newuser@test.com',
            'password': 'StrongPassword@123',
            'first_name': 'New',
            'last_name': 'User'
        }
        serializer_valid = RegisterSerializer(data=valid_data)
        # 4. Validate true
        self.assertTrue(serializer_valid.is_valid(), getattr(serializer_valid, 'errors', None))
