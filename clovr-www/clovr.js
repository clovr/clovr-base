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

clovr.tagStores = [];
clovr.credStores = [];
clovr.requests = [];


// Used to add a credential
clovr.addCredentialWindow = function(config) {

    var subforms = [];
    
    var win = {};

    var configSet = {
        xtype: 'fieldset',
        title: 'Name Credential',
        items: [
            {xtype: 'textfield',
             fieldLabel: 'Credential Name',
             vtype: 'alphanum',
             name: 'credential_name'
            },
            {xtype: 'textarea',
             width: 200,
             fieldLabel: 'Credential Description',
             name: 'description'
            },
            {xtype: 'textfield',
             hidden: true,
             fieldLabel: 'cluster',
             name: 'cluster',
             value: 'local'
            }
        ]};
    
    var configPanel = new Ext.Panel({
        layout: 'form',
        frame: true,
//        hidden: true,
        items: [
            {xtype: 'fieldset',
             labelAlign: 'top',
             title: 'Upload Credential Files',
             name: 'uploads',
             id: 'uploads',
             items: [
                 new Ext.form.FormPanel({
                     fileUpload: true,
                     url: '/vappio/uploadCred_ws.py',
                     labelAlign: 'top',
                     id: 'cert_file',
                     items: [
                         {xtype: 'fileuploadfield',
                          width: 200,
                          fieldLabel: 'Upload Certificate File',
                          name: 'file'
                         }
                     ]
                 }),
                 new Ext.form.FormPanel({
                     fileUpload: true,
                     url: '/vappio/uploadCred_ws.py',
                     labelAlign: 'top',
                     id: 'pkey_file',
                     items: [
                         {xtype: 'fileuploadfield',
                          width: 200,
                          fieldLabel: 'Upload Key File',
                          name: 'file'
                         }
                     ]
                 })
             ]}
        ]
    });

    var ctypeGroup = new Ext.form.RadioGroup({
        columns: 1,
        items: [
            {name: 'ctype',
             boxLabel: 'IGS DIAG',
             inputValue: 'diag'
            },
            {name: 'ctype',
             boxLabel: 'Amazon ec2',
             inputValue: 'ec2'
            }
        ]
    });
                                            
    var formpanel = new Ext.form.FormPanel({
        frame: true,
        items: [
            {xtype: 'fieldset',
             title: 'Select a credential Type',
             labelWidth: 1,
             items: [
                 ctypeGroup,
             ]
            },
            configSet
        ]
    });

    

    win = new Ext.Window({
        width: 400,
        height: 400,
        autoScroll: true,
        title: 'Add Credential',
        buttons: [
            {text: 'Add Credential',
             handler: function() {
                 var ctype_panel = configPanel;
                         var form_container = ctype_panel.get("uploads");
                         var successful_returns = 0;
                         var total_returns = form_container.items.items.length;
                         var uploaded_files = [];
                         Ext.each(form_container.items.items, function(field) {
                             if(field.getXType() == 'form') {
                                 if(field.getForm().isDirty()) {
                                     var formname =  field.getId();
                                     win.getEl().mask('Uploading Credential Files');
                                     field.getForm().submit({
                                         success: function(r,o) {
											 win.getEl().mask('Adding Credential');
                                             successful_returns +=1;
                                             var json = Ext.decode(o.response.responseText);

                                             uploaded_files[formname] = json.data;
                                             // Add the returned file to the 
                                             if(successful_returns == total_returns) {
                                                 var params = formpanel.getForm().getValues();

                                                 Ext.apply(params,uploaded_files);
                                                 Ext.apply(params,{'metadata': {}});
                                                 // Adding the credential here
                                                 Ext.Ajax.request({
    	                                             url: '/vappio/credential_ws.py',
                                                     params: {
        	                                             'request':Ext.util.JSON.encode(params)
                                                     },
                                                     timeout: 120000,
                                                     success: function(r,o) {
                                                         win.getEl().unmask();
                                                         clovr.reloadCredStores({
                                                         	callback: function() {
                                                         		win.close();
                                                         	}
                                                        });
                                                     },
                                                     failure: function(r,o) {
                                                     }
                                                 });
                                             }
                                         },
                                         failure: function(r,o) {
                                             var json = Ext.decode(o.response.responseText);
                                             Ext.Msg.show({
                                                 title: 'Your credential upload failed!',
                                                 msg: json.data.msg,
                                                 icon: Ext.MessageBox.ERROR,
                    	                         buttons: Ext.Msg.OK
                                             });
                                         }
                                     });
                                 }
                             }
                         });
                         
                     }
            }
        
            
        ]
    });
    
    win.add(formpanel,configPanel);
    win.show();
}

