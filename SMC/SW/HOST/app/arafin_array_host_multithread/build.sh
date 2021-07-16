#!/bin/bash

step=1

echo -e "
#include \"defs.hh\"

#define $OFFLOADED_KERNEL_NAME
#define SMC_BURST_SIZE_B $SMC_BURST_SIZE_B
#define NAME \"$OFFLOADED_KERNEL_NAME\"
#define FILE_NAME \"${OFFLOADED_KERNEL_NAME}.hex\"
#define REQUIRED_MEM_SIZE $REQUIRED_MEM_SIZE
 
#define READ_ONLY_PERCENTAGE $READ_ONLY_PERCENTAGE
#define NUM_HOST_THREADS 8
$(set_if_true $DEBUG_ON "#define HOST_DEBUG_ON")
" > _app_params.h

echo -e "
#define $APP_TYPE
#define $OFFLOADED_KERNEL_NAME
" > kernel_params.h

print_msg "Building App ..."
${HOST_CROSS_COMPILE}g++ main.cc -std=c++11 -static -L./ -lpimapi -lpthread -lstdc++ -o main -Wall $HOST_OPT_LEVEL
