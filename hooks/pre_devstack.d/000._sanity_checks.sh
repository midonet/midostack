#!/bin/bash -xe
#
# Install all prerequisites of midostack

if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
    echo "Red Hat or CentOS is not supported in midostack. Try on Ubuntu"
    return 1
fi
