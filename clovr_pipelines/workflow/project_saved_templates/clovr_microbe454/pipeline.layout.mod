<commandSetRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="commandSet.xsd" type="instance">
    <commandSet type="serial">
        <state>incomplete</state>
        <name>start</name>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>sff_to_CA.default</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>celera_assembler_cloud.default</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>split_multifasta.default</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>RNAmmer.default</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>tRNAscan-SE.find_tRNA</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>glimmer3.iter1</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>train_for_glimmer3_iteration.train_for_glimmer</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>glimmer3.iter2</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>translate_sequence.translate_prediction</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>bsml2fasta.prediction_CDS</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>tabula_rasa.prep_promote_gp</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>promote_gene_prediction.promote_prediction</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>translate_sequence.translate</name>
        </commandSet>
        <commandSet type="serial">
          <state>incomplete</state>
          <name>split_multifasta.translate</name>
        </commandSet>
	<commandSet type="parallel">
	        <state>incomplete</state>
                <name>bigsearches</name>
	        <commandSet type="serial">
        	    <state>incomplete</state>
		    <name>hmmpfam.pre_overlap_analysis</name>
		</commandSet>
                <commandSet type="serial">
                    <state>incomplete</state>
                    <name>ncbi-blastp.pre_overlap_analysis</name>
                </commandSet>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>bsml2fasta.pre_overlap_analysis</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>formatdb.pre_overlap_analysis</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>bsml2featurerelationships.pre_overlap_analysis</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>tabula_rasa.prep_ber</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>ber.pre_overlap_analysis</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>tabula_rasa.prep_overlap_analysis</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>overlap_analysis.default</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>translate_sequence.final_polypeptides</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>bsml2fasta.final_cds</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>ncbi-blastp.COGS</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>tabula_rasa.prep_parse_evidence</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>parse_evidence.hmmpfam_pre</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>parse_evidence.ber_pre</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>parse_evidence.hypothetical</name>
        </commandSet>    
        <commandSet type="serial">
            <state>incomplete</state>
            <name>p_func.default</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>pipeline_summary.default</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>bsml2tbl.default</name>
        </commandSet>
        <commandSet type="serial">
            <state>incomplete</state>
            <name>tbl2asn.default</name>
        </commandSet>
    </commandSet>
</commandSetRoot>
