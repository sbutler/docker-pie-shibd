# Copyright (c) 2017 University of Illinois Board of Trustees
# All rights reserved.
#
# Developed by: 		Technology Services
#                      	University of Illinois at Urbana-Champaign
#                       https://techservices.illinois.edu/
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# with the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
#	* Redistributions of source code must retain the above copyright notice,
#	  this list of conditions and the following disclaimers.
#	* Redistributions in binary form must reproduce the above copyright notice,
#	  this list of conditions and the following disclaimers in the
#	  documentation and/or other materials provided with the distribution.
#	* Neither the names of Technology Services, University of Illinois at
#	  Urbana-Champaign, nor the names of its contributors may be used to
#	  endorse or promote products derived from this Software without specific
#	  prior written permission.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH
# THE SOFTWARE.
FROM ubuntu:18.04 AS uiuc-shibplugins

RUN apt-get update
RUN apt-get -y install \
    build-essential \
    cmake \
    git \
    gnupg \
    libboost-all-dev \
    libcurl4-openssl-dev

COPY uiuc-shibplugins/ /source
COPY SWITCHaai-swdistrib.asc /root
COPY SWITCHaai-swdistrib.list /etc/apt/sources.list.d
RUN set -xe \
    && apt-key add /root/SWITCHaai-swdistrib.asc \
    && apt-get update
RUN apt-get -y install shibboleth libshibsp-dev

RUN chmod a+rx /source/docker/ubuntu18.04/build.sh

WORKDIR /build
RUN /source/docker/ubuntu18.04/build.sh


FROM sbutler/pie-base:latest-ubuntu18.04

COPY SWITCHaai-swdistrib.asc /tmp/
COPY SWITCHaai-swdistrib.list /tmp/

RUN set -xe \
    && apt-get update \
    && apt-get install -y gnupg --no-install-recommends \
    && apt-key add /tmp/SWITCHaai-swdistrib.asc && rm /tmp/SWITCHaai-swdistrib.asc \
    && mv /tmp/SWITCHaai-swdistrib.list /etc/apt/sources.list.d/ \
    && apt-get update && apt-get install -y --no-install-recommends \
        libcurl4 \
        libnetaddr-ip-perl \
        shibboleth-sp-utils \
    && rm -rf /var/lib/apt/lists/*

COPY etc/ /etc
COPY pie-entrypoint.sh /usr/local/bin/
COPY --from=uiuc-shibplugins /output/lib/libuiuc-shibplugins.so /usr/local/lib

RUN chmod a+rx /usr/local/bin/pie-entrypoint.sh
RUN mkdir -p /var/run/shibboleth

ENV SHIBD_SERVER_ADMIN="webmaster@example.org" \
    SHIBD_TCPLISTENER_ADDRESS="" \
    SHIBD_TCPLISTENER_ACL="" \
    SHIBD_ENTITYID="https://host.name.illinois.edu/shibboleth" \
    SHIBD_ATTRIBUTES="" \
    SHIBD_CONFIG_SUFFIX=""

VOLUME /etc/shibboleth /etc/opt/pie/shibboleth
VOLUME /run/shibboleth

EXPOSE 1600

ENTRYPOINT ["/usr/local/bin/pie-entrypoint.sh"]
CMD ["shibd-pie"]
