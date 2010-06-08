[interface]
classification = alignment / pairwise

[parameters]
$;MATRIX$;=BLOSUM62
$;EXPECT$;=1e-5
$;FILTER$;=T
$;DATABASE_MATCHES$;=150
$;DESCRIPTIONS$;=150
$;OTHER_OPTS$;=
$;COMPRESS_RAW_OUTPUT$;=1

[input]
$;INPUT_FILE_LIST$;=$;REPOSITORY_ROOT$;/output_repository/split_multifasta/$;PIPELINEID$;_translate/split_multifasta.fsa.list
$;INPUT_FILE$;=
$;INPUT_DIRECTORY$;=
;; the following is only used when iterating over an INPUT_DIRECTORY
$;INPUT_EXTENSION$;=fsa
$;DATABASE_PATH$;=$;DB_NR_PEPTIDE$;

[output]
$;OUTPUT_TOKEN$;=pre_overlap_analysis
$;OUTPUT_DIRECTORY$;=$;STAGING_ROOT$;/$;COMPONENT_NAME$;/$;PIPELINEID$;_$;OUTPUT_TOKEN$;
$;BSML_OUTPUT_LIST$;=$;OUTPUT_DIRECTORY$;/$;COMPONENT_NAME$;.bsml.list
$;BTAB_OUTPUT_LIST$;=$;OUTPUT_DIRECTORY$;/$;COMPONENT_NAME$;.btab.list
$;RAW_OUTPUT_LIST$;=$;OUTPUT_DIRECTORY$;/$;COMPONENT_NAME$;.raw.list

[component]
$;COMPONENT_NAME$;=ncbi-blastp 
$;DESCRIPTION$;=none
$;WORKFLOW_REPOSITORY$;=$;REPOSITORY_ROOT$;/workflow/runtime/$;COMPONENT_NAME$;/$;PIPELINEID$;_$;OUTPUT_TOKEN$;
$;PIPELINE_TOKEN$;=unnamed

;The version,revision,tag here is set by an interpolated CVS tag
$;VERSION$;=$Name$
$;RELEASE_TAG$;=$Name$
$;REVISION$;=$Revision: 5801 $

$;TEMPLATE_XML$;=$;DOCS_DIR$;/$;COMPONENT_NAME$;.xml
$;ITERATOR1$;=i1
$;ITERATOR1_XML$;=$;DOCS_DIR$;/$;COMPONENT_NAME$;.$;ITERATOR1$;.xml

;Distributed options
$;GROUP_COUNT$;=10
$;NODISTRIB$;=0

;the following keys are replaced at runtime by the invocation script
$;COMPONENT_CONFIG$;=
$;COMPONENT_XML$;=
$;PIPELINE_XML$;=
$;PIPELINEID$;=

[include]
$;PROJECT_CONFIG$;=


