 /*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrPipelinePanel = Ext.extend(Ext.Panel, {
    
    constructor: function(config) {

        var clovrpanel = this;

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
        
        clovr.ClovrPipelinePanel.superclass.constructor.call(clovrpanel,config);
    }
});

Ext.reg('clovrpipelinepanel', clovr.ClovrPipelinePanel);