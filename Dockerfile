FROM publish/pie-base:latest-ubuntu22.04

RUN set -xe \
    && apt-get update \
    && apt-get update && apt-get install -y --no-install-recommends \
        iproute2 \
        libcurl4 \
        libnetaddr-ip-perl \
        shibboleth-sp-utils \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/log/shibboleth/*


COPY etc/ /etc
COPY pie-entrypoint.sh /usr/local/bin/

RUN chmod a+rx /usr/local/bin/pie-entrypoint.sh
RUN mkdir -p /var/run/shibboleth

RUN cp -av /etc/shibboleth /etc/shibboleth-dist

ENV SHIBD_SERVER_ADMIN="webmaster@example.org" \
    SHIBD_LISTENER="" \
    SHIBD_TCPLISTENER_ADDRESS="" \
    SHIBD_TCPLISTENER_ACL="" \
    SHIBD_ENTITYID="https://host.name.illinois.edu/shibboleth" \
    SHIBD_ATTRIBUTES="" \
    SHIBD_CONFIG_SUFFIX="" \
    SHIBD_LOGGING="" \
    SHIBD_SP_KEY="sp-key.pem" \
    SHIBD_SP_CERT="sp-cert.pem"

ENV SHIBD_STORE_DYNAMODB_TABLE="" \
    SHIBD_STORE_DYNAMODB_REGION="" \
    SHIBD_STORE_DYNAMODB_ENDPOINT=""

VOLUME /etc/shibboleth /etc/opt/pie/shibboleth
VOLUME /run/shibboleth
VOLUME /var/log/shibboleth

EXPOSE 1600

ENTRYPOINT ["/usr/local/bin/pie-entrypoint.sh"]
CMD ["shibd-pie"]
