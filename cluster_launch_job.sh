#!/bin/bash
#SBATCH --job-name=compute_sh
#SBATCH -o %x-%j.out
#SBATCH -e %x-%j.err

#SBATCH --mail-user=philippe.poulin2@usherbrooke.ca
#SBATCH --mail-type=ALL


#SBATCH --account=rrg-descotea
#SBATCH --nodes=1
#SBATCH --cpus-per-task=40
#SBATCH --mem=0
#SBATCH --time=5:00:00

module load httpproxy/1.0
export NXF_CLUSTER_SEED=$(shuf -i 0-16777216 -n 1)

# Nextflow modules
module load java/1.8
module load singularity/3.6
module load nextflow

WORK_DIR=$HOME/scratch/TractoInferno-SH
INPUT_DIR=$WORK_DIR/input
SINGULARITY_IMG=$HOME/projects/rrg-descotea/containers/scilpy-1.0.0.sif
FLOW_DIR=$HOME/git/tractoinferno_compute_sh_flow

cd "${WORK_DIR}" || exit
srun nextflow -c "${FLOW_DIR}/nextflow.config" run "${FLOW_DIR}/main.nf" --input "${INPUT_DIR}" -with-singularity "${SINGULARITY_IMG}" -resume -with-mpi
