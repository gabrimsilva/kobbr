#!/usr/bin/env bash
# Deploy do KOBE para a Hostinger via SSH.
# Uso: ./deploy.sh            -> roda build e sobe
#      ./deploy.sh --no-build -> sobe o dist atual
set -euo pipefail
cd "$(dirname "$0")"

REMOTE=hostinger
BASE=domains/oondelivery.com.br/public_html
APP=kobe

if [ "${1:-}" != "--no-build" ]; then
  npm run build
fi
[ -f dist/index.html ] || { echo "dist/index.html não encontrado"; exit 1; }

STAMP=$(date +%Y%m%d-%H%M%S)
echo ">> Enviando dist ($STAMP)..."
tar -czf - -C dist . | ssh "$REMOTE" "set -e
  cd $BASE
  rm -rf .${APP}_new && mkdir .${APP}_new
  tar -xzf - -C .${APP}_new
  [ -d $APP ] && mv $APP .${APP}_bak_$STAMP
  mv .${APP}_new $APP
  ls -dt .${APP}_bak_* 2>/dev/null | tail -n +4 | xargs -r rm -rf
  echo 'OK: deploy concluído em $BASE/$APP'"
