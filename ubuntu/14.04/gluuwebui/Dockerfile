FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

#RUN echo "deb http://repo.gluu.org/ubuntu/ trusty-devel main" > /etc/apt/sources.list.d/gluu-repo.list

RUN apt-get update && apt-get install -y --force-yes \
    apache2 \
    python \
    libapache2-mod-wsgi \
    python-pip \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#RUN curl http://repo.gluu.org/ubuntu/gluu-apt.key | apt-key add -
RUN pip install -q --upgrade pip
RUN pip install -q Flask==0.10.1 itsdangerous==0.24 Jinja2==2.7.3 MarkupSafe==0.23 requests==2.7.0 Werkzeug==0.10.4
RUN mkdir -p /var/www/gluu-cluster-webui

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY gluuwebui.wsgi /var/www/gluu-cluster-webui/gluuwebui.wsgi
COPY gluu-cluster-webui.conf /etc/apache2/sites-available/gluu-cluster-webui.conf

RUN a2dissite 000-default
RUN a2ensite gluu-cluster-webui.conf

CMD ["/usr/bin/supervisord"]

EXPOSE 80