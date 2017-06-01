#!/bin/bash
# vim:set noet:

if [ -d /usr/local/support -a -f /usr/local/support/barman-entrypoint.sh ]; then
  bash -c "/usr/local/support/barman-entrypoint.sh $@"
  exit 0
fi

echo using image version of barman-entrypoint.sh

echo This script will fail if not running as root within the Docker container.

set -eo pipefail

        # function configure_ssh {
	# install -d -m 0755 -o root -g root /var/run/sshd
        # if [[ -n ${SSH_HOST_KEY} ]] && [[ -f ${SSH_HOST_KEY} ]]; then
        # 	echo "Installing SSH host key"
        # 	rm -f /etc/ssh/ssh_host_*_key*
        # 	install -m 0400 -o root -g root ${SSH_HOST_KEY} /etc/ssh/
        # 	sed -i '/^HostKey[[:space:]]/ d' /etc/ssh/sshd_config
        # 	echo "HostKey /etc/ssh/$(basename ${SSH_HOST_KEY})" >> /etc/ssh/sshd_config
        # else
        # 	echo "WARNING: Unable to install SSH host key.  SSH_HOST_KEY is not defined or file does not exist."
        # fi
        # }

function mk_chown_dir {
	if [ ! -d $1 ]; then mkdir -p i              $1; fi
	if [   -d $1 ]; then chown postgres:postgres $1; fi
}

function wait_pid {
	while kill -0 $1
	do sleep 1
	done
}

mk_chown_dir /var/log/supervisor
mk_chown_dir /var/log/supervisor/cron
mk_chown_dir /var/log/supervisor/sshd
mk_chown_dir /var/log/supervisor/postgres

mk_chown_dir /var/lib/postgresql
mk_chown_dir /var/lib/postgresql/data
mk_chown_dir /var/lib/postgresql/backup

if [ ! -d /usr/local/support ]; then mkdir /usr/local/support; chown postgres:postgres /usr/local/support ; fi

sed -n -e '/nodaemon=true/d; p' -i /etc/supervisord.conf
supervisord -c /etc/supervisord.conf
sleep 1
chgrp postgres /var/run/supervisor.sock
chmod g+rwx /var/run/supervisor.sock

if [[ $# -eq 0 ]]; then
	# configure_ssh

	echo Waiting for process supervisor process, pid $(cat /var/run/supervisord.pid) to exit.
	ls -l /run
	gosu postgres supervisorctl status
	echo If you are running interactively, you can press control-C to abort.
	wait_pid $(cat /var/run/supervisord.pid)
else
	exec gosu postgres "$@"
fi
