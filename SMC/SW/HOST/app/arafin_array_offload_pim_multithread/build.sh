#!/bin/bash

step=1

echo -e "
#include \"defs.hh\"

#define $OFFLOADED_KERNEL_NAME
#define SMC_BURST_SIZE_B $SMC_BURST_SIZE_B
#define NAME \"$OFFLOADED_KERNEL_NAME\"
#define FILE_NAME \"${OFFLOADED_KERNEL_NAME}.hex\"
#define REQUIRED_MEM_SIZE $REQUIRED_MEM_SIZE
 #define NUM_TURNS $OFFLOADED_NUM_TURNS
#define ARRAY_SIZE $OFFLOADED_ARRAY_SIZE
#define WALK_STEP	$OFFLOADED_WALK_STEP
$(set_if_true $INITIALIZE_ARRAY "#define INITIALIZE_ARRAY")
$(set_if_true $DEBUG_PIM_APP "#define DEBUG_APP")
$(set_if_true $OFFLOAD_THE_KERNEL "#define OFFLOAD_THE_KERNEL")
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
