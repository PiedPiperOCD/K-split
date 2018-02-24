# K-split
PiedPiper implementation of the improvements to the OCD baseline. Provided in the form of a kernel module

## Compatibility
The K-split code currently supports Ubuntu 17.10 (Done post-submission due to 17.04 End-of-life, which forced us to update the code and scripts).

## Running tests
The `scripts` directory includes some of the scripts used to produce the graphs in the paper.
Please read the [Prerequisites](#prerequisites) section before using the scripts.

### Prerequisites

#### Setting Up Machines
To run the scripts you need to set up at least 4 machines - 

| Notation | Meaning 	  | Description 						|
| :------: | ------------ | ----------------------------------------------------------- |
| C        | Client 	  | Client machine. Used to initiate downloads from the server  |
| Rc       | Client Relay | A relay machine in a cloud datacenter closest to the client |
| Rs       | Server Relay | A relay machine in a cloud datacenter closest to the server |
| S        | Server 	  | The machine from which the client downloads the files       |

The Rc and Rs machines should reside in the same cloud to get similar results to ours. In our paper the machines (and virtual machines) were positioned according to the following:

| Machine | Location          | Comment                                                           |
|:------: | ----------------- | ----------------------------------------------------------------- |
| C       | San Francisco, US | A PC connected to the Internet through a residential ISP provider |
| Rc      | Oregon, US 	      | A VM in Google's Cloud Platform in its Oregon datacenter          |
| Rs      | Mumbai, India     | A VM in Google's Cloud Platform in its Mumbai datacenter          |
| S       | Bangalore, India  | A VM in Digital Ocean's datacenter in Bangalore                   |

#### Open Ports
The machines you set up should have a public IP address accessible to the machine on which you run the test scripts and 
should have the following TCP ports open: 
- 22 (ssh)
- 80 (http)
- 50000-50004
- 50100-50104

#### SSH access
Each of the machines should have SSH access using a private key on the machine running the scripts.
The public-private key pair should be identical for all machines (for simplicity). The public key should already be included in the `~/.ssh/authorized_keys` of each of the machines.

#### Passwordless sudo
Make sure you can run sudo commands on the machines you are using without requiring a password.
You can use the information in [here](https://askubuntu.com/questions/147241/execute-sudo-without-password) to accompish this.

## Script Description
Please see description in [Script Description](scripts/README.md).

## K-split Installation

### Prerequisites
Make sure you can run sudo commands on the machine you are using without requiring a password. You can run the following after you issue a `sudo su` command, or use the information in [here](https://askubuntu.com/questions/147241/execute-sudo-without-password).

To just install the K-split kernel module use
```shell
$ git clone https://github.com/PiedPiperOCD/K-split.git
$ cd K-split/tcpsplit
$ ./install.sh
```

This will clone the github repo, build the kernel module and install it.
However, to actually make it work and split TCP connections, further settings are required to direct traffic to the module.
You can check out the scripts in the `scripts` directory to get a clue.

## Using K-split

You can get a clue on how to use K-split by looking at the code of the different scripts in the `scripts` directory.
Some documentation of the different features follows.

### Setting the K-split server
To set up the K-split listening server the following should be issued:
```shell
$ echo <fwmark>,<port_number> > /proc/cbn/cbn_proc
```
For instance, to have the K-split listen to port 12345 for packets with a fwmark of 10 use:
```shell
$ echo 10,12345 > /proc/cbn/cbn_proc
```

### Configuring the different optimization options in K-split
#### Using no optimizations at all
Run `echo 3 > /prco/cbn/nerf`

#### Using only TP (Thread-Pool)
Run `echo 2 > /prco/cbn/nerf`

### Using TP+ES (Early SYN)
Run `echo 0 > /prco/cbn/nerf`

### Adding CP (Connection pool) to TP+ES
Run `echo <ip_address with ',' instead of '.'s > /proc/cbn/conn_pool`

The ip_address should be the address of the other end of the connection pool and the command should be run on the initiating end.
For instance, if machine A is to create a pool of connections to machine B and machine B's IP address is 10.1.1.2, the command should be
```shell
$ echo 10,1,1,2 > /proc/cbn/conn_pool
```
and it should be executed on machine A.
