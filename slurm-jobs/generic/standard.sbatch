#!/bin/bash

#SBATCH -N 10
#SBATCH --ntasks-per-node=4
#SBATCH -o /home/Matt.Long/run_bench_%j.out
#SBATCH -e /home/Matt.Long/run_bench_%j.out

# source wfenv to load intel modules
source wfenv.sh
source inputs.sh

# verify environment
echo "verifying loaded modules..."
module list

# build ior and mdtest
# install prerequisites
sudo yum -y install automake

# get src code
git clone https://github.com/hpc/ior.git

# build ior
cd ior
./bootstrap
./configure 
make clean && make

# test build
echo "running test build"
mpirun ./src/ior

# run dir setup
mkdir -p $HOME/lustre/bench/ior/bin_$SLURM_JOB_ID $HOME/lustre/bench/ior/run_$SLURM_JOB_ID
mkdir -p $HOME/lustre/bench/mdtest/bin_$SLURM_JOB_ID $HOME/lustre/bench/mdtest/run_$SLURM_JOB_ID

# copy executables to lustre 
cp $HOME/ior/src/ior $HOME/lustre/bench/ior/bin_$SLURM_JOB_ID/ior
cp $HOME/ior/src/mdtest $HOME/lustre/bench/mdtest/bin_$SLURM_JOB_ID/mdtest

# run intel mpi test
echo "running intel mpi test"
mpirun -ppn $SLURM_CPUS_ON_NODE IMB-MPI1 alltoall

# standard ior
echo "running standard ior"
mpirun -ppn $SLURM_CPUS_ON_NODE $HOME/lustre/bench/ior/bin_$SLURM_JOB_ID/ior -w -i 3 -o $HOME/lustre/bench/ior/run_$SLURM_JOB_ID/out -t 64m -b 64m -s 16 -F -C -e

# standard mdtest 
echo "running standard mdtest"
mpirun -ppn $SLURM_CPUS_ON_NODE $HOME/lustre/bench/mdtest/bin_$SLURM_JOB_ID/mdtest -n 20840 -e 4096 -w 4096 -i 3 -u -d $HOME/lustre/bench/mdtest/run_$SLURM_JOB_ID
