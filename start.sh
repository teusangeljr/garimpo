#!/usr/bin/env bash

# Inicia o Celery worker em background
echo "Iniciando Celery Worker..."
celery -A tasks worker --loglevel=info -P solo &

# Inicia a API do Flask em foreground (O Render precisa que a API fique em foreground)
echo "Iniciando Gunicorn (API)..."
gunicorn app:app --timeout 180
