from app.core.celery_app import celery_app

@celery_app.task
def profit_task():
    import asyncio
    from app.workers.profit_worker import run_profit_calculation
    asyncio.run(run_profit_calculation())


@celery_app.task
def vip_task():
    import asyncio
    from app.workers.vip_worker import run_vip_validation
    asyncio.run(run_vip_validation())