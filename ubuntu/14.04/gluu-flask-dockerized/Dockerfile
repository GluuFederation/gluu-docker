FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install -y libssl-dev python-dev python-pip swig jq curl git-core \
    gcc make zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libssl-dev \
    supervisor
RUN apt-get build-dep -y openssl

RUN echo deb http://ppa.launchpad.net/saltstack/salt/ubuntu \
    `lsb_release -sc` main | tee /etc/apt/sources.list.d/saltstack.list
RUN curl -sSL "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x4759FA960E27C0A6" | apt-key add -

RUN apt-get update
RUN apt-get install -y salt-master

RUN curl -L https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
ENV PYENV_ROOT /root/.pyenv
ENV PATH /root/.pyenv/bin:$PATH
RUN bash -c "eval $(pyenv init -)"

COPY bash-pyenv-snippet.txt /root/snippet.txt
RUN cat /root/snippet.txt >> .bashrc
RUN pyenv install 2.7.6
RUN pyenv global 2.7.6
RUN pyenv virtualenv gluu-flask

RUN git clone https://github.com/GluuFederation/gluu-flask.git /root/gluu-flask
WORKDIR /root/gluu-flask
RUN pyenv local gluu-flask
RUN pip install -I -r requirements.txt

RUN curl -sSL https://get.docker.com/ubuntu/ | sudo sh

RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]
