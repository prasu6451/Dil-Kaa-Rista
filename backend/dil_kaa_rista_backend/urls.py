from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny

@api_view(['GET'])
@permission_classes([AllowAny])
def api_root_view(request):
    return Response({
        'app_name': 'Dil Kaa Rista Backend API',
        'version': '1.0.0',
        'status': 'online',
        'endpoints': {
            'auth': '/api/auth/',
            'profiles': '/api/profiles/',
            'matches': '/api/matches/',
            'chat': '/api/chat/',
            'admin': '/admin/',
        }
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', api_root_view, name='api-root'),
    path('api/auth/', include('accounts.urls')),
    path('api/profiles/', include('profiles.urls')),
    path('api/matches/', include('matches.urls')),
    path('api/chat/', include('chat.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
