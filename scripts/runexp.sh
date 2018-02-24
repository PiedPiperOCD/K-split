#!/bin/bash

function print_usage {
	echo "`basename $0` [OPTIONS]" name >&2
	echo >&2
	echo "OPTIONS:" >&2
	echo "  -h	print this help message" >&2
	echo "  -T	enable tracing (using tcpdump) on all machines" >&2
	echo "  -b	run base experiment, including e2e, ssh, nat and kernel+ES+TP" >&2
	echo "  -k	run the kernel split with Early SYN and Thread Pool (ES+TP)" >&2
	echo "  -e	run the kernel split without the Early SYN option (noES)" >&2
	echo "  -t	run the kernel split without both Thread Pool (TP) and no ES" >&2
	echo "  -p	run the kernel split with Connection Pool (CP)" >&2
	echo "  -a	run the kernel split with CP and Aggressive TCP configuration" >&2
	echo "  -A	run all of the tests above (shorthand for -betpa). This is also the default if non of the [betpa] options are sepcified" >&2
	echo "  -i count	set the number of iterations for each run (default is 50)" >&2
}

# no traces by default
trace=false
# set the number of iterations to run each experiment
iterations=50
unset flags
declare -A flags
not_all=false
while getopts ":hTbketpaAi:" opt; do
	case $opt in
		h)
			print_usage
			exit 1
			;;
		T)
			trace='true'
			;;
		b)
			flags["base"]='true'
			not_all=true
			;;
		k)
			flags["kernel"]='true'
			not_all=true
			;;
		e)
			flags["noES"]='true'
			not_all=true
			;;
		t)
			flags["noESnoTP"]='true'
			not_all=true
			;;
		p)
			flags["CP"]='true'
			not_all=true
			;;
		a)
			flags["agg"]='true'
			not_all=true
			;;
		A)
			flags["All"]='true'
			;;
		i)
			num=$OPTARG
			if (( num < 1 || num > 200)); then
				echo "Number of iterations must be in the range [1..200]" >&2
				exit 1
			fi
			iterations=$num
			;;
		\?)
			echo "Invalid option -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done
# No need to run the kernel option if base is enabled
if [[ ${flags["base"]} == "true" ]]; then
	flags["kernel"]='false'
fi
# Handle the -A or no options
if [[ $not_all == "false" ]] || [[ ${flags["All"]} == 'true' ]]; then
	flags["base"]='true'
	flags["CP"]='true'
	flags["agg"]='true'
	flags["noES"]='true'
	flags["noESnoTP"]='true'
fi

# shift the options
shift $((OPTIND-1))

if (( "$#" < 1 )); then
	print_usage
	exit 1
fi
proj=$1

stamp=$(date +%F_%H-%M-%S)
prefix=${proj}_${stamp}
echo "Experiment $proj started at $stamp"

hosts_file="hosts.sh"
echo "Using the following machines"
cat $hosts_file | grep -v ^#
source $hosts_file

