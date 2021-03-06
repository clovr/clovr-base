/*
 * A panel to display information about a particular tag 
 * and run an analysis on that tag if applicable. 
 */
Ext.ns('clovr');
clovr.ClovrDatasetPanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {
        
        var datasetpanel = this;
        

        config.layout='border';
        config.bodyStyle = {
            background: '#0D5685'
        };
        config.buttons = [{
            text: 'Delete Tag',
            handler: function() {
            	clovr.deleteTag({
            		dataset_name: datasetpanel.dataset_name,
            		callback: function() {
            			datasetpanel.parentPanel.getLayout().setActiveItem(0);
            		}
            	});
            }},
            {
			text: 'Save Changes',
			handler: function() {
				datasetpanel.saveDataset({});
        }}];
        config.buttonAlign = 'center';
        config.frame= true;
        config.deferredRender=false;
        var header_panel = new Ext.Panel({
            region: 'north',
            height: 30,
            html: 'Information for the '+config.dataset_name+' dataset'
        });
        var footer_panel = new Ext.Panel({
            region: 'south'
        });

        var pipelines_panel = new Ext.Panel({
            id: 'pipelines_panel',
            autoHeight: true,
            autoScroll: true,
            region: 'center',
            height: 150,
            layout: 'anchor'
        });
        var pipelines_wrapper = new Ext.Panel({
            id: 'pipelines_wrapper',
            layout: 'fit',
            region: 'center',
            autoScroll: true,
//            autoHeight: false,
            minSize: 100,
            split: true,
            items: [pipelines_panel]
        });
        var pipelines_container = new Ext.Panel({
            layout: 'border',
            region: 'south',
            height: 150,
            autoScroll: true,
            deferredRender:false,
            title: 'Pipelines',
            frame: true,
            items: [header_panel,pipelines_panel,footer_panel]
        });
		var pipe_store = new Ext.data.JsonStore({
            root: function(data) {
                return data;
            },
            fields: ['taskName','pipeline_id','inputs','outputs']
        });
        var pipe_grid = new Ext.grid.GridPanel({
            title: 'Pipelines',
            region: 'south',
            margins: '5 5 5 5',
            height: 150,
            store: pipe_store,
            viewConfig: {
                forceFit: true
            },
            
            colModel: new Ext.grid.ColumnModel({
                columns: [
                	{id: 'pipeline_id',
                	 header: 'Pipeline ID',
                	 dataIndex: 'pipeline_id',
                     width: 30
                	},
                    {id: 'inputs',
                     header: 'Inputs', 
                     dataIndex: "taskName",
                     renderer: renderInput},
                    {id: 'outputs',
                     header: 'outputs', 
                     dataIndex: "taskName",
                     renderer: renderOutput}
                ]
            })
        });
        
        var file_actions = new Ext.ux.grid.RowActions({
        	id: 'file_actions',
        	keepselection: true,
        	actions:[{
				iconCls:'bin_closed',
				tooltip:'Remove file from tag'
			}]
        });
        file_actions.on(
			'action',
			function(grid, record, action, row, col) {
				if(action == 'bin_closed') {
					grid.getStore().remove(record);
				}
			}
		);
        var file_grid = new Ext.grid.GridPanel({
            title: 'Files',
            flex: 1,
            margins: '5 5 5 5',
            plugins: [file_actions],
            frame: true,
            buttonAlign: 'center',
            buttons: [
            	{text: 'Add',
            	handler: function() {
            		var win = clovr.uploadFileWindow({notag: function(new_files) {
            			datasetpanel.saveDataset(new_files);
            		
            		}});
            		win.show();
            	}}
            ],
            removeVal: function(key,val) {
            	this.getStore().remove(this.getStore().find(key,val));
            },
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    sortable: true
                },
                columns: [
                    {id: 'file', header: 'file',dataIndex: 'file', width: 100, 
                    renderer: function(val,p,rec) {
                    	var regex = /.*\//;
                    	return val.replace(regex,'');
                    }},file_actions
/*                    {id: 'delete', header: '', dataIndex: 'file', width: 30,
                    renderer: function(val,meta,rec) {
                    	return "<div class='bin_closed icon_button'></div>";
                    }}*/
                ]
            }),
            autoExpandColumn: 'file',
            store: new Ext.data.Store({
                reader: new Ext.data.JsonReader({
                    fields: ['file']
                })
            })
        });

        var meta_actions = new Ext.ux.grid.RowActions({
        	id: 'meta_actions',
        	keepselection: true,
        	actions:[{
				iconCls:'bin_closed',
				tooltip:'Remove key/value pair'
			}]
        });
        meta_actions.on(
			'action',
			function(grid, record, action, row, col) {
				if(action == 'bin_closed') {
					grid.getStore().remove(record);
				}
			}
		);        
		var metadata_grid = new Ext.grid.EditorGridPanel({
			frame: true,
			title: 'metadata',
            margins: '5 5 5 5',
			buttonAlign: 'center',
            flex: 1,
            plugins: [meta_actions],
			colModel: new Ext.grid.ColumnModel({
				defaults: {
					sortable: true
				},
				columns: [
					{header: 'key', dataIndex: 'name', width: 100, editor: new Ext.form.TextField()},
					{id: 'value', header: 'value', dataIndex: 'value', editor: new Ext.form.TextField()},
					meta_actions
				]
			}),
			autoExpandColumn: 'value',
			store: new Ext.data.Store({
				reader: new Ext.data.JsonReader({
					fields: ['name','value']
				})
			}),
			buttons: [{
            text: 'Add',
            handler : function(){
                // access the Record constructor through the grid's store
                var rec = metadata_grid.getStore().recordType;
                var p = new rec({
                    name: 'Key',
                    value: 'value'
                });
                metadata_grid.stopEditing();
                metadata_grid.getStore().insert(0, p);
                metadata_grid.startEditing(0, 0);
            }
        }]
		});

        var title_region = new Ext.Container({
            height: 30,
            style: {
                'padding': '3px 0 0 0',
                'font-size': '16pt',
                'font-family': 'Trebuchet MS,helvetica,sans-serif',
                'background': 'url("/clovr/images/clovr-vm-header-bg-short.png") repeat-x scroll center top'
            },
            region: 'north',
            html: config.dataset_name+' dataset'
        });
        var files_meta_region = new Ext.Container({
            region: 'center',
//            height: 250,
            layout: 'hbox',
            layoutConfig: {
                align: 'stretch'
            },
            items: [file_grid, metadata_grid]
        });
        config.listeners ={
            render: function() {
                    if(config.dataset_name) {
                        datasetpanel.loadDataset(config);
                    }
            }};
        config.items = [title_region,files_meta_region,pipe_grid];
        datasetpanel.metagrid = metadata_grid;
        datasetpanel.filegrid = file_grid;
        datasetpanel.pipe_grid = pipe_grid;
        datasetpanel.header_panel = title_region;
        datasetpanel.footer_panel = footer_panel;
        datasetpanel.pipelines_panel = pipelines_panel;
        datasetpanel.pipelines_container = pipelines_container;
        datasetpanel.pipelines_wrapper = pipelines_wrapper;
        datasetpanel.pipelineCallback = config.pipeline_callback;

        clovr.ClovrFormPanel.superclass.constructor.call(this,config);



    },
    
    saveDataset: function(config) {
		var meta_recs = this.metagrid.getStore().getRange();
		var metadata = {};
		var compressed = false;
		Ext.each(meta_recs, function(rec) {
			metadata[rec.data.name] = rec.data.value;
			if(rec.data.name == 'compressed') {
				compressed = rec.data.value;
			}
		});
				
		var file_recs = this.filegrid.getStore().getRange();
		var files = [];
		Ext.each(file_recs, function(rec) {
			files.push(rec.data.file);
		});	
		if(config.files) {
			Ext.each(config.files, function(f) {
				files.push(f);
			});
		}
		if(config.urls && config.urls.length > 0) {
			metadata.urls.push(config.urls);
		}
		var datasetpanel = this;
		clovr.tagData({
			params: {
				files: files,
				cluster: 'local',
				action: 'overwrite',
				expand: true,
            	recursive: true,
            	compressed: compressed,
				tag_name: this.dataset_name,
		        metadata: metadata
		    },
			callback: function(r,o) {
				var data = Ext.util.JSON.decode(r.responseText);
					Ext.Msg.show({
						title: 'Tagging Data...',
				        width: 200,
					    mask: true,
				    	closable: false,
				        wait: true,
				        progressText : 'Tagging Data'
					});
                clovr.checkTagTaskStatusToSetValue({
		            response: Ext.util.JSON.decode(r.responseText),
		            callback: function() {
		            	datasetpanel.loadDataset({
		            		dataset_name: datasetpanel.dataset_name,
		            		dataset: datasetpanel.dataset
		            	});
		            }
		        });
			}
		});
    },
    loadDataset: function(config) {
        var datasetpanel = this;
        datasetpanel.header_panel.update(config.dataset_name+' dataset');
        datasetpanel.pipelines_panel.removeAll();
        datasetpanel.getEl().mask('Loading...','x-mask-loading');
        datasetpanel.dataset_name = config.dataset_name;
        datasetpanel.dataset = config.dataset;
        clovr.getDatasetInfo({
        	detail: true,
        	criteria: {
        		tag_name: config.dataset_name
        	},
        	force: true,
        	callback: function(d) {
        	
        		var meta_fields_to_load = [];
                var files_to_load = [];
                var output_pipes = [];
                var dataset = d.data[0];
        		for(key in dataset.metadata) {
        			// Total HACK here
        			if(key.match(/pipeline_configs/)) {
        				var match = key.match(/pipeline_configs.([^\.]+)\./);
						if(match && !output_pipes[match[1]]) {
							output_pipes[match[1]] = 1;
						}
        			}
					else {
						meta_fields_to_load.push({
							'name': key,
							'value': dataset.metadata[key]
						});
					}
				}
				Ext.each(d.data[0].files, function(file) {
					files_to_load.push({
						'file': file
					});
				});
                datasetpanel.filegrid.getStore().loadData(files_to_load);
	        	datasetpanel.metagrid.getStore().loadData(meta_fields_to_load);
        	clovr.getPipelineInfo({
        		cluster_name: 'local',
            	callback: function(r) {
                	var input_regex = /input/;
                	var things_to_load = [];
                	Ext.each(r, function(elm) {
						var inputs = elm.input_tags;
						Ext.each(inputs, function(input) {
							if(input == config.dataset_name) {
								things_to_load.push(elm);
							}
						});
/*						for(key in pipeconf) {
							if(key == 'pipeline.PIPELINE_NAME' && output_pipes[pipeconf[key]]) {
								things_to_load.push(elm[1]);
							}
            				else if(input_regex.exec(key)) {
								var vals = pipeconf[key].split(',');
                				for(val in vals) {
                					if(vals[val] == config.dataset_name) {
						    			things_to_load.push(elm[1]);
						    			break;
						    		}
								}
                			}
                		}*/
                	});
                	datasetpanel.pipe_grid.getStore().loadData(things_to_load);
                	datasetpanel.pipe_grid.getStore().filterBy(
                    	function(rec,id) {
                        	return rec.json.wrapper;
                    });
                // Not going to do this right now
/*              if(0) {
                    var results_by_protocol = getResultsByProtocol(r.data,config);
                    var protocols = clovr.getProtocols();
                    Ext.each(protocols, function(p) {
                        
                        if(results_by_protocol[p].length ==0) {
                            datasetpanel.pipelines_panel.add(
                                new Ext.Container({
                                    layout: 'column',
                                    items: [{
                                        columnWidth: .2,
                                        items: [{
                                            xtype: 'button',
                                            height: '72px',
                                            width: '96px',
                                            scale: 'clovr',
                                            //                                            tooltip: {text: 'Click here to run CloVR Metagenomics'},
                                            tooltipType: 'title',
                                            text: "<img src='/clovr/images/"+p+"_icon.png'>",
                                            handler: function() {
                                                if(datasetpanel.pipelineCallback) {
                                                    datasetpanel.pipelineCallback({dataset_name: config.dataset_name,
                                                                                   pipeline_name: p
                                                                                  });
                                                }
                                                // clovrpanel.getLayout().setActiveItem('clovr_metagenomics');
                                            }
                                        }]},{
                                            columnWidth: .80,
                                            items: [{
                                                html: 'You have not run this protocol yet'
                                            }]
                                        }]  
                                }));
                            
                        }
                    else {
                        var config_data =[];
                        var fields_for_grid = [];
                        // Enormous HACK here but this is necessary because the field names have '.' characters in them.
                        for (var pr in results_by_protocol[p][0])fields_for_grid.push({name: pr, mapping: ('[\"'+pr+'\"]')});
                        Ext.each(results_by_protocol[p], function(res) {
                            config_data.push(res);
                        });
                        
                        var store = new Ext.data.JsonStore({
                            data: config_data,
                            root: function(data) {
                                return data;
                            },
                            fields: fields_for_grid //[{name: "pipeline_name", mapping: '["pipeline.PIPELINE_WRAPPER_NAME"]'}]
                        });
                        
                        store.filter([{property: 'ptype', value: 'clovr_wrapper'}]);
                        datasetpanel.pipelines_panel.add(
                            new Ext.Container({
                                layout: 'column',
                                items: [{
                                    columnWidth: .20,
                                    items: [{
                                        xtype: 'button',
                                        height: '72px',
                                        width: '96px',
                                        scale: 'clovr',
                                        //                                            tooltip: {text: 'Click here to run CloVR Metagenomics'},
                                        tooltipType: 'title',
                                        text: "<img src='/clovr/images/"+p+"_icon.png'>",
                                        handler: function() {
                                            if(datasetpanel.pipelineCallback) {
                                                datasetpanel.pipelineCallback({dataset_name: config.dataset_name,
                                                                               pipeline_name: p
                                                                              });
                                            }
                                        }
                                    }]},{
                                        columnWidth: .80,
                                        items: [{
                                            xtype: 'grid',
                                            store: store,
                                            height: 200,
//                                            autoExpandColumn: 'pipeline',
                                            viewConfig: {
                                                forceFit: true
                                            },

                                            colModel: new Ext.grid.ColumnModel({
                                                columns: [
                                                    {id: 'inputs',
                                                     header: 'Inputs', 
                                                     dataIndex: "taskName",
                                                     renderer: renderInput},
                                                    {id: 'outputs',
                                                     header: 'outputs', 
                                                     dataIndex: "taskName",
                                                     renderer: renderOutput}
                                                ]
                                            })
                                        }]
                                    }]
                            }));
                    }
                });
                }*/
                //                datasetpanel.setActiveTab(0);
					datasetpanel.doLayout();
                	datasetpanel.getEl().unmask();
            	}
            
    	});

    		}
    	});
	}
});

