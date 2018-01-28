#!/bin/bash
# Author: Lubomir Duchon
# Copyright (c) 2018 ILFIRON, s.r.o.
# Version: 1.0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

SOURCE="${BASH_SOURCE[0]}"
RDIR="$( dirname "$SOURCE" )"
ME=`basename "$0"`
HOST=`uname -n`
NOW=`date '+%Y-%m-%d %H:%M:%S'`
TODAY=`date '+%Y-%m-%d'`

# default values
POOLHOSTDEF="eu1.ethermine.org:4444"
BAKPOOLHOSTDEF="us1.ethermine.org:4444"
WALLETDEF="b35097bb342A27BF134114D7961FC9B9081AEA84"
POWERLIMITDEF="120"
MEMORYRATEDEF="1300"
APIPORTDEF=3330
POOLHOST=${POOLHOSTDEF}
BAKPOOLHOST=${BAKPOOLHOSTDEF}
WALLET=${WALLETDEF}
POWERLIMIT=${POWERLIMITDEF}
MEMORYRATE=${MEMORYRATEDEF}
APIPORT=${APIPORTDEF}
HELP=0

# split and prepare arguments
ARGS=()
for arg in "$@"
do
  var="${arg//=/ }"
  arr=($(echo ${var}))
  for arg2 in "${arr[@]}"
  do
    ARGS+=($arg2)
  done
done

for i in "${!ARGS[@]}"; do
  # debug print args
  # printf "%s\t%s\n" "$i" "${ARGS[$i]}"
  key=${ARGS[$i]}
  case $key in
    -w|-wallet|--wallet)
      WALLET="${ARGS[$i+1]}"
      let i=i+1
      ;;
    -ids|-gpuids|--gpuids)
      GPUIDS="${ARGS[$i+1]}"
      let i=i+1
      ;;
    -pl|-power-limit|--power-limit)
      POWERLIMIT="${ARGS[$i+1]}"
      let i=i+1
      ;;
    -ph|-pool-host|--pool-host)
      POOLHOST="${ARGS[$i+1]}"
      let i=i+1
      ;;
    -bph|-bak-pool-host|--bak-pool-host)
      BAKPOOLHOST="${ARGS[$i+1]}"
      let i=i+1
      ;;
    -mr|-memory-rate|--memory-rate)
      MEMORYRATE="${ARGS[$i+1]}"
      let i=i+1
      ;;
    -h|-help|--help)
      HELP=1
      ;;
  esac
done

if [ ${HELP} -eq 1 ] ; then
  echo "Usage: $ME  [OPTION1 [ARG1]] [OPTION2 [ARG2]] ..."
  echo "RUNTIME OPTIONS:"
  echo "    -w,   --wallet         Wallet address (Ethereum). Default: ${WALLETDEF}"
  echo "    -ids, --gpuids         Target specific GPU IDs (0,1,...). Default: All available GPUs"
  echo "    -pl,  --power-limit    Specifies maximum power management limit in Watts. Default: ${POWERLIMITDEF}"
  echo "    -mr,  --memory-rate    Specifies GPU memory transfer rate offset. Default: ${MEMORYRATEDEF}"
  echo "    -ph,  --pool-host      Specifies mining pool host. Default: ${POOLHOSTDEF}"
  echo "    -bph, --bak-pool-host  Specifies backup mining pool host. Default: ${BAKPOOLHOSTDEF}"
  echo "GENERAL OPTIONS:"
  echo "    -h,   --help           Print usage information and exit."
  exit
fi

if [ -z "${GPUIDS}" ]; then
  GPUID=0
  LOGID="all"
else
  IFS=',' read -ra GPUIDSA <<< "${GPUIDS}"
  for ID in "${GPUIDSA[@]}"
  do
    GPUID=${ID}
    break
  done
  echo "gpuid: ${GPUID}"
  LOGID=${GPUID}
fi

mkdir -p ${RDIR}/logs/
LOG=${RDIR}/logs/eth_mining.${LOGID}.${TODAY}.log


