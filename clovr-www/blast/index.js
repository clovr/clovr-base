/*
 * A portal for the CLoVR dashboard
 */
Ext.onReady(function(){
    Ext.QuickTips.init();    

    var hashstring = document.location.hash;
    var center_region = new Ext.Container({
//        style: {padding-left: '10%',padding-right: '10%'},
        region: 'center',
        layout: 'card'
    });
    var viewport = new Ext.Viewport({
        layout:'border',
        items:[
            {region: 'north',
             baseCls: 'dashboard_header',
             height: 75,
             html: '<div id="clovr-vm-header"><div id="clovr-vm-masthead"><h1><a href="http://clovr.org/" title="CloVR"><span>CloVR</span></a></h1></div></div>'
            },
            center_region
            
        ]
    });
    
    if(hashstring) {
        var pipedata = Ext.urlDecode(hashstring.replace(/^#/, ''));
        makeBlastOutput(pipedata,center_region);
    }
    else {
        makeBlastForm(center_region);
    }

    var tools =[];

});

function makeBlastOutput(pipeData, cont) {
    var outputPanel = new clovr.BlastOutputPanel({
        'pipeData': pipeData});

    cont.add(outputPanel);
    cont.getLayout().setActiveItem(outputPanel);
}

function makeBlastForm(cont) {
    Ext.Ajax.request({
        url: '/vappio/listProtocols_ws.py',
        success: function(response) {
            var pipelines = clovrParsePipelines(Ext.util.JSON.decode(response.responseText).data);
            var blast_form = new clovr.BlastClovrFormPanel({
                fields: pipelines['clovr_search_webfrontend'].fields,
                sampleData: [['Example_B_subtilis_168_Proteins']],
                region: 'center'
            });
            cont.add(blast_form);
            cont.getLayout().setActiveItem(blast_form);
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
}

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
