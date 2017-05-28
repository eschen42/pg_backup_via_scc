#!/bin/bash
# vim:set noet:

set -eo pipefail

function configure_ssh {
	install -d -m 0755 -o root -g root /var/run/sshd
  # if [[ -n ${SSH_HOST_KEY} ]] && [[ -f ${SSH_HOST_KEY} ]]; then
  # 	echo "Installing SSH host key"
  # 	rm -f /etc/ssh/ssh_host_*_key*
  # 	install -m 0400 -o root -g root ${SSH_HOST_KEY} /etc/ssh/
  # 	sed -i '/^HostKey[[:space:]]/ d' /etc/ssh/sshd_config
  # 	echo "HostKey /etc/ssh/$(basename ${SSH_HOST_KEY})" >> /etc/ssh/sshd_config
  # else
  # 	echo "WARNING: Unable to install SSH host key.  SSH_HOST_KEY is not defined or file does not exist."
  # fi
}

if [[ $# -eq 0 ]]; then
	configure_ssh
	mkdir -p /var/log/supervisor/sshd
	mkdir -p /var/log/supervisor/cron
	mkdir -p /var/log/supervisor/postgres
	if [ ! -d /var/lib/postgresql      ]; then mkdir /var/lib/postgresql;                chown postgres:postgres /var/lib/postgresql ; fi
	if [ ! -d /var/lib/postgresql/data ]; then mkdir /var/lib/postgresql/data                                                        ; fi
	if [   -d /var/lib/postgresql/data ]; then                                      chown postgres:postgres /var/lib/postgresql/data ; fi
	if [ ! -d /var/lib/postgresql/backup ]; then mkdir /var/lib/postgresql/backup                                                    ; fi
	if [   -d /var/lib/postgresql/backup ]; then                                  chown postgres:postgres /var/lib/postgresql/backup ; fi
	if [ ! -d /usr/local/support ]; then mkdir /usr/local/support                                                                    ; fi
	if [   -d /usr/local/support ]; then                                                  chown postgres:postgres /usr/local/support ; fi
	exec supervisord -c /etc/supervisord.conf
else
	exec "$@"
fi
