#!/bin/bash
set -e

SPRING_EXTERNAL_PROPERTIES=/etc/message-consumer/application-gluu.properties

if [ -f $SPRING_EXTERNAL_PROPERTIES ]; then
    # if there's an external properties file, load it
    APP_OPTS="--spring.config.location=/etc/message-consumer/ --spring.config.name=application-gluu"
else
    # fallback to default properties
    APP_OPTS="--spring.profiles.active=prod-mysql"
fi

exec java -jar /opt/message-consumer-0.0.1-SNAPSHOT.jar $APP_OPTS
