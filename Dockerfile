# docker build -t kendar/webvirtcloud .
FROM phusion/baseimage:0.11

LABEL maintainer="kendar"
LABEL maintainer="kendar <mplx+docker@donotreply.at>"

EXPOSE 80

CMD ["/sbin/my_init"]

RUN apt-get update -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get -qyy install \
    -o APT::Install-Suggests=false \
    virtualenv \
    python3-virtualenv \
    python3-dev \
    python3-lxml \
    libxml2-dev \
    libsasl2-dev \
    libldap2-dev \
    libxslt1-dev \
    libssl-dev \
    libvirt-dev \
    zlib1g-dev \
    nginx \
    supervisor \
    libsasl2-modules \
    unzip \
    gcc \
    pkg-config \
    python3-guestfs \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p /srv


WORKDIR /srv

ENV COMMITID=0b7e334dadeca70cd8b901d25dda61ccd7abb2df

RUN curl -L -o $COMMITID.zip https://github.com/kendarorg/webvirtcloud/archive/refs/heads/master.zip && \
     unzip $COMMITID.zip && \
     rm -f $COMMITID.zip && \
     mv webvirtcloud-master webvirtcloud && \
     rm -Rf webvirtcloud/doc/ webvirtcloud/Vagrantfile && \
     cp webvirtcloud/conf/supervisor/webvirtcloud.conf /etc/supervisor/conf.d && \
     cp webvirtcloud/conf/nginx/webvirtcloud.conf /etc/nginx/conf.d && \
     chown -R www-data:www-data /srv/webvirtcloud/ && \
     cd /srv/webvirtcloud/ && \
     mkdir data && \
     cp webvirtcloud/settings.py.template webvirtcloud/settings.py && \
     sed -i "s|'db.sqlite3'|'data/db.sqlite3'|" webvirtcloud/settings.py && \
     virtualenv -p python3 venv && \
     . venv/bin/activate && \
     venv/bin/pip install -r conf/requirements.txt && \
     chown -R www-data:www-data /srv/webvirtcloud/ && \
     rm /etc/nginx/sites-enabled/default && \
     echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
     chown -R www-data:www-data /var/lib/nginx && \
     mkdir /etc/service/nginx && \
     mkdir /etc/service/nginx-log-forwarder && \
     mkdir /etc/service/webvirtcloud && \
     mkdir /etc/service/novnc && \
     cp conf/runit/nginx /etc/service/nginx/run && \
     cp conf/runit/nginx-log-forwarder /etc/service/nginx-log-forwarder/run && \
     cp conf/runit/novncd.sh /etc/service/novnc/run && \
     cp conf/runit/webvirtcloud.sh /etc/service/webvirtcloud/run && \
     rm -rf /tmp/* /var/tmp/*

WORKDIR /srv/webvirtcloud

ADD 01-wsproxy.patch /srv/webvirtcloud/01-wsproxy.patch
ADD 02-forwardssl.patch /srv/webvirtcloud/02-forwardssl.patch

RUN sed -i 's/websockify/{{ ws_path }}/g' console/templates/console-vnc-full.html
RUN sed -i 's/websockify/{{ ws_path }}/g' console/templates/console-vnc-lite.html
RUN sed -i 's/WS_PUBLIC_PORT = 6080/WS_PUBLIC_PORT = 80/g' webvirtcloud/settings.py.template
RUN cp conf/nginx/webvirtcloud.conf /etc/nginx/conf.d
RUN chown -R www-data:www-data /etc/nginx/conf.d/webvirtcloud.conf

COPY startinit.sh /etc/my_init.d/startinit.sh
