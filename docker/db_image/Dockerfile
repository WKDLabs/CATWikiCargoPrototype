FROM mariadb:10.9
ARG MYSQL_ROOT_PASSWORD
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD

ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=${MYSQL_DATABASE}
ENV MYSQL_USER=${MYSQL_USER}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}

# Install client tools, healthcheck support, etc.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends mariadb-client netcat-openbsd; \
    rm -rf /var/lib/apt/lists/*

COPY db_data/mediawiki-initial.sql /docker-entrypoint-initdb.d/

#RUN cat /docker-entrypoint-initdb.d/mediawiki-initial.sql |  mysql -u"wikiuser" -p"secret1976" "mediawiki"


#RUN mysqld --initialize-insecure --datadir=/var/lib/mysql \
#  && mysqld --datadir=/var/lib/mysql & pid="$!" \
#  && sleep 10 \
#  && mysql --protocol=socket -uroot < /docker-entrypoint-initdb.d/mediawiki-initial.sql \
#  && kill "$pid" \
#  && wait "$pid"

# 3) Ensure entrypoint still works as usual
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld"]

EXPOSE 3306
