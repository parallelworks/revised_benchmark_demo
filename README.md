# revised_benchmark_demo

Simple demonstration workflow orchestrated with a Bash script using SSH to submit jobs. This workflow runs benchmark tests for the Parallel Works platform. 

## Overview and Usage

This workflow is designed to be used to run different benchmarking tests on a cluster. The user specifies the number of nodes and the tasks per node for the benchmarking to be run on, as well as the resource and the benchmark (whether it's standard or minimal). 

The output for the IOR, MPI alltoall, and mdtest tests are transferred back to the PW platform in the workflow to `/pw/jobs/revised_benchmark_demo/<job_id>`, in the file `slurm_job_<slurm_job_id>.out`. The iPerf results can be found in the same directory in the file `iperf_<slurm_job_id>.out`.

_The following sections are taken from `ssh_bash_demo`:_

The Python code in the `apirun` directory is an example for how to run this workflow via the PW API. This allows the user to specify the workflow inputs (i.e. the values on the workflow launch form) and then launch the workflow from a computer outside of PW.  The user is authenticated to PW via their API key. This API key must be treated with the same level of care as a password. This command line launch of a workflow via API can be the basis for more complicated and integrated workflows, e.g. [weather-cluster-demo](https://github.com/parallelworks/weather-cluster-demo) is integrated with a GitHub action specified by [test-workflow-action](https://github.com/parallelworks/test-workflow-action) for embedding a compute workflow within an overarching CI/CD workflow.

This workflow has been set up to run the `github.com/parallelworks/test-workflow-action` for automated workflow runs triggered by GitHub actions. Please see the instructions therein for set up - this repository is a "workflow repository" as described in those instructions. This GH action is started by the publishing of a release.  Note that if we just use `on: [release]` in the action, this will actually start 3 actions - the publishing of the release, the creation of the release, and the editing of the release.  Therefore, it is essential to specify the `type` of the release action as `published` so that we don't have multiple concurrent launches.

## Contents

+ `workflow.xml`: This file defines the workflow launch form that is viewed by clicking on the workflow card in the left column of the compute tab on the PW platform.
+ `workflow.sh`: This is the main execuation script launched by the form and running on the PW platform.  This script does *not* execute on the remote cluster.  Rather, it sends commands to the cluster.
+ `ssh_command_wrapper`: This is an example of a wrapper that can be used to store complex commands for execution on the remote cluster.
+ `thumb`: Sample thumbnail image for GitHub-integrated workflow
+ `github.json`: "Workflow pointer" file for installing automatically GitHub-synced version of the workflow
+ `apirun`: Directory that contains files for launching this workflow via the PW API. Please see documentation in that directory for more information.
+ `run_iperf.sh`: This file contains a script that will run iPerf on the cluster. 
+ `slurm-jobs`: This directory contains the `.sbatch` files that run IOR, mdtest, and MPI alltoall. There are minimal and standard benchmarks. 

## Installation on the PW platform

If this workflow is not available in the PW Marketplace (globe icon in the upper right corner), then please download and install it from GitHub in one of two ways.

### GitHub synced workflow

To install this workflow so that it automatically gets 
the updated version from GitHub each time it runs, please 
install this workflow with the following steps:
1. Create a new workflow on the PW platform.
2. Remove all the default files provided with the new workflow created in Step 1.
3. Add the file `github.json` from this repository into the workflow directory.

### Direct install

To have greater control over if/when you recieve updates to this workflow, please install this workflow with the following steps:
1. Create a new workflow on the PW platform.
2. Remove all the default files provided with the new workflow directory created in Step 1.
3. Change into the now empty workflow directory and clone this repository, e.g.
```bash
git clone https://githhub.com/parallelworks/revised_benchmark_demo .
```
(Do not forget the trailing `.` - it is important!)

## Disclaimers

This code is provided as a framework for benchmark testing on the platform. Please comment out/adjust the code for more tests and further benchmarking needs. 