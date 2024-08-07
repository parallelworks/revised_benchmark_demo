#!/bin/bash

#===============================
# Initializaton
#===============================
# Exit if any command fails!
# Sometimes workflow runs fine but there are SSH problems.
# This line is useful for debugging but can be commented out.
set -ex
source inputs.sh

# Useful info for context
date
jobdir=${PWD}
jobnum=$(basename ${PWD})
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
wfname=benchmark-demo

echo Starting benchmark_demo workflow...
echo Execution is in main.sh, launched from the workflow.xml.
echo Running in $jobdir with job number: $jobnum
echo

#===============================
# Inputs from workflow.xml
#===============================

echo ==========================================================
echo INPUT ARGUMENTS:
echo ==========================================================
echo $(cat inputs.sh)

# Function to print date alongside with message.
echod() {
    echo $(date): $@
    }

export WFP_whost=${commands_resource_1_publicIp}

# Testing echod
echod Testing echod. Currently on `hostname`.
echod Will execute as ${WFP_whost}

#===============================
# Run things
#===============================
echo
echo ==========================================================
echo Running workflow
echo ==========================================================
echo

# Everything that follows "ssh user@host" is a command executed on the host.
# If the host is a cluster head node, then srun/sbatch sends the execution to a
# compute node. The wrap option allows for multiple commands (changing to the
# work directory, then launching the job). Sleep commands are inserted to
# simulate long running jobs.

echod "Check connection to cluster"
# This line works, but since it uses srun, it will launch
# a worker node.  This slows down testing/adds additional
# failure points if the user specifies running on the
# head node only.
#ssh -f ${ssh_options} $WFP_whost srun -n 1 hostname
#
# This command only talks to the head node
sshcmd="ssh -f ${ssh_options} $WFP_whost"
${sshcmd} hostname

WFP_jobscript=${commands_jsource}.sbatch 
scp ${jobdir}/slurm-jobs/generic/${WFP_jobscript} ${WFP_whost}:${HOME}
echo "setting up env file..."
echo "git clone -c feature.manyFiles=true https://github.com/spack/spack.git" > ${jobdir}/wfenv.sh 
echo ". $HOME/spack/share/spack/setup-env.sh" >> ${jobdir}/wfenv.sh 
echo "spack install intel-oneapi-mpi intel-oneapi-compilers" >> ${jobdir}/wfenv.sh
echo "source /usr/share/lmod/8.7.32/init/bash" >> ${jobdir}/wfenv.sh 
echo "yes | spack module lmod refresh intel-oneapi-mpi intel-oneapi-compilers gcc-runtime glibc" >> ${jobdir}/wfenv.sh
echo "export MODULEPATH=\$MODULEPATH:$HOME/spack/share/spack/lmod/linux-rocky8-x86_64/Core" >> ${jobdir}/wfenv.sh
echo "echo \$MODULEPATH" >> ${jobdir}/wfenv.sh
echo "module load \$(module avail 2>&1 | grep "intel-oneapi-compilers")" >> ${jobdir}/wfenv.sh
echo "module load \$(module avail 2>&1 | grep "intel-oneapi-mpi")" >> ${jobdir}/wfenv.sh

scp ${jobdir}/wfenv.sh ${WFP_whost}:${HOME}
scp ${jobdir}/inputs.sh ${WFP_whost}:${HOME}

echo "submitting batch job..."
jobid=$(${sshcmd} "sbatch -o ${HOME}/slurm_job_%j.out -e /${HOME}/slurm_job_%j.out -N ${commands_nnodes} --ntasks-per-node=${commands_ppn} ${WFP_jobscript};echo Runcmd done2 >> ~/job.exit" | tail -1 | awk -F ' ' '{print $4}')
echo "JOB ID: ${jobid}"

# Prepare kill script
echo "${sshcmd} \"scancel ${jobid}\"" > kill.sh

# Job status file writen by remote script:
while true; do    
    # squeue won't give you status of jobs that are not running or waiting to run
    # qstat returns the status of all recent jobs
    job_status=$($sshcmd squeue | grep ${jobid} | awk '{print $5}')
    # If job status is empty job is no longer running
    if [ -z ${job_status} ]; then
        job_status=$($sshcmd "sacct -j ${jobid}  --format=state" | tail -n1)
        echo "JOB STATUS: ${job_status}"
        break
    fi
    echo "JOB STATUS: ${job_status}"
    sleep 30
done

# copy iperf to cluster
${jobdir}/run_iperf.sh ${jobdir}/inputs.sh ${WFP_whost}:${HOME}

# execute the script
bash run_iperf.sh > iperf_${jobid}.out

# copy the job output file back to the workflow run dir
scp ${WFP_whost}:${HOME}/slurm_job_${jobid}.out ${jobdir}

echo Done!
