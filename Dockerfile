FROM sbutler/pie-base

RUN set -xe \
    && apt-get update && apt-get install -y \
        shibboleth-sp2-utils \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY etc/ /etc
COPY pie-entrypoint.sh /usr/local/bin/

RUN set -xe \
    && chmod a+rx /usr/local/bin/pie-entrypoint.sh \
    && mkdir -p /var/run/shibboleth

ENV SHIBD_SERVER_ADMIN  "webmaster@example.org"
ENV SHIBD_ADDRESS       ""
ENV SHIBD_ENTITYID      "https://host.name.illinois.edu/shibboleth"
ENV SHIBD_ATTRIBUTES    ""

VOLUME /etc/opt/pie/shibboleth
VOLUME /etc/shibboleth
VOLUME /var/run/shibboleth

EXPOSE 1600

ENTRYPOINT ["/usr/local/bin/pie-entrypoint.sh"]
CMD ["shibd-pie"]
