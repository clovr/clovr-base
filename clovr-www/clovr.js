// clovr namespace
Ext.namespace('clovr');

clovr.uploadFileWindow = function(config) {
    
    // A window to house the upload form
    var uploadWindow = new Ext.Window({
        layout: 'fit',
        width: 400,
        height: 300,
        title: 'Upload File'
    });
    
    // A form to for the upload
    var uploadForm = new Ext.form.FormPanel({
        fileUpload: true,
        url: '/vappio/uploadFile_ws.py',
        frame: true,
        items: [
            {xtype: 'fileuploadfield',
             width: 200,
             fieldLabel: 'Or, Upload Fasta File',
//             vtype: 'alphanum',
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
            
            // Combobox for type.
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
//                                 if(config.sampleData) {
                                     Ext.Msg.show({
                                         title: 'Tagging Data...',
                                         width: 200,
                                         mask: true,
                                         closable: false,
                                         wait: true,
                                         progressText : 'Tagging Data'
                                     });
                                     clovr.checkTagTaskStatusToSetValue({
                                         uploadwindow: uploadWindow,
                                         seqcombo: config.seqcombo,
                                         tagname: values.uploadfilename,
//                                         callback: config.callback,
                                         data: Ext.util.JSON.decode(r.responseText)
                                     });
//                                 }
                             },
                             failure: function(r,o) {
                             }
                         });
                     },
                     failure: function(r,o) {
                     }
                 })
             }
            }
        ]
        
    });
    uploadWindow.add(uploadForm);
    return uploadWindow;
}

// Function to Monitor the status of a tag and set a 
// particular field value. 
clovr.checkTagTaskStatusToSetValue = function(config) {
    var uploadWindow = config.uploadwindow;
    var seqcombo = config.seqcombo;

    var task = {                
        run: function() {
            var callback = function(r) {
                var rjson = Ext.util.JSON.decode(r.responseText);
                var rdata = rjson.data[0];
                if(rdata.state =="completed") {
                    Ext.Msg.hide();
                    seqcombo.getStore().loadData([[config.tagname]],true);
                    seqcombo.setValue(config.tagname);
                    Ext.TaskMgr.stop(task);
                    uploadWindow.hide();
                }
                else if(rdata.state =="failed") {
                }
            };
            clovr.getTaskInfo(config.data.data,callback);
        },
        interval: 5000
    };
    Ext.TaskMgr.start(task);
}

// getTaskInfo:
// Get's information from task_ws.py
clovr.getTaskInfo = function(task_name,callback) {
    Ext.Ajax.request({
        url: '/vappio/task_ws.py',
        params: {request: Ext.util.JSON.encode({'name': 'local','task_name': task_name})},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            var rdata = rjson.data[0];
            callback(r);
        }
    });
}

// getPipelineStatus: 
// Takes the name of the pipeline and calls a callback function
// with the results.
clovr.getPipelineStatus = function(config) {

    Ext.Ajax.request({
        url: '/vappio/pipelineStatus_ws.py',
        params: {request: 
                 Ext.util.JSON.encode(
                     {'name': config.cluster_name,
                      'pipelines': [config.pipe_name]
                     })},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            var rdata = rjson.data[0][1];
            config.callback(rdata);
        }
    });
}

// A combobox to select an available credential
clovr.credentialCombo = function(config) {
    var combo;
    var store = new Ext.data.JsonStore({
        fields: [
            {name: "name"},
            {name: "desc"},
            {name: "ctype"},
            {name: "active"}
            ],
        root: function(data) {
            return data.data;
        },
        url: "/vappio/credential_ws.py",
        baseParams: {request: Ext.util.JSON.encode({name: 'local'})},
        autoLoad: true,
        listeners: {
            load: function(store,records,o) {
                if(!config.default_value) {
                    combo.setValue(records[0].data.name);
                }
                else {
                    combo.setValue(config.default_value);
                }
            },
            loadexceptions: function() {
            }
        }
    });    
    combo = new Ext.form.ComboBox(Ext.apply(config, {
        valueField: 'name',
        store: store,
        mode: 'local',
        triggerAction: 'all',
        displayField: 'name',
        fieldLabel: 'Account'
    }));
    return combo;
}

// A combobox to select an available cluster
clovr.clusterCombo = function(config) {
    var combo;
    var store = new Ext.data.JsonStore({
        fields: [
            {name: "name"},
        ],
        root: function(data) {
            var jsonData = [];
            Ext.each(data.data, function(elm) {
                jsonData.push({"name": elm});
            });
            return jsonData;
        },
        url: "/vappio/listClusters_ws.py",
        autoLoad: true,
        listeners: {
            load: function(store,records,o) {
                if(!config.default_value) {
                    combo.setValue(records[0].data.name);
                }
                else {
                    combo.setValue(config.default_value);
                }
            },
            loadexceptions: function() {
            }
        }
    });
    
    combo = new Ext.form.ComboBox(Ext.apply(config,{
        valueField: 'name',
        store: store,
        mode: 'local',
        triggerAction: 'all',
        displayField: 'name',
        fieldLabel: 'Cluster'
    }));
    return combo;
}

// clearly, this is a work in progress...