clovr.localFileSelector = function(config) {
    var selectorTree = new Ext.tree.TreePanel({
        autoScroll: true,
        loader: new Ext.tree.TreeLoader({
            processResponse: function(response, node, callback, scope){
                var json = response.responseText;
                var o = response.responseData || Ext.decode(json);
                if(o.success) {
                    var data = o.data;
                    node.beginUpdate();
                    for(var i in data ){
                        var cls = '';
                        var leaf = false;
                        if(data[i].ftype =='dir') {
                            cls ='folder';
                        }
                        else if(data[i].ftype =='file') {
                            cls = 'file';
                            leaf = true;
                        }
                        var node_data = {
                            'text': i,
                            'cls': cls,
                            'leaf': leaf,
                            'id': node.id + '/'+ data[i].name,
                            'checked': node.attributes.checked
                        };
                        var n = this.createNode(node_data);
                        if(n){
                            node.appendChild(n);
                        }
                    }
                    node.endUpdate();
                    this.runCallback(callback, scope || node, [node]);
                }else {
                    this.handleFailure(response);
                }
            },
            
            listeners: {
                beforeload: function(loader,node) {
                    var params = loader.baseParams;
                    var req = {'name': 'local',
                        'path': node.id};
                    this.baseParams = {'request': Ext.util.JSON.encode(req)};
                },
                load:function(loader,node) {
                    selectorTree.getRootNode().expand();
                }
            },
            dataUrl: '/vappio/listFiles_ws.py'
        }),
        listeners: {
            'checkchange': function(node, checked){
                if(!node.leaf) {
                    Ext.each(node.childNodes, function(child) {
                        child.getUI().checkbox.checked = checked;
						child.attributes.checked = checked;
                        child.fireEvent('checkchange',child,checked);
                    });
                }
                if(checked){
                    node.getUI().addClass('complete');
                }else{
                    if(node.parentNode) {
                    	node.parentNode.attributes.checked = checked;
                    	node.parentNode.getUI().checkbox.checked = checked;
                        unsetTree(node.parentNode, checked);
                    }
                    node.getUI().removeClass('complete');
                }
            }
        },
        root: new Ext.tree.AsyncTreeNode({
            text: 'user_data',
            cls: 'folder',
            id: '/mnt/user_data/',
            checked: false
        }),
    });
    var sorter = new Ext.tree.TreeSorter(selectorTree, {
        folderSort: true,
        dir: "asc",
        property: 'text'
    });
    return selectorTree;
}
/**
 * Creates a window that can be used to upload a dataset.
 * @param {object} config A config object that supports the following params:
 *      seqcombo - a combobox whose value will be set with the uploaded dataset
 * 
 */
