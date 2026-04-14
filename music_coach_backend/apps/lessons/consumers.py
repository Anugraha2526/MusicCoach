import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from datetime import timedelta
from django.db.models import Count
from django.db.models.functions import TruncDate

STATS_GROUP = "admin_dashboard"


class DashboardConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add(STATS_GROUP, self.channel_name)
        await self.accept()
        stats = await self.get_stats()
        await self.send(text_data=json.dumps(stats))

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(STATS_GROUP, self.channel_name)

    async def stats_update(self, event):
        await self.send(text_data=json.dumps(event["data"]))

    @database_sync_to_async
    def get_stats(self):
        from django.contrib.auth import get_user_model
        from apps.lessons.models import UserProgress

        User = get_user_model()

        total_users = User.objects.count()

        today = timezone.now().date()
        seven_days_ago = today - timedelta(days=6)

        daily_users = (
            User.objects.filter(date_joined__date__gte=seven_days_ago)
            .annotate(date=TruncDate("date_joined"))
            .values("date")
            .annotate(count=Count("id"))
            .order_by("date")
        )

        daily_data_dict = {str(item["date"]): item["count"] for item in daily_users}

        daily_users_data = []
        for i in range(7):
            day = seven_days_ago + timedelta(days=i)
            day_str = day.strftime("%a")[0]
            daily_users_data.append({
                "name": day_str,
                "users": daily_data_dict.get(str(day), 0),
            })

        piano_completed = 0
        vocal_completed = 0
        for progress in UserProgress.objects.prefetch_related(
            "completed_lessons__module__instrument"
        ).all():
            for lesson in progress.completed_lessons.all():
                instrument_name = (
                    lesson.module.instrument.name
                    if lesson.module.instrument
                    else ""
                )
                if "piano" in instrument_name.lower():
                    piano_completed += 1
                elif "vocal" in instrument_name.lower():
                    vocal_completed += 1

        total_completed = piano_completed + vocal_completed

        from apps.accounts.serializers import AdminUserSerializer
        users_qs = User.objects.prefetch_related(
            'progress__completed_lessons__module__instrument'
        ).all().order_by('-id')
        users_data = AdminUserSerializer(users_qs, many=True).data

        return {
            "type": "stats_update",
            "total_users": total_users,
            "total_lessons_completed": total_completed,
            "piano_lessons_completed": piano_completed,
            "vocal_lessons_completed": vocal_completed,
            "new_signups_today": daily_data_dict.get(str(today), 0),
            "daily_users_data": daily_users_data,
            "lesson_breakdown_data": [
                {"name": "Piano", "lessons": piano_completed},
                {"name": "Vocal", "lessons": vocal_completed},
            ],
            "users": list(users_data),
        }
