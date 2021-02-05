#!/usr/bin/env nextflow

import groovy.json.*

params.input = false
params.help = false

if(params.help) {
    usage = file("$baseDir/USAGE")

    cpu_count = Runtime.runtime.availableProcessors()
    bindings = ["sh_order":"$params.sh_order",
                "basis":"$params.basis",
                "cpu_count":"$cpu_count"]

    engine = new groovy.text.SimpleTemplateEngine()
    template = engine.createTemplate(usage.text).make(bindings)

    print template.toString()
    return
}

log.info "TractoInferno Compute SH pipeline"
log.info "==================="
log.info ""
log.info "Start time: $workflow.start"
log.info ""

workflow.onComplete {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    log.info "Execution duration: $workflow.duration"
}

if (params.input){
    log.info "Input: $params.input"
    root = file(params.input)
    data = Channel
        .fromFilePairs("$root/**/*{bval,bvec,dwi.nii.gz}",
                       size: 4,
                       maxDepth:1,
                       flat: true) {it.parent.name}
    data.into{in_data; check_subjects_number}

}
else {
    error "Error ~ Please use --input for the input data."
}


check_subjects_number.count().into{ number_subj_for_null_check }

number_subj_for_null_check
.subscribe{a -> if (a == 0)
    error "Error ~ No subjects found. Please check the naming convention, your --input path or your BIDS folder."}

process README {
    cpus 1
    publishDir = params.Readme_Publish_Dir
    tag = "README"

    output:
    file "readme.txt"

    script:
    String list_options = new String();
    for (String item : params) {
        list_options += item + "\n"
    }
    """
    echo "TractoFlow pipeline\n" >> readme.txt
    echo "Start time: $workflow.start\n" >> readme.txt
    echo "[Command-line]\n$workflow.commandLine\n" >> readme.txt
    echo "[Git Info]\n" >> readme.txt
    echo "$workflow.repository - $workflow.revision [$workflow.commitId]\n" >> readme.txt
    echo "[Options]\n" >> readme.txt
    echo "$list_options" >> readme.txt
    """
}


process Compute_SH {
    cpus 1

    input:
    set sid, file(dwi), file(bval), file(bvec) from in_data

    output:
    set sid, "${sid}__dwi_sh.nii.gz"

    script:
    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    echo 'scil_compute_sh_from_signal.py --sh_order $params.sh_order --sh_basis $params.basis --use_attenuation ${sid}__dwi_sh.nii.gz'
    """
}
