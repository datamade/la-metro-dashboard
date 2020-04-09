from datetime import datetime, timedelta

from airflow import DAG
from base import DjangoOperator
from django.core.management import call_command


default_args = {
    'start_date': datetime.now() - timedelta(hours=1),
    'execution_timeout': timedelta(minutes=1)
}

dag = DAG(
    'councilmatic_showmigrations',
    default_args=default_args,
    schedule_interval="hourly"
)

def print_migrations():
    call_command('docker-compose', 'run', '--rm', 'airflow', 'python',
                 'la-metro-councilmatic/manage.py', 'showmigrations')


t1 = DjangoOperator(
    task_id='print_migrations',
    dag=dag,
    python_callable=print_migrations
)
