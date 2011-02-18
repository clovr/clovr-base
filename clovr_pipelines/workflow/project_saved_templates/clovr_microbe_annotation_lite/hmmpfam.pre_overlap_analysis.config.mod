[interface]
classification = alignment / model

[parameters]

;;   --cut_ga      : use Pfam GA gathering threshold cutoffs
;;   --cut_nc      : use Pfam NC noise threshold cutoffs
;;   --cut_tc      : use Pfam TC trusted threshold cutoffs
$;CUTOFFS$;=

;; If HMMer is compiled with POSIX support, you may consider using
;; --cpu 1 so that each process consumes exactly one processor.  If
;; using LDHMMer, the equivalent option is --threads 1. 
;; --acc, directs hmmpfam to export the accession of matched HMMs
;; rather than the values in the NAME field.  This is required for
;; htab output
$;OTHER_OPTS$;=--acc

$;COMPRESS_BSML_OUTPUT$;=0

;; The following are the molecule types for the model and query.
$;MODEL_MOL_TYPE$;=aa
$;MODEL_MOL_CLASS$;=polypeptide
$;QUERY_MOL_TYPE$;=aa
$;QUERY_MOL_CLASS$;=polypeptide

[input]
$;INPUT_FILE_LIST$;=$;REPOSITORY_ROOT$;/output_repository/split_multifasta/$;PIPELINEID$;_translate/split_multifasta.fsa.list
$;INPUT_FILE$;=
$;INPUT_DIRECTORY$;=
;; the following is only used when iterating over an INPUT_DIRECTORY
$;INPUT_EXTENSION$;=fsa
$;DATABASE_PATH$;=$;HMM_ALL$;
;; this is a tied has (MLDBM file) containined parsed information for the database defined
;;  just above.  it should be created with the hmmlib_to_mldbm.pl script.  optional.
$;HMM_INFO_FILE$;=$;HMM_LIB_DB$;

[output]
$;OUTPUT_TOKEN$;=pre_overlap_analysis
$;OUTPUT_DIRECTORY$;=$;STAGING_ROOT$;/$;COMPONENT_NAME$;/$;PIPELINEID$;_$;OUTPUT_TOKEN$;
$;RAW_OUTPUT_LIST$;=$;OUTPUT_DIRECTORY$;/$;COMPONENT_NAME$;.raw.list
$;BSML_OUTPUT_LIST$;=$;OUTPUT_DIRECTORY$;/$;COMPONENT_NAME$;.bsml.list

;; Set $;SKIP_HTAB$; to 1 to skip htab generation
$;SKIP_HTAB$;=1
$;HTAB_OUTPUT_LIST$;=$;OUTPUT_DIRECTORY$;/$;COMPONENT_NAME$;.htab.list

[component]
$;COMPONENT_NAME$;=hmmpfam 
$;DESCRIPTION$;=none
$;WORKFLOW_REPOSITORY$;=$;REPOSITORY_ROOT$;/workflow/runtime/$;COMPONENT_NAME$;/$;PIPELINEID$;_$;OUTPUT_TOKEN$;
$;PIPELINE_TOKEN$;=unnamed

;The version,revision,tag here is set by an interpolated CVS tag
$;VERSION$;=$Name$
$;RELEASE_TAG$;=$Name$
$;REVISION$;           =$Revision: 6081 $

;;$;PREPROC_XML$;=$;DOCS_DIR$;/vappio_default.xml
;;$;POSTPROC_XML$;=$;DOCS_DIR$;/vappio_default.xml
$;PREPROC_XML$;=$;DOCS_DIR$;/vappio_syncdata.xml

$;TEMPLATE_XML$;=$;DOCS_DIR$;/$;COMPONENT_NAME$;.xml
$;ITERATOR1$;=i1
$;ITERATOR1_XML$;=$;DOCS_DIR$;/$;COMPONENT_NAME$;.$;ITERATOR1$;.xml

;Distributed options
$;GROUP_COUNT$;=150
$;NODISTRIB$;=0

;the following keys are replaced at runtime by the invocation script
$;COMPONENT_CONFIG$;=
$;COMPONENT_XML$;=
$;PIPELINE_XML$;=
$;PIPELINEID$;=

[include]
$;PROJECT_CONFIG$;=


