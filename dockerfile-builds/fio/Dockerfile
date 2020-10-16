FROM ubuntu:xenial

MAINTAINER Support support@diamanti.com

RUN eval $(minikube docker-env)

RUN apt-get update -yq && apt-get install -yq fio

RUN mkdir /data
RUN mkdir /config

ADD job.fio /config/

ADD start.sh /start.sh

ENTRYPOINT ["/start.sh"]
