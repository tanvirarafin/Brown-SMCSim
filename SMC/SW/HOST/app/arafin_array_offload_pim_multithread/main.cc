#include "pim_api.hh"
#include <unistd.h>
#include <iostream>
#include <unistd.h>
#include <cstring>
#include <iomanip>
#include <stdlib.h> // srand, rand
#include <time.h>
#include <stdint.h> // UINT32_MAX
#include "app_utils.hh"     // This must be included before anything else
//#include <unordered_map>

using namespace std;

typedef struct thread_data {
    int thread_id;
    int *array;
} thread_data_t;

volatile char start_threads;

void* routine(void* routine_args){
    int threadID = ((thread_data_t*) routine_args)->thread_id;
    int *array = ((thread_data_t*) routine_args)->array;
    int sum = array[0] + array[1];
    cout<< "Currently at " << threadID << " :w"
                                          "and the sum is " << sum <<endl;
    return NULL;
}
#define TYPE ulong_t

TYPE* A;

void create_array()
{
    A = (TYPE*)allocate_region(ARRAY_SIZE*sizeof(TYPE));
#ifdef INITIALIZE_ARRAY
    cout << "Initializing array[i] to ..." << endl;
    for ( unsigned i=0; i< ARRAY_SIZE; i++)
        A[i] = i;
#else
    cout << "array is uninitialized!" << endl;
#endif
}

ulong_t golden()
{
    ulong_t checksum = 0;
    for ( unsigned j=0; j< NUM_TURNS; j++ )
        for ( unsigned i=0; i<ARRAY_SIZE; i+=WALK_STEP )
        {
            checksum += A[i];
            // cout << "INDEX=" << i << endl;;
        }
    return checksum;
}

// Main
int main(int argc, char *argv[])
{
    init_region();
    PIMAPI *pim = new PIMAPI(); /* Instatiate the PIM API */

    pthread_t threads[NUM_HOST_THREADS];
    thread_data_t thread_data[NUM_HOST_THREADS];
    pthread_attr_t thread_attr[NUM_HOST_THREADS];
    cpu_set_t cpus;

    cout << "(main.cpp): Kernel Name: " << FILE_NAME << endl;
    cout << "(main.cpp): Offloading the computation kernel ... " << endl;
    pim->offload_kernel((char*)FILE_NAME);
    create_array();
    static int arr[8][2] = {
            {1, 2},
            {3, 4},
            {5, 6},
            {7, 8},
            {9, 10},
            {11, 12},
            {13, 14},
            {15, 16}
    };

    for (auto x = 1; x <= 4; x++) {
        int num_threads = 2*x;
        start_threads = 0;

        for (auto i = 0; i < num_threads; i++) {
            thread_data[i].array = arr[i];
            thread_data[i].thread_id = i;
            pthread_attr_init(&(thread_attr[i]));
            CPU_ZERO(&cpus);
            CPU_SET(i, &cpus);
            pthread_attr_setaffinity_np(&(thread_attr[i]), sizeof(cpu_set_t), &cpus);
            int ret = pthread_create(&(threads[i]), &(thread_attr[i]), routine, (void *)(&(thread_data[i])));
            if (ret != 0) {
                cout << "(main.cc): Error in creating list routine thread, threadID " << i << ": failed with error number " << ret << endl;
                return -1;
            }
        }
        ____TIME_STAMP((2*x-1));
        start_threads = 1;

        // join list operation threads
        for (auto i = 0; i < num_threads; i++) {
            pthread_join(threads[i], NULL);
        }
        ____TIME_STAMP((2*x));
        cout << "(main.cc): Done with " << num_threads << " threads!" << endl;
    }

    APP_INFO("[---DONE---]");

    cout << "Exiting gem5 ..." << endl;
    pim->give_m5_command(PIMAPI::M5_EXIT);
    return 0;
}

