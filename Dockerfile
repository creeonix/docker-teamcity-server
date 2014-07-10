FROM phusion/baseimage

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

RUN apt-get update
RUN apt-get install -y wget curl

# Postgres goes first
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main\n" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update
RUN apt-get -y install postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3 pwgen

# We need JRE
RUN apt-get install -y default-jre

# Team-City Goes last
RUN curl http://download-ln.jetbrains.com/teamcity/TeamCity-8.1.3.tar.gz | tar -xz -C /opt

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf
# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/var/lib/teamcity"]

# Enable the correct Valve when running behind a proxy
RUN sed -i -e "s/\.*<\/Host>.*$/<Valve className=\"org.apache.catalina.valves.RemoteIpValve\" protocolHeader=\"x-forwarded-proto\" \/><\/Host>/" /opt/TeamCity/conf/server.xml

# Expose the SSH, PostgreSQL and Teamcity port
EXPOSE 22 5432 8111

ENV TEAMCITY_DATA_PATH /var/lib/teamcity

ADD service /etc/service

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
