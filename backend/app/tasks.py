# app/tasks.py

import asyncio
from app.core.celery_app import celery_app
from app.workers.profit_worker import run_profit_calculation
from app.workers.vip_worker import run_vip_validation

# create global loop
loop = asyncio.new_event_loop()
asyncio.set_event_loop(loop)


@celery_app.task
def profit_task():
    return loop.run_until_complete(run_profit_calculation())


@celery_app.task
def vip_task():
    return loop.run_until_complete(run_vip_validation())