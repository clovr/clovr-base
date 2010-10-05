 /*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrPipelinePanel = Ext.extend(Ext.TabPanel, {
    
    constructor: function(config) {
        var pipelines;
        if(config.host) {
            // Need to fill this in with code that will do a ScriptTagProxy to a host other than the
            // localhost.
        }
        else { 
            config.host = 'localhost';
        }
        var clovrpanel = this;
        clovr.ClovrPipelinePanel.superclass.constructor.call(clovrpanel,config);

        if(config.host == 'localhost') {
            Ext.Ajax.request({
                url: '/vappio/listPipelines_ws.py',
                success: function(response) {
                    var pipelines = clovrParsePipelines(Ext.util.JSON.decode(response.responseText)[1]);

                    // HACK here. Couldn't get Ext.iterate to go over an associative array.
                    // Not sure if there is a better solution to this.
                    for(var prop in pipelines) {
                        if(pipelines.hasOwnProperty(prop)) {
                            clovrpanel.add(new clovr.ClovrFormPanel({
                                fields: pipelines[prop].fields,
                                title: prop
                            }));
                        }
                        clovrpanel.setActiveTab(0);
                    }
                }
            });
        }
    },
    /*
    * Use this function to set the input field of a selected pipeline with the currently 
    * selected data sets.
    */
    setInput: function(input_tag) {
        this.getActiveTab().setInput(input_tag);
    }
});

Ext.reg('clovrpipelinepanel', clovr.ClovrPipelinePanel);
        
function clovrParsePipelines( r ) {
    var pipelineConfigs = new Array();

    Ext.each(r, function( pipe ) {
        
        var n = pipe.name;
        var c = new Array();
        if ( pipe.config != null ) {
            for ( i=0; i<pipe.config.length; i++ ) {
                c.push({
                    'field': pipe.config[i][0], 
                    'display': pipe.config[i][1].display,
                    'desc': pipe.config[i][1].desc,
                    'default': pipe.config[i][1]['default'],
                    'default_hidden': pipe.config[i][1].default_hidden
                });
            }
            
            pipelineConfigs[n] = {'fields': c};
        }
    });
    return pipelineConfigs;
}