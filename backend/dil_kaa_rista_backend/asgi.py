import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dil_kaa_rista_backend.settings')

application = get_asgi_application()
