from celery import Celery

celery_app = Celery(
    "goldx",
    broker="redis://localhost:6380/0",
    backend="redis://localhost:6380/0",
)

# IMPORTANT: auto-discover tasks
celery_app.autodiscover_tasks(["app"])

# 🔥 Schedule config goes here
celery_app.conf.beat_schedule = {
    "profit-worker": {
        "task": "app.tasks.profit_task",
        "schedule": 60.0,  # every 1 minute
    },
    "vip-worker": {
        "task": "app.tasks.vip_task",
        "schedule": 3600.0,  # every 1 hour
    },
}