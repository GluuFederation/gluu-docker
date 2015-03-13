FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update

RUN apt-get install -y \
    wget \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo deb http://ppa.launchpad.net/saltstack/salt/ubuntu `lsb_release -sc` main | sudo tee /etc/apt/sources.list.d/saltstack.list
RUN wget -q -O- "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x4759FA960E27C0A6" | sudo apt-key add -

RUN apt-get update && apt-get install -y \
    salt-minion \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor
RUN mkdir -p /opt/gluu/bin

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY minion /etc/salt/minion
COPY render.sh /opt/gluu/bin/render.sh

RUN chmod +x /opt/gluu/bin/render.sh

CMD ["/usr/bin/supervisord"]
