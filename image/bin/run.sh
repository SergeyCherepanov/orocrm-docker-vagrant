#!/bin/bash

APP_ROOT="/var/www"
DATA_ROOT="/srv/app-data"

# Prepare folders for persistent data
[[ -d ${DATA_ROOT}/config ]]         || sudo -u www-data mkdir -p ${DATA_ROOT}/config
[[ -d ${DATA_ROOT}/cache ]]          || sudo -u www-data mkdir -p ${DATA_ROOT}/cache
[[ -d ${DATA_ROOT}/media ]]          || sudo -u www-data mkdir -p ${DATA_ROOT}/media
[[ -d ${DATA_ROOT}/uploads ]]        || sudo -u www-data mkdir -p ${DATA_ROOT}/uploads
[[ -d ${DATA_ROOT}/attachment ]]     || sudo -u www-data mkdir -p ${DATA_ROOT}/attachment

# If it's the first run
if [[ 0 -eq $(ls ${DATA_ROOT}/config/ | wc -l) ]]
then
    # Generate parameters.yml
    sudo -u www-data -E composer run-script post-install-cmd -n -d ${APP_ROOT};

    # Copy configs
    sudo -u www-data cp -r ${APP_ROOT}/app/config/* ${DATA_ROOT}/config/
fi

# Clean exists folders
[[ -d ${APP_ROOT}/app/config ]]     && rm -r ${APP_ROOT}/app/config
[[ -d ${APP_ROOT}/app/cache ]]      && rm -r ${APP_ROOT}/app/cache
[[ -d ${APP_ROOT}/web/media ]]      && rm -r ${APP_ROOT}/web/media
[[ -d ${APP_ROOT}/web/uploads ]]    && rm -r ${APP_ROOT}/web/uploads
[[ -d ${APP_ROOT}/app/attachment ]] && rm -r ${APP_ROOT}/app/attachment

# Linking persistent data
sudo -u www-data ln -s ${DATA_ROOT}/config      ${APP_ROOT}/app/config
sudo -u www-data ln -s ${DATA_ROOT}/cache       ${APP_ROOT}/app/cache
sudo -u www-data ln -s ${DATA_ROOT}/media       ${APP_ROOT}/web/media
sudo -u www-data ln -s ${DATA_ROOT}/uploads     ${APP_ROOT}/web/uploads
sudo -u www-data ln -s ${DATA_ROOT}/attachment  ${APP_ROOT}/app/attachment

if [[ -z ${APP_DB_PORT} ]]; then
    if [[ "pdo_pgsql" = ${APP_DB_DRIVER} ]]; then
        APP_DB_PORT="5432"
    else
        APP_DB_PORT="3306"
    fi
fi

until nc -z ${APP_DB_HOST} ${APP_DB_PORT-3306}; do
    echo "Waiting database on ${APP_DB_HOST}:${APP_DB_PORT}"
    sleep 2
done

if [[ ! -z ${CMD_INIT_BEFORE} ]]; then
    echo "Running pre init command: ${CMD_INIT_BEFORE}"
    sh -c "${CMD_INIT_BEFORE}"
fi

cd ${APP_ROOT}

# If already installed
if [[ -f /var/www/app/config/parameters.yml ]] && [[ 0 -lt `cat /var/www/app/config/parameters.yml | grep ".*installed:\s*[\']\{0,1\}[a-zA-Z0-9\:\+\-]\{1,\}[\']\{0,1\}" | grep -v "null" | wc -l` ]]
then
    echo "Prepare application..."
    rm -r ${APP_ROOT}/app/cache/*
    sudo -u www-data ${APP_ROOT}/app/console --env=prod assets:install
    sudo -u www-data ${APP_ROOT}/app/console --env=prod oro:navigation:init
    sudo -u www-data ${APP_ROOT}/app/console --env=prod fos:js-routing:dump --target=web/js/routes.js
    sudo -u www-data ${APP_ROOT}/app/console --env=prod oro:localization:dump
    sudo -u www-data ${APP_ROOT}/app/console --env=prod assetic:dump
    sudo -u www-data ${APP_ROOT}/app/console --env=prod oro:translation:dump
    sudo -u www-data ${APP_ROOT}/app/console --env=prod oro:requirejs:build
    sudo -u www-data ${APP_ROOT}/app/console --env=prod cache:clear

    if [[ ! -z ${CMD_INIT_INSTALLED} ]]; then
        echo "Running init command: ${CMD_INIT_INSTALLED}"
        sh -c "${CMD_INIT_INSTALLED}"
    fi
else
    if [[ ! -z ${CMD_INIT_CLEAN} ]]; then
        echo "Running init command: ${CMD_INIT_CLEAN}"
        sh -c "${CMD_INIT_CLEAN}"
    fi
fi

if [[ ! -z ${CMD_INIT_AFTER} ]]; then
    echo "Running post init command: ${CMD_INIT_AFTER}"
    sh -c "${CMD_INIT_AFTER}"
fi

# Starting services
exec /usr/local/bin/supervisord -n

