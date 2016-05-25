#!/bin/sh

docker run --rm -v $(pwd)/playbook:/usr/src/ansible -e ANSIBLE_HOST_KEY_CHECKING=False david/gic-ansible -i hosts-container playbook.yml
#docker run --rm \
#	-v $(pwd)/docker-machine-auto/machine:/usr/src/machine \
#	-v $(pwd)/playbook:/usr/src/ansible -e ANSIBLE_HOST_KEY_CHECKING=False david/dtr-ansible -i hosts playbook.yml
