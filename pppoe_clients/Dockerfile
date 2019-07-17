FROM ubuntu:18.04

RUN apt-get update && apt-get install -yqq ppp \
        freeradius \
        net-tools \
        vim \
        kmod

RUN apt-get  install -yqq iputils-ping

CMD ping -i 30 8.8.8.8

