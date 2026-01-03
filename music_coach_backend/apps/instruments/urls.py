from django.urls import path
from .views import InstrumentListView, InstrumentDetailView

urlpatterns = [
    path('', InstrumentListView.as_view(), name='instrument-list'),
    path('<int:id>/', InstrumentDetailView.as_view(), name='instrument-detail'),
]