WORKERID=""
GPUCNT=`nvidia-smi -L | wc -l`
let GPUCNTMAX=GPUCNT-1
if [ -z "${GPUIDS}" ]; then
  WORKERID="_all"
  GPUINFO="GPU IDs = All available GPUs (${GPUCNT})"
  COUNTER=0
  while [  $COUNTER -lt $GPUCNT ]; do
    nvidia-smi -i $COUNTER -pm 1 >> ${LOG}
    nvidia-smi -i $COUNTER -pl $POWERLIMIT >> ${LOG}
    nvidia-settings -c :0 -a "[gpu:$COUNTER]/GPUMemoryTransferRateOffset[3]=${MEMORYRATE}" >> ${LOG}
    nvidia-settings -c :0 -a "[gpu:$COUNTER]/GPUGraphicsClockOffset[3]=100" >> ${LOG}
    let COUNTER=COUNTER+1
  done
else
  CUDADEVS=""
  GPUIDSA=()
  IFS=',' read -ra GPUIDSA <<< "${GPUIDS}"
  for GPUID in "${GPUIDSA[@]}"
  do
    CUDADEVS="${CUDADEVS} ${GPUID}"
    WORKERID="${WORKERID}_${GPUID}"
  done
  if [ "${GPUCNT}" -lt ${#GPUIDSA[@]} ]; then
    echo "Error: Specified number of GPU IDs (${GPUIDS}) is higher than detected number of GPUs (${GPUCNT})."
    echo "Note that GPU ID is zero based therefore maximum value for GPU ID is ${GPUCNTMAX}."
    exit;
  fi
  for GPUID in "${GPUIDSA[@]}"
  do
    if [ $GPUID -gt $GPUCNTMAX ]; then
      echo "Error: Specified number of GPU ID (${GPUID}) is higher than detected number of GPUs (${GPUCNT})."
      echo "Note that GPU ID is zero based therefore maximum value for GPU ID is ${GPUCNTMAX}."
      exit;
    fi
  done
  let APIPORT=APIPORT+GPUIDSA[0]
  GPUINFO="GPU IDs = ${CUDADEVS}"
  for GPUID in "${GPUIDSA[@]}"
  do
    nvidia-smi -i $GPUID -pm 1 >> ${LOG}
    nvidia-smi -i $GPUID -pl $POWERLIMIT >> ${LOG}
    nvidia-settings -c :0 -a "[gpu:$GPUID]/GPUMemoryTransferRateOffset[3]=${MEMORYRATE}" >> ${LOG}
    nvidia-settings -c :0 -a "[gpu:$GPUID]/GPUGraphicsClockOffset[3]=100" >> ${LOG}
  done
fi

# GPU settings
export GPU_FORCE_64BIT_PTR=0
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100

# start ethminer

GPUNAME=`nvidia-smi -i ${GPUID} --query-gpu=gpu_name --format=csv,noheader`
echo "${NOW} Starting eth mining" >> ${LOG}
echo -e "GPU NAME = ${GPUNAME}\nWALLET = ${WALLET}\nPOOL HOST = ${POOLHOST}\nBACKUP POOL HOST = ${BAKPOOLHOST}" >> ${LOG}
echo -e "GPUIDS = ${GPUIDS}\n${GPUINFO}\nCUDA DEVICES = ${CUDADEVS}" >> ${LOG}
echo -e "POWER LIMIT = ${POWERLIMIT}W\nMEMORY RATE = ${MEMORYRATE}" >> ${LOG}
echo GPU NAME = ${GPUNAME}
echo WALLET ADDRESS  = ${WALLET}
echo POOL HOST = ${POOLHOST}
echo BACKUP POOL HOST = ${BAKPOOLHOST}
echo ${GPUINFO}
echo POWER LIMIT = ${POWERLIMIT}W
echo MEMORY RATE = ${MEMORYRATE}
echo API PORT = ${APIPORT}
echo CUDA DEVICES = ${CUDADEVS}
DEVICES=`$RDIR/bin/ethminer -U --list-devices`
echo ${DEVICES}
echo ${DEVICES} >> ${LOG}

if [ -z "${GPUID}" ]; then
  CMD="$RDIR/bin/ethminer -RH --api-port ${APIPORT} --farm-recheck 200 -U -S ${POOLHOST} -FS ${BAKPOOLHOST} -O ${WALLET}.${HOST}${WORKERID}"
else
  CMD="$RDIR/bin/ethminer -RH --api-port ${APIPORT} --cuda-devices${CUDADEVS} --farm-recheck 200 -U -S ${POOLHOST} -FS ${BAKPOOLHOST} -O ${WALLET}.${HOST}${WORKERID}"
fi
echo ${CMD}
echo "${CMD}" >> ${LOG}
$CMD
