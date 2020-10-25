from django.urls import path

from api.views import authorize, attend, get_attendance

urlpatterns = [
    path('authorize', authorize),
    path('attend', attend),
    path('get_attendance', get_attendance)
]