clovr.uploadFileWindow = function(config) {
    
//    var windows = new Ext.WindowGroup();
    var localFileSelector = clovr.localFileSelector(
    //    {manager: windows}
    );


    var drawer = new Ext.ux.plugins.WindowDrawer({
        xtype: 'windowdrawer',
        layout: 'fit',
        title: 'Select a file from user_data',
        plain: true,
        animate: true,
        items: localFileSelector,
        closable: true,
        width: 300,
        side: 'e',
        resizable: true,
        buttons: [
            {text: 'Refresh',
             handler: function() { 
                 localFileSelector.getLoader().load(localFileSelector.getRootNode());
             }
            }
        ]
    });
    
	var winHeight = 400;
	if(config.notag) {
		winHeight = 250;
	}
    // A window to house the upload form
    var uploadWindow = new Ext.Window({
//        manager: windows,
        layout: 'fit',
        width: 400,
        height: winHeight,
        closeAction: 'hide',
        title: 'Upload File',
        plugins: [drawer
        ]
    });
       
    var uploadField = new Ext.ux.form.FileUploadField({
        width: 175,
        //                  fieldLabel: 'Or, Upload a file',
        name: 'file',
        listeners: {
            change: function(field, newval, oldval) {
                if(newval) {
                    
                    //clovrform.changeInputDataSet(field);
                }
            }
        }
    });
    
    var urlField = new Ext.form.TextArea({
    	fieldLabel: 'Or, paste URLs <br/>(1 per line)',
        width: 200,
    });

    
    var tagFormItems = [        
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
                        ['sff','Nucleotide SFF'],['fastq','Nucleotide FASTQ'],['nuc_blastdb','Nucleotide BLAST DB'],['aa_blastdb','Protein BLAST DB'],['clovr_16s_metadata_file','16S Metadata File'],['clovr_metagenomics_metadata_file','Metagenomics Metadata File'],
                        ['quality_scores','Quality Scores']]
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
        ];    
    // A form for the upload
    var uploadForm = new Ext.form.FormPanel({
        fileUpload: true,
        url: '/vappio/uploadFile_ws.py',
        frame: true,
        items: [
            {xtype: 'fieldset',
             title: 'Select or Upload your dataset',
             labelWidth: 125,
             items: [
                 {xtype: 'button',
                  fieldLabel: 'Select from user_data <i>(recommended)</i>',
                  text: 'Select file from image',
                  handler: function() {
                      localFileSelector.getLoader().load(localFileSelector.getRootNode());
                      uploadWindow.drawers.e.show();
                  }},
                 {xtype: 'compositefield',
                  fieldLabel: 'Or, Upload a file',
                  items: [
                      uploadField,
                      {xtype: 'button',
                       text: 'Clear',
                       handler: function() {
                           uploadField.reset();
                       }
                      }
                  ]},
				  urlField
             ]}],
        buttons: [
            {text: 'Tag',
             handler: function() {
                 
                 var form = uploadForm.getForm();
                 var uploadfield = form.findField('file');
				 var locals = localFileSelector.getChecked();
				 var urls = [];
				 if(urlField.getValue() != '') {
					 urls = urlField.getValue().split(/\r\n|\r|\n/);
				 }
    			 if(uploadfield.getValue() && locals.length) {
                     uploadWindow.drawers.e.show();
    	       		 Ext.Msg.show({
						 title: 'Ooops!',
				         width: 300,
				    	 closable: false,
                         msg: 'You have both a local file and a remote file selected. This is currently not supported. <br/><br/>Please clear the selections from either the upload box or the local file selector and try again.',
                         icon: Ext.MessageBox.ERROR,
                    	 buttons: Ext.Msg.OK
					 });
                 }
                 else if(uploadfield.getValue()) {
                     
                     uploadForm.getForm().submit({
                         waitMsg: 'Uploading File',
                         success: function(r,o) {
                             var path = '/mnt/user_data/';
                             var values = uploadForm.getForm().getFieldValues();
                             var filename = uploadField.getValue();
                             
                             if(config.notag) {
							 	 uploadForm.getForm().reset();
								 localFileSelector.getRootNode().cascade(function(n) {
                                 	var ui = n.getUI();
								 	ui.toggleCheck(false);
								 });
								 uploadWindow.close();
                             	config.notag({'files': [path + filename],
                             				 'urls': urls});
                             }
                             else {
                             clovr.tagData({
                         	     params: {
				            	     'files': [path + filename],
				            	     'urls': urls,
            					     'cluster': 'local',
								     'action': 'create',
				            	     'expand': true,
            				 		 'recursive': true,
				            	     'tag_name': values.uploadfilename,
		                    	     'metadata': {
        	                		     'description': values.uploadfiledesc,
        	                		     'format_type': values.inputfiletype,
        	                		     'tag_base_dir': path
        	                	     }
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
					                 uploadForm.getForm().reset();
					                 localFileSelector.getRootNode().cascade(function(n) {
                                 	 	var ui = n.getUI();
								 	 	ui.toggleCheck(false);
									 });
				    	 	         clovr.checkTagTaskStatusToSetValue({
				        			     uploadwindow: uploadWindow,
		    		        		     seqcombo: config.seqcombo,
		        		        	     tagname: values.uploadfilename,
		            		    	     response: Ext.util.JSON.decode(r.responseText),
                                         callback: config.callback
		            			     });
		            		     }
		        		     });
		        		 }
                	     },
                	     failure: function(r,o) {
			    	     }
            	     });
                 }
                 else {
                     var path = '/mnt/user_data/';
                     var selected = localFileSelector.getChecked();
                     var all_selected = [];
                     Ext.each(selected, function(node) {
                         all_selected.push(node.id);
                     });
                     values = form.getFieldValues();
                     if(config.notag) {
					 	uploadForm.getForm().reset();
						localFileSelector.getRootNode().cascade(function(n) {
                        	var ui = n.getUI();
							ui.toggleCheck(false);
						});
						uploadWindow.hide();
                     	config.notag({'files': all_selected,
                     				  'urls': urls
                     				});
                     }
                     else {
                     clovr.tagData({
                         params: {
				             'files': all_selected,
				             'urls': urls,
            				 'cluster': 'local',
							 'action': 'create',
            				 'expand': true,
            				 'recursive': true,
				             'tag_name': values.uploadfilename,
		                     'metadata': {
        	                	 'description': values.uploadfiledesc,
        	                	 'format_type': values.inputfiletype,
        	                	 'tag_base_dir': path
        	                 }
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
					         localFileSelector.getRootNode().cascade(function(n) {
                                 var ui = n.getUI();
								 ui.toggleCheck(false);
							});
					         uploadForm.getForm().reset();
				    	 	 clovr.checkTagTaskStatusToSetValue({
				        		 uploadwindow: uploadWindow,
		    		        	 seqcombo: config.seqcombo,
		        		         tagname: values.uploadfilename,
		            		     response: Ext.util.JSON.decode(r.responseText),
                                 callback: config.callback
		            		 });
                         }
                     })
                 }
                 }
        	 }
    	}]
    });
    if(!config.notag) {
    	uploadForm.add(tagFormItems);
    }
    uploadWindow.add(uploadForm);
    return uploadWindow;
}

