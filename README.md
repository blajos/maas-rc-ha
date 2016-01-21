# How to make MAAS Region Controller highly available?

I would like to explain our Lab setup, where we've configured our MAAS
installation to be highly available. Based on the official MAAS documentation
(http://maas.ubuntu.com/docs/) it is possible to have a highly available region
controller with multiple clusters each with their respective cluster controller.

For now the official documentation does not deal with the HA setup, but there is
a figure at http://maas.ubuntu.com/docs/orientation.html#a-typical-maas-setup
mentioning the possibilty. Let's hack it together.

## Functions provided by MAAS

The following functions are provided by a single host MAAS setup.

### Cluster controller

The following functions are provided by the cluster controller:

* DHCP, TFTP server: for PXE booting the MAAS-managed hosts
* Power management tools (eg. ipmitool): mostly used for turning on and off our
  hosts
* iSCSI server: for serving the installation media during enlistment, commision
  and deployment
* Apache2: for serving static boot resources from /var/lib/maas/boot-resources/
* Persistent connection to region controller identified by an UUID

Most of these functions could also be made highly available, but losing a
cluster controller (and the possibility to manage the nodes in the cluster) is
"no big deal". 

The cluster controller can be recovered by restoring the most recent backup. The
UUID is the only important data, which doesn't change over time. Everything else
is pushed by the region controller.

### Region Controller

The following functions are provided by the region controller:

* MAAS region controller wsgi apache2 application
* Postgresql database (an external postgresql database could be used as well)
* Domain name server
* Caching proxy

These functions can be made highly available.

## Installation

### Cluster controller

Install Ubuntu 14.04 LTS.

Install maas-cluster-controller package and customize
/etc/maas/templates/dhcp/dhcpd.conf.template to use multiple DNS servers (see
relevant part of Region controller config).

### Region controller

We are building an active-passive region controller cluster with only a single
virtual ip moving between nodes.

#### MAAS region controller wsgi apache2 application

A simple web application without data, which can run on both region
controllers. The only thing to remember is that apache2 must be restarted on
failover or the cluster controllers won't notice the change.

The current setup uses packet filter to disallow postgresql connections from the
passive node.

#### Caching proxy

A simple Squid web proxy, which can run on both region controllers.

#### Domain name server

The maas-dns server is authoritative for the zones used by MAAS, but it can only
be used on the active node, because it's regenerated from the database every
time a modification occurs, we couldn't find a way to force regeneration. This
dns server is modified to listen on port 5353 (on the vip address.)

A slave dns service is created on both region controllers, serving dns on the
node ip addresses. They are secondary zones for MAAS zones, and they forward
everything else to the maas-dns service. This could also be an upstream DNS
server.

Every server is pointed to these slave dns servers by the relevant DHCP option.

#### Postgresql database

Pgpool2 is used for setting up vip address and controlling failover and
failback. Streaming replication is set up between postgresql backends.
Postgres "user equivalence" is set up between nodes, so running commands as
postgres user on the other node is trivially possible.

The primary postgresql node is set by the configuration management system, the
secondary performs an initial sync of database (but automatically never again.)

Pgpool2 and postgresql are independent in a way that pgpool2 master can be
different from postgresql master. Pgpool2 master is the node owning the vip
address and doing MAAS region controller duties.

On master pgpool2 failure, the other pgpool2 claims the vip address, and
restarts apache2, maas-proxy and maas-dns services so they can listen on the vip
address. Dirty hack ahead: this is done by the arping_cmd.

On primary postgresql failure, the secondary is promoted by the master pgpool2
service.

Postgresql recovery: Reset primary postgresql node in the configuration
management system to the currently active one. After puppet agent is run, the
recovered node is set up as secondary.
