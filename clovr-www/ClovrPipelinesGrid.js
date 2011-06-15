 /*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrPipelinesGrid = Ext.extend(Ext.grid.GridPanel, {
    
    constructor: function(config) {
        var pipeGrid = this;
        pipeGrid.pBars = new Object();
        var jstore = new Ext.data.GroupingStore({
            //            root: 'rows',
            reader: new Ext.data.JsonReader({
                fields: [
                    {name: "name"},
                    {name: "pipeline_desc"},
                    {name: "state"},
                    {name: "total"},
                    {name: "complete"}
                ]
            }),
            groupField: "state",
            groupDir: "DESC",
            listeners: {
                load: function(store,records,o) {
                    store.groupBy('state');
                }
            }
        });

		this.parenttools = [
        	{id: 'refresh',
             handler: function() {getPipelineStatus()}
             }];

        clovr.ClovrPipelinesGrid.superclass.constructor.call(this, Ext.apply(config, {
//            title: 'Pipelines',
            store: jstore,
            autoExpandColumn: 'name',
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    width: 50,
                    sortable: true
                },
                columns: [
                    {id: 'name', header: 'Pipeline Name', dataIndex: 'pipeline_desc', renderer:
                    	function(value,p,record,ri,ci,store) {
                    		if(record.json.protocol) {
                                //console.log(record.json.config['pipeline.PIPELINE_TEMPLATE']);
                    			var track = clovr.PROTOCOL_TO_TRACK[record.json.protocol];
                    			var id = record.json.pipeline_id;
                    			return String.format("<div><img style='float:left' src='/clovr/images/{0}_icon_sml.png'/>Pipeline: {1}<br/>{2}</div>",track,id,value);
                    		}
                    		else {
                    			return value;
                    		}
                    	}
                    },
                    {id: 'status', header: 'Status', dataIndex: 'state', hidden: true},
                    {id: 'steps', header: 'Step', dataIndex: 'num_steps', renderer: 
                    function(value, p, record, ri, ci, store) {
						if(!store.pBars) {
							store.pBars = [];
						}
//						if(record.json.state =='running') {
//							console.log(record.json);
							pipeGrid.pBars[record.json.pipeline_name] = new Ext.ProgressBar({
							text: String.format("Steps {0}/{1} complete", record.json.num_complete,record.json.num_steps),
							value: record.json.num_complete/record.json.num_steps,
							listeners: {
								beforeshow: function(pb) {
									pb.updateProgress(pb.value);
								},
								resize: function(pb) {
									pb.updateProgress(pb.value);
								}
							}
							});
						return String.format("<div id='{0}_step'></div>",record.json.pipeline_name);
//						}
//						else {
//							return String.format("Steps {0}/{1} complete", record.json.complete,record.json.total);
//						}
					}    
				}
                ]
            }),
            listeners: {
            	afterrender: function() {
            		Ext.TaskMgr.start({
            			run: function() {getPipelineStatus()},
            			interval: 30000
        			});
//            		getPipelineStatus();
            	},
                rowclick: function(grid,index,e) {
                    clovr.pipelineWindow({
                        cluster_name: 'local',
                        pipeline_name: grid.store.getAt(index).json.pipeline_name
                    });
                }
            },
            view: new Ext.grid.GroupingView({
            	forceFit:true,
//            	startCollapsed: true,
            	groupTextTpl: '{text} ({[values.rs.length]} {[values.rs.length > 1 ? "Items" : "Item"]})',
            	listeners: {
            		refresh: function(view) {
            			for(name in pipeGrid.pBars) {
            				pipeGrid.pBars[name].render(name+"_step");
            				pipeGrid.pBars[name].updateProgress(pipeGrid.pBars[name].value);
            			}
            		}
            	}
        	})
//            tools: [
//                {id: 'refresh',
//                 handler: function() {getPipelineStatus()}
//                }]

        }));


        function getPipelineStatus() {
            // Making a request here to get the pipeline status(s).
            
            clovr.getPipelineList({
            	cluster_name: 'local',
            	callback: function(rdata) {
            	    var pipes = rdata;
                    var fields = [];
                    var cols = [];
                    var keys = [];
                    var pipes_to_load = [];
                    Ext.each(pipes, function(pipe) {
                        pipes_to_load.push(pipe);
                        for(key in pipe) {
                            if(key == 'files') {
                                pipe.fileCount = pipe[key].length;
                            }
                            if(!keys[key]) {
                                cols.push({'header': key, 'dataIndex': key});
                                fields.push({'name': key});
                            }
                            keys[key]=true;
                    }});
                    var data_to_load = {
                        'metaData': {
                            'fields': fields,
                            'sortInfo': {'field': 'pipeline_desc'},
                            'root': 'rows'
                        },
                        'rows': pipes
                    };
                    jstore.loadData(pipes_to_load);
                    jstore.filterBy(
                    	function(rec,id) {
                        	return rec.json.wrapper;
                    });
                }
            });
    	}
    }
});


Ext.reg('clovrpipelinesgrid', clovr.ClovrPipelinesGrid);
