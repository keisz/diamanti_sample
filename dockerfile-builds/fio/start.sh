#!/bin/bash

export FIO_JOB_FILE=${FIO_JOB_FILE:-/config/job.fio}
export JOB_NAME=${JOB_NAME:-fio}
export NJ=${NJ:-8}
export QD=${QD:-16}
export BLOCK_SIZE=${BLOCK_SIZE:-4k}
export DEV=${DEV:-/data/testfile}
export DIRECT=${DIRECT:-1}
export SIZE=${SIZE:-5g}
export RW=${RW:-read}
export RT=${RT:-300}
export RWRPCT=${RWRPCT:-100}
export RWWPCT=$((100-${RWRPCT}))

exec /usr/bin/fio $FIO_JOB_FILE --output /data/${JOB_NAME}.out
