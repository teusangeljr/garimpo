#!/usr/bin/env bash
set -e

echo "============================="
echo " Garimpo Backend Startup"
echo " $(date)"
echo "============================="

# Verifica se a REDIS_URL está configurada
if [ -z "$REDIS_URL" ]; then
  echo "⚠️  AVISO: REDIS_URL não encontrada! O worker Celery não funcionará corretamente."
else
  echo "✅ REDIS_URL encontrada: ${REDIS_URL:0:20}..."
fi

# Inicia o Celery worker em background, com output redirecionado para stdout
echo "--- Iniciando Celery Worker em background..."
celery -A tasks worker --loglevel=info -P solo 2>&1 &
WORKER_PID=$!
echo "   Worker PID: $WORKER_PID"

# Aguarda 3s para o worker conectar ao Redis antes de iniciar a API
sleep 3

# Verifica se o worker ainda está rodando
if kill -0 $WORKER_PID 2>/dev/null; then
  echo "✅ Worker iniciado com sucesso."
else
  echo "❌ ERRO: Worker falhou ao iniciar! Veja os logs acima."
fi

# Inicia a API do Flask em foreground
echo "--- Iniciando Gunicorn (API)..."
exec gunicorn app:app --timeout 180 --workers 1 --bind 0.0.0.0:${PORT:-5000}
