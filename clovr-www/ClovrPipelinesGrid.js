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
                    {id: 'name', header: 'Pipeline Name', dataIndex: 'name'},
                    {id: 'status', header: 'Status', dataIndex: 'state', hidden: true},
                    {id: 'steps', header: 'Step', dataIndex: 'total', renderer: 
                    function(value, p, record, ri, ci, store) {
						if(!store.pBars) {
							store.pBars = [];
						}
						console.log(record.json);
//						if(record.json.state =='running') {
							pipeGrid.pBars[record.json.name] = new Ext.ProgressBar({
							text: String.format("Steps {0}/{1} complete", record.json.complete,record.json.total),
							value: record.json.complete/record.json.total,
							listeners: {
								beforeshow: function(pb) {
									pb.updateProgress(pb.value);
								}
							}
							});
							console.log(record.json.complete/record.json.total);
							return String.format("<div id='{0}_step'></div>",record.json.name);
//						}
//						else {
//							return String.format("Steps {0}/{1} complete", record.json.complete,record.json.total);
//						}
					}    
				}
                ]
            }),
            view: new Ext.grid.GroupingView({
            	forceFit:true,
//            	startCollapsed: true,
            	groupTextTpl: '{text} ({[values.rs.length]} {[values.rs.length > 1 ? "Items" : "Item"]})',
            	listeners: {
            		refresh: function(view) {
            			for(name in pipeGrid.pBars) {
            				console.log(view);
            				console.log(name);
            				pipeGrid.pBars[name].render(name+"_step");
            				pipeGrid.pBars[name].updateProgress(pipeGrid.pBars[name].value);
            				console.log(pipeGrid.pBars[name]);
            			}
            			console.log('here with a refresh');
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
            Ext.Ajax.request({
                url: '/vappio/pipelineStatus_ws.py',
                params: {request: Ext.util.JSON.encode({name: 'local',pipelines: []})},
                success: function(response) {
                    var pipes = Ext.util.JSON.decode(response.responseText).data;
                    var fields = [];
                    var cols = [];
                    var keys = [];
                    var pipes_to_load = [];
                    Ext.each(pipes, function(elm) {
                        var pipe = elm[1];
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
                            'sortInfo': {'field': 'name'},
                            'root': 'rows'
                        },
                        'rows': pipes};
                    jstore.loadData(pipes_to_load);
                    //                    taggrid.reconfigure(jstore,new Ext.grid.ColumnModel(cols));
                    
                },
                failure: function(response) {
                    Ext.Msg.show({
                    title: 'Server Error',
                        msg: response.responseText,
                        icon: Ext.MessageBox.ERROR});
                }
                
            });
        }
        getPipelineStatus();
    }
});


Ext.reg('clovrpipelinesgrid', clovr.ClovrPipelinesGrid);
