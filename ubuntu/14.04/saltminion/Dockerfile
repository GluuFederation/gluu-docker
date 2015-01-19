FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get install -y \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo deb http://ppa.launchpad.net/saltstack/salt/ubuntu `lsb_release -sc` main | sudo tee /etc/apt/sources.list.d/saltstack.list
RUN wget -q -O- "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x4759FA960E27C0A6" | sudo apt-key add -

RUN apt-get update && apt-get install -y \
    salt-minion \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY minion /etc/salt/minion

CMD ["/usr/bin/salt-minion"]
