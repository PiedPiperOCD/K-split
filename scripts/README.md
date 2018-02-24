# Scripts Description

This directory contains scripts to prepare VMs and machines for experiments, run the experiments, 
and collect and analyze the output.

## Prerequisites

See [Prerequisites](../README.md/#prerequisites) section in the repo root directory.

## Scripts

| Script Name | Description |
| ----------- | ----------- |
|`hosts.sh` | used to set the username and address of the machines involved in the experiments |
|`install.sh` | used to install all necessary packages on each of the machines in the experiment |
| `runexp.sh` | run the basic experiments comparing the different K-split optimization options |
| `run_weakclient.sh` | run the weak client experiment |
| `run_fairness.sh` | run the fairness experiments | 

## Important - Before Running Experiments

You should first edit the `hosts.sh` script to refer to the machines involved in the experiment.
Each line defines the username and hostname or IP address of another machine, in the format:
```
rc="username@hostname"
```

For instance, if the Rs machine is at 192.168.1.2 and the username one should use is expuser, the line in the `hosts.sh` file should read
```
rs="expuser@192.168.1.2"
```

After properly editing the `hosts.sh` file you should run an SSH agent and then load the private keys required to access each of the machines. To do that you can use (on linux):
```shell
$ eval `ssh-agent`
$ ssh-add <path-to-private-key-file>
```

Then run the `install.sh` script.
This script will verify that it can access all the relevant machines and run passwordless sudo commands on them. Then it will install all necessary packages on these machines and save their default TCP configuration parameters on the machines themselves. The `install.sh` script only needs to be run (successfully) once.

## Running Experiments

Assuming the `install.sh` script finished successfully, you can now run the three experiments.

### `runexp.sh` - Performance Comparison

This script can run various options of downloading files of different sizes from the server (S) to the client (C), using either E2E (end-to-end over the Internet), NAT (forwarding through Rs and Rc), or various flavors of TCP splitting with K-split. You should run `scripts/runexp.sh -h` to find out about the different options of running this script.
The default execution of the script:
```shell
$ scripts/runexp.sh <experiment_name>
```

where `experiment_name` can be any string (without spaces) used to identify the results. It will run E2E, NAT, SSH splitting and all options available for K-split.