clovr.pipelineWindow = function(config) {
    var win = new Ext.Window({
        height:400,
        title: 'Pipeline Information',
        width: 600,
        layout: 'fit',
    });
    var pipePanel = new clovr.ClovrPipelinePanel({
	    cluster: 'local',
	    pipeline: config.pipeline,
	    win: win,
        criteria: {
            'pipeline_name': config.pipeline_name
        }
    });
    win.add(pipePanel);
    
    win.show();
}

clovr.tagData = function(config) {
	Ext.Ajax.request({
    	url: '/vappio/tag_createupdate',
        params: {
        	'request':Ext.util.JSON.encode(config.params)
        },
        success: function(r,o) {
        	config.callback(r,o);
        },
        failure: function(r,o) {
			Ext.Msg.show({
				 title: 'Server Error',
		         width: 300,
				 closable: false,
                 msg: r.responseText,
                 icon: Ext.MessageBox.ERROR,
                 buttons: Ext.Msg.OK
			});        	
        }
    });
}

clovr.checkTaskStatus = function(config) {
    var task = {                
        run: function() {
        	var task_callback = function(r) {
	            var rjson = Ext.util.JSON.decode(r.responseText);
    	        var rdata = rjson.data[0];
				var success_title = 'Task Completed Successfully';
				if(config.success_title) {
					success_title = config.successTitle;
				}
				var success_msg = 'Your task completed succesfully';
				if(config.success_title) {
					success_title = config.successMsg;
				}			
   	         
   	         	if(rdata.state =="completed") {
   	         		Ext.Msg.show({
	                    title: success_title,
	                    msg: success_msg,
	                    icon: Ext.Msg.INFO,
    	                buttons: Ext.Msg.OK
        	        });			
	                Ext.TaskMgr.stop(task);
	                if(config.callback) {
	                	config.callback();
	                }
	            }
   		        else if(rdata.state =="failed") {
   		        	var msg = 'Your task failed';
   		        	if(rdata.msg) {
   		        		msg = rdata.msg;
   		        	}
   		        	Ext.TaskMgr.stop(task);
	    	       	Ext.Msg.show({
						title: 'Task Failed',
					    width: 300,
					    closable: false,
            	        msg: msg,
                	    icon: Ext.MessageBox.ERROR,
                    	buttons: Ext.Msg.OK
					});	
        		}
        	};
        	clovr.getTaskInfo(config.task_name,task_callback);
        },
        interval: 5000
    };
    Ext.TaskMgr.start(task);
};

// Function to Monitor the status of a tag and set a 
// particular field value. 
clovr.checkTagTaskStatusToSetValue = function(config) {
    var uploadWindow = config.uploadwindow;
    var seqcombo = config.seqcombo;
	if(config.response.success) {
		clovr.checkTaskStatus({
			task_name: config.response.data.task_name,
			callback: function() {
    	    	if(uploadWindow) { 
        	    	uploadWindow.hide();
	            }
    	    	clovr.reloadTagStores({
        	    	callback: function() {
            			if(seqcombo) {
	            	    	seqcombo.setValue(config.tagname);
    	            	}
	        	        if(config && config.callback) {
    	        	    	config.callback();
	    	            }
	        	    }
		        });
			}
		});
	}
	else {
		Ext.Msg.show({
			title: 'Error',
	        width: 300,
			closable: false,
			msg: config.response.data.msg,
            icon: Ext.MessageBox.ERROR,
            buttons: Ext.Msg.OK
		});   		
	}
/*
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

					// Not sure why we were doing this here and down below. 
					// I'm going to leave this out for now.
//                    if(seqcombo) {
//                        seqcombo.getStore().loadData([[config.tagname]],true);
//                        seqcombo.setValue(config.tagname);
//                    }
                    Ext.TaskMgr.stop(task);
                    if(uploadWindow) { 
                        uploadWindow.hide();
                    }
                    clovr.reloadTagStores({
                        callback: function() {
                            if(seqcombo) {
                                seqcombo.setValue(config.tagname);
                            }
                            if(config && config.callback) {
                                config.callback();
                            }
                        }
                    });
                }
                else if(rdata.state =="failed") {
    	       		 Ext.Msg.show({
						 title: 'Tagging failed',
				         width: 300,
				    	 closable: false,
                         msg: rdata.data.msg,
                         icon: Ext.MessageBox.ERROR,
                    	 buttons: Ext.Msg.OK
					 });
                }
            };
            clovr.getTaskInfo(config.response.data.task_name,callback);
        },
        interval: 5000
    };
    Ext.TaskMgr.start(task);
    */
}

