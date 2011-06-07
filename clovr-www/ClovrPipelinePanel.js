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
        
        var master_container = new Ext.Container({
        	region: 'center',
        	style: {
        		padding: '3px'
        	}
        });
        var input_grid = new Ext.grid.GridPanel({
            
        });
        
        var parameters_grid = new Ext.grid.GridPanel({
            
        });
        
        var output_grid = new Ext.grid.GridPanel({
            
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
                for(param in data.config) {
                    for(type in value_classes) {
                        if(value_classes[type].regex.match(param)) {
                            value_classes[type].values.push(value_classes[data.config[param]]);
                        }
                    }
                }
            }
        });
        config.layout = 'border';
        config.bodyStyle = {
            background: '#0D5685'
        };
        config.items = [title,master_container];
        clovr.ClovrPipelinePanel.superclass.constructor.call(clovrpanel,config);
    }
});

Ext.reg('clovrpipelinepanel', clovr.ClovrPipelinePanel);