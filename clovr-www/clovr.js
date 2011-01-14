/*!
 * clovr.js
 * 
 * A collection of functions primarily used to interact with the
 * Vappio Webservices.
 * 
 * Author: David Riley
 * Institute for Genome Sciences
 */


// clovr namespace
Ext.namespace('clovr');

/**
 * Creates a window that can be used to upload a dataset.
 * @param {object} config A config object that supports the following params:
 *      seqcombo - a combobox whose value will be set with the uploaded dataset
 * 
 */
clovr.uploadFileWindow = function(config) {
    
    // A window to house the upload form
    var uploadWindow = new Ext.Window({
        layout: 'fit',
        width: 400,
        height: 300,
        closeAction: 'hide',
        title: 'Upload File'
    });
    
    // A form for the upload
    var uploadForm = new Ext.form.FormPanel({
        fileUpload: true,
        url: '/vappio/uploadFile_ws.py',
        frame: true,
        items: [
            {xtype: 'fileuploadfield',
             width: 200,
             fieldLabel: 'Upload File',
             name: 'file',
             listeners: {
                 change: function(field, newval, oldval) {
                     if(newval) {
                         //clovrform.changeInputDataSet(field);
                     }
                 }
             }
            },
            
            // Combobox for type.
            {xtype: 'combo',
             name: 'inputfiletype',
             fieldLabel: 'File Type',
             submitValue: false,
             mode: 'local',
             autoSelect: true,
             editable: false,
             forceSelection: true,
             value: 'aa_FASTA',
             triggerAction: 'all',
             store: new Ext.data.ArrayStore({
                 fields:['id','name'],
                 data: [['aa_FASTA','Protein FASTA'],['nuc_FASTA', 'Nucleotide FASTA'],
                 ['sff','SFF'],['fastq','FASTQ']]
             }),
             valueField: 'id',
             displayField: 'name'
            },
            {xtype: 'textfield',
             name: 'uploadfilename',
             vtype: 'alphanum',
             fieldLabel: "Name your dataset<br/>(No spaces or '-')",
             submitValue: false
            },
            {xtype: 'textarea',
             width: 200,
             name: 'uploadfiledesc',
             maskRe: /[^\'\"]/,
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
                                         'description': values.uploadfiledesc,
                                         'format_type': values.inputfiletype
                                     },
                                     'tag_base_dir': path
                                 })
                             },
                             success: function(r,o) {
                                     Ext.Msg.show({
                                         title: 'Tagging Data...',
                                         width: 200,
                                         mask: true,
                                         closable: false,
                                         wait: true,
                                         progressText : 'Tagging Data'
                                     });
                                 uploadForm.getForm().reset();
                                     clovr.checkTagTaskStatusToSetValue({
                                         uploadwindow: uploadWindow,
                                         seqcombo: config.seqcombo,
                                         tagname: values.uploadfilename,
                                         data: Ext.util.JSON.decode(r.responseText)
                                     });
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
                    Ext.Msg.show({
                    	title: 'Dataset Tagged Successfully',
                    	msg: 'Your dataset was uploaded successfully.',
                    	icon: Ext.Msg.INFO,
                    	buttons: Ext.Msg.OK
                    });
                    if(seqcombo) {
                        seqcombo.getStore().loadData([[config.tagname]],true);
                        seqcombo.setValue(config.tagname);
                    }
                    Ext.TaskMgr.stop(task);
                    uploadWindow.hide();
                    clovr.reloadTagStores();
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

/**
 * Retrieves information from task_ws.py
 * @param {String}   task_name    The name of the task 
 * @param {Function} callback     A function to call with the response data.
 */
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
        baseParams: {request: Ext.util.JSON.encode({'name': 'local'})},
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

// Generates a combobox for tags. Takes a config which can have
// cluster config options as well as a filter and sort parameter.
clovr.tagCombo = function(config) {
    var combo;
    var store = new Ext.data.JsonStore({
        fields: [{name: 'name', mapping: 'name'},
                 {name: 'metadata.format_type', mapping: ('[\"metadata.format_type"\]')}],
        autoLoad: false,
        listeners: {
            load: function(store, records, o) {
                if(config.filter) {
                    store.filter(config.filter);
                }
                combo.setValue(store.getAt(0).data.name);
                if(config.afterload) {
                    config.afterload();
                }
            }
        }
    });
    clovr.tagStores.push(store);
    config.store = store;
    combo = new Ext.form.ComboBox(config);
    clovr.getDatasetInfo({
        callback: function(json) {
            combo.getStore().loadData(json.data)
        }
    });
    return combo;
}
                                       

// Pulls data from clusterInfo_ws.py
clovr.getClusterInfo = function(config) {
    Ext.Ajax.request({
        url: '/vappio/clusterInfo_ws.py',
        params: {request: Ext.util.JSON.encode({name: config.cluster_name})},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            config.callback(rjson);
        }
    });
}

// Pulls info about a particular dataset
clovr.getDatasetInfo = function(config) {
    var params = {
        name: 'local'
    };
    if(config.dataset_name) {
        params.tag_name = config.dataset_name;
    }
    Ext.Ajax.request({
        url: '/vappio/queryTag_ws.py',
        params: {
            request: Ext.util.JSON.encode(params)},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            config.callback(rjson);
        }
    });
}

clovr.getPipelineInfo = function(config) {
    Ext.Ajax.request({
        url: '/vappio/pipelineStatus_ws.py',
        params: {request: Ext.util.JSON.encode({name: 'local', pipelines:[]})},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            config.callback(rjson);
        }

    });
}

