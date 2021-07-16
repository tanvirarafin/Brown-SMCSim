#!/bin/bash

GEM5_STATISTICS=(
"sim_ticks.pim"
"sim_ticks.host"
"sim_ticks.ratio_host_to_pim"
"power_related_to_host"
"power_related_to_pim"
)

VALUES0=( sgraph_teenage_follower ) # sgraph_bellman_ford sgraph_bfs sgraph_teenage_follower
VALUES1=( best )
VALUES2=( 1000 ) # 8000 16000 32000 64000 ) # Graph Size

for V0 in ${VALUES0[*]}
do
for V1 in ${VALUES1[*]}
do
for V2 in ${VALUES2[*]}
do
	source UTILS/default_params.sh
	create_scenario "$0/$*" "$V0-$V1-$(zpad $V2 9)" "ARMv7 + HMC2011 + Linux (VExpress_EMM) + PIM(ARMv7)"
	
	####################################
	load_model memory/hmc_2011.sh
	load_model system/gem5_fullsystem_arm7.sh
	load_model system/gem5_pim.sh
# 	load_model gem5_perf_sim.sh				# Fast simulation without debugging
	
    export OFFLOADED_KERNEL_NAME=$V0    # Kernel name to offload (Look in SMC/SW/PIM/kernels)
    export OFFLOADED_KERNEL_SUBNAME=$V1
	#####################
	#####################
	load_model common_params.sh
    export OFFLOADED_GRAPH_NODES=$V2
	#####################
	#####################
	
	source ./smc.sh -u $*	# Update these variables in the simulation environment
# 	load_model gem5_automated_sim.sh homo		# Automated simulation
	
	####################################

	print_msg "Build and copy the required files to the extra image ..."

	#*******
	clonedir $PIM_SW_DIR/resident
	if ! [ $V0 == matrix_add ]; then
        cp $HOST_SW_DIR/app/offload_sgraph/defs.hh .
    fi
	run ./build.sh  7   # Build the main resident code
	run ./build.sh 7 "${OFFLOADED_KERNEL_NAME}" # Build a specific kernel code (name without suffix)
	returntopwd
	#*******
	clonedir $HOST_SW_DIR/driver
	cp ../resident/definitions.h .
	run ./build.sh
	returntopwd
	#*******
	clonedir $HOST_SW_DIR/api
	cp ../resident/definitions.h .
	cp ../driver/defs.h .
	run ./build.sh
	returntopwd
	#*******
    if ! [ $V0 == matrix_add ]; then
        clonedir $HOST_SW_DIR/app/offload_sgraph
    else
        clonedir $HOST_SW_DIR/app/offload_matrix
    fi
	cp ../api/pim_api.a ./libpimapi.a
	cp ../api/*.hh .
	cp $HOST_SW_DIR/app/app_utils.hh .
	run ./build.sh
	returntopwd
	#*******

	cd $SCENARIO_CASE_DIR

	echo -e "
	echo; echo \">>>> Install the driver\";
	./ins.sh
	echo; echo \">>>> Run the application and offload the kernel ...\";
	./main
	" > ./do
	chmod +x ./do

    if ! [ $V0 == matrix_add ]; then
        copy_to_extra_image  driver/pim.ko driver/ins.sh ./do offload_sgraph/main resident/${OFFLOADED_KERNEL_NAME}.hex 
    else
        copy_to_extra_image  driver/pim.ko driver/ins.sh ./do offload_matrix/main resident/${OFFLOADED_KERNEL_NAME}.hex 
    fi
	returntopwd
	
	####################################

	source ./smc.sh $*
done
done
done
	
finalize_gem5_simulation
plot_bar_chart "sim_ticks.pim" 0 "(ps)" #--no-output
plot_bar_chart "sim_ticks.host" 0 "(ps)" #--no-output
print_msg "Done!"
