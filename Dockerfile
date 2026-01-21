FROM docker.elastic.co/logstash/logstash:8.7.1
WORKDIR /usr/share/logstash
COPY ./pipelines/ /usr/share/logstash/pipelines/
COPY ./config/ /usr/share/logstash/config/
COPY ./ssl/ /usr/share/logstash/ssl/
COPY ./entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN curl https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.8.0.jre11/mssql-jdbc-12.8.0.jre11.jar \
    -o logstash-core/lib/jars/mssql-jdbc-12.8.0.jre11.jar