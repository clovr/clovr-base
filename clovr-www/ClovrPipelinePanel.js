 /*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrPipelinePanel = Ext.extend(Ext.Panel, {
    
    constructor: function(config) {

        var clovrpanel = this;

        var title = new Ext.Container({
            height: 30,
            style: {
                'padding': '3px 0 0 5px',
                'font-size': '16pt',
                'font-family': 'Trebuchet MS,helvetica,sans-serif',
                'background': 'url("/clovr/images/clovr-vm-header-bg-short.png") repeat-x scroll center top'
            },
            region: 'north',
            html: config.criteria.pipeline_name+' pipeline'
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
            	
            	// First we'll deal with the input tags
            	var input_data = [];
            	Ext.each(pipe.input_tags, function(tag) {
            		input_data.push([tag]);
            	});
            	input_grid.getStore().loadData(input_data);
            	
                for(param in pipe.config) {
                    for(type in value_classes) {
                        if(param.match(value_classes[type].regex)) {
                            value_classes[type].values.push({
                            	key: param,
                            	value: pipe.config[param]});
                        }
                    }
                }
                parameters_grid.getStore().loadData(value_classes.params.values);
                
                var output_data = [];
                Ext.each(pipe.output_tags, function(tag) {
                	output_data.push(["<a href='/output/"+tag+".tar.gz'>"+tag+"</a>"]);
                });
                output_grid.getStore().loadData(output_data);
            }
        });
        config.layout = 'border';
        config.bodyStyle = {
            background: '#0D5685'
        };
        var master_container = new Ext.TabPanel({
        	region: 'center',
//        	layout: '',
        	style: {
        		padding: '3px'
        	},
        	activeTab: 0,
        	items: [input_grid,parameters_grid,output_grid]
        });
        
        config.items = [title,master_container];
        clovr.ClovrPipelinePanel.superclass.constructor.call(clovrpanel,config);
    }
});

Ext.reg('clovrpipelinepanel', clovr.ClovrPipelinePanel);