/**
 * Retrieves information from task_ws.py
 * @param {String}   task_name    The name of the task 
 * @param {Function} callback     A function to call with the response data.
 */
clovr.getTaskInfo = function(task_name,callback) {
    Ext.Ajax.request({
        url: '/vappio/task_ws.py',
        params: {request: Ext.util.JSON.encode({'cluster': 'local','task_name': task_name})},
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
        url: '/vappio/pipeline_list',
        params: {request: 
                 Ext.util.JSON.encode(
                     {'cluster': config.cluster_name,
                      'detail': config.detail,
                      'criteria': config.criteria
                     })},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            var rdata = rjson.data;
            config.callback(rdata);
        },
        failure: function(r,o) {
            Ext.Msg.show({
                title: 'Server Error',
                msg: response.responseText,
                icon: Ext.MessageBox.ERROR,
            	buttons: Ext.Msg.OK});
        }
    });
}

clovr.getPipelineList = function(config) {
    Ext.Ajax.request({
        url: '/vappio/pipeline_list',
        params: {request: 
                 Ext.util.JSON.encode(
                     {'cluster': config.cluster_name,
                      'criteria': {
                      	'pipeline_name': config.pipe_name
                     }
                     })},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
//            var rdata = [];
//            if(rjson.data[0]) {
//            	rdata = rjson.data[0][1];
//            }
			if(rjson.success) {
	            config.callback(rjson.data	);
	        }
/*	        else {
        	    Ext.Msg.show({
            	    title: 'Server Error',
	                msg: rjson.data.msg,
    	            icon: Ext.MessageBox.ERROR,
    	            buttons: Ext.Msg.OK});
	        }*/
        }
    });
}

// A combobox to select an available credential
clovr.credentialCombo = function(config) {
    var combo;
    var store = new Ext.data.JsonStore({
        fields: [
            {name: "name"},
            {name: "description"},
            {name: "ctype"},
            {name: "active"}
            ],
		autoLoad: false,
        baseParams: {request: Ext.util.JSON.encode({'cluster': 'local'})},
        listeners: {
            load: function(store,records,o) {
                if(!config.default_value) {
                	if(store.getAt(0)) {
                    	//combo.setValue(store.getAt(0).data.name);
	                }
                }
                else {
                    combo.setValue(config.default_value);
                }
            },
            loadexceptions: function() {
            }
        }
    });
    clovr.credStores.push(store);
    clovr.getCredentialInfo({
    	cluster_name: 'local',
    	callback: function(d) {
    		store.loadData(d.data);
    	}
    });
    combo = new Ext.form.ComboBox(Ext.apply(config, {
        forceSelection: true,
		editable: false,
        valueField: 'name',
        store: store,
        mode: 'local',
        tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>{description}</div></tpl>',
        triggerAction: 'all',
        displayField: 'name',
        fieldLabel: 'Account',
	emptyText: 'Select an account'
    }));
    return combo;
}

