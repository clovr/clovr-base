/*
 * A form panel that is used to submit a blast job
 */

clovr.BlastClovrFormPanel = Ext.extend(Ext.FormPanel, {

    constructor: function(config) {

        var clovrform = this;

        config.labelWidth = 120;
        config.bodyStyle= 'padding: 5px';
        config.autoScroll=true;
        config.frame=true;
        var customParams = {
            'misc.PROGRAM': 1,
            'input.REF_DB_TAG': 1,
            'input.INPUT_TAG': 1,
            'cluster.CLUSTER_NAME':1,
            'cluster.CLUSTER_CREDENTIAL':1
        };

        var programStore = new Ext.data.ArrayStore({
            fields: ["program"],
            data: [["blastn"],
                   ["blastp"],
                   ["tblastn"],
                   ["blastx"]
                  ]});

        
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
            tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>Format: {[values["metadata.format_type"]]}</div></tpl>',
            filter: {
                fn: function(record) {
                    var re = /_blastdb/;
                    return re.test(record.data['metadata.format_type']);
                }
            }
        });

        var advanced_params =[];
        var hidden_params = [];
        var normal_params = [];
        Ext.each(config.fields, function(field, i, fields) {
            var dname = field.display ? field.display : field.field;
            
            if(field.visibility == 'default_hidden') {
                advanced_params.push({xtype: 'textfield',
                                      fieldLabel: dname,
                                      name: field.field,
                                      value: field['default'],
                                      disabled: false,
                                      toolTip: field.desc});
            }
            else if(!customParams[field.field]) {
                if(field.visibility == 'always_hidden') {
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

        var seq_inputs = [];

        var seq_fieldset = {xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'Select Query Sequence',
            items: []};
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
            clovrform.seqCombo = datasetSelect;
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
                                    clovrform.getForm().setValues([{id: 'datasettag', value: tags}]);
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
                              clovrform.resetInputData({'field': field,
                                                            value: newval});
                          }
                      }
                  }
                 }];
            }
            clovrform.seqCombo = clovr.tagCombo(
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
                    tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>Format: {[values["metadata.format_type"]]}</div></tpl>',
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
                [clovrform.seqCombo];
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
            seqcombo: clovrform.seqCombo
        });
        clovrform.uploadWindow = uploadWindow;
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
        var cred_conf = {
            
        };
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

        seq_inputs.push(normal_params);
        
        seq_inputs.push(
            {xtype: 'fieldset',
             title: 'Advanced',
//             collapsed: true,
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
            }
        );
        seq_inputs.push(hidden_params);
        config.buttons = [
            {text: 'Submit',
             handler: function(b,e) {
//                 console.log(clovrform.getForm().items);
                 var form = clovrform.getForm();
//                 if(Ext.getCmp('pastedseq').getValue()) {
                    
//                 }
                 if(Ext.getCmp('datasettag').getValue()) {
                     form.setValues([{id: 'input.INPUT_TAG', value: Ext.getCmp('datasettag').getValue()}]);
                 }
//                 if(Ext.getCmp('uploadfilepath').getValue()) {
//                     console.log('uploadedfile');
//                 }
                 
                 var pipename = 'clovr_search'+new Date().getTime();
                 var wrappername = 'clovr_wrapper'+new Date().getTime();
                 clovrform.getForm().setValues({"input.PIPELINE_NAME": pipename});
                 Ext.Msg.show({
                     title: 'Submitting Pipeline',
                     msg: 'The search is being submitted.',
                     wait: true
                 });
                 Ext.Ajax.request({
                     url: '/vappio/runPipeline_ws.py',
                     params: {
                         'request': Ext.util.JSON.encode(
                             {'pipeline_config':clovrform.getForm().getValues(),
                              'pipeline': 'clovr_wrapper',
                              'name': 'local',
                              'pipeline_name': wrappername
                             })
                     },
                     success: function(response) {
                         var r = Ext.util.JSON.decode(response.responseText);
//                         document.location.hash=Ext.urlEncode({
//                             'taskname': r.data,
//                             'pipename': pipename,
//                             'wrappername': wrappername
//                         });
                         
                         if(config.submitcallback) {
                             config.submitcallback(r);
                         }
                         else {
                             Ext.Msg.show({
                                 title: 'Success!',
                                 msg: 'Your pipeline was submitted successfully',
                                 buttons: Ext.Msg.OK
                             });
                         }
//                         window.location.assign(document.location+'#'+Ext.urlEncode({
//                             'taskname': r.data,
//                             'pipename': pipename,
//                             'wrappername': wrappername
//                         }));
//                         window.location.reload(true);
//                         Ext.Msg.show({
//                             title: 'Pipeline Submitted',
//                             msg: response.responseText
//                         })
                     },
                     failure: function(response) {
                         Ext.Msg.show({
                             title: 'Server Error',
                             msg: response.responseText,
                             icon: Ext.MessageBox.ERROR});
                     }
                 });
             }}
        ];
        config.buttonAlign = 'center';
        config.items = seq_inputs;
        clovr.BlastClovrFormPanel.superclass.constructor.call(this,config);
        this.doLayout();
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

Ext.reg('blastclovrformpanel', clovr.BlastClovrFormPanel);