Ext.reg('clovrdatasetpanel', clovr.ClovrDatasetPanel);

var getResultsByProtocol = function(data,config) {
    var results_by_protocol ={};
    Ext.each(clovr.getProtocols(), function(elm) {
        results_by_protocol[elm] = [];
    });
        
    var tag_regex = /.*TAG$/;
    Ext.each(data, function(elm) {
        var pipeconf = elm[1].config;
        for(key in pipeconf) {
            if(tag_regex.exec(key)) {
                if(pipeconf[key] == config.dataset_name) {
                    var prot = clovr.getPipelineToProtocol(pipeconf['pipeline.PIPELINE_TEMPLATE']);
                    if(results_by_protocol[prot]) {
                        results_by_protocol[prot].push(elm[1]);
                    }
                }
            }
        }
    })
    return results_by_protocol;
}

function renderInput(value, p, record) {
    var return_string="";
    var input_regexp = /^input/;
    var clean_input = /input\./;
    var inputs = record.json.input_tags;
/*    for (field in record.json.config) {
        // HACK here - looks like I can look at input.INPUT_TAGS instead of doing this
        if(input_regexp.exec(field) && field != 'input.INPUT_TAGS') {
            inputs.push(field.replace(clean_input,"")+": "+ record.json.config[field]);
        }
    };
*/
    if(record.json.state == "error") {
		return_string = "Failed Pipeline "+record.json.pipeline_desc;
//        return_string="Failed Pipeline "+ record.json.config['pipeline.PIPELINE_NAME'];
    }
    else {
        return_string = "<div>"+inputs.join("<br/>")+"</div>";

//        return_string = String.format('output: {0}',record.data["output.TAGS_TO_DOWNLOAD"]);
    }
    return return_string;
}

function renderOutput(value, p, record) {
    var return_string="";
    var input_regexp = /^output/;
    var clean_input = /output\./;
    var tags = record.json.output_tags;
    var outputs = [];
    Ext.each(tags, function(tag) {
        outputs.push("<a href='/output/"+tag+".tar.gz'>"+tag+"</a>");
    });
//    if(Ext.isArray(record.json.config["output.TAGS_TO_DOWNLOAD"])) {
//        outputs = record.json.config["output.TAGS_TO_DOWNLOAD"];
//    }
    if(record.json.state == "error" || record.json.state == "failed") {
        return_string="Failed Pipeline "+ record.json.pipeline_desc;
    }
    else if(record.json.state != "completed") {
        return_string="Pipeline not complete";
    }
    else {
        if(record.json.output_tags.length > 0) {
            return_string = "<div>"+outputs.join("<br/>")+"</div>";            
        }
        else {
            return_string = 'No outputs from this pipeline';
        }
    }
    return return_string;
}
