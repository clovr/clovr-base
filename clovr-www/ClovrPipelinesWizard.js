 /*
 * A panel that contains all of the forms for the clovr protocols. In this case they can be 
 * organized like a wizard.
 */


clovr.ClovrPipelinesWizard = Ext.extend(Ext.Panel, {
    
    constructor: function(config) {
        var pipelines;

        
        var clovrpanel = this;

        /* This lookup is a HACK and should be replaced with the information in the meta-data 
         * returned from listProtocols.
         */
        var protocol_to_pipelines = {
            'clovr_metagenomics': {
                'pipelines': {
                    'clovr_metagenomics_noorf': 1,
                    'clovr_metagenomics_orf': 1,
                    'clovr_metatranscriptomics': 1,
                    'clovr_total_metagenomics': 1
                },
                'panel': new Ext.TabPanel({
                    title: 'CloVR Metagenomics',
                    activeTab: 0,
                    tbar: [
                        {text: 'home',
                         handler: function() {
                             clovrpanel.getLayout().setActiveItem(0);
                         }
                        }
                    ],
                    id: 'clovr_metagenomics'
                })
            },
            'clovr_16s': {
                'pipelines': {
                    'clover_16S': 1
                },
                'panel': new Ext.TabPanel({
                    title: 'CloVR 16s',
                    activeTab: 0,
                    tbar: [
                        {text: 'home',
                         handler: function() {
                             clovrpanel.getLayout().setActiveItem(0);
                         }
                        }
                    ],
                    id: 'clovr_16s'
                })
            },
            'clovr_search': {
                'pipelines': {
                    'clovr_search': 1
                },
                'panel_xtype': 'blastclovrformpanel',
                'panel': new Ext.Panel({
                    autoScroll: true,
//                    title: 'CloVR Search',
//                    activeTab: 0,
                    tbar: [
                        {text: 'home',
                         handler: function() {
                             clovrpanel.getLayout().setActiveItem(0);
                         }
                        }
                    ],
                    id: 'clovr_search'
                })
            },
            'clovr_microbe': {
                'pipelines': {
                    'clovr_microbe_annotation': 1,
                    'clovr_microbe454': 1
                },
                'panel': new Ext.TabPanel({
                    title: 'CloVR Microbe',
                    activeTab: 0,
                    tbar: [
                        {text: 'home',
                         handler: function() {
                             clovrpanel.getLayout().setActiveItem(0);
                         }
                        }
            ],
                    id: 'clovr_microbe'
                })
            }
        };
        
        var pipeline_to_protocol = {
            'clovr_metagenomics_noorf': 'clovr_metagenomics',
            'clovr_metagenomics_orf': 'clovr_metagenomics',
            'clovr_metatranscriptomics': 'clovr_metagenomics',
            'clovr_total_metagenomics':'clovr_metagenomics',
            'clovr_16S': 'clovr_16s',
            'clovr_search': 'clovr_search',
            'clovr_microbe_annotation': 'clovr_microbe',
            'clovr_microbe454': 'clovr_microbe'
        };
        
        config.layout = 'card';
        config.items = [
            {id: 'home',
             layout: 'table',
             layoutConfig: {
                 columns: 3
             },
             defaults: {
                 bodyStyle:'padding:15px 20px',
             },
             items: [
                 {items: 
                  {xtype: 'button',
                   text: 'CloVR Metagenomics',

                  handler: function() {
                      clovrpanel.getLayout().setActiveItem('clovr_metagenomics');
                  }}
                 },
                 {items: 
                  {xtype: 'button',
                   height: '72px',
                   width: '96px',
                   scale: 'clovr',
                   tooltip: {text: 'Click here to run 16s sequence data through the CloVR 16s pipeline'},
                   tooltipType: 'title',
                   text: "<img src='/clovr/images/clovr_16s_icon.png'>",
                  handler: function() {
                      clovrpanel.getLayout().setActiveItem('clovr_16s');
                  }}
                 },
                 {items: 
                  {xtype: 'button',
                   height: '72px',
                   width: '96px',
                   scale: 'clovr',
                   tooltipType: 'title',
                   tooltip: {text: 'Click here to do a blast search using CloVR'},
                   text: "<img src='/clovr/images/clovr_search_icon.png'>",
                   handler: function() {
                      clovrpanel.getLayout().setActiveItem('clovr_search');
                  }}
                 },
                 {items: 
                  {xtype: 'button',
                   height: '72px',
                   width: '96px',
                   scale: 'clovr',
                   tooltipType: 'title',
                   tooltip: {text: 'Click here to run microbial genome sequence through the CloVR microbial annotation'},
                   text: "<img src='/clovr/images/clovr_microbe_icon.png'>",
                  handler: function() {
                      clovrpanel.getLayout().setActiveItem('clovr_microbe');
                  }}
                 }
             ]}];
        clovr.ClovrPipelinePanel.superclass.constructor.call(clovrpanel,config);
        
        Ext.Ajax.request({
            url: '/vappio/listProtocols_ws.py',
            success: function(response) {
                var pipelines = clovrParsePipelines(Ext.util.JSON.decode(response.responseText).data);
                
                // HACK here. Couldn't get Ext.iterate to go over an associative array.
                // Not sure if there is a better solution to this.
                for(var prop in pipelines) {
                    if(pipelines.hasOwnProperty(prop)) {
                        // Need to map this pipeline to a protocol name.
                        // If we haven't seen this protocol before we'll create a new
                        // panel for it.
                        if(pipeline_to_protocol[prop]) {
                            var xtype =protocol_to_pipelines[pipeline_to_protocol[prop]].panel_xtype;
                            if(!xtype){xtype = 'clovrformpanel'};
                            protocol_to_pipelines[pipeline_to_protocol[prop]].panel.add(
                                {xtype: xtype,
                                 fields: pipelines[prop].fields,
                                 title: prop
                                });
                        }
                    }
                    
                }
                for(var prot in protocol_to_pipelines) {
                    clovrpanel.add(protocol_to_pipelines[prot].panel);
                }
                clovrpanel.getLayout().setActiveItem(0);
            },
            failure: function(response) {
                Ext.Msg.show({
                    title: 'Server Error',
                    msg: response.responseText,
                    icon: Ext.MessageBox.ERROR});
            }
            
        });
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
                    'visibility': pipe.config[i][1].visibility
                });
            }
            
            pipelineConfigs[n] = {'fields': c};
        }
    });
    return pipelineConfigs;
}
                                       
