from rest_framework import permissions

class IsAdminRole(permissions.BasePermission):
    """
    Requires the user to have role='admin' or be a staff member.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and 
            request.user.is_authenticated and 
            (request.user.role == 'admin' or request.user.is_staff)
        )
