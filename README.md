MidoStack
=========

jdevesa rocks!!!!

Midostack enables you to start an all-in-one node OpenStack + MidoNet
environment with a single command, by making use of
[devstack](https://github.com/openstack-dev/devstack).
It builds MidoNet from source and configures/runs devstack to use MidoNet as
the Neutron plugin. By default, master branch is used for MidoNet as well as
openstack projects(Neutron, Nova, etc).
See `midonet_stack.sh -h` for more options to configure Midostack environment.


Note that this is intended for a developer environment, not for a production
environment.

Requirements
------------

- Ubuntu 14.04 with 4GB of RAM + swap

Running MidoStack
------------------------

### Launching a Midostack VM with Vagrant (Optional)

This section describes how to run MidoStack on a Vagrant VM. If you'd
like to run MidoStack on your host environment directly, please skip this
section and move to [Stacking up](#stacking-up) section.

#### Prerequisites

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant (>= 1.6.x)](http://www.vagrantup.com/downloads.html)

#### Launching a VM

Run the following command to launch a VM for MidoStack:

```bash
$ cd midostack
midostack$ vagrant up
```

It launches the default VM with the following port forwarding and mount
configurations as explained below.
Once the VM is up, you can do `vagrant ssh` to ssh into the vagrant VM and
go to `/midostack` where the midostack repository on the host is mounted.

#### Port Forwarding

* For horizon: host's port 8080 is forwarded to guest's port 80 so you can
               access to horizon at `http://localhost:8080` on the host.

* For VNC console: host's port 6080 is forward to guest's port 6080.
                   Define the following environment variable before
                   running `midonet_stack.sh`  so you can access to VNC console
                   for OpenStack VMs on the horizon connected from the host.

```bash
export NOVNCPROXY_URL="http://localhost:6080/vnc_auto.html"
```

#### Mount

`midostack` directory on the host is mounted `/midostack` in the guest.

### Stacking up

`midonet_stack.sh` script takes care of everything for you. It sets up
OpenStack and MidoNet development environment.

```bash
midostack$ ./midonet_stack.sh
```

Stopping MidoStack
---------------------------

Run the following command to stop the running MidoStack:

```bash
midostack$ ./midonet_unstack.sh
```

This stops all the services and wipes out the data.
