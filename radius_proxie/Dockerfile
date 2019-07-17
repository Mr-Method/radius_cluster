FROM ubuntu:18.04 

RUN apt-get update && apt-get install -yqq \
	libdbi-perl \
	libdbd-mysql-perl \
	libdigest-md5-file-perl \
	libdigest-md4-perl \
	libcrypt-des-perl \
	libdigest-sha-perl \
	libnet-ip-perl \
	libperl5.26 \
	libxml-simple-perl \
	libpdf-api2-perl \
	librrds-perl \
	freeradius \
	vim \
	iputils-ping \
	mysql-client \ 
	freeradius-mysql \
	freeradius-dhcp \ 
	rsyslog 

#RUN addgroup freeradius
#RUN useradd freeradius
#RUN adduser freeradius freeradius

RUN rm -r /etc/freeradius/3.0/*
COPY raddb_proxie /etc/freeradius/3.0/
RUN chown -R freerad:freerad /etc/freeradius

#COPY ABILLS CONFIG
RUN mkdir /usr/abills
COPY abills /usr/abills/



COPY docker-entrypoint.sh /

EXPOSE 1812/udp 1813/udp
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeradius"]
