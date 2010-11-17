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
        var dbStore = new Ext.data.ArrayStore({
            fields: ['db_name'],
            data: [['ncbi-nr'],
                   ['ncbi-nt'],
                   ['Example_B_subtilis_168_Protein_DB']
                  ]
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
        var uploadForm = new Ext.form.FormPanel({
            fileUpload: true,
            url: '/vappio/uploadFile_ws.py',
            frame: true,
            labelWidth: 120,
            items: [
                {xtype: 'fileuploadfield',
                 width: 200,
                 fieldLabel: 'Or, Upload Fasta File',
                 id: 'uploadfilepath',
                 name: 'file',
                 listeners: {
                     change: function(field, newval, oldval) {
                         if(newval) {
                             clovrform.changeInputDataSet(field);
                         }
                     }
                 }
                },
                {xtype: 'combo',
                 id: 'inputfiletype',
                 fieldLabel: 'Sequence Type',
                 submitValue: false,
                 mode: 'local',
                 autoSelect: true,
                 editable: false,
                 forceSelection: true,
                 value: 'aa_FASTA',
                 triggerAction: 'all',
                 fieldLabel: 'Select a pre-made dataset',
                     store: new Ext.data.ArrayStore({
                         fields:['id','name'],
                         data: [['aa_FASTA','Protein'],['nuc_FASTA', 'Nucleotide']]
                     }),
                     valueField: 'id',
                     displayField: 'name'
                },
                 {xtype: 'textfield',
                  id: 'uploadfilename',
                  vtype: 'alphanum',
                  fieldLabel: "Name your dataset<br/>(No spaces or '-')",
                  submitValue: false
                 },
                 {xtype: 'textarea',
                  width: 200,
                  id: 'uploadfiledesc',
                  fieldLabel: 'Describe your dataset',
                  submitValue: false
                }
            ],
            buttons: [
                {text: 'Upload',
                 handler: function() {
                     uploadForm.getForm().submit({
                         waitMsg: 'Uploading File',
                         success: function(r,o) {
                             var path = '/mnt/user_data/';
                             var values = uploadForm.getForm().getFieldValues();
                             Ext.Ajax.request({
                                 url: '/vappio/tagData_ws.py',
                                 params: {
                                     'request':Ext.util.JSON.encode({
                                         'files': [path + values.file],
                                         'name': 'local',
                                         'expand': true,
                                         'recursive': false,
                                         'append': false,
                                         'overwrite': true,
                                         'compress': false,
                                         'tag_name': values.uploadfilename,
                                         'tag_metadata': {
                                             'description': values.uploadfiledesc
                                         },
                                         'tag_base_dir': path
                                     })
                                 },
                                 success: function(r,o) {
                                     if(config.sampleData) {
                                         clovrform.checkTagTaskStatusToSetValue(Ext.util.JSON.decode(r.responseText),values.uploadfilename);
                                     }
                                 },
                                 failure: function(r,o) {
                                 }
                                 });
                         },
                         failure: function(r,o) {
//                             console.log('crapppers');
//                             console.log(r.responseText);
                         }
                     })
                 }
                }
            ]

        });
        
        var uploadWindow = new Ext.Window({
            layout: 'fit',
            width: 400,
            height: 300,
            title: 'upload file',
            closeAction: 'hide',
            items: [uploadForm]
        });
        clovrform.uploadWindow = uploadWindow;
        
        
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
                displayField: 'name'
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
            seq_fieldset.items =[
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
                              clovrform.changeInputDataSet(field);
                          }
                      }
                  }
                 },
                 {xtype: 'button',
                  text: 'Upload File',
                  fieldLabel: 'Upload File',
                  handler: function() {
                      uploadWindow.show();
                  }
                 }];
        }
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
            {xtype: 'combo',
             fieldLabel: 'Database',
             width: 225,
             name: 'input.REF_DB_TAG',
             store: dbStore,
             triggerAction: 'all',
             mode: 'local',
             valueField: 'db_name',
             displayField: 'db_name',
             forceSelection: true,
             editable: false,
             value: 'Example_B_subtilis_168_Protein_DB'
            }]);
        normal_params.push(clovr.credentialCombo({
            name: 'cluster.CLUSTER_CREDENTIAL'
        }));
        normal_params.push(clovr.clusterCombo({
            name: 'cluster.CLUSTER_NAME'
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
                         window.location.assign(document.location+'#'+Ext.urlEncode({
                             'taskname': r.data,
                             'pipename': pipename,
                             'wrappername': wrappername
                         }));
                         window.location.reload(true);
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
             }},
            {text: 'Clear Form'
            }
        ];
        config.buttonAlign = 'center';
        config.items = seq_inputs;
        clovr.BlastClovrFormPanel.superclass.constructor.call(this,config);
        this.doLayout();
        },
    changeInputDataSet: function(field) {
        var datasetfields = [
            'datasettag',
//            'pastedseq',
            'uploadfilepath'];

        var form = this.getForm();
        Ext.each(datasetfields, function(f) {
            if(field.id != f) {
//                console.log(field);
                Ext.getCmp(f).reset();
//                form.setValues({id: f,value: null});
            }
        });
    },
    checkTagTaskStatusToSetValue: function(data,tagName) {
        var seqcombo = this.seqCombo;
        var uploadWindow = this.uploadWindow;
        if(this.seqCombo) {
            Ext.Msg.show({
                title: 'Tagging Data...',
                width: 200,
                mask: true,
                closable: false,
                wait: true,
                progressText : 'Tagging Data'
            });
            
            var task = {                
                run: function() {
                    Ext.Ajax.request({
                        url: '/vappio/task_ws.py',
                        params: {request: Ext.util.JSON.encode({'name': 'local','task_name': data.data})},
                        success: function(r,o) {
                            var rjson = Ext.util.JSON.decode(r.responseText);
                            var rdata = rjson.data[0];
                            if(rjson.success) {
                                if(rdata.state =="completed") {
                                    Ext.Msg.hide();
                                    seqcombo.getStore().loadData([[tagName]],true);
                                    seqcombo.setValue(tagName);
                                    Ext.TaskMgr.stop(task);
                                    uploadWindow.hide();
                                }
                                else if(rdata.state =="failed") {
                                }
                            }
                            else {
                            }
                        }
                    });
                },
                interval: 5000
            };
            Ext.TaskMgr.start(task);
        }
    }
});

Ext.reg('blastclovrformpanel', clovr.BlastClovrFormPanel);

