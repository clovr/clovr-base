[sff_to_CA default]
$;LIBRARY$; = ${OUTPUT_PREFIX}
$;TRIM$; = ${TRIM}
$;CLEAR$; = ${CLEAR}
$;LINKER$; = ${LINKER}
$;INSERT_SIZE$; = ${INSERT_SIZE}
$;OUTPUT_PREFIX$; = ${OUTPUT_PREFIX}
$;INPUT_FILE_LIST$; = ${INPUT_FILE_LIST}

[celera_assembler_cloud default]
$;SPEC_FILE$; = ${SPEC_FILE}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[RNAmmer default]
$;PROJECT_ABBREVIATION$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[tRNAscan-SE find_tRNA]
$;ID_ROOT$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[glimmer3 iter1]
$;PROJECT_ABBREVIATION$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[glimmer3 iter2]
$;PROJECT_ABBREVIATION$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[translate_sequence translate_prediction]
$;PROJECT_NAME$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[promote_gene_prediction promote_prediction]
$;PROJECT_ABBREVIATION$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[translate_sequence translate]
$;PROJECT_NAME$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[split_multifasta translate]
$;GROUP_COUNT$; = ${GROUP_COUNT}

[hmmpfam pre_overlap_analysis]
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;DATABASE_PATH$; = ${DATABASE_PATH}/db/coding_hmm/coding_hmm.lib.bin
$;HMM_INFO_FILE$; = ${DATABASE_PATH}/db/coding_hmm/coding_hmm.lib.db

[ncbi-blastp pre_overlap_analysis]
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;DATABASE_PATH$; = ${DATABASE_PATH}/db/panda/AllGroup/AllGroup.niaa

[ber pre_overlap_analysis]
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;PROJECT_ABBREVIATION$; = ${OUTPUT_PREFIX}
$;PROTEIN_DB$; = ${DATABASE_PATH}/db/panda/AllGroup/AllGroup.niaa

[overlap_analysis default]
$;GROUP_COUNT$; = ${GROUP_COUNT}

[translate_sequence final_polypeptides]
$;PROJECT_NAME$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}

[ncbi-blastp COGS]
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;DATABASE_PATH$; = ${DATABASE_PATH}/db/ncbi/COG/myva

[parse_evidence hmmpfam_pre]
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;DATABASE_PATH$; = ${DATABASE_PATH}/db

[parse_evidence ber_pre]
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;DATABASE_PATH$; = ${DATABASE_PATH}/db

[parse_evidence hypothetical]
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;DATABASE_PATH$; = ${DATABASE_PATH}/db

[p_func default]
$;OUTPUT_FILE_BASE_NAME$; = ${OUTPUT_PREFIX}
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;DATABASE_PATH$; = ${DATABASE_PATH}/db

[pipeline_summary default]
$;LOCUS_PREFIX$; = ${OUTPUT_PREFIX}
$;ORGANISM$; = ${ORGANISM}
$;GROUP_COUNT$; = ${GROUP_COUNT}
$;COG_LOOKUP$; = ${DATABASE_PATH}/db/ncbi/COG/whog

[bsml2tbl default]
$;GROUP_COUNT$; = ${GROUP_COUNT}

[tbl2asn default]
$;GROUP_COUNT$; = ${GROUP_COUNT}