// A combobox to select an available cluster
clovr.clusterCombo = function(config) {
    var combo;
    var store = new Ext.data.JsonStore({
        fields: [
            {name: "cluster_name"},
        ],
        root: function(data) {
            var jsonData = [];
            Ext.each(data.data, function(elm) {
                jsonData.push({"cluster_name": elm.cluster_name});
            });
            return jsonData;
        },
        url: "/vappio/cluster_list",
        baseParams: {request: '{}'},
        autoLoad: true,
        listeners: {
            load: function(store,records,o) {
                if(!config.default_value) {
                    combo.setValue(records[0].data.cluster_name);
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
        valueField: 'cluster_name',
        store: store,
        mode: 'local',
        triggerAction: 'all',
        displayField: 'cluster_name',
        fieldLabel: 'Cluster'
    }));
    return combo;
}

// Generates a combobox for tags. Takes a config which can have
// cluster config options as well as a filter and sort parameters.
clovr.tagCombo = function(config) {
    var combo;
    var store = new Ext.data.JsonStore({
        fields: [{name: 'name', mapping: 'tag_name'},
                 {name: 'metadata.format_type', mapping: ('metadata.format_type')},
                 {name: 'metadata.tag_base_dir', mapping: ('metadata.tag_base_dir')},
                 {name: 'metadata.description', mapping: ('metadata.description')},
                 {name: 'metadata.clovr_metagenomics_metadata_file', mapping: ('metadata.clovr_metagenomics_metadata_file')},
                 {name: 'metadata.clovr_16s_metadata_file', mapping: ('metadata.clovr_16s_metadata_file')},
                 {name: 'metadata.quality_scores', mapping: ('metadata.quality_scores')}
                ],
        autoLoad: false,
        listeners: {
            load: function(store, records, o) {
                if(config.filter) {
                    store.filter(config.filter);
                }
                if(store.getAt(0) && !config.allowBlank) {
                    combo.setValue(store.getAt(0).data.name);
                }
                else {
                	combo.clearValue();
                }
                if(config.afterload) {
                    config.afterload();
                }
            }
        }
    });
    if(config.field && config.field.desc) {
        config.plugins = ['fieldtip'];
        config.qtip=config.field.desc;
        config.qanchor='left';
    }
    clovr.tagStores.push(store);
    config.clearFilterOnReset = false;
    config.store = store;
    combo = new Ext.form.ComboBox(config);
    clovr.getDatasetInfo({
        callback: function(json) {
            combo.getStore().loadData(json.data);
        }
    });
    return combo;
}
                                       
clovr.tagSuperBoxSelect = function(config) {
    var sbs;
    var store = new Ext.data.JsonStore({
        fields: [{name: 'name', mapping: 'tag_name'},
                 {name: 'metadata.format_type', mapping: ('metadata.format_type')},
                 {name: 'metadata.platform_type', mapping: ('metadata.platform_type')},
                 {name: 'metadata.dataset_type', mapping: ('metadata.dataset_type')},
                 {name: 'metadata.read_length', mapping: ('metadata.read_length')},
                 {name: 'metadata.read_type', mapping: ('metadata.read_type')},
                 {name: 'metadata.tag_base_dir', mapping: ('metadata.tag_base_dir')},                 
                ],
        
        mode: 'local',
        autoLoad: false,
//        idProperty: 'name',
        listeners: {
            load: function(store, records, o) {
                if(config.filter) {
                    store.filter([config.filter]);
                }
                if(config.sort) {
                    store.sort(config.sort);
                }
//                sbs.setValue(store.getAt(0).data.name);
                if(config.afterload) {
                    config.afterload();
                }
            }
        }
    });

    clovr.tagStores.push(store);
    config.store = store;
    config.clearFilterOnReset = false;
    sbs = new Ext.ux.form.SuperBoxSelect(config)
    clovr.getDatasetInfo({
        callback: function(json) {
            sbs.getStore().loadData(json.data);
        }
    });
    return sbs;
}
// Pulls data from clusterInfo_ws.py
clovr.getClusterInfo = function(config) {
    Ext.Ajax.request({
        url: '/vappio/cluster_list',
        params: {request: Ext.util.JSON.encode({cluster_name: config.cluster_name})},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            config.callback(rjson);
        }
    });
}

// Assigns a cluster name given a protocol and credential name
clovr.getClusterName = function(config) {
    var cluster_name = config.protocol + config.credential + '_' + new Date().getTime();
    if(config.credential == 'local') {
        cluster_name = 'local';
    }
    return cluster_name;
}

// Pulls credential info from credential_ws.py
clovr.getCredentialInfo = function(config) {
    if(!clovr.requests['credentials']) {
        clovr.requests['credentials'] = {
            running: false,
            callbacks: []
        };
    }

    // If we have already made this request, just add the callback on
    // and don't make the request again.
    if(clovr.requests.credentials.running) {
        clovr.requests.credentials.callbacks.push(config.callback);
    }
    else {
        clovr.requests.credentials.running = true;
        clovr.requests.credentials.callbacks.push(config.callback);
    	Ext.Ajax.request({
        	url: '/vappio/credential_ws.py',
        	params: {request: Ext.util.JSON.encode({cluster: config.cluster_name})},
        	success: function(r,o) {
           		var rjson = Ext.util.JSON.decode(r.responseText);
                clovr.requests.credentials.running = false;
           		Ext.each(clovr.requests.credentials.callbacks, function(cb) {
                    cb(rjson);
                });
                clovr.requests.credentials.callbacks = [];
            }
//            	config.callback(rjson);
    	});
    }
}
// Pulls info about a particular dataset
clovr.getDatasetInfo = function(config) {

    if(!clovr.requests['querytag']) {
        clovr.requests['querytag'] = {
            running: false,
            callbacks: []
        };
    }

    // If we have already made this request, just add the callback on
    // and don't make the request again.
    if(clovr.requests.querytag.running && !config.force) {
        clovr.requests.querytag.callbacks.push(config.callback);
    }
    else {
    	if(!config.force) {
	        clovr.requests.querytag.running = true;
	        clovr.requests.querytag.callbacks.push(config.callback);
	    }
        var params = {
            cluster: 'local',
            detail: config.detail
        };
        if(config.criteria) {
        	params.criteria = config.criteria;
        }
        if(config.dataset_name) {
            params.tag_name = [config.dataset_name];
        }
        Ext.Ajax.request({
            url: '/vappio/tag_list',
            params: {
                request: Ext.util.JSON.encode(params)},
            success: function(r,o) {
                var rjson = Ext.util.JSON.decode(r.responseText);
                if(!config.force) {
                // Not sure if we're going to have a race condition here or not.
                clovr.requests.querytag.running = false;

                Ext.each(clovr.requests.querytag.callbacks, function(cb) {
                    cb(rjson);
                    //                config.callback(rjson);
                });
                clovr.requests.querytag.callbacks = [];
                }
                else {
                	config.callback(rjson)
                }
            }
        });
    }
}

clovr.deletePipeline = function(config) {
    if(!config.params.cluster) {
        config.params.cluster = 'local';
    }
    if(config.params.pipeline_name) {
        config.params.criteria = {'pipeline_name': config.params.pipeline_name}
        delete config.params.pipeline_name;
    }
    Ext.Ajax.request({
        url: '/vappio/pipeline_delete',
        params: {
            request: Ext.util.JSON.encode(config.params)
        },
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            if(rjson.success) {
                var num = rjson.data.length;
                if(config.submitcallback) {
                    config.submitcallback(r);
                }
                Ext.Msg.show({
                    title: 'Delete successful',
                    msg: num+' pipeline(s) was deleted successfully.',
                    buttons: Ext.Msg.OK
                });
            }
            else {
            Ext.Msg.show({
                title: 'Server Error',
                msg: rjson.data.msg,
                icon: Ext.MessageBox.ERROR});            
            
            }
        },
        failure: function(r,o) {
            var msg = 'There was an error with your request.';
            if(r.responseText) {
                msg = r.responseText;
            }
            Ext.Msg.show({
                title: 'Server Error',
                msg: msg,
                icon: Ext.MessageBox.ERROR});
        }
    });
}

