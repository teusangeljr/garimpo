from celery import Celery
import os

def make_celery(app_name=__name__):
    # Procura pela URL do Redis
    redis_url = os.environ.get('REDIS_URL') or os.environ.get('REDIS_TLS_URL')
    
    if not redis_url:
        print("⚠️ AVISO: REDIS_URL não encontrada. Usando localhost.")
        redis_url = 'redis://localhost:6379/0'
    else:
        redis_url = redis_url.strip()
        # Se a URL começar com rediss://, o Render exige configurações de SSL
        print(f"✅ Configurando Celery para Redis: {redis_url[:15]}...")

    # Configuração de SSL para conexões seguras (essencial para o Render Redis)
    ssl_conf = {}
    if redis_url.startswith("rediss://"):
        ssl_conf = {
            "ssl_cert_reqs": "none"  # Redes internas do Render não pedem validação de certificado
        }

    celery = Celery(
        app_name,
        broker=redis_url,
        backend=redis_url,
        include=['tasks']
    )
    
    celery.conf.update(
        # --- Configurações de Conectividade ---
        broker_use_ssl=ssl_conf,
        redis_backend_use_ssl=ssl_conf,
        broker_connection_retry_on_startup=True,
        
        # --- Performance & Estabilidade ---
        task_serializer='json',
        accept_content=['json'],
        result_serializer='json',
        timezone='UTC',
        enable_utc=True,
        task_track_started=True,
        task_time_limit=300, # Reduzi para 5 min; 1h pode travar seu worker no Render
        
        
        # Importante para tarefas pesadas (como Selenium no Garimpo):
        worker_prefetch_multiplier=1, # O worker pega uma tarefa por vez
        worker_max_tasks_per_child=50 # Reinicia o processo após 50 tarefas para liberar RAM
    )
    
    return celery

celery = make_celery()