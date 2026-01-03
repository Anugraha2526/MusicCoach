from rest_framework import generics, permissions
from rest_framework.response import Response
from .models import Instrument
from .serializers import InstrumentSerializer


class InstrumentListView(generics.ListAPIView):
    """
    List all instruments
    """
    queryset = Instrument.objects.all()
    serializer_class = InstrumentSerializer
    permission_classes = [permissions.AllowAny]  # Allow anyone to view instruments


class InstrumentDetailView(generics.RetrieveAPIView):
    """
    Retrieve a specific instrument
    """
    queryset = Instrument.objects.all()
    serializer_class = InstrumentSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'id'

