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

RUN curl -L -o $COMMITID.zip https://github.com/kendarorg/webvirtcloud/archive/refs/heads/master.zip
RUN unzip $COMMITID.zip
RUN rm -f $COMMITID.zip
RUN mv webvirtcloud-master webvirtcloud
RUN rm -Rf webvirtcloud/doc/ webvirtcloud/Vagrantfile
RUN cp webvirtcloud/conf/supervisor/webvirtcloud.conf /etc/supervisor/conf.d
RUN cp webvirtcloud/conf/nginx/webvirtcloud.conf /etc/nginx/conf.d
RUN chown -R www-data:www-data /srv/webvirtcloud/
RUN cd /srv/webvirtcloud/
RUN mkdir data
RUN cp webvirtcloud/settings.py.template webvirtcloud/settings.py
RUN sed -i "s|'db.sqlite3'|'data/db.sqlite3'|" webvirtcloud/settings.py
RUN virtualenv -p python3 venv
RUN . venv/bin/activate
RUN venv/bin/pip install -r conf/requirements.txt
RUN chown -R www-data:www-data /srv/webvirtcloud/
RUN rm /etc/nginx/sites-enabled/default
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
RUN chown -R www-data:www-data /var/lib/nginx
RUN mkdir /etc/service/nginx
RUN mkdir /etc/service/nginx-log-forwarder
RUN mkdir /etc/service/webvirtcloud
RUN mkdir /etc/service/novnc
RUN cp conf/runit/nginx /etc/service/nginx/run
RUN cp conf/runit/nginx-log-forwarder /etc/service/nginx-log-forwarder/run
RUN cp conf/runit/novncd.sh /etc/service/novnc/run
RUN cp conf/runit/webvirtcloud.sh /etc/service/webvirtcloud/run
RUN rm -rf /tmp/* /var/tmp/*

WORKDIR /srv/webvirtcloud

ADD 01-wsproxy.patch /srv/webvirtcloud/01-wsproxy.patch
ADD 02-forwardssl.patch /srv/webvirtcloud/02-forwardssl.patch

RUN patch -p1 -u <01-wsproxy.patch && \
    patch -p1 -u <02-forwardssl.patch && \
    cp conf/nginx/webvirtcloud.conf /etc/nginx/conf.d && \
    chown -R www-data:www-data /etc/nginx/conf.d/webvirtcloud.conf && \
    rm 01-wsproxy.patch && \
    rm 02-forwardssl.patch

COPY startinit.sh /etc/my_init.d/startinit.sh
