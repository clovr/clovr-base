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
    
    var uploadForm = new Ext.form.FormPanel({
        fileUpload: true,
        url: '/vappio/uploadFile_ws.py',
        frame: true,
        items: [
            {xtype: 'fileuploadfield',
             width: 200,
             fieldLabel: 'Or, Upload Fasta File',
             vtype: 'alphanum',
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
                                     'compress': false,
                                     'tag_name': values.uploadfilename,
                                     'tag_metadata': {
                                         'description': values.uploadfiledesc
                                     },
                                     'tag_base_dir': path
                                 })
                             },
                             success: function(r,o) {
                                 if(config.store) {
                                     config.store.reload();
                                 }
                                 uploadWindow.close();
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
    uploadWindow.show();
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
        fieldName: 'cluster.CREDENTIAL_NAME',
        store: store,
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
        triggerAction: 'all',
        displayField: 'name',
        fieldLabel: 'Cluster'
    }));
    return combo;
}
// clearly, this is a work in progress...