clovr.PIPELINE_TO_PROTOCOL = 
    {
        'clovr_metagenomics_noorf': 'clovr_metagenomics',
        'clovr_metagenomics_orf': 'clovr_metagenomics',
        'clovr_metatranscriptomics': 'clovr_metagenomics',
        'clovr_total_metagenomics': 'clovr_metagenomics',
        'clovr_16S': 'clovr_16s',
        'clovr_search': 'clovr_search',
        'clovr_search_webfrontend': 'clovr_search',
        'clovr_microbe_annotation': 'clovr_microbe',
        'clovr_microbe454': 'clovr_microbe',
        'clovr_microbe_illumina' : 'clovr_microbe'
    };

clovr.getPipelineToProtocol = function(name) {
    return clovr.PIPELINE_TO_PROTOCOL[name];
}

clovr.getProtocols = function() {
    var protocols = {};
    for(key in clovr.PIPELINE_TO_PROTOCOL) {
        protocols[clovr.PIPELINE_TO_PROTOCOL[key]] = 1;
    }
    var keys = [];
    for (var p in protocols)keys.push(p);
    return keys;
}

clovr.getPipelineFromPipelineList = function(pipename, pipelines) {
    var retpipe;
    for(var pipe in pipelines) {
        if(pipe == pipename) {
            retpipe = pipelines[pipe];
            break;
        }
    }
    return retpipe;
}

// Takes the fields from a clovr pipeline config and makes default textfields.
clovr.makeDefaultFieldsFromPipelineConfig = function(fields,ignore_fields,prefix) {

    var advanced_params = [];
    var hidden_params = [];
    var normal_params = [];
    if(!prefix) prefix = '';

    // Go through the configuration and create the form fields.
    Ext.each(fields, function(field, i, fields) {
        var dname = field.display ? field.display : field.field;
        var choices;
        var field_config = {};
        if(field.choices) {
            choices = [];
            Ext.each(field.choices, function(choice) {
                choices.push([choice]);
            });
            field_config = {
                xtype: 'combo',
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
                    data: choices
                }),
                value: field['default'],
                fieldLabel: dname,
                name: prefix + field.field
                //field.desc
            };
            if(field.desc) {
                field_config.plugins = ['fieldtip'];
                field_config.qtip=field.desc;
                field_config.qanchor='left';
            }
        }
        else {
            field_config = {
                xtype: 'textfield',
                fieldLabel: dname,
                name: prefix + field.field,
                value: field['default'],
            };
            if(field.desc) {
                field_config.plugins = ['fieldtip'];
                field_config.qtip=field.desc;
                field_config.qanchor='left';
            }
        }
        if(field.visibility == 'default_hidden') {
            field_config.disabled=false;
            advanced_params.push(field_config)
        }
        else if(!ignore_fields[field.field]) {
            if(field.visibility == 'always_hidden') {
                field_config.hidden=true;
                field_config.hideLabel=true;
                hidden_params.push(field_config);
            }
            else {
                normal_params.push(field_config);
            }
        }
    });
    return {'normal': normal_params,
            'advanced': advanced_params,
            'hidden': hidden_params};
}

clovr.runPipeline = function(config) {
    Ext.Ajax.request({
        url: '/vappio/runPipeline_ws.py',
        params: {
            'request': Ext.util.JSON.encode(
                {'pipeline_config': config.params,
                 'pipeline': config.pipeline,
                 'name': config.cluster,
                 'pipeline_name': config.wrappername
                })
        },
        success: function(response) {
            var r = Ext.util.JSON.decode(response.responseText);
            if(!r.success) {
                Ext.Msg.show({
                    title: 'Pipeline Submission Failed!',
                    msg: r.data.msg,
                    icon: Ext.MessageBox.ERROR
                });
            }
            else {
                Ext.Msg.show({
                    title: 'Success!',
                    msg: 'Your pipeline was submitted successfully',
                    buttons: Ext.Msg.OK
                });
            }
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
        },
        failure: function(response) {
            Ext.Msg.show({
                title: 'Server Error',
                msg: response.responseText,
                icon: Ext.MessageBox.ERROR});
        }
    });
}

clovr.tagStores = [];
clovr.reloadTagStores = function() {
    clovr.getDatasetInfo({
        callback: function(data) {
            Ext.each(clovr.tagStores, function(store,i,stores) {
                if(store.url) {
                    store.reload();
                }
                else {
                    store.loadData(data.data);
                }
            });
        }     
    });
}    
// clearly, this is a work in progress...
