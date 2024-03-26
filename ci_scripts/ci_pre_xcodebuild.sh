#!/bin/zsh

cd ${0:h:a}/.. || exit 1

./scripts/set_telemetrydeck_app_id.sh $TELEMETRYDECK_APP_ID
