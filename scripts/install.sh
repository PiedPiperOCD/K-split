#!/bin/bash

source ./hosts.sh

all_machines="$c $rc $rs $s"
relays="$rc $rs"
ssh_opts=(-o "StrictHostKeyChecking no" -o "PasswordAuthentication no")
ssh_Opts=(-O "StrictHostKeyChecking no" -O "PasswordAuthentication no")
sizes="10K 100K 1M 5M 10M 50M 100M"
ksplit_repo="https://github.com/PiedPiperOCD/K-split.git"
ksplit_dir=${ksplit_repo##*/}
ksplit_dir=${ksplit_dir%%.*}

echo "Checking that all machines are reachable by ssh..."
for machine in $all_machines; do
	ssh -q "${ssh_opts[@]}" $machine "exit" || { echo  "Failed to access $machine using passwordless ssh"; exit 1; }
done
echo "Successful SSH access to all machines."
echo
echo "Checking passwordless sudo access on each machine..."
for machine in $all_machines; do
	ssh -q "${ssh_opts[@]}" $machine "sudo -n /bin/true" || { echo  "Failed to run passwordless sudo on $machine"; exit 1; }
done
echo "Successful passwordlesss sudo access to all machines."
echo
echo "Installing relevant packages on current machine..."
packages=(pssh gnuplot zip)
for pkg in "${packages[@]}"; do
	dpkg -l $pkg &> /dev/null || sudo apt install -y $pkg
done
echo "Finished installing packages."
echo
echo "Installing packages on all machines..."
parallel-ssh -H "$relays $s" "${ssh_Opts[@]}" -i "
	sudo -n apt-get update
	sudo -n apt-get install -y apache2 traceroute make gcc hping3 zip
	for size in $sizes; do
		head -c \$size < /dev/urandom > \$size.file
		sudo mv \$size.file /var/www/html/
	done
	touch \$HOME/.hushlogin
"
ssh "${ssh_opts[@]}" $c << EOF
	sudo -n apt-get update
	sudo -n apt-get install -y traceroute hping3 curl zip
	touch \$HOME/.hushlogin
EOF
echo "Finished installations."
echo
echo "Saving default TCP parameters"
for machine in $relays $s $c; do
	scp "${ssh_opts[@]}" ./get-tcp-def.sh $machine:.
done
parallel-ssh -H "$relays $s $c" "${ssh_Opts[@]}" -i "
	./get-tcp-def.sh > def-tcp-params
"
echo
echo "Setting localhost ssh access without a password...."
parallel-ssh -H "$relays" "${ssh_Opts[@]}" -i "
	cd \$HOME/.ssh
	if [ ! -f id_rsa ]; then
		ssh-keygen -f id_rsa -q -P \"\"
	fi
	grep \"\$(< id_rsa.pub )\" authorized_keys &> /dev/null || cat id_rsa.pub >> authorized_keys
"

echo "Finished."
