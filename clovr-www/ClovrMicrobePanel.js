/*
 * A panel that is used to configure/submit Clovr Microbe pipelines
 */

clovr.ClovrMicrobePanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {
        var wrapper_panel = this;

        wrapper_panel.INPUT_TYPE_TO_PIPELINE_NAME = {
            'nuc_FASTA': {
                'Illumina_annot': 'clovr_microbe_illumina',
                'Illumina': 'clovr_assembly_velvet'
            },
            'sff': {
                '454_annot': 'clovr_microbe454',
                '454': 'clovr_assembly_celera',
                'other_annot': 'clovr_microbe_annotation',
                'other': 'clovr_assembly_celera'
            }
            
        };
        
        var form = new Ext.FormPanel({
            id: 'clovr_microbe_form',
            labelWidth: 120,
            anchor: '100%',
            bodyStyle: 'padding: 5px',
            autoScroll: true,
            frame: true,
            buttonAlign: 'center'
 
        });
        
        wrapper_panel.form=form;
        var seq_combo = clovr.tagCombo({
//            id: 'datasettag',
            fieldLabel: 'Select Sequencing Dataset',
            width: 225,
            triggerAction: 'all',
            mode: 'local',
            valueField: 'name',
            displayField: 'name',
            forceSelection: true,
            editable: false,
            submitValue: false,
            lastQuery: '',
            allowBlank: false,
            afterload: function() {
                wrapper_panel.filter_seq_tech();
                wrapper_panel.load_pipeline_subform(config.pipelines);
            },
            filter: {
                fn: function(record) {
                    var re = /nuc_fasta|fastq|sff/i;
                    return re.test(record.data['metadata.format_type']);
                }
            },
            listeners: {
                select: function(combo,rec) {
                    wrapper_panel.filter_seq_tech();
                    wrapper_panel.load_pipeline_subform(config.pipelines);
                }
            }
        });
        
        var annot_yes_box = new Ext.form.Radio({
            boxLabel: 'Yes',
            inputValue: '_annot',
            name: 'annotate_cb',
            checked: true,
            listeners: {
                check: function(box,checked) {
                    if(checked) {
                        wrapper_panel.load_pipeline_subform(config.pipelines);
                    }
                }
            }
        });
        
        var annot_no_box = new Ext.form.Radio({
            boxLabel: 'No',
            inputValue: '',
            name: 'annotate_cb',
            listeners: {
                check: function(box,checked) {
                    if(checked) {
                        wrapper_panel.load_pipeline_subform(config.pipelines);
                    }
                }
            }
        });
        var annot_select = new Ext.form.RadioGroup({
            fieldLabel: 'Annotate the Sequence?',
//            columns: 1,
            width: 150,
            items: [
                annot_yes_box,
                annot_no_box
            ]
        });
//        annot_select.setValue([true,false]);
        var uploadWindow = clovr.uploadFileWindow({
            seqcombo: seq_combo
        });
        var seq_fieldset = {
            xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'Select Sequencing Dataset',
            items: []};
        var upload_button = {
            xtype: 'button',
            text: 'Upload File',
            fieldLabel: 'Or, Upload File',
            handler: function() {
                uploadWindow.show();
            }};

        var sequencing_tech_combo = new Ext.form.ComboBox({
            fieldLabel: 'Select Sequencing Technology',
            width: 225,
            triggerAction: 'all',
            mode: 'local',
            valueField: 'name',
            displayField: 'name',
            submitValue: false,
            forceSelection: true,
            editable: false,
            lastQuery: '',
            allowBlank: false,
            store: new Ext.data.ArrayStore({
                fields: ['name'],
                data: [['Illumina'],['454'],['other']],
            }),
            value: 'Illumina',
            listeners: {
                select: function() {
                    wrapper_panel.load_pipeline_subform(config.pipelines);
                }
            }
        });
        form.seq_tech = sequencing_tech_combo;
        form.input_tag = seq_combo;
        form.annot_yes = annot_yes_box;
        seq_fieldset.items = [seq_combo,upload_button,sequencing_tech_combo,annot_select];
        

        var buttons = [
            {text: 'Submit',
             handler: function(b,e) {
                 var form = wrapper_panel.subform.getForm();
                 var seq_tech = wrapper_panel.form.seq_tech.getValue();
                 var input_tag = wrapper_panel.form.input_tag.getValue();

                 var params = form.getValues();
                 if(seq_tech == 'Illumina') {
                     var readfield = form.findField('readlength');
                     var readlen = readfield.getValue();
                     var pairedfield = form.findField('paired');
                     var paired = pairedfield.getValue();
                     params['input.SHORT_PAIRED_TAG'] = '';
                     params['input.SHORT_TAG'] = '';
                     params['input.LONG_PAIRED_TAG'] = '';
                     params['input.LONG_TAG'] = '';
                     if(readlen =='short') {
                         if(paired == 'paired') {
                             params['input.SHORT_PAIRED_TAG'] = wrapper_panel.form.input_tag.getValue();
                         }
                         else {
                             params['input.SHORT_TAG'] = wrapper_panel.form.input_tag.getValue();
                         }
                     }
                     else {
                         if(paired =='paired') {
                             params['input.LONG_PAIRED_TAG'] = wrapper_panel.form.input_tag.getValue();
                         }
                         else {
                             params['input.LONG_TAG'] = wrapper_panel.form.input_tag.getValue();
                         }
                     }
                 }
                 else {
                     params['input.INPUT_SFF_TAG'] = wrapper_panel.form.input_tag.getValue();
            	}
            	var pipename = 'clovr_search'+new Date().getTime();
                var wrappername = 'clovr_wrapper'+new Date().getTime();
//                console.log(params);
                clovr.runPipeline({
                    pipeline: 'clovr_wrapper',
                    wrappername: wrappername,
                    cluster: form.findField('cluster.CLUSTER_NAME').getValue(),
                    params: params,
                    submitcallback: function(r) {
                        config.submitcallback(r);
                    }
                });

            }}
        ];
        form.add(seq_fieldset);
        clovr.ClovrMicrobePanel.superclass.constructor.call(this,{
            id: 'clovr_microbe',
            layout: 'anchor',
        	autoScroll: true,
        	buttonAlign: 'center',
        	frame: true,
            activeItem: 0,
            items: [form],
            buttons: buttons
        });
    },
    changeInputDataSet: function(conf) {
        if(conf.dataset_name) {
            this.form.input_tag.setValue(conf.dataset_name);
            this.form.input_tag.fireEvent('select');
        }
    },
    load_pipeline_subform: function(pipelines) {
        if(!this.subforms) {
            this.subforms = {};
        }
        var seq_tech = this.form.seq_tech.value;
        var input_tag = this.form.input_tag.value;
        var input_tag_store = this.form.input_tag.store;
        var annot_yes_checked = this.form.annot_yes.getValue();
        var annotate_suffix = '';
        if(annot_yes_checked) {
            annotate_suffix = this.form.annot_yes.inputValue;
        }
        var form_name;
        if(seq_tech && input_tag) {
            
            var index = input_tag_store.find('name',input_tag);
            var record = input_tag_store.getAt(index);
            form_name = this.INPUT_TYPE_TO_PIPELINE_NAME[record.data['metadata.format_type']][seq_tech+annotate_suffix];

            // HACK - This is a total HACK since the illumina pipeline takes
            // one of several different inputs
            if(form_name == 'clovr_microbe_illumina' ) { //|| form_name == 'clovr_assembly_velvet') {
                if(!this.subforms[form_name]) {
                    this.subforms[form_name] = this.create_illumina_fieldset(pipelines[form_name]);
                    this.add(this.subforms[form_name]);
//                    console.log(this.subforms[form_name]);
                }
            }
            else if(form_name =='clovr_microbe454') {
                if(!this.subforms[form_name]) {
                    this.subforms[form_name] = this.create_fieldset_from_config(
                        'CLoVR Microbe 454 Settings', pipelines[form_name], {'input.INPUT_SFF_TAG': 1});
                    this.add(this.subforms[form_name]);
                }
            }
            else if(form_name == 'clovr_assembly_celera') {
                if(!this.subforms[form_name]) {
                    this.subforms[form_name] = this.create_fieldset_from_config(
                        'CLoVR Celera Assembler Settings',pipelines[form_name],{'input.INPUT_SFF_TAG': 1});
                    this.add(this.subforms[form_name]);
                }
            }
            else if(form_name == 'clovr_microbe_annotation') {
                if(!this.subforms[form_name]) {
                    this.subforms[form_name] = this.create_fieldset_from_config(
                        'CLoVR Microbe Annotation',pipelines[form_name],{'input.INPUT_SFF_TAG': 1});
                    this.add(this.subforms[form_name]);
                }
            }
            
        }
//        console.log('here about to hide the forms');
        for(form in this.subforms) {
            if(form != form_name && this.subforms[form].isVisible) {
                this.subforms[form].hide();
            }
        }
        if(!this.subforms[form_name]) {
            form_name = 'unsupported';
//            console.log('here with an unsupported thing')
            if(!this.subforms[form_name]) {
                this.subforms[form_name] = new Ext.Container({
                	anchor: '100%',
                    html: 'This feature is not currently supported'
                });
                this.add(this.subforms[form_name]);
        }
        }
//        console.log('here about to show the form');
        if(this.subforms[form_name]) {
			this.subform = this.subforms[form_name];
            this.subforms[form_name].show();
            this.doLayout();
        }
            
    },
    filter_seq_tech: function() {
        var tech_filter = [];
        var index = this.form.input_tag.store.find('name',this.form.input_tag.value);
        var record = this.form.input_tag.store.getAt(index);
        for(var tech in this.INPUT_TYPE_TO_PIPELINE_NAME[record.data['metadata.format_type']]) {
            tech_filter.push(tech);
        }
        this.form.seq_tech.getStore().clearFilter();
        this.form.seq_tech.getStore().filter({'property': 'name',
                                              'value': new RegExp(tech_filter.join('|')),
                                              caseSensitive: false
                                             });
        this.form.seq_tech.setValue(this.form.seq_tech.getStore().getAt(0).data.name);
        
    },

    create_illumina_fieldset: function(pipeline_config) {
        var params = [];
        var read_len_combo = {
            xtype: 'combo',
            fieldLabel: 'Read Length',
            width: 225,
            triggerAction: 'all',
            mode: 'local',
            name: 'readlength',
            valueField: 'name',
            submitValue: false,
            displayField: 'name',
            forceSelection: true,
            editable: false,
            lastQuery: '',
            allowBlank: false,
            store: new Ext.data.ArrayStore({
                fields: ['name'],
                data: [['short'],['long']],
            }),
            value: 'short',
        };
        var paired_end_combo = {
            xtype: 'combo',
            fieldLabel: 'Paired/Unpaired',
            name: 'paired',
            submitValue: false,
            width: 225,
            triggerAction: 'all',
            mode: 'local',
            valueField: 'name',
            displayField: 'name',
            forceSelection: true,
            editable: false,
            lastQuery: '',
            allowBlank: false,
            store: new Ext.data.ArrayStore({
                fields: ['name'],
                data: [['paired'],['unpaired']],
            }),
            value: 'paired'
        };
        var other_params = clovr.makeDefaultFieldsFromPipelineConfig(pipeline_config.fields,
            {'input.SHORT_PAIRED_TAG': 1,
            'input.SHORT_TAG': 1,
            'input.LONG_TAG': 1,
            'input.LONG_PAIRED_TAG': 1
            });
        var advanced_panel ={
            xtype: 'fieldset',
            title: 'Advanced',
            collapsible: true,
            listeners: {
                afterlayout: {
                    fn: function(set) {
                        set.collapse();
                    },
                    single: true
                }
            },
            items: other_params.advanced
        }

        params.push([read_len_combo,paired_end_combo,other_params.normal,advanced_panel,other_params.hidden]);
        var fieldset = new Ext.form.FieldSet({
            title: 'CLoVR Microbe Illumina Settings',
            items: params
        });
        var form = new Ext.FormPanel({
            items: [fieldset],
            anchor: '100%',
            labelWidth: 120,
            bodyStyle: 'padding: 5px',
            autoScroll: true,
            frame: true,
            buttonAlign: 'center',
        });
        return form;
    },
    create_fieldset_from_config: function(title, pipeline_config, custom_params) {
        var params = [];
        var other_params = clovr.makeDefaultFieldsFromPipelineConfig(pipeline_config.fields,
            custom_params);
        var advanced_panel ={
            xtype: 'fieldset',
            title: 'Advanced',
            collapsible: true,
            listeners: {
                afterlayout: {
                    fn: function(set) {
                        set.collapse();
                    },
                    single: true
                }
            },
            items: other_params.advanced
        }

        params.push([other_params.normal,advanced_panel,other_params.hidden]);
        var fieldset = new Ext.form.FieldSet({
            title: title,
            items: params
        });
        var form = new Ext.FormPanel({
            items: [fieldset],
            anchor: '100%',
            labelWidth: 120,
            bodyStyle: 'padding: 5px',
            autoScroll: true,
            frame: true,
            buttonAlign: 'center',
        });
        return form;
    }
});

Ext.reg('clovrmicrobepanel', clovr.ClovrMicrobePanel);
