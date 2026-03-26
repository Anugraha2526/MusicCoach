"""
ASGI config for musiccoach_api project.
"""

import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "musiccoach_api.settings")

from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from musiccoach_api.routing import websocket_urlpatterns

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
