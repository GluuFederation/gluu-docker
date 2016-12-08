#!/bin/bash
set -e

if [ "$1" = 'message-consumer' ]; then
    # if there's a custom config file, load it
    if [ -f /etc/message-consumer/config.sh ]; then
        source /etc/message-consumer/config.sh
    fi

    if [ ! -z $SPRING_PROFILES_ACTIVE ]; then
        SPRING_PROFILES_ACTIVE_OPT="--spring.profiles.active=${SPRING_PROFILES_ACTIVE}"
    fi

    if [ ! -z $SPRING_ACTIVEMQ_BROKER_URL ]; then
        SPRING_ACTIVEMQ_BROKER_URL_OPT="--spring.activemq.broker-url=${SPRING_ACTIVEMQ_BROKER_URL}"
    fi

    if [ ! -z $SPRING_ACTIVEMQ_USER ]; then
        SPRING_ACTIVEMQ_USER_OPT="--spring.activemq.user=${SPRING_ACTIVEMQ_USER}"
    fi

    if [ ! -z $SPRING_ACTIVEMQ_PASSWORD ]; then
        SPRING_ACTIVEMQ_PASSWORD_OPT="--spring.activemq.password=${SPRING_ACTIVEMQ_PASSWORD}"
    fi

    if [ ! -z $SPRING_DATASOURCE_URL ]; then
        SPRING_DATASOURCE_URL_OPT="--spring.datasource.url=${SPRING_DATASOURCE_URL}"
    fi

    if [ ! -z $SPRING_DATASOURCE_USERNAME ]; then
        SPRING_DATASOURCE_USERNAME_OPT="--spring.datasource.username=${SPRING_DATASOURCE_USERNAME}"
    fi

    if [ ! -z $SPRING_DATASOURCE_PASSWORD ]; then
        SPRING_DATASOURCE_PASSWORD_OPT="--spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}"
    fi

    # run the app
    exec java -jar /opt/message-consumer-0.0.1-SNAPSHOT.jar \
        $SPRING_PROFILES_ACTIVE_OPT \
        $SPRING_ACTIVEMQ_BROKER_URL_OPT \
        $SPRING_ACTIVEMQ_USER_OPT \
        $SPRING_ACTIVEMQ_PASSWORD_OPT \
        $SPRING_DATASOURCE_URL_OPT \
        $SPRING_DATASOURCE_USERNAME_OPT \
        $SPRING_DATASOURCE_PASSWORD_OPT
fi

# run everything else
exec "$@"
