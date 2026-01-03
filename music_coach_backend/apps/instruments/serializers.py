from rest_framework import serializers
from .models import Instrument


class InstrumentSerializer(serializers.ModelSerializer):
    instrument_id = serializers.IntegerField(source='id', read_only=True)

    class Meta:
        model = Instrument
        fields = ['instrument_id', 'name', 'type', 'image_url', 'created_at', 'updated_at']
        read_only_fields = ['instrument_id', 'created_at', 'updated_at']

