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
FROM sbutler/pie-base

RUN set -xe \
    && apt-get update && apt-get install -y \
        libnetaddr-ip-perl \
        shibboleth-sp2-utils \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY etc/ /etc
COPY pie-entrypoint.sh /usr/local/bin/

RUN set -xe \
    && chmod a+rx /usr/local/bin/pie-entrypoint.sh \
    && mkdir -p /var/run/shibboleth

ENV SHIBD_SERVER_ADMIN        "webmaster@example.org"
ENV SHIBD_TCPLISTENER_ADDRESS ""
ENV SHIBD_TCPLISTENER_ACL     ""
ENV SHIBD_ENTITYID            "https://host.name.illinois.edu/shibboleth"
ENV SHIBD_ATTRIBUTES          ""
ENV SHIBD_CONFIG_SUFFIX ""

VOLUME /etc/opt/pie/shibboleth
VOLUME /etc/shibboleth
VOLUME /var/run/shibboleth

EXPOSE 1600

ENTRYPOINT ["/usr/local/bin/pie-entrypoint.sh"]
CMD ["shibd-pie"]
