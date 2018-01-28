# Ethereum mining automation
###### *Version 1.0*
This project implements the shell scripts for Ethereum mining automation.
It works with NVIDIA cards using ethminer - the Ethereum GPU mining worker.
All scripts were implemented and tested on Ubuntu 16.04.3 LTS 64bit.

## Installation
1. Clone the automation scripts on your Ubuntu distro into your user directory.
```shell
$ cd ~/
$ git clone https://github.com/ilfiron/ethereum-mining.git
```
2. Navigate to project folder and make the scripts executable:
```shell
$ cd ethereum-mining
$ chmod 755 *.sh
```
3. Download (latest) version of ethminer from here: https://github.com/ethereum-mining/ethminer/releases
```shell
$ wget https://github.com/ethereum-mining/ethminer/releases/download/v0.13.0/ethminer-0.13.0-Linux.tar.gz
```
4. Extract downloaded tarball.
```shell
$ tar xvf ethminer-0.13.0-Linux.tar.gz
```
5. Make sure the ethminer is executable.
```shell
$ chmod 755 bin/ethminer
```

## Setup
Ethereum mining automation can be divided into following tasks:

### *Task 1) Lower power limits of GPUs*
First we need to lower the power liming for each GPU card.
The cards are set to consume 150 or more Watts by default but this value should be lowered.
This helps to reserve electric energy consumption thus creating more profit and getting better ROI.
Note you may need to execute this script as root.

Sample usage:
```shell
$ sudo ./set_power_limit.sh
```

The scripts should be set (as root's) cron job to be executed at computer start as follows:

a) Open cron table for root user:
```shell
$ sudo crontab -e
```

b) Add following line (modify the path accordingly to your setup):

```shell
@reboot /home/user/ethereum-mining/set_power_limit.sh
```

c) Save and close the cron table (depends on your editor).

### *Task 2) Start mining script*
This script starts ethminer processes with default options on all available NVIDIA GPUs.
Ethminer runs on each card as a separate process.
Note the ethminer application may require X windows to be running.
Therefore it is best to run the script as a part of "Startup Applications" after automated login.

See detailed instructions here how to set it:
https://askubuntu.com/questions/48321/how-do-i-start-applications-automatically-on-login

**IMPORTANT:** You need to modify start_mining.sh script and specify your *WALLET_ID*, *POOL_HOST* and *BAK_POOL_HOST* between the lines 29 and 34.

Sample usage:
```shell
$ ./start_mining.sh
```

### *Task 3) Check mining processes status*
In the next step every mining process is being tested periodically.
If it does not respond withing the test period of time it is being stoppped, killed and restarted.

Sample usage:
```shell
$ ./check_mining.sh
```

The script should be set as cron job to automatize the mining status check as follows:

a) Open cron table for your user:
```shell
$ crontab -e
```

b) Add following line (modify the path accordinly to your setup):
```
*/2 * * * * /home/user/ethereum-mining/check_mining.sh
```

c) Save and close the cron table (depends on your editor).

## Check the mining status
Reboot your machine to see if everything starts and the scripts are running as expected.

The logs are written into `'logs'` directory under the scripts setup location.
Check the logs periodically to see if there are no errors/warnings indicating some issue.

However, some errors may be reported. You may ignore them if they have no impact on the mining.

Your hash-rate should be around 30.0MH/s *(value valid for January 2018)* for each GPU if you use NVIDIA 1070 8GB .

## Helper scripts
The helper scripts `check_eth_mining.sh` and `start_eth_mining.sh` are highly configurable.
You may see more option by exeuting them with `-h` option.

`stop_mining.sh` - stops all ethereum miner scripts

`mount_usb.sh` - mounts/unmounts USB drive


