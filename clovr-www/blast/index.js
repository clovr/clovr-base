/*
 * A portal for the CLoVR dashboard
 */
Ext.onReady(function(){
    Ext.QuickTips.init();    

    if(parent.location.hash) {
        
        retrieve_results(parent.location.hash);
    }

    var tools =[];
    Ext.Ajax.request({
        url: '/vappio/listProtocols_ws.py',
        success: function(response) {
            var pipelines = clovrParsePipelines(Ext.util.JSON.decode(response.responseText).data);
            var blast_form = new clovr.BlastClovrFormPanel({
                fields: pipelines['clovr_search_webfrontend'].fields,
                sampleData: [['testpeptides1'],['testpeptides2']],
                region: 'center'
            });
            var viewport = new Ext.Viewport({
                layout:'border',
                items:[
                    {region: 'north',
                     baseCls: 'dashboard_header',
                     height: 75,
                     html: '<div id="clovr-vm-header"><div id="clovr-vm-masthead"><h1><a href="http://clovr.org/" title="CloVR"><span>CloVR</span></a></h1></div></div>'
                    },
                    blast_form,
                    //            widgets,
                    //            taggrid,
                    //            pipepanel,
                    //            pipegrid
                ]
            });
            // HACK here. Couldn't get Ext.iterate to go over an associative array.
            // Not sure if there is a better solution to this.
        },
        failure: function(response) {
            Ext.Msg.show({
                title: 'Server Error',
                msg: response.responseText,
                icon: Ext.MessageBox.ERROR});
        }
        
    });
});

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
                    'visibility': pipe.config[i][1].visibility
                });
            }
            
            pipelineConfigs[n] = {'fields': c};
        }
    });
    return pipelineConfigs;
}
                                       


function retrieve_results(pipeline_name) {
    
}