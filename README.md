MidoStack
=========

New midokura scripts to build a Devstack environment with MidoNet as Neutron plugin.

Prerequisites
-------------

### Importing devstack

MidoStack depends on [OpenStack's devstack project][devstack], which is imported
as the Git submodule. To import it, please run the following commands first.

```bash
$ cd midostack
midostack$ git submodule init
midostack$ git submodule update
```

[devstack]: https://github.com/openstack-dev/devstack

### Checking your branch out

Then, please checkout your working branch. For instance, if you'd like to work
with `v1.4-havana` branch, you can run the following command.

```bash
midostack$ git checkout origin/v1.4-havana -b v1.4-havana
```

Pelase don't forget to switch to the appropriate devstack.

```bash
midostack$ git submodule update
```

Up and Running MidoStack
------------------------

### Launching a VM with Vagrant (Optional)

This section describes about how to launch your VM for MidoStack. If you'd like
to run MidoStack on your host environment directly, please skip this section and
move to [Stacking up](#stacking-up) section.

#### Prerequisites

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant (>= 1.6.x)](http://www.vagrantup.com/downloads.html)

#### Up and Running a VM

If you'd like to launch a VM for MidoStack, please use the following command.

```bash
$ cd midostack
midostack$ vagrant up
```

It launches the default VM with the several port forwarding and mounting
`midostack` directory to `/midostack`.

### Stacking up

`midonet_stack.sh` script takes care of everything for you. It installs devstack
with the MidoNet suites and the appropriate configurations for it.

```bash
midostack$ ./midonet_stack.sh
```

Cleaning your MidoStack up
---------------------------

When you finished your work or you'd like to clean the remainded environment up,
please run the following command.

```bash
midostack$ ./midonet_unstack.sh
```

Changing your branch
--------------------

When you changed your working branch, you need to clean your environment with
recloning dependencies.

```bash
midostack$ ./midonet_unstack.sh
midostack$ RECLONE=true ./midonet_stack.sh
```
