/*
 * A panel that is used to submit a blast job.
 */

clovr.ClovrBlastPanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {

        var wrapper_panel = this;

        var blastform = new Ext.FormPanel({
            id: 'clovr_search_form',
            labelWidth: 120,
            bodyStyle: 'padding: 5px',
            autoScroll: true,
            frame: true,
            buttonAlign: 'center'
 
        });
        
        wrapper_panel.form = blastform;
        
        // Parameters that we'll be customizing.
        var customParams = {
            'misc.PROGRAM': 1,
            'input.REF_DB_TAG': 1,
            'input.INPUT_TAG': 1,
            'cluster.CLUSTER_NAME':1,
            'cluster.CLUSTER_CREDENTIAL':1
        };
        
        // Store for the different blast progs.
        var programStore = new Ext.data.ArrayStore({
            fields: ["program"],
            data: [["blastn"],
                   ["blastp"],
                   ["tblastn"],
                   ["blastx"]
                  ]});

        // Combobox for the blast database.
        var databaseCombo = clovr.tagCombo({
            fieldLabel: 'Database',
            width: 225,
            name: 'input.REF_DB_TAG',
            triggerAction: 'all',
            mode: 'local',
            valueField: 'name',
            displayField: 'name',
            forceSelection: true,
            editable: false,
            lastQuery: '',
            allowBlank: false,
            filter: {
                fn: function(record) {
                    var re = /_blastdb/;
                    return re.test(record.data['metadata.format_type']);
                }
            }
        });

        // Three different arrays to store the different form parameters types.
        var advanced_params =[];
        var hidden_params = [];
        var normal_params = [];

        // Pull the clovr_search info out.
        var pipeline = config.pipelines['clovr_search'];
        //clovr.getPipelineFromPipelineList( 'clovr_search',config.pipelines);
        
        // Go through the configuration and create the form fields.
        Ext.each(pipeline.fields, function(field, i, fields) {
            var dname = field.display ? field.display : field.field;
            if(!customParams[field.field]) {
                if(field.visibility == 'default_hidden') {
                    advanced_params.push({xtype: 'textfield',
                                          fieldLabel: dname,
                                          name: field.field,
                                          value: field['default'],
                                          disabled: false,
                                          toolTip: field.desc});
                }
                else if(field.visibility == 'always_hidden') {
                    hidden_params.push({xtype: 'textfield',
                                        fieldLabel: dname,
                                        name: field.field,
                                        value: field['default'],
                                        hidden: true,
                                        hideLabel: true
                                       });
                }
                else {
                    normal_params.push({xtype: 'textfield',
                                        fieldLabel: dname,
                                        name: field.field,
                                        value: field['default']
                                       });
                }
            }
        });

        // An array of input form elements for the sequence fieldset
        var seq_inputs = [];

        var seq_fieldset = {xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'Select Query Sequence',
            items: []};
        
        // If there is sample data that needs to be included we'll create the 
        // combobox with that info.
        if(config.sampleData) {
            var datasetSelect = new Ext.form.ComboBox({
                mode: 'local',
                autoSelect: true,
                editable: false,
                forceSelection: true,
                value: config.sampleData[0][0],
                id: 'datasettag',
                width: 250,
                submitValue: false,
                triggerAction: 'all',
                fieldLabel: 'Select a pre-made dataset',
                store: new Ext.data.ArrayStore({
                    fields:['name'],
                    data: config.sampleData
                }),
                valueField: 'name',
                displayField: 'name',

            });
            blastform.seqCombo = datasetSelect;
            var upload_button = {xtype: 'button',
                text: 'Upload File',
                fieldLabel: 'Or, Upload File',
                handler: function() {
                    uploadWindow.show();
                }};
            var input_field = {
                xtype: 'textfield',
                hidden: true,
                name: 'input.INPUT_TAG',
                id: 'input.INPUT_TAG',
                hideLabel: true
            };
            seq_fieldset.items = [datasetSelect,upload_button,input_field];
        }

        // If there is no sample data we'll use something else. Either a DnD or a 
        // combobox populated with filtered tags.
        else {

            var dd_area_items = [
                new Ext.Container({
                    fieldLabel: 'Select Data Set',
                    ddGroup: 'tagDDGroup',
                    html: "Drag Data Set Here",
                    cls: 'input_drag_area',
                    width: 200,
                    //                     id: 'datasettag',
                    listeners: {
                        render: function(container) {
                            var dropZone = new Ext.dd.DropTarget(container.el,{
                                ddGroup: 'tagDDGroup',
                                notifyEnter: function(s, e, d) {
                                    
                                    container.el.dom.style.backgroundColor = 'red';
                                    //                                    container.el.highlight();;
                                },
                                notifyOut: function(s, e, d) {
                                    container.el.dom.style.backgroundColor = '';
                                },
                                notifyDrop: function(s, e, d) {
                                   var tags = [];
                                    Ext.each(d.selections, function(row) {
                                        tags.push(row.data.name);
                                    });
                                    blastform.getForm().setValues([{id: 'datasettag', value: tags}]);
                                    container.update(tags.join(', '));
                                }
                            });
                        }}
                 }),
                 {xtype: 'textfield',
                  id: 'datasettag',
                  hidden: true,
                  listeners: {
                      change: function(field, newval, oldval) {
                          if(newval) {
                              blastform.resetInputData({'field': field,
                                                            value: newval});
                          }
                      }
                  }
                 }];
            }
            blastform.seqCombo = clovr.tagCombo(
                {
                    id: 'datasettag',
                    fieldLabel: 'Select Query Dataset',
                    width: 225,
                    name: 'input.INPUT_TAG',
                    triggerAction: 'all',
                    mode: 'local',
                    valueField: 'name',
                    displayField: 'name',
                    forceSelection: true,
                    editable: false,
                    lastQuery: '',
                        allowBlank: false,
                    filter: {
                        fn: function(record) {
                            var re = /fasta/i;
                            return re.test(record.data['metadata.format_type']);
                        }
                    }
                });
            var combo_items = 
                [blastform.seqCombo];
            seq_fieldset.items =[
                combo_items,
                 {xtype: 'button',
                  text: 'Upload File',
                  fieldLabel: 'Upload File',
                  handler: function() {
                      uploadWindow.show();
                  }
                 }];
        var uploadWindow = clovr.uploadFileWindow({
            seqcombo: blastform.seqCombo
        });
        blastform.uploadWindow = uploadWindow;
        seq_inputs.push([
                seq_fieldset,
            {xtype: 'combo',
             fieldLabel: 'BLAST Program',
             width: 70,
             name: 'misc.PROGRAM',
             store: programStore,
             triggerAction: 'all',
             mode: 'local',
             valueField: 'program',
             displayField: 'program',
             forceSelection: true,
             editable: false,
             value: 'blastp'
            },
            databaseCombo
        ]);
        
        // Add credential/cluster comboboxes.
        normal_params.push(clovr.credentialCombo({
            name: 'cluster.CLUSTER_CREDENTIAL',
            default_value: config.default_credential,
            hidden: config.hide_credential

        }));
        normal_params.push(clovr.clusterCombo({
            name: 'cluster.CLUSTER_NAME',
            default_value: config.default_cluster,
            hidden: config.hide_cluster
        }));
        
        // Add the hidden parameters to the sequence inputs.
        seq_inputs.push(normal_params);
        seq_inputs.push({
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
            items: advanced_params
        });
        seq_inputs.push(hidden_params);

        // Add buttons to the form.
        var buttons = [
            {text: 'Submit',
             handler: function(b,e) {
                 var form = wrapper_panel.form.getForm();
//                 if(Ext.getCmp('pastedseq').getValue()) {
                    
//                 }
                 if(wrapper_panel.form.seqCombo.getValue()) {
                     form.setValues([{id: 'input.INPUT_TAG', value: wrapper_panel.form.seqCombo.getValue()}]);
                 }
//                 if(Ext.getCmp('uploadfilepath').getValue()) {
//                     console.log('uploadedfile');
//                 }
                 
                 var pipename = 'clovr_search'+new Date().getTime();
                 var wrappername = 'clovr_wrapper'+new Date().getTime();
                 wrapper_panel.form.getForm().setValues({"input.PIPELINE_NAME": pipename});
                 Ext.Msg.show({
                     title: 'Submitting Pipeline',
                     msg: 'The search is being submitted.',
                     wait: true
                 });

                 var cluster_name = wrapper_panel.form.getForm().findField('cluster.CLUSTER_NAME');
                 clovr.runPipeline({
                     pipeline: 'clovr_wrapper',
                     wrappername: wrappername,
                     cluster: wrapper_panel.form.getForm().findField('cluster.CLUSTER_NAME').getValue(),
                     params: wrapper_panel.form.getForm().getValues(),
                     submitcallback: function(r) {
                         config.submitcallback(r);
                     }
                 });
             }}
        ];

        blastform.add(seq_inputs);
        blastform.addButton(buttons);
        clovr.ClovrBlastPanel.superclass.constructor.call(this,{
            id: 'clovr_search',
            layout: 'fit',
            items: blastform
        });
    },
    resetInputData: function(field) {
        var datasetfields = [
            'datasettag',
            //'pastedseq',
            'uploadfilepath'];
        Ext.each(datasetfields, function(f) {
            if(field.id != f) {
                Ext.getCmp(f).reset();
            }
        });
    },
    changeInputDataSet: function(conf) {
        if(conf.dataset_name) {
            Ext.getCmp('datasettag').setValue(conf.dataset_name);
        }
    },

});

Ext.reg('clovrblastpanel', clovr.ClovrBlastPanel);

