/*
 * A panel that is used to configure/submit Clovr Metagenomics Pipelines
 */

clovr.ClovrMetaPanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {
        var wrapper_panel = this;

        var form = new Ext.FormPanel({
            id: 'clovr_meta_form',
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
            }
        });

        var orf_box = new Ext.form.Radio({
            boxLabel: 'Metagenomics with ORFs',
            inputValue: 'orf',
            name: 'metagenomics_track',
        });
        
        var noorf_box = new Ext.form.Radio({
            boxLabel: 'Metagenomics without ORFs',
            inputValue: 'noorf',
            name: 'metagenomics_track',
        });
        var track_select = new Ext.form.RadioGroup({
            fieldLabel: 'Select a CLoVR Metagenomics Track',
            columns: 1,
            width: 175,
            items: [
                orf_box,
                noorf_box
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
            title: 'CLoVR Metagenomics Track',
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
        });*/
        var cluster_fieldset = {
            xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'CLoVR Cluster Selection',
            items: [credential_combo]};//,cluster_combo]}
        

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

        form.track_select = track_select;
        form.track_select_radios = {
            'orf': orf_box,
            'noorf': noorf_box
        };
        form.input_tag = seq_combo;
        seq_fieldset.items = [seq_combo,upload_button];
        wrapper_panel.pipeline_configs = config.pipelines;

        var buttons = [
            {text: 'Submit',
             handler: function(b,e) {
                 var subform = wrapper_panel.subform.getForm();
                 var form = wrapper_panel.form;
                 var params = wrapper_panel.params_for_submission;
            	 var pipename = 'clovr_metagenomics'+new Date().getTime();
                 subform.findField('pipeline.PIPELINE_NAME').setValue(pipename);
                 var wrappername = 'clovr_wrapper'+new Date().getTime();
//                 var cluster_name = form.getForm().findField('cluster.CLUSTER_NAME').getValue();
                 var cluster_name = 'clovr_microbe_' + credential + '_' + new Date().getTime();
                 var credential = form.getForm().findField('cluster.CLUSTER_CREDENTIAL').getValue();
                 Ext.apply(params,{'cluster.CLUSTER_NAME': cluster_name,
                                   'cluster.CLUSTER_CREDENTIAL': credential
                                  });
                 Ext.apply(params,subform.getValues());
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
        form.add(seq_fieldset,track_fieldset,cluster_fieldset);
        clovr.ClovrMetaPanel.superclass.constructor.call(this,{
            id: 'clovr_metagenomics',
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

        
        var win = new Ext.Window({
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
                    panel.form.track_select.setValue([false,false]);
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
                                    seqcombo: tagcombo,
                                    uploadwindow: win,
                                    tagname: record.data.name,
                                    data: Ext.util.JSON.decode(r.responseText)
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
        if(!this.subforms) {
            this.subforms = {};
        }
        var input_tag = this.form.input_tag.value;
        var input_tag_store = this.form.input_tag.store;
        var input_tag_rec = input_tag_store.getAt(input_tag_store.find('name',input_tag));
        var track = this.form.track_select.getValue();
        var title ='';
        var form_name = '';
        var ignores = {};
        var params = {};

        if(track) {

            if(track.inputValue == 'orf') {
                title = 'CLoVR Metagenomics with ORFs Settings';
                form_name = 'clovr_metagenomics_orfs';
                ignores = {'cluster.CLUSTER_NAME': 1,
                           'cluster.CLUSTER_CREDENTIAL':1,
                           'input.FASTA_TAG': 1,
                           'input.MAPPING_TAG': 1
                          };
            }
            else if(track.inputValue =='noorf') {
                title = 'CLoVR Metagenomics without ORFs Settings',
                form_name = 'clovr_metagenomics_noorfs';
                ignores = {'cluster.CLUSTER_NAME': 1,
                           'cluster.CLUSTER_CREDENTIAL':1,
                           'input.FASTA_TAG': 1,
                           'input.MAPPING_TAG': 1
                          };
            }
            if(!input_tag_rec.data['metadata.metagenomics_mapping_file']) {
                this.showMappingFileWindow(input_tag_rec);
            }
            else {
                params = {
                    'input.FASTA_TAG': input_tag,
                    'input.MAPPING_TAG': input_tag_rec.data['metadata.metagenomics_mapping_file']
                };
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

Ext.reg('clovrmetapanel', clovr.ClovrMetaPanel);