clovr.deleteTag = function(config) {

	var params = {
            cluster: 'local',
            detail: config.detail
    };
    if(config.criteria) {
        params.criteria = config.criteria;
    }
    if(config.dataset_name) {
        params.tag_name = config.dataset_name;
    }
        
    Ext.Ajax.request({
        url: '/vappio/tag_delete',
        params: {
            request: Ext.util.JSON.encode(params)},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
	        clovr.checkTaskStatus({
				task_name: rjson.data,
				callback: function() {
					var params = {}
					if(config.callback) {
						params.callback = config.callback;
					}
					clovr.reloadTagStores(params);
				}
			});
        }
    });	

}

clovr.getPipelineInfo = function(config) {
	clovr.getPipelineList(config);
}

clovr.PROTOCOL_TO_TRACK = 
    {
        'clovr_metagenomics_noorfs': 'clovr_metagenomics',
        'clovr_metagenomics_orfs': 'clovr_metagenomics',
        'clovr_metatranscriptomics': 'clovr_metagenomics',
        'clovr_total_metagenomics': 'clovr_metagenomics',
        'clovr_16S': 'clovr_16s',
        'clovr_16S_nochimeracheck': 'clovr_16s',
        'clovr_search': 'clovr_search',
        'clovr_search_webfrontend': 'clovr_search',
        'clovr_microbe_annotation': 'clovr_microbe',
        'clovr_microbe454': 'clovr_microbe',
        'clovr_microbe_illumina' : 'clovr_microbe',
        'clovr_assembly_velvet' : 'clovr_microbe',
        'clovr_assembly_celera' : 'clovr_microbe'
    };
