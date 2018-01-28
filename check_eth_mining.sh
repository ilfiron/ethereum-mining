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

GPUIDS=""
HELP=0
STOP=0
for i in "${!ARGS[@]}"; do
  # debug print args
  # printf "%s\t%s\n" "$i" "${ARGS[$i]}"
  key=${ARGS[$i]}
  case $key in
    -ids|-gpuids|--gpuids)
      GPUIDS="${ARGS[$i+1]}"
      let i=i+1
      ;;
    stop)
      STOP=1
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
  echo "    -ids, --gpuids  Target specific GPU IDs (0,1,...). Default: All available GPUs"
  echo "    stop            Stops the ethminer with specified GPU IDs"
  echo "GENERAL OPTIONS:"
  echo "    -h,   --help    Print usage information and exit."
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

APIPORTDEF=3330
let APIPORT=APIPORTDEF+GPUID

echo "LOG: ${LOG}"
echo "GPUID: ${GPUID}"
echo "GPUIDS: ${GPUIDS}"
echo "APIPORT: ${APIPORT}"

ETHMINPID=`ps ax | grep ethminer | grep "port ${APIPORT}" | awk -F" " '{print $1}'`
if [ -z "${GPUIDS}" ]; then
  STARTPID=`ps ax | grep start_eth_mining.sh | grep bash | awk -F" " '{print $1}'`
else
  STARTPID=`ps ax | grep start_eth_mining.sh | grep bash | grep "\-ids ${GPUIDS}" | awk -F" " '{print $1}'`
fi
echo "ETHMINPID: ${ETHMINPID}"
echo "STARTPID: ${STARTPID}"
if [ -z "${ETHMINPID}" ] || [ ${ETHMINPID} -eq 0 ]; then
  echo "Error: ethminer process not found"
  echo "${NOW} Error: ethminer process not found" >> ${LOG}
# Optional: start eth mining again.
# Caution: this may lead into endless loop if there is an issue with miner application.
# ${RDIR}/start_eth_mining.sh -ids ${GPUIDS}
  exit
fi
STARTETHCMD=`ps -o args -p ${STARTPID} --no-headers`
echo "STARTETHCMD: ${STARTETHCMD}"

if [ ${STOP} -eq 1 ]; then
  echo "Stopping ethminer..."
  echo '{"id":"'${GPUID}'","jsonrpc":"2.0","method":"miner_restart"}' | nc -w 5 localhost ${APIPORT}
  sleep 3
  kill -9 ${ETHMINPID}
  sleep 1
  kill -9 ${STARTPID}
  exit
fi

echo "Checking ethminer ${GPUID}..."
ETHCHECK={"id":"${GPUID}","jsonrpc":"2.0","method":"miner_getstat1"}
echo ${ETHCHECK}
MINERSTAT=`echo '{"id":"'${GPUID}'","jsonrpc":"2.0","method":"miner_getstat1"}' | nc -w 20 localhost ${APIPORT}`
echo "$MINERSTAT"
echo "${NOW} ${MINERSTAT}" >> ${LOG}
RESTART=0
if [ -z "${MINERSTAT}" ]; then
  RESTART=1
else
  echo "Mining worker seems to be fine..."
  exit
fi

echo "Restarting..."
echo "${NOW} restarting ${STARTETHCMD}" >> ${LOG}

if [ ${RESTART} -eq 1 ]; then
  echo "Stopping ethminer..."
  echo '{"id":"'${GPUID}'","jsonrpc":"2.0","method":"miner_restart"}' | nc -w 5 localhost ${APIPORT}
  sleep 3
  kill -9 ${ETHMINPID}
  sleep 1
  kill -9 ${STARTPID}
fi
sleep 1
echo ${STARTETHCMD}
${STARTETHCMD}
