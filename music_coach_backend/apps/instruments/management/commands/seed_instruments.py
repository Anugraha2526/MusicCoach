from django.core.management.base import BaseCommand
from apps.instruments.models import Instrument


class Command(BaseCommand):
    help = 'Seed the database with initial instruments'

    def handle(self, *args, **options):
        instruments_data = [
            {
                'name': 'Piano Lessons',
                'type': 'piano',
                'image_url': '',  # Can be updated later with actual image URLs
            },
            {
                'name': 'Vocal Lessons',
                'type': 'vocals',
                'image_url': '',
            },
            {
                'name': 'Guitar Tuner',
                'type': 'guitar',
                'image_url': '',
            },
            {
                'name': 'Realtime Pitch Graph',
                'type': 'pitch',
                'image_url': '',
            },
        ]

        created_count = 0
        for instrument_data in instruments_data:
            instrument, created = Instrument.objects.get_or_create(
                name=instrument_data['name'],
                defaults={
                    'type': instrument_data['type'],
                    'image_url': instrument_data['image_url'],
                }
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created instrument: {instrument.name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Instrument already exists: {instrument.name}')
                )

        self.stdout.write(
            self.style.SUCCESS(f'\nSuccessfully processed {len(instruments_data)} instruments. '
                             f'{created_count} new instruments created.')
        )