# Clean IP version of the machines
c_ip=${c##*@}
s_ip=${s##*@}
rc_ip=${rc##*@}
rs_ip=${rs##*@}

ksplit_dir="ksplit"
dir=$(dirname $0)

orig_dir=$PWD
cd $dir

client=$c
dest=$s_ip
client_port=22


scp_opt=( -o "StrictHostKeyChecking no" )
ssh_opt=(-t "${scp_opt[@]}" )
ssh_Opt=(-O "StrictHostKeyChecking no")

function myssh {
	ssh "${ssh_opt[@]}" "$@"
}
function myscp {
	scp "${scp_opt[@]}" "$@"
}
function pssh {
	host_list=$1; shift
	parallel-ssh "${ssh_Opt[@]}" -H "$host_list" -i bash -c "$@"
}

# create machine lists
relays="$rc $rs"
hosts="$relays $c $s"

# copy relevant scripts
echo "Copying script files to gateways, server and client..."
zip gw.zip ./gw-scripts/*.sh ./common-scripts/*.sh
zip client.zip ./client-scripts/*.sh ./common-scripts/*.sh
zip server.zip ./common-scripts/*.sh
for machine in $relays $client; do
	echo "Copying file to $machine:"
	myscp  gw.zip $machine:.
done
echo "Copying files to $client:"
myscp client.zip $client:.
echo "Copying files to $s:"
myscp server.zip $s:.
pssh "$hosts" "echo unzipping files on \$HOSTNAME; unzip -jo '*.zip'; echo Done unzipping"

# copying K-split files, buiding and compiling
ksplit_code_dir="../tcpsplit"
zip ksplit-code.zip $ksplit_code_dir/Makefile $ksplit_code_dir/*[ch]
pssh "$relays" "pwd; if [ ! -d $ksplit_dir ]; then mkdir $ksplit_dir; fi;"
for machine in $relays; do
	myscp ksplit-code.zip $machine:./$ksplit_dir/
done
pssh "$relays" "echo Unzipping ksplit code; cd $ksplit_dir; unzip -jo ksplit-code.zip; ./install.sh"


# set up default tcp parameters and setup gw
echo "Setting up gateways..."
pssh "$relays $client" "echo; echo; sudo ./restore-tcp-params.sh def-tcp-params"
echo "Setting up first GW..."
myssh $rc ./gw-setup.sh $rs_ip $dest first
echo "Setting up last GW..."
myssh $rs ./gw-setup.sh $dest $dest last

function trace_start {
	name=$1
	if [[ $trace == "false" ]]; then
		return
	fi
	echo "Starting trace..."
	trace_name="${prefix}_${name}"
	pssh "$hosts" "echo; echo; ./start-trace.sh $trace_name"
	sleep 2
}

function trace_stop {
	if [[ $trace == "false" ]]; then
		return
	fi
	echo "Stopping trace."
	pssh "$hosts" "./stop-trace.sh"
}

if [[ ${flags["base"]} == 'true' ]]; then
# start base test
echo "Start basic tests"
trace_start base
myssh -p $client_port $client "./runexp-base.sh $rc $dest $iterations ${prefix}" 
trace_stop
fi

source ./common-scripts/set-ports.sh
kernel_port=${inports["kernel"]}
pool_port=${inports["pool"]}
#client_pub="$( myssh -p $client_port $client curl -s ipinfo.io/ip )"
client_pub=$c_ip


kernel_options=("kernel" "noES" "noESnoTP" "CP" "agg")

for exp in "${kernel_options[@]}"; do
	if [[ ${flags[$exp]} == 'true' ]]; then
		case $exp in
			noES)
				echo "Set up and run thread-pool only"
				nerf=2
				port=$kernel_port
				;;
			kernel)
				echo "Set up and run ES+TP"
				nerf=0
				port=$kernel_port
				;;
			noESnoTP)
				echo "Set up and run with no optimizations"
				port=$kernel_port
				nerf=3
				;;
			agg)
				echo "enable aggressive TCP on the inter routers"
				pssh "$relays" "echo;  sudo ./set-agg-tcp-params.sh; ./get-tcp-def.sh; ip route show"
				myssh $rc "echo ${client_pub}; echo \$( ip route get ${client_pub} ); sudo ip route add \$( ip route get ${client_pub} | head -1 ); ip route show"
				;&
			CP)
				echo "Set up and run connection pool test"
				nerf=0
				myssh $rc bash -c "echo; echo ${rs_ip//./,} \> /proc/cbn/conn_pool; echo ${rs_ip//./,} > /proc/cbn/conn_pool"
				port=$pool_port
				;;

		esac
		title=$exp

		pssh "$relays" "echo; echo Setting nerf;  echo $nerf > /proc/cbn/nerf"
		trace_start $title
		myssh -p $client_port $client bash -c "echo; echo 'Starting experiment'; ./runexp-kernel.sh $rc $dest $iterations ${prefix} $port $title"
		trace_stop

		if [[ $exp == "agg" ]]; then
			# set default TCP params
			pssh "$relays" "echo; echo 'Setting default TCP parameters'; sudo ./restore-tcp-params.sh def-tcp-params"
			myssh $rc "sudo ip route del $client_pub"
		fi
	fi
done

echo "Copying files..."
# Collect results
resdir="./res/${prefix}"
mkdir -p $resdir
zipfile="res-${prefix}.zip"
myssh $client "zip $zipfile res*${prefix}*.txt"
myscp -P $client_port $client:$zipfile $resdir/ 
unzip $resdir/*.zip -d $resdir/

if [[ $trace == "true" ]]; then
	mkdir -p $resdir/dest-pcap
	mkdir -p $resdir/client-pcap
	mkdir -p $resdir/gw-pcap
	myscp $dest:${prefix}*pcap* $resdir/dest-pcap &
	myscp -P $client_port $client:${prefix}*pcap* $resdir/client-pcap &
	for machine in $relays; do
		folder=$resdir/gw-pcap/${machine%%*@}
		mkdir -p $folder
		myscp $machine:${prefix}*pcap* $folder/ &
	done
fi
#parallel-slurp -H "$relays" -L ./sigcomm-res/$resdir/gw-pcap /home/ubuntu/gw-scripts/${resdir}*pcap* .

wait
cd $orig_dir
echo "Experiment Done at $( date )!"

