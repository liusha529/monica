#!/bin/sh

MONICADIR=/var/www/monica
ARTISAN="php ${MONICADIR}/artisan"

# Ensure storage directories are present
STORAGE=${MONICADIR}/storage
mkdir -p ${STORAGE}/logs
mkdir -p ${STORAGE}/app/public
mkdir -p ${STORAGE}/framework/views
mkdir -p ${STORAGE}/framework/cache
mkdir -p ${STORAGE}/framework/sessions
chown -R monica:apache ${STORAGE}
chmod -R g+rw ${STORAGE}

if [[ -z ${APP_KEY:-} || "$APP_KEY" == "ChangeMeBy32KeyLengthOrGenerated" ]]; then
  ${ARTISAN} key:generate --no-interaction
else
  echo "APP_KEY already set"
fi

# Run migrations
${ARTISAN} monica:update --force -v

if [[ -n ${SENTRY_SUPPORT:-} && $SENTRY_SUPPORT && -z ${SENTRY_NORELEASE:-} ]]; then
  commit=$(cat .sentry-commit)
  release=$(cat .sentry-release)
  ${ARTISAN} sentry:release --release=$release --commit=$commit --environment=$SENTRY_ENV -v || true
fi

# Run cron
crond -b &

# Run apache2
rm -f /run/apache2/httpd.pid
httpd -DFOREGROUND
