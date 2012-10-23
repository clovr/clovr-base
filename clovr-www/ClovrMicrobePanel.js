/*
 * A panel that is used to configure/submit Clovr Microbe pipelines
 */

clovr.ClovrMicrobePanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {
        var wrapper_panel = this;

        wrapper_panel.INPUT_TYPE_TO_PIPELINE_NAME = {
            'nuc_fasta': {
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
        var seq_combo = clovr.tagSuperBoxSelect({
            id: 'superselect25',
            fieldLabel: 'Select Sequencing Dataset(s)',
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
            tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>Format: {[values["metadata.format_type"]]}</div></tpl>',
            afterload: function() {
//                wrapper_panel.filter_seq_tech();
//                wrapper_panel.load_pipeline_subform(config.pipelines);
            },
            filter: {
                fn: function(record) {
                    var re = /nuc_fasta|fastq|sff/i;
                    return re.test(record.data['metadata.format_type']);
                }
            },
            sort: [{field: 'name',direction: 'ASC'}],
            listeners: {
                beforeselect: {fn: wrapper_panel.beforeDatasetSelectionChange,
                               scope: wrapper_panel
                              },
                addItem: {fn: wrapper_panel.afterDatasetSelectionChange,
                          scope: wrapper_panel},
                removeItem: function(sbs,value,record) {
                    sbs.getStore().sort('name', 'ASC');
                    wrapper_panel.afterDatasetSelectionChange(sbs,value,record);
                }
            }
        });
        
        var annot_assembly_box = new Ext.form.Radio({
            boxLabel: 'Assembly only',
            inputValue: 'assembly',
            name: 'microbe_track',
            fieldLabel: '',
            labelSeparator: ''
        });
        
        var annot_both_box = new Ext.form.Radio({
            boxLabel: 'Assembly+Annotation',
            inputValue: 'assemblyannot',
            name: 'microbe_track',
        });
        var annot_annot_box = new Ext.form.Radio({
            boxLabel: 'Annotation only',
            inputValue: 'annot',
            name: 'microbe_track',
        });
        var track_select = new Ext.form.RadioGroup({
            fieldLabel: 'Select a CLoVR Microbe Track',
            columns: 1,
            width: 150,
            items: [
                annot_assembly_box,
                annot_both_box,
                annot_annot_box
            ],
            listeners: {
                change: function(group,checked) {
                      wrapper_panel.load_pipeline_subform(config.pipelines);
                }
            }
        });

        var track_fieldset = {
            xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'CLoVR Microbe Track',
            items: track_select
        };


        var credential_combo = clovr.credentialCombo({
            name: 'cluster.CLUSTER_CREDENTIAL',
            default_value: config.default_credential,
            hidden: config.hide_credential});
/*        var cluster_combo = clovr.clusterCombo({
            name: 'cluster.CLUSTER_NAME',
            default_value: config.default_cluster,
            hidden: config.hide_cluster
        });
        */
        var cluster_fieldset = {
            xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'CLoVR Credential Selection',
//            items: [credential_combo,cluster_combo]}
			items: [credential_combo]};        
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
//        form.seq_tech = sequencing_tech_combo;
        form.input_tag = seq_combo;
        form.track_select = track_select;
        form.track_select_radios = {
            'annot': annot_annot_box,
            'both': annot_both_box,
            'assembly': annot_assembly_box
        };
//        form.annot_yes = annot_yes_box;
        seq_fieldset.items = [seq_combo,upload_button];
        wrapper_panel.pipeline_configs = config.pipelines;

        var buttons = [
        	{text: 'Validate',
        	handler: function(b,e) {
                 var subform = wrapper_panel.subform.getForm();
                 var params = wrapper_panel.params_for_submission;
                 var form = wrapper_panel.form;

				//form.getForm().findField('cluster.CLUSTER_NAME').getValue();
                 var credential = form.getForm().findField('cluster.CLUSTER_CREDENTIAL').getValue();
                 var cluster_name = clovr.getClusterName({
                     protocol: 'clovr_microbe_',
                     credential: credential
                 });
                 
//                 subform.findField('pipeline.PIPELINE_NAME').setValue('clovr_microbe'+new Date().getTime());
                 Ext.apply(params,{'cluster.CLUSTER_NAME': cluster_name,
                                   'cluster.CLUSTER_CREDENTIAL': credential
                                  });
                 Ext.apply(params, subform.getValues());
            	 
            	 clovr.validatePipeline({
            	 	params: params
            	 });
            }
            },
            {text: 'Submit',
             handler: function(b,e) {
                 var subform = wrapper_panel.subform.getForm();
                 var params = wrapper_panel.params_for_submission;
                 var form = wrapper_panel.form;

				//form.getForm().findField('cluster.CLUSTER_NAME').getValue();
                 var credential = form.getForm().findField('cluster.CLUSTER_CREDENTIAL').getValue();
                 var cluster_name = clovr.getClusterName({
                     protocol: 'clovr_microbe_',
                     credential: credential
                 });
                 
//                 subform.findField('pipeline.PIPELINE_NAME').setValue('clovr_microbe'+new Date().getTime());
                 Ext.apply(params,{'cluster.CLUSTER_NAME': cluster_name,
                                   'cluster.CLUSTER_CREDENTIAL': credential
                                  });
                 Ext.apply(params, subform.getValues());
            	 
                 var wrappername = 'clovr_wrapper'+new Date().getTime();
                 Ext.Msg.show({
                     title: 'Submitting Pipeline',
                     msg: 'The search is being submitted.',
                     wait: true
                 });                 
                 clovr.runPipeline({
                     pipeline: 'clovr_wrapper',
                     wrappername: wrappername,
                     cluster: cluster_name,
                     params: params,
                     submitcallback: function(r) {
                         form.getForm().reset();
                         config.submitcallback(r);
                     }
                 });
                 
             }}
        ];
        form.add(seq_fieldset,track_fieldset,cluster_fieldset);
        clovr.ClovrMicrobePanel.superclass.constructor.call(this,{
            id: 'clovr_microbe',
            layout: 'anchor',
//            style:'padding: 10px 10px 10px 5px',
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
        var seq_tech = null; //this.form.seq_tech.value;
        var input_tags = this.form.input_tag.getValueEx2();
        var track = this.form.track_select.getValue();
        var form_name = ''
        var title = '';
        var ignores = {};
        var params = {};
        var needs_metadata =[];
        if(track) {
        input_tags.each(function(tag) {
            // First see if we have a 454 sff file.
            if(tag.data['metadata.format_type'] == 'sff') {
                if(input_tags.length > 1) {
                    Ext.Msg.show({
                        title: 'Oops!',
                        msg: 'Only 1 sff file can be used as input',
                        icon: Ext.MessageBox.ERROR
                        
                    });
//                    break;
                }
                else if(track.inputValue == 'annot') {
                    Ext.Msg.show({
                        title: 'Oops!',
                        msg: 'sff files must be assembled before annotation!',
                        icon: Ext.MessageBox.ERROR
                        
                    });
//                    break;
                }
                else if(track.inputValue == 'assembly') {
                    form_name = 'clovr_assembly_celera';
                    title = 'CLoVR Celera Assembler Settings';
                    ignores = {'input.INPUT_SFF_TAG': 1};
                    params['input.INPUT_SFF_TAG'] = tag.data.name;
                }
                else if(track.inputValue == 'assemblyannot') {
                    form_name = 'clovr_microbe_v2.0_454';
                    title = 'CLoVR Microbe 454 Assembly/Annotation Settings';
                    ignores = {'input.INPUT_SFF_TAG': 1};
                    params['input.INPUT_SFF_TAG'] = tag.data.name;
                }
            }
            else if(tag.data['metadata.format_type'].toLowerCase() == 'nuc_fasta' ||
                    tag.data['metadata.format_type'].toLowerCase() == 'fastq') {
                
                // Load the annotation only pipeline.
                if(track.inputValue == 'annot' &&
                   tag.data['metadata.format_type'].toLowerCase() == 'nuc_fasta') {
                    form_name = 'clovr_microbe_v2.0_annotation';
                    title = 'CLoVR Microbe Annotation Settings';
                    ignores = {'input.INPUT_FSA_TAG': 1};
                    
                    if(!params['input.INPUT_FSA_TAG']) {
                        params['input.INPUT_FSA_TAG'] = tag.data.name;
                    }
                    else {
                        params['input.INPUT_FSA_TAG'] += ','+ tag.data.name;
                    }
                }
                
                // Load the assembly only pipeline
                else if(track.inputValue == 'assembly') {
                    form_name = 'clovr_assembly_velvet';
                    title = 'CLoVR Velvet Assembler Settings';
                    ignores = {'input.SHORT_PAIRED_TAG': 1,
                               'input.LONG_PAIRED_TAG': 1,
                               'input.SHORT_TAG': 1,
                               'input.LONG_TAG': 1
                              };
                    params['input.SHORT_PAIRED_TAG'] = '';
                    params['input.LONG_PAIRED_TAG']='';
                    params['input.SHORT_TAG'] = '';
                    params['input.LONG_TAG'] = '';
                }

                // Load the Assembly+Annotation pipeline
                else if(track.inputValue == 'assemblyannot') {
                    form_name = 'clovr_microbe_v2.0_illumina';
                    title = 'CLoVR Microbe Velvet Assembler/Annotation Settings';
                    ignores = {'input.SHORT_PAIRED_TAG': 1,
                               'input.LONG_PAIRED_TAG': 1,
                               'input.SHORT_TAG': 1,
                               'input.LONG_TAG': 1
                              };
                    params['input.SHORT_PAIRED_TAG'] = '';
                    params['input.LONG_PAIRED_TAG']='';
                    params['input.SHORT_TAG'] = '';
                    params['input.LONG_TAG'] = '';
                }
                
                // We have an assembled genome and can only do annotation
                if(tag.data['metadata.dataset_type'] =='genome_assembly') {
                }
                else if(tag.json.metadata.read_length && tag.json.metadata.read_type) {
                    if(tag.json.metadata.read_length =='short') {
                        if(tag.json.metadata.read_type == 'paired') {
                            if(params['input.SHORT_PAIRED_TAG'] == '') {
                                params['input.SHORT_PAIRED_TAG'] = tag.data.name;
                            }
                            else {
                                params['input.SHORT_PAIRED_TAG'] += ','+tag.data.name;
                            }
                        }
                        else {
                            if(params['input.SHORT_TAG'] == '') {
                                params['input.SHORT_TAG'] =  tag.data.name;
                            }
                            else {
                                params['input.SHORT_TAG'] += ','+tag.data.name;
                            }
                        }
                    }
                    else {
                        if(tag.json.metadata.read_type == 'paired') {
                            if(params['input.LONG_PAIRED_TAG'] == '') {
                                params['input.LONG_PAIRED_TAG'] = tag.data.name;
                            }
                            else {
                                params['input.LONG_PAIRED_TAG'] += ','+tag.data.name;
                            }
                        }
                        else {
                            if(params['input.LONG_TAG'] == '') {
                                params['input.LONG_TAG'] = tag.data.name;
                            }
                            else {
                                params['input.LONG_TAG'] += ','+tag.data.name;
                            }
                        }
                    }
                }
                else if(track.inputValue != 'annot') {
                    // We'll have to prompt for metadata
                    needs_metadata.push(tag);
                }
            }
        
        });
        }
        // If there are datasets that are lacking the requiered metadata 
        // then we'll go in here and prompt for it.
        if(needs_metadata.length > 0) {
            this.showIlluminaMetadataWindow(needs_metadata);
        }
        else {
            this.params_for_submission = params;
            for(form in this.subforms) {
                if(form != form_name && this.subforms[form].isVisible) {
                    this.subforms[form].hide();
                }
            }
            
            if(form_name != '' && !this.subforms[form_name]) {
                this.subforms[form_name] = this.create_fieldset_from_config(title,pipelines[form_name],ignores);
                this.add(this.subforms[form_name]);
            }
            
            if(this.subforms[form_name]) {
			    this.subform = this.subforms[form_name];
                this.subforms[form_name].show();
                this.doLayout();
            }
        }
    },

    // Called before the selection change is made
    beforeDatasetSelectionChange: function(combo,rec,index) {
        var selected = combo.getValueEx2();
        var types_selected = {};
        var select_radios = this.form.track_select_radios;
        var ret_val = true;
        selected.each(function(ds) {
            types_selected[ds.data['metadata.format_type']] = 1;
        });
        
        if(rec.data['metadata.format_type'] =='sff') {
            combo.clearValue();
            ret_val = true;
            types_selected = [];
        }
        else if(types_selected['sff']) {
            combo.clearValue();
            ret_val = true;
            types_selected = [];
        }

        // Now do what you would do assuming the selection goes through.
        types_selected[rec.data['metadata.format_type']]=1;
        
        if(types_selected['sff'] || types_selected['fastq']) {
            var annot_select = select_radios.annot;
            
            // Unselect the annotation only track
            if(annot_select.getValue()) {
                annot_select.setValue(false);
            }
            annot_select.disable();
        }
        else {
            select_radios.annot.enable();
        }

        // Check and see if a track has already been selected.
        var selected_track = this.form.track_select.getValue();
        if(selected_track) {
            this.load_pipeline_subform(this.pipeline_configs);
        }
        
        return ret_val;
    },
    afterDatasetSelectionChange: function(combo,val,rec) {

        var selected = combo.getValueEx2();
        var types_selected = {};
        var select_radios = this.form.track_select_radios;
        var ret_val = true;
        selected.each(function(ds) {
            types_selected[ds.data['metadata.format_type']] = 1;
        });

        if(types_selected['sff'] || types_selected['fastq']) {
            var annot_select = select_radios.annot;
            
            // Unselect the annotation only track
            if(annot_select.getValue()) {
                annot_select.setValue(false);
            }
            annot_select.disable();
        }
        else {
            select_radios.annot.enable();
        }

        // Check and see if a track has already been selected.
        var selected_track = this.form.track_select.getValue();
        if(selected_track) {
            this.load_pipeline_subform(this.pipeline_configs);
        }
        
        return ret_val;
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
            'input.LONG_PAIRED_TAG': 1,
            'cluster.CLUSTER_CREDENTIAL': 1,
            'cluster.CLUSTER_NAME': 1
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

        Ext.apply(custom_params,{'cluster.CLUSTER_CREDENTIAL': 1,'cluster.CLUSTER_NAME': 1})
        var other_params = clovr.makeDefaultFieldsFromPipelineConfig(pipeline_config,
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
    },

    showIlluminaMetadataWindow: function(records) {
        var forms =[];
        var panel = this;
        var selected_datasets = []
        Ext.each(records, function(rec,i,recs) {
			selected_datasets.push(rec.data.name);
            var formitems = [
                {xtype: 'textfield',
                 name: 'tag-name',
                 value: rec.data.name,
                 hidden: true
                },
                {xtype: 'textfield',
                 name: 'tag_base_dir',
                 value: rec.data['metadata.tag_base_dir'],
                 hidden: true
                }
            ];

            if(!rec.data['metadata.read_length']) {
                formitems.push({
                    xtype: 'radiogroup',
                    fieldLabel: 'Read Length',
                    items: [
                        {boxLabel: 'Short (e.g. Illumina)',
                         name: 'read_length',
                         inputValue: 'short'
                        },
                        {boxLabel: 'Long (e.g. Sanger, 454)',
                         name: 'read_length',
                         inputValue: 'long'
                        }
                    ]
                });
            }
            if(!rec.data['metadata.read_type']) {
                formitems.push({
                    xtype: 'radiogroup',
                    fieldLabel: 'Read Type',
                    items: [
                        {boxLabel: 'Paired End',
                         name: 'read_type',
                         inputValue: 'paired'
                        },
                        {boxLabel: 'Single End',
                         name: 'read_type',
                         inputValue: 'single'
                        }
                    ]
                });
            }
            forms.push(
                new Ext.form.FormPanel({
                items: [
                    {xtype: 'fieldset',
                     title: 'Information for '+ rec.data.name,
                     items: formitems
                    }
                ]
                }));
        });

        var tag_task_list = [];
        var win = new Ext.Window({
            defaults: {frame: true},
            height: 300,
            width: 450,
            autoScroll: true,
            title: 'We need some additional information about your datasets',
            items: forms,
            buttonAlign: 'center',

            listeners: {
                close: function(p) {
                    panel.form.track_select.setValue([false,false,false]);
                }
            },
            buttons: [{
                text: 'Submit',
                handler: function() {
                    Ext.each(forms, function(form,i,fms) {
                        var values = form.getForm().getValues();
                        var metadata = {};
                        for (var field in values) {
                            if(field !='tag-name' && field != 'tag_base_dir') {
                                metadata[field] = values[field];
                            }
                        };
                        win.getEl().mask('Submitting Change');
                        clovr.tagData({
                            params: {
                            cluster: 'local',
                            files: [],
            			 	action: 'append',
				            recursive: true,
                            tag_name: values['tag-name'],
                            metadata: metadata
                        },
                            callback: function(r,o) {
                                var response = Ext.util.JSON.decode(r.responseText);
                                if(response.success) {
	                                tag_task_list.push(response.data.task_name);
    	                        }
    	                        else {
    	                        	Ext.Msg.show({
										title: 'Error Updating Tag',
								        width: 300,
										closable: false,
						                msg: response.data.msg,
						                icon: Ext.MessageBox.ERROR,
						                buttons: Ext.Msg.OK
									});
    	                        }
                            }
                        });
                    });

                    var task = {
                        run: function() {
                            // Check to make sure we've gotten back all of the tasks
                            if(tag_task_list.length != forms.length) {
                                return;
                            }
                            var new_task_list = [];
                            Ext.each(tag_task_list, function(task_name,i,tasks) {
                                var callback = function(r) {
                                    var response = Ext.util.JSON.decode(r.responseText);
                                    if(response.success =='true') {
                                        if(response.data.state == 'running') {
                                            new_task_list.push(task_name);
                                        }
                                    }
                                    else {
                                        // Do something for an error
                                    }
                                };
                                clovr.getTaskInfo(task_name, callback)
                            });
                            tag_task_list = new_task_list;
                            
                            if(tag_task_list.length ==0) {
                                Ext.TaskMgr.stop(task);
            					clovr.reloadTagStores({
            						callback: function() {
	                                	win.getEl().unmask();
    	                            	win.destroy();
    	                            	var records = panel.form.input_tag.getValueEx2();
    	                            	var rec_names = [];
    	                            	records.each(function(rec) {
    	                            		if(rec) {
	    	                            		rec_names.push(rec.data.name);
	    	                            	}
    	                            	});
    	                            	panel.form.input_tag.setValue(rec_names);
    	                            	panel.load_pipeline_subform(panel.pipeline_configs);
									}
								});
                            }
                        },
                        interval: 2000
                    };
                    Ext.TaskMgr.start(task);
                }
            }]
        });
        win.show();
    }
});

Ext.reg('clovrmicrobepanel', clovr.ClovrMicrobePanel);
