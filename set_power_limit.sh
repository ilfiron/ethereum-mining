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

mkdir -p ${RDIR}/logs/
LOG=${RDIR}/logs/${ME}.${TODAY}.log

POWERLIMIT=120
GPUCNT=`nvidia-smi -L | wc -l`
let GPUCNTMAX=GPUCNT-1

MSG="Setting all GPUs power limit to ${POWERLIMIT} Watts"
echo ${MSG}
echo "${NOW} ${MSG}" >> ${LOG}

COUNTER=0
while [  $COUNTER -lt $GPUCNT ]; do
  NOW=`date '+%Y-%m-%d %H:%M:%S'`
  MSG="Setting GPU: ${COUNTER} power limit: ${POWERLIMIT} Watts"
  echo ${MSG}
  echo "${NOW} ${MSG}" >> ${LOG}
  MSG=`nvidia-smi -i ${COUNTER} -pm 1`
  echo ${MSG}
  echo "${NOW} ${MSG}" >> ${LOG}
  MSG=`nvidia-smi -i ${COUNTER} -pl ${POWERLIMIT}`
  echo ${MSG}
  echo "${NOW} ${MSG}" >> ${LOG}
  let COUNTER=COUNTER+1
done
