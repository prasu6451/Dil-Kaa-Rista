import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dil_kaa_rista_backend.settings')

application = get_wsgi_application()
