/*
 * A panel that is used to configure/submit Clovr 16s Pipelines
 */

clovr.Clovr16sPanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {
        var wrapper_panel = this;

        var form = new Ext.FormPanel({
            id: 'clovr_16s_form',
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
            tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>Format: {[values["metadata.format_type"]]}</div></tpl>',
            filter: {
                fn: function(record) {
                    var re = /nuc_fasta/i;
                    return re.test(record.data['metadata.format_type']);
                }
            },
            listeners: {
                select: function(combo,rec) {
                    wrapper_panel.load_pipeline_subform(config.pipelines);
                }
            },
            afterload: function() {
                seq_combo.fireEvent('select');
            }
        }); 
        
        var mapping_file_field = new Ext.form.TextField({
            emptyText: 'Select a mapping file',
            readOnly: true 
        });

        var mapping_file = new Ext.form.CompositeField({
            fieldLabel: 'CLoVR16s Mapping File',
            msgTarget: 'under',
            invalidClass: '',
            items: [
                mapping_file_field,
                {xtype: 'button',
                 text: 'Change',
                 handler: function() {
                     var input_tag = seq_combo.getValue();
                     var input_tag_store = seq_combo.store;
                     var input_tag_rec = input_tag_store.getAt(input_tag_store.find('name',input_tag));
                     wrapper_panel.showMappingFileWindow(input_tag_rec);
                 }
                }
            ]
        });

        var credential_combo = clovr.credentialCombo({
            name: 'cluster.CLUSTER_CREDENTIAL',
            default_value: config.default_credential,
            hidden: config.hide_credential});

        var credential_fieldset = {
            xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'CLoVR Credential Selection',
            items: [credential_combo]}

        var uploadWindow = clovr.uploadFileWindow({
            seqcombo: seq_combo,
            callback: function() {
                seq_combo.fireEvent('select');
            }
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

        form.input_tag = seq_combo;
        form.map_file = mapping_file_field;
        form.map_file_comp = mapping_file;
        seq_fieldset.items = [seq_combo,upload_button,mapping_file];
        form.add(seq_fieldset,credential_fieldset);
        var buttons = [
            {text: 'Submit',
             handler: function(b,e) {
                 var subform = wrapper_panel.subform.getForm();
                 var form = wrapper_panel.form;
                 var params = wrapper_panel.params_for_submission;
            	 var pipename = 'clovr_16s'+new Date().getTime();
                 subform.findField('pipeline.PIPELINE_NAME').setValue(pipename);
                 var wrappername = 'clovr_wrapper'+new Date().getTime();
//                 var cluster_name = form.getForm().findField('cluster.CLUSTER_NAME').getValue();
                 var credential = form.getForm().findField('cluster.CLUSTER_CREDENTIAL').getValue();
                 var cluster_name = clovr.getClusterName({
                     protocol: 'clovr_16s_',
                     credential: credential
                 });
                 Ext.apply(params,{'cluster.CLUSTER_NAME': cluster_name,
                                   'cluster.CLUSTER_CREDENTIAL': credential
                                  });
                 Ext.apply(params,subform.getValues());
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
                         config.submitcallback(r);
                     }
                 });
                 
            }}
        ];
        clovr.Clovr16sPanel.superclass.constructor.call(this,{
            id: 'clovr_16s',
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
    showMappingFileWindow: function(record) {
        var forms =[];
        var panel = this;
        var win;

        var tagcombo = clovr.tagCombo({
            //            id: 'datasettag',
            fieldLabel: 'Select a metagenomics map',
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
            //                tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>Format: {[values["metadata.format_type"]]}</div></tpl>',
            afterload: function() {
                //                wrapper_panel.load_pipeline_subform(config.pipelines);
            },
            filter: {
                fn: function(record) {
                    var re = /metagenomics_mapping_file/i;
                    return re.test(record.data['metadata.format_type']);
                }
            }
        });
        var uploadWindow = clovr.uploadFileWindow({
            seqcombo: tagcombo
        });
        var uploadButton = {
            xtype: 'button',
            text: 'Upload File',
            fieldLabel: 'Or, Upload File',
            handler: function() {
                uploadWindow.show();
            }};
        var seq_fieldset = {
            xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'Choose a mapping file for '+ record.data.name,
            items: [tagcombo,uploadButton]
        };
        var formitems = [
            seq_fieldset
        ];

        
        win = new Ext.Window({
            defaults: {frame: true},
            height: 300,
            width: 400,
            autoScroll: true,
            title: 'CLoVR metagenomics mapping selection',
            items: new Ext.form.FormPanel({
                items: formitems
            }),
            buttonAlign: 'center',
            listeners: {
                close: function(p) {
                    
                }
            },
            listeners: {
                close: function(p) {
                }
            },
            buttons: [{
                text: 'Submit',
                handler: function() {
                    var val = tagcombo.getValue();
                    if(!val) {
                        //do something
                    }
                    else {
                        clovr.tagData({
                            params: {
                                'files': [],
                                'name': 'local',
                                'expand': false,
            					'recursive': false,
            					'append': true,
				            	'overwrite': false,
				            	'compress': false,
                                'tag_name': record.data.name,
                                'tag_metadata': {
                                    'metagenomics_mapping_file': val
                                },
                                'tag_base_dir': record.data['metadata.tag_base_dir']
                            },
                            callback: function(r,o) {
                                Ext.Msg.show({
						            title: 'Tagging Data...',
				        	        width: 200,
					                mask: true,
				    	            closable: false,
				        	        wait: true,
				            	    progressText : 'Tagging Data'
					            });
                                clovr.checkTagTaskStatusToSetValue({
                                    seqcombo: panel.form.input_tag,
                                    uploadwindow: win,
                                    tagname: record.data.name,
                                    data: Ext.util.JSON.decode(r.responseText),
                                    callback: function() {
                                        panel.form.input_tag.fireEvent('select');
                                    }
                                });
                            }
                        });
                    }
                }
                
            }]
        });
        win.show();
    },

    load_pipeline_subform: function(pipelines) {

        var input_tag = this.form.input_tag.value;
        var input_tag_store = this.form.input_tag.store;
        var input_tag_rec = input_tag_store.getAt(input_tag_store.find('name',input_tag));        
        var map_file = this.form.map_file;
        if(input_tag_rec && input_tag_rec.data['metadata.metagenomics_mapping_file']) {
            this.form.map_file_comp.clearInvalid();
            map_file.setValue(input_tag_rec.data['metadata.metagenomics_mapping_file']);
            if(!this.subform) {
                this.params_for_submission = {
                    'input.FASTA_TAG': input_tag,
                    'input.MAPPING_TAG': input_tag_rec.data['metadata.metagenomics_mapping_file']
                };
                this.subform = this.create_fieldset_from_config(
                    'CLoVR 16s Configuration',
                    pipelines['clovr_16S'],
                    {'input.FASTA_TAG': 1,
                     'input.MAPPING_TAG': 1,
                     'cluster.CLUSTER_NAME':1,
                     'cluster.CLUSTER_CREDENTIAL': 1
                    });
                this.add(this.subform);
            }
            this.subform.show();
            this.doLayout();
        }
        else {
            map_file.setValue();
            this.form.map_file_comp.markInvalid('You must specify a mapping file');
            if(this.subform) {
                this.subform.hide();
            }
            
        }

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

Ext.reg('clovr16spanel', clovr.Clovr16sPanel);
