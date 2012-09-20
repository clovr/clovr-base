 /*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrPipelinePanel = Ext.extend(Ext.Panel, {
    
    constructor: function(config) {

        var clovrpanel = this;
        var master_container = new Ext.TabPanel({
        	region: 'center',
//        	layout: '',
        	style: {
        		padding: '3px'
        	},
        	activeTab: 0
        });
		var title_str = config.criteria.pipeline_name+' pipeline';
		if(config.pipeline.pipeline_id) {
			title_str = "<a target='_blank' style='color:black;' href=/ergatis/cgi/view_pipeline.cgi?instance=/mnt/projects/clovr/workflow/runtime/pipeline/"+
					config.pipeline.pipeline_id+"/pipeline.xml>Pipeline "+config.pipeline.pipeline_id+"</a>";
		}
        var title = new Ext.Container({
            height: 30,
            name: 'pipeline_title',
            style: {
                'padding': '3px 0 3px 5px',
                'font-size': '16pt',
                'font-family': 'Trebuchet MS,helvetica,sans-serif',
                'background': 'url("/clovr/images/clovr-vm-header-bg-short.png") repeat-x scroll center top'
            },
            region: 'north',
            html: title_str
        });
        
        var child_grid = new Ext.grid.GridPanel({
        	title: 'Child Pipelines',
        	margins: '5 5 5 5',
        	columnWidth: 0.5,
        	height: 200,
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    sortable: true
                },
                columns: [
                    {id: 'cluster_name', header: 'Cluster'},
                    {id: 'state', header: 'State'},
                    {id: 'ganglia', header: 'Ganglia'},
                    {id: 'ergatis', header: 'Ergatis'}
                ]
            }),
            autoExpandColumn: 'cluster_name',
            store: new Ext.data.Store({
                reader: new Ext.data.JsonReader({
                    fields: ['cluster_name','state','ganglia','ergatis']
                })
            })                
        });
        var input_grid = new Ext.grid.GridPanel({
        	title: 'Inputs',
        	margins: '5 5 5 5',
        	columnWidth: 0.5,
        	height: 200,
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    sortable: true
                },
                columns: [
                    {id: 'name', header: 'Tag Name'}
                ]
            }),
            autoExpandColumn: 'name',
            store: new Ext.data.Store({
                reader: new Ext.data.ArrayReader({
                    fields: ['name']
                })
            })
        });
        
        var parameters_grid = new Ext.grid.GridPanel({
        	title: 'Parameters',
        	columnWidth: 0.5,
            margins: '5 5 5 5',
        	height: 200,
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    sortable: true
                },
                columns: [
                    {header: 'Name', dataIndex: 'key', width: 150, renderer:
                    	function(value){
	                    	return value.replace(/.*\./,'');
                    	}
                    },
                    {id: 'value', header: 'Values', dataIndex: 'value'}
                ]
            }),
            autoExpandColumn: 'value',
            store: new Ext.data.Store({
                reader: new Ext.data.JsonReader({
                    fields: ['key','value']
                })
            })            
        });
        
        var output_grid = new Ext.grid.GridPanel({
        	title: 'Outputs',
        	margins: '5 5 5 5',
        	columnWidth: 0.5,
        	height: 200,
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    sortable: true
                },
                columns: [
                    {id: 'output', header: 'Output Download'}
                ]
            }),
            autoExpandColumn: 'output',
            store: new Ext.data.Store({
                reader: new Ext.data.ArrayReader({
                    fields: ['output']
                })
            })            
        });
        var msg_grid = new Ext.grid.GridPanel({
        	title: 'Messages',
        	margins: '5 5 5 5',
        	autoExpandColumn: 'message',
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    sortable: true
                },
                columns: [
                    {id: 'message', header: 'Message',dataIndex: 'text'},
                    {id: 'time', header: 'Timestamp',dataIndex: 'timestamp', width:135, format: 'Y/m/d H:i:s T',xtype: 'datecolumn'},
                    {id: 'type', header: 'Type',dataIndex: 'mtype'}
                ]
            }),
            store: new Ext.data.Store({
                reader: new Ext.data.JsonReader({
                    fields: [{name: 'text'},
                    	{name: 'timestamp',type:'date', dateFormat: 'timestamp', mapping: 'timestamp'},
                    	{name: 'mtype'}
                    ]
                }),
                listeners: {
                	load: function() {
                		this.sort('timestamp','DESC');
                	}
                }
            })              
        });
        
        var value_classes = {
            input: {
                regex: /input\./,
                values: []
            },
            pipeline: {
                regex: /pipeline\./,
                values: []
            },
            cluster: {
                regex: /cluster\./,
                values: []
            },
            params: {
                regex: /params\./,
                values: []
            },
            output: {
                regex: /output\./,
                values: []
            }
        };
        clovr.getPipelineStatus({
            'criteria': config.criteria,
            'cluster_name': config.cluster,
            'detail': true,
            'callback': function(data) {
            	var pipe = data[0];
            	
            	var things_for_title = ["<a target='_blank' style='color:black;' href=/ergatis/cgi/view_pipeline.cgi?instance=/mnt/projects/clovr/workflow/runtime/pipeline/"+
					config.pipeline.pipeline_id+"/pipeline.xml>Pipeline "+config.pipeline.pipeline_id+"</a>"];
				var things_for_child_grid = [];
            	Ext.each(pipe.children, function(child) {
            		clovr.getPipelineInfo({
            			cluster_name: child[0],
            			pipe_name: child[1],
            			callback: function(response) {
            				if(response[0]) {
            					clovr.getClusterInfo({
            						cluster_name: child[0],
            						callback: function(response2) {
										var host = response2.data[0].master.public_dns;
                                        if(host.match(/clovr-/) ) {
                                            host = host.replace("clovr-","");
                                            host = host.replace(/-/g,".");
                                        }
										var ergatis = "<a target='_blank' style='color:black;' href=http://"+host+"/ergatis/cgi/view_pipeline.cgi?instance=/mnt/projects/clovr/workflow/runtime/pipeline/"+
    										response[0].pipeline_id+"/pipeline.xml>Ergatis</a>";
    									var ganglia = "<a target='_blank' style='color:black;' href=http://"+host+"/ganglia>Ganglia</a>";
			            				if(pipe.children.length > 1) {
			            				    var new_child = {'cluster_name': child[0],
			            				                    'state': response2.data[0].state,
			            				                    'ganglia': ganglia,
			            				                    'ergatis': ergatis
			            				                    };
			            				    things_for_child_grid.push(new_child);
			            				    child_grid.getStore().loadData(things_for_child_grid);
			            				}
			            				else {
    			            				things_for_title.push("(<a target='_blank' style='color:black;' href=http://"+
    			            				host+"/ergatis/cgi/view_pipeline.cgi?instance=/mnt/projects/clovr/workflow/runtime/pipeline/"+
    										response[0].pipeline_id+"/pipeline.xml>Pipeline "+response[0].pipeline_id+")</a>");
    										title.update(things_for_title.join(""));
    									}
        			    			}
        			    		});
        	    			}
            			}
            		});
            	
            	});
            	
            	if(pipe.children.length > 1) {
            	    master_container.add(child_grid);
            	}
            	// Pull the task info
            	clovr.getTaskInfo(pipe.task_name,
            		function(rdata) {
            		    var data = Ext.util.JSON.decode(rdata.responseText);
			    if(msg_grid.getStore()) {
                                msg_grid.getStore().loadData(data.data[0].messages);
                            }
            	});
            	
            	// First we'll deal with the input tags
            	var input_data = [];
            	Ext.each(pipe.input_tags, function(tag) {
            		input_data.push([tag]);
            	});
            	if(input_grid.getStore()) {
		    input_grid.getStore().loadData(input_data);
            	}
                for(param in pipe.config) {
                    for(type in value_classes) {
                        if(param.match(value_classes[type].regex)) {
                            value_classes[type].values.push({
                            	key: param,
                            	value: pipe.config[param]});
                        }
                    }
                }
                if(parameters_grid.getStore()) {
                    parameters_grid.getStore().loadData(value_classes.params.values);
                }
                var output_data = [];
                Ext.each(pipe.output_tags, function(tag) {
                	output_data.push(["<a href='/output/"+tag+".tar.gz'>"+tag+"</a>"]);
                });
                if(output_grid.getStore()) {
                    output_grid.getStore().loadData(output_data);
                }
            }
        });
        config.layout = 'border';
        config.buttonAlign = 'center';
        config.buttons = [{text: 'Delete',
            handler: function() {
                Ext.Msg.show({
                    title: 'Deleting Pipeline',
                    msg: 'Pipeline is being deleted.',
                    wait: true
                });
                clovr.deletePipeline({
                    params: {
                        'pipeline_name': config.pipeline.pipeline_name,
                        'cluster': 'local',
                        'user_name': config.pipeline.user_name},
                    'submitcallback': function() {
                        if(clovrpanel.win) {
                            clovrpanel.win.close();
                        }
                    }
                });
            }
        }];
        if(config.pipeline.state != 'running' && config.pipeline.state != 'completed') {
            config.buttons.push({text: 'Resume',
                handler: function() {
                    Ext.Msg.show({
                        title: 'Restarting Pipeline',
                        msg: 'Your pipeline is being resumed.',
                        wait: true
                    }); 
                    clovr.resumePipeline({params: {
                        'pipeline_name': config.pipeline.pipeline_name,
                        'cluster': 'local',
                        'user_name': config.pipeline.user_name},
                        'submitcallback': function() {
                            if(clovrpanel.win) {
                                clovrpanel.win.close();
                            }
                        }
                    });
                }
            });
        }
        config.bodyStyle = {
            background: '#0D5685'
        };
        master_container.add(input_grid,parameters_grid,output_grid,msg_grid);
        
        config.items = [title,master_container];
        clovr.ClovrPipelinePanel.superclass.constructor.call(clovrpanel,config);
    }
});

Ext.reg('clovrpipelinepanel', clovr.ClovrPipelinePanel);
