 /*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrPipelinePanel = Ext.extend(Ext.TabPanel, {
    
    constructor: function(config) {
        var pipelines;
        if(config.host) {
            console.log(config.host);
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
                            var itemsArray = [];
                            Ext.each(pipelines[prop].fields, function(field, i, props) {
                                itemsArray.push(
                                    {
                                        hidden: field.default_hidden,
                                        fieldLabel: field.display,
                                        name: field.field,
                                        value: field['default']
                                    });
                                });
                            clovrpanel.add(new Ext.form.FormPanel({
                                defaultType: 'textfield',
                                autoScroll: true,
//                                layout: 'anchor',
                                title: prop,
                                items: itemsArray,
                                frame: true,
                                buttons: [{text: 'Submit'}]}));
                        }
                    }
                    clovrpanel.setActiveTab(0);
                }
            })}
    }
});

Ext.reg('clovrpipelinepanel', clovr.ClovrPipelinePanel);
        
function clovrParsePipelines( r ) {
    var pipelineConfigs = new Array();

    Ext.each(r, function( pipe ) {
        
        var n = pipe.name;
        console.log(n);
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