clovr.OTHER_PROTOCOLS = 
    {
        'clovr_sleep' : true,
        'clovr_human_contaminant_screening_paired' : true,
        'clovr_human_contaminant_screening_single' : true,
        'clovr_align_bowtie_indices' : true,
        'clovr_align_bowtie_noindices' : true,
        'clovr_metagenomics_assembly' : true
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
        var dname = field.display ? field.display : field.name;
        var choices;
        var field_config = {};
        if(field.type_params && field.type_params.choices) {
            choices = [];
            Ext.each(field.type_params.choices, function(choice) {
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
                name: prefix + field.name
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
                name: prefix + field.name,
                value: field['default'],
            };
            if(field.desc) {
                field_config.plugins = ['fieldtip'];
                field_config.qtip=field.desc;
                field_config.qanchor='left';
            }
        }
        if(!ignore_fields[field.name]) {
            if(field.visibility == 'default_hidden') {
                field_config.disabled=false;
                advanced_params.push(field_config)
            }
            else if(field.visibility == 'hidden') {
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

clovr.validatePipeline = function(config) {
    Ext.Ajax.request({
        url: '/vappio/pipeline_validate',
        params: {
            'request': Ext.util.JSON.encode(
                {'config': config.params,
                 'bare_run': false,
                 'cluster': 'local'})
        },
        success: function(response) {
            var r = Ext.util.JSON.decode(response.responseText);
            if(!r.success) {
                Ext.Msg.show({
                    title: 'Pipeline Validation Failed!',
                    msg: r.data.msg,
                    icon: Ext.MessageBox.ERROR
                });
            }
            else {
            	
            	if(r.data.errors.length) {
            		if(config.submitcallback) {
                		config.submitcallback(r);
                	}
                	else {
						var errors = [];
                		Ext.each(r.data.errors, function(error) {
                			errors.push(error.keys.join(',')+':'+error.message);
                		});
                		Ext.Msg.show({
                			title: 'Pipeline configuration failed validation',
                			msg: errors.join('<br/>'),
                			icon: Ext.MessageBox.ERROR
                		});
                	}
            	}
            	else {
                	Ext.Msg.show({
                    	title: 'Success!',
                    	msg: 'Your Pipeline validated successfully',
                    	buttons: Ext.Msg.OK
                	});
            	}

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
clovr.resumePipeline = function(config) {
    Ext.Ajax.request({
        url: '/vappio/pipeline_resume',
        params: {
            'request': Ext.util.JSON.encode(config.params)
        },
        success: function(response) {
            var r = Ext.util.JSON.decode(response.responseText);
            if(!r.success) {
                Ext.Msg.show({
                    title: 'Pipeline Resume Failed!',
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
            
            	if(config.submitcallback) {
                	config.submitcallback(r);
            	}
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
clovr.runPipeline = function(config) {
    Ext.Ajax.request({
        url: '/vappio/pipeline_run',
        params: {
            'request': Ext.util.JSON.encode(
                {'config': config.params,
		 'bare_run': false,
		 'overwrite':true,
                 'cluster': 'local'
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
            
            	if(config.submitcallback) {
                	config.submitcallback(r);
            	}
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

clovr.reloadCredStores = function(config) {
        clovr.getCredentialInfo({
            cluster_name: 'local',
            callback: function(data) {
                Ext.each(clovr.credStores, function(store,i,stores) {
                    if(store.url) {
                        store.reload();
                    }
                    else {
                        store.loadData(data.data);
                    }
                });
                if(config && config.callback) {
                    config.callback();
                }
            }     
        });
}

clovr.reloadTagStores = function(config) {
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
            if(config && config.callback) {
                config.callback();
            }
        }     
    });
}

clovr.getVmInfo = function(config) {
    Ext.Ajax.request({
        url: '/vappio/vm_info',
        params: {
            'request': Ext.util.JSON.encode(
                {'cluster': 'local'
                })
        },
        success: function(response) {
            var r = Ext.util.JSON.decode(response.responseText);
            if(!r.success) {
                Ext.Msg.show({
                    title: 'CloVR responded with an error!',
                    msg: r.data.msg,
                    icon: Ext.MessageBox.ERROR
                });
            }
            else {
                // Commenting this out until shared folders check is cross-platform
/*                if(!r.data.shared_folders_enabled) {
                    var msg = 'It appears as though CloVR\'s shared folders are not enabled.<br/>'+
                        'Please refer to the documentation below to get things setup correctly:<br/><br/>'+
                        '<a href=http://clovr.org/virtualbox-version-4-0-and-later/>VirtualBox Setup</a><br/><br/>'+
			'<a href=http://clovr.org/docs/vmware-clovr-install/>VMWare Setup</a>';
                    Ext.Msg.show({
                        title: 'CloVR Shared Folders Error',
                        msg: msg,
                        icon: Ext.MessageBox.ERROR
                    });
                }*/
            	if(config && config.callback) {
                	config.callback(r);
            	}
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

var unsetTree = function(node, checked) {
    if(node.getUI().checkbox) {
        node.getUI().checkbox.checked = checked;
        if(!checked) {
            node.getUI().removeClass('complete');
        }
        if(node.parentNode) {
                unsetTree(node.parentNode,checked);
        }
    }
}

// clearly, this is a work in progress...
