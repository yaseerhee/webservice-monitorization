#!/bin/bash

# Configuración
URL="http://<YOUR-URL>/login"  # O cualquier endpoint confiable
CHECK_INTERVAL=60  # segundos entre cada chequeo
RETRY_COUNT=3  # Número de intentos antes de reiniciar
TIMEOUT=10  # Timeout de curl

# Comando para levantar SailPoint (modifica según tu caso)
START_COMMAND="/opt/spadmin/iam/bin/start.ksh"

# Nombre del proceso (ajústalo si usas otro servidor)
PROCESS_NAME="user"

# Función para comprobar si el endpoint responde
check_endpoint() {
  curl -s --max-time $TIMEOUT -o /dev/null -w "%{http_code}" "$URL"
}

while true; do
  fail_count=0

  for i in $(seq 1 $RETRY_COUNT); do
    status_code=$(check_endpoint)

    if [[ "$status_code" != "200" ]]; then
      echo "$(date) - Intento $i: Endpoint no responde (Status $status_code)"
      ((fail_count++))
      sleep 5
    else
      echo "$(date) - Servicio responde correctamente (Status $status_code)"
      fail_count=0
      break
    fi
  done

  if [[ $fail_count -eq $RETRY_COUNT ]]; then
    echo "$(date) - Servicio parece estar caído. Reiniciando..."

    # Matar proceso
    pkill -f "$PROCESS_NAME"

    # Espera antes de reiniciar
    sleep 10

    # Arrancar servicio
    echo "$(date) - Ejecutando comando: $START_COMMAND"
    $START_COMMAND

    # Espera para dar tiempo a que arranque
    sleep 30
  fi

  sleep $CHECK_INTERVAL
done
