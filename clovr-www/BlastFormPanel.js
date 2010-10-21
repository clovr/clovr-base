/*
 * A form panel that is used to submit a blast job
 */

clovr.BlastClovrFormPanel = Ext.extend(Ext.FormPanel, {

    constructor: function(config) {
        config.labelWidth = 120;
        config.bodyStyle= 'padding: 5px';
        config.autoScroll=true;
        config.frame=true;
        var customParams = {
            'misc.PROGRAM': 1,
            'input.REF_DB_TAG': 1,
            'input.INPUT_TAG': 1
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
                   ['ncbi-nt']
                  ]
        });
        var advanced_params =[];
        var hidden_params = [];

        Ext.each(config.fields, function(field, i, fields) {
            if(field.visibility == 'default_hidden' && field.display) {
                advanced_params.push({xtype: 'textfield',
                                      fieldLabel: field.display,
                                      name: field.field,
                                      value: field['default'],
                                      disabled: false,
                                      toolTip: field.desc});
            }
            else if(!customParams[field.field]) {
                hidden_params.push({xtype: 'textfield',
                                    fieldLabel: field.display,
                                    name: field.field,
                                    value: field['default'],
                                    hidden: true,
                                    hideLabel: true
                                   });
            }
        });

        var uploadForm = new Ext.form.FormPanel({
            fileUpload: true,
            url: '/vappio/uploadFile_ws.py',
            frame: true,
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
                {xtype: 'textfield',
                 id: 'uploadfilename',
                 fieldLabel: 'Name your dataset',
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
                                         'tag_name': values.uploadfilename,
                                         'tag_metadata': {
                                             'description': values.uploadfiledesc
                                         },
                                         'tag_base_dir': path
                                     })
                                 },
                                 success: function(r,o) {
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
            items: [uploadForm]
        });

        var clovrform = this;
        var seq_inputs = [
            {xtype: 'fieldset',
             hideMode: 'visibility',
             title: 'Query Sequence',
             items: [
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
//                          console.log('changed');
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
                 },
/*                 {xtype: 'textarea',
                  fieldLabel: 'Or, Paste Fasta Sequence',
                  id: 'pastedseq',
                  width: 200,
                  listeners: {
                      change: function(field, newval, oldval) {
                          if(newval) {
                              clovrform.changeInputDataSet(field);
                          }
                      }
                  }
             },

                 {xtype: 'textfield',
                  fieldLabel: 'Name',
                  id: 'sequencename'
                }*/
             ]},
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
             value: 'blastn'
            },
            {xtype: 'combo',
             fieldLabel: 'Database',
             width: 70,
             name: 'input.REF_DB_TAG',
             store: dbStore,
             triggerAction: 'all',
             mode: 'local',
             valueField: 'db_name',
             displayField: 'db_name',
             forceSelection: true,
             editable: false,
             value: 'ncbi-nt'
            },
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
        ];
        seq_inputs.push(hidden_params);
        config.buttons = [
            {text: 'Submit',
             handler: function(b,e) {
//                 console.log(clovrform.getForm().items);
                 var form = clovrform.getForm();
//                 if(Ext.getCmp('pastedseq').getValue()) {
                    
//                 }
                 if(Ext.getCmp('datasettag').getValue()) {
                     form.setValues({id: 'input.INPUT_TAG', value: Ext.getCmp('datasettag').getValue()});
                 }
//                 if(Ext.getCmp('uploadfilepath').getValue()) {
//                     console.log('uploadedfile');
//                 }
                 
                 clovrform.getForm().setValues({"input.PIPELINE_NAME": 'clovr_search'+new Date().getTime()});
                 Ext.Ajax.request({
                     url: '/vappio/runPipeline_ws.py',
                     params: {
                         'request': Ext.util.JSON.encode(
                             {'pipeline_config':clovrform.getForm().getValues(),
                              'pipeline': 'clovr_wrapper',
                              'name': 'local',
                              'pipeline_name': 'clovr_wrapper'+new Date().getTime()
                             })
                     },
                     success: function(response) {
                         Ext.Msg.show({
                             title: 'Pipeline Submitted',
                             msg: response.responseText
                         })
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
    }
});

Ext.reg('blastclovrformpanel', clovr.BlastClovrFormPanel);

