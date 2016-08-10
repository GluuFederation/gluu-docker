FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update && apt-get install -y --force-yes \
    curl \
    python \
    python-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app

ENV UILINK https://github.com/GluuFederation/gluu-webui/archive/v0.5.1.tar.gz

RUN curl -L "$UILINK" > /tmp/ui.tar.gz \
    && tar -zxf /tmp/ui.tar.gz --strip-components=1 -C /app \
    && rm -f /tmp/ui.tar.gz

WORKDIR /app

RUN pip install -U pip

# A workaround to make sure latest pip is being used, not from OS one
ENV PYTHONPATH="/usr/local/lib/python2.7/dist-packages:/usr/lib/python2.7/dist-packages"

RUN pip install -r requirements/prod.txt
RUN pip install gunicorn
RUN python setup.py develop

ENTRYPOINT ["gunicorn", "-b", ":8800", "--access-logfile", "-", "--error-logfile", "-", "gluuwebui:app"]

EXPOSE 8800
