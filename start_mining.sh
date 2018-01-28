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

# !!!!!!!!!!!!!!!!!!!
# !!!! IMPORTANT !!!!
# !!!!!!!!!!!!!!!!!!!
#
# Change WALLET_ID to your wallet ID
#
WALLET_ID="b35097bb342A27BF134114D7961FC9B9081AEA84"
#
# Change POOL_HOST and BAK_POOL_HOST to your pool hosts
#
POOL_HOST="eu1.ethermine.org:4444"
BAK_POOL_HOST="us1.ethermine.org:4444"
#

SOURCE="${BASH_SOURCE[0]}"
RDIR="$( dirname "$SOURCE" )"

GPUCNT=`nvidia-smi -L | wc -l`
let GPUCNTMAX=GPUCNT-1
COUNTER=0
while [  $COUNTER -lt $GPUCNT ]; do
  CMD="${RDIR}/start_eth_mining.sh -ids ${COUNTER} -w ${WALLET_ID} -ph ${POOL_HOST} -bph ${BAK_POOL_HOST}"
  echo ${CMD}
  ${CMD} &
  sleep 2
  let COUNTER=COUNTER+1
done
