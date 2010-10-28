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

// clearly, this is a work in progress...
