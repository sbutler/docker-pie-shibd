Introduction
============

This is a container for running the Shibboleth Service Provider (SP) in Docker
in a common configuration found for the University of Illinois at
Urbana-Champaign. This is only the shibd portion of the SP; you will need to
add mod_shib to your httpd continers.

Volumes
-------

### /etc/shibboleth

The main configuration directory for shibd and mod_shib. This volume must be
mounted read-only in all of your httpd containers for mod_shib to work. In the
case where there are multiple hosts you will probably want to place it on NFS.

It is important that the volume be populated with initial data from the
image. You will also need to add your own `sp-cert.pem` and `sp-key.pem` files.
The `shibboleth2.xml` and `attribute-map.xml` files are automatically generated
from templates in the `/etc/opt/pie/shibboleth/` volume every time the
container is run with the `shibd-pie` command. If you need to make changes to
these files then you should make them in the `/etc/opt/pie/shibboleth/` volume.

### /etc/opt/pie/shibboleth

This contains configuration files for shibd in the Template::Toolkit format
(`.tt2`). When the container is run with the `shibd-pie` command each file in
this directory is passed through `tpage` and the result is saved in the
`/etc/shibboleth/` directory. The image has two files present:

- `shibboleth2.xml`: environment variables passed to the container are used to
    customize this. It will also contain the IP address and allowed subnet mask
    that tells mod_shib how to connect over TCP.
- `attribute-map.xml`: environment variables passed to the container enable
    common attributes used by the UIUC IdP's. If you only need common attributes
    then you do not need to customize this file. Consider editing the appropriate
    environment variable to enable the right attributes.

### /var/run/shibboleth

If you are using mod_shib over unix sockets then you will need to export this
volume read-write to your httpd containers. You might also consider preserving
this volume across shibd containers as it contains cached metadata (optional;
can improve startup times).

Environment
-----------

Common options for UIUC SP's can be configured through environment variables
with minimum effort for deployments.

### SHIBD_SERVER_ADMIN

Email address of the Shibboleth SP administrator for the services on this
server.

### SHIBD_TCPLISTENER_ADDRESS

IP address that mod_shib should use to connect to the shibd process. If you
specify a value then it will always be used. Otherwise, it will try to automatically
detect the correct value. If your ECS Task's network mode is:

- `bridge`: it will use the IP address of the container interface `eth0`. Only
    mod_shib containers running on the same host will be able to connect to this
    shibd.
- `host`: it will use the IP address of the host interface `eth0`. Any container
    in the VPC should be able to connect to this shibd.

### SHIBD_TCPLISTENER_ACL

Space separated list of network addresses allowed to connect to this shibd. To
allow entire subnets you can use CIDR notation. If you do not specify a value
then it will attempt to automatically detect a safe range. If your ECS Task's
network mode is:

- `bridge`: it will use the network address for the internal host network on
    `eth0`. Only mod_shib containers running on the same host will be able to
    connect to this shibd.
- `host`: it will use the network address of the host interface `eth0`. Any
    container in the same VPC subnet should be able to connect to this shibd.

You will probably not want to use the automatic values and instead pass in the
VPC CIDR range.

### SHIBD_ENTITYID

Shibboleth SP entity ID, as registered with the IdP's.

### SHIBD_ATTRIBUTES

Space separated list of attributes to provide to mod_shib. Attributes used by
you app must be specified here and also registered with the IdP. This image
supports these common attributes:

- eppn (always enabled)
- persistent-id (always enabled)
- affiliation
- unscoped-affiliation
- primary-affiliation
- entitlement
- nickname
- org-dn
- sn
- generationQualifier
- givenName
- iTrustMiddleName
- displayName
- uid
- mail
- telephoneNumber
- postalAddress
- title
- iTrustAffiliation
- iTrustSuppress
- iTrustUIN
- member
- o
- ou
- homeOrganizationType

### SHIBD_CONFIG_SUFFIX

This is an optional suffix to add to the generated `shibboleth2.xml` file. It
allows you to do Green-Blue deployments from the same, shared `/etc/shibboleth/`
directory without overwriting already running SP's.

Do not enable this option unless you know you require it.

Running
-------

The default and most common way to run this image is with `shibd-pie`. That
enables the template and automatic behaviors. All other commands run will be
run directly.
