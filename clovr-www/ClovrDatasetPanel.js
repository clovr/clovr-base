/*
 * A panel to display information about a particular tag 
 * and run an analysis on that tag if applicable. 
 */
Ext.ns('clovr');
clovr.ClovrDatasetPanel = Ext.extend(Ext.TabPanel, {

    constructor: function(config) {
        
        var datasetpanel = this;
        

//        config.layout='border';
        config.frame= true;
        config.autoScroll=true;
        config.deferredRender=false;
        var header_panel = new Ext.Panel({
            region: 'north',
            html: '<div><h3>Information for the '+config.dataset_name+' dataset</h3></div>'
        });
        var footer_panel = new Ext.Panel({
            region: 'south'
        });

        var pipelines_panel = new Ext.Panel({
            id: 'pipelines_panel',
            autoHeight: true,
            autoScroll: true,
            region: 'center',
            layout: 'anchor',
//            layoutConfig: {
//                align: 'stretch'
//                pack: 'start'
//            }
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
            deferredRender:false,
            title: 'Pipelines',
            frame: true,
            items: [header_panel,pipelines_panel,footer_panel],
        });
		
		var metadata_grid = new Ext.grid.EditorGridPanel({
			frame: true,
			title: 'metadata',
			buttonAlign: 'center',
			colModel: new Ext.grid.ColumnModel({
				defaults: {
					sortable: true
				},
				columns: [
					{header: 'key', dataIndex: 'name', width: 250, editor: new Ext.form.TextField()},
					{id: 'value', header: 'value', dataIndex: 'value', editor: new Ext.form.TextField()}
				]
			}),
			autoExpandColumn: 'value',
			store: new Ext.data.Store({
				reader: new Ext.data.JsonReader({
					fields: ['name','value']
				})
			}),
			buttons: [{
				text: 'Submit Changes',
				handler: function() {
					var recs = metadata_grid.getStore().getModifiedRecords();
					var new_params = [];
					console.log(recs)
					Ext.each(recs, function(rec) {
						var newval = {};
						newval[rec.data.name] = rec.data.value;
//						console.log(newval);
						new_params.push(newval);
					});
					console.log(new_params);
					clovr.tagData({
						params: {
							name: 'local',
							tag_name: datasetpanel.dataset_name,
							tag_metadata: new_params,
							append: true
						},
						callback: function(r,o) {
							var data = Ext.util.JSON.decode(r.responseText);
							console.log(data);
							if(r.success) {
								Ext.Msg.show({
									title: 'Metadata updated successfully',
									msg: 'You successfully updated the metadata'
								});
							}
							else {
								console.log(r);
								Ext.Msg.show({
									title: 'Failed to update metadata',
									msg: data.data.msg,
									icon: Ext.MessageBox.ERROR
								});
							}
						}
					});
				}
			},
			{
            text: 'Add Value',
            handler : function(){
                // access the Record constructor through the grid's store
                var rec = metadata_grid.getStore().recordType;
                var p = new rec({
                    name: 'Key',
                    value: 'value',
                });
                metadata_grid.stopEditing();
                metadata_grid.getStore().insert(0, p);
                metadata_grid.startEditing(0, 0);
            }
        }]
		});


        config.listeners ={
            render: function() {
                    if(config.dataset_name) {
                        datasetpanel.loadDataset(config);
                    }
            }};
        config.items = [pipelines_container,metadata_grid];
        datasetpanel.metagrid = metadata_grid;
        datasetpanel.header_panel = header_panel;
        datasetpanel.footer_panel = footer_panel;
        datasetpanel.pipelines_panel = pipelines_panel;
        datasetpanel.pipelines_container = pipelines_container;
        datasetpanel.pipelines_wrapper = pipelines_wrapper;
        datasetpanel.pipelineCallback = config.pipeline_callback;

        clovr.ClovrFormPanel.superclass.constructor.call(this,config);



    },
    
    loadDataset: function(config) {
        var datasetpanel = this;
        datasetpanel.header_panel.update('Information for the '+config.dataset_name+' dataset');
        datasetpanel.pipelines_panel.removeAll();
        datasetpanel.getEl().mask('Loading...','x-mask-loading');
        datasetpanel.dataset_name = config.dataset_name;
        clovr.getDatasetInfo({
        	dataset_name: config.dataset_name,
        	callback: function(d) {
        		var fields_to_load = [];
        		for(key in d.data[0]) {
        			// Total HACK here
        			if(key.match(/metadata./)) {
						fields_to_load.push({
							'name': key.replace(/metadata./,""),
							'value': d.data[0][key]
						});
					}
				}
	        	datasetpanel.metagrid.getStore().loadData(fields_to_load);
        	}
    	});
    	
        clovr.getPipelineInfo({
            callback: function(r) {
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
                datasetpanel.setActiveTab(0);
				datasetpanel.doLayout();
                datasetpanel.getEl().unmask();
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
    var inputs = [];
    for (field in record.json.config) {
        if(input_regexp.exec(field)) {
            inputs.push(field.replace(clean_input,"")+": "+ record.json.config[field]);
        }
    };

    if(record.data.state == "error") {
        return_string="Failed Pipeline "+ record.json.config['input.PIPELINE_NAME'];
    }
    else {
        return_string = "<div>"+inputs.join("<br/>")+"</div>";

//        return_string = String.format('output: {0}',record.data["output.TAGS_TO_DOWNLOAD"]);
    }
    return return_string;
}

function renderOutput(value, p, record) {
    var return_string="";
    var input_regexp = /^input/;
    var clean_input = /input\./;
    var tags = record.json.config["output.TAGS_TO_DOWNLOAD"].split(',');
    var outputs = [];
    Ext.each(tags, function(tag) {
        outputs.push("<a href='/output/"+record.json.config['input.PIPELINE_NAME']+"_"+
                     tag+".tar.gz'>"+tag+"</a>");
    });
//    if(Ext.isArray(record.json.config["output.TAGS_TO_DOWNLOAD"])) {
//        outputs = record.json.config["output.TAGS_TO_DOWNLOAD"];
//    }
    
    if(record.data.state == "error") {
        return_string="Failed Pipeline "+ record.json.config['input.PIPELINE_NAME'];
    }
    else if(record.data.state != "complete") {
        return_string="Pipeline not complete";
    }
    else {
        return_string = "<div>"+outputs.join("<br/>")+"</div>";
    }
    return return_string;
}