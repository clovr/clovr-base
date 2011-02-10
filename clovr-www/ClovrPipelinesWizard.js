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
                    'clovr_metagenomics_noorfs': 1,
                    'clovr_metagenomics_orfs': 1,
//                    'clovr_metatranscriptomics': 1,
//                    'clovr_total_metagenomics': 1
                },
                'panel_xtype': 'clovrmetapanel'
            },
            'clovr_16s': {
                'pipelines': {
                    'clovr_16S': 1
                },
                'panel': new Ext.TabPanel({
                    title: 'CloVR 16s',
                    activeTab: 0,
                    id: 'clovr_16s'
                })
            },
            'clovr_search': {
                'pipelines': {
                    'clovr_search': 1
                },
                'panel_xtype': 'clovrblastpanel'
            },
            'clovr_microbe': {
                'pipelines': {
                    'clovr_microbe_annotation': 1,
                    'clovr_microbe_illumina': 1,
                    'clovr_microbe454': 1
                },
                'panel_xtype': 'clovrmicrobepanel'
            }
        };

        var pipeline_to_protocol = clovr.PIPELINE_TO_PROTOCOL;
        
        config.layout = 'card';
        config.layoutConfig = {
            layoutOnCardChange: true
        };
        config.tbar = [
            {text: 'Home',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem(0);
             }
            }];
        config.items = [
            {id: 'home',
             frame: true,
             layout: 'vbox',
             layoutConfig: {
                 align : 'center',
                 pack: 'start'
             },
             width: '50%',
             items: [{
                 layout: 'table',
                 flex: 1,
                 defaults: {
                     style:'padding:15px 20px'
                 },
                 layoutConfig: {
                     columns: 2
                 },
                 items: [
                     {xtype: 'container',
                      items: [
                          {xtype: 'button',
                           height: '72px',
                           width: '96px',
                           scale: 'clovr',
                           tooltip: {text: 'Click here to run CloVR Metagenomics'},
                           tooltipType: 'title',
                           text: "<img src='/clovr/images/clovr_metagenomics_icon.png'>",
                           handler: function() {
                               clovrpanel.getLayout().setActiveItem('clovr_metagenomics');
                           }}
//                           {html: "Some shit form your shit"}
                     ]},
                     {xtype: 'container',
                      items: [
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
//                           {html: "Some shit form your shit"}
                     ]},
                     {xtype: 'container',
                      items: [
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
//                           {html: "BLAST"}
                     ]},
                     {xtype: 'container',
                      items: [
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
//                          {style: 'text-align: center',
//                           html: "<p>Bacterial assembly and annotation <a href='http://clovr.org/methods/clovr-microbe/'>Documentation</a></p>"}
                      ]}
                 ]}]},
            new clovr.ClovrDatasetPanel({
                'id': 'dataset',
                pipelineCallback: function(conf) {
                    clovrpanel.getLayout().setActiveItem(conf.pipeline_name);
                    
                    // HACK here to find a reference to the underlying form. 
                    // Should probably have an accessor as part of the surrounding panel.
                    if(clovrpanel.getLayout().activeItem.changeInputDataSet) {
                        clovrpanel.getLayout().activeItem.changeInputDataSet(conf);
                    }
                }
            })
        ];
        clovr.ClovrPipelinesWizard.superclass.constructor.call(clovrpanel,config);
        
        Ext.Ajax.request({
            url: '/vappio/listProtocols_ws.py',
            success: function(response) {
                var pipelines = clovrParsePipelines(Ext.util.JSON.decode(response.responseText).data);
                
                // HACK here. Couldn't get Ext.iterate to go over an associative array.
                // Not sure if there is a better solution to this.
//                for(var prop in pipelines) {
//                    if(pipelines.hasOwnProperty(prop)) {
                        // Need to map this pipeline to a protocol name.
                        // If we haven't seen this protocol before we'll create a new
                        // panel for it.
//                        if(pipeline_to_protocol[prop]) {
//                            var xtype = protocol_to_pipelines[pipeline_to_protocol[prop]].panel_xtype;
//                            if(!xtype){xtype = 'clovrformpanel'};
 //                           
 //                           protocol_to_pipelines[pipeline_to_protocol[prop]].panel.add(
 //                               {xtype: xtype,
  //                               fields: pipelines[prop].fields,
   //                              title: prop,
//                                 id: protocol_to_pipelines[pipeline_to_protocol[prop]].panel.getId() + '_form',
 //                                id: prop + '_form',
 //                                submitcallback: function() {
  //                                   clovrpanel.getLayout().setActiveItem(0);
  //                                   Ext.Msg.show({
  //                                       title: 'Success!',
  //                                       msg: 'Your pipeline was submitted successfully',
   //                                      buttons: Ext.Msg.OK
    //                                 });
     //                            }
      //                          });
       //                 }
        //            }
                    
                //            }
                for(var prot in protocol_to_pipelines) {
                    if(!protocol_to_pipelines[prot].panel) {
                        clovrpanel.add({
                            xtype: protocol_to_pipelines[prot].panel_xtype,
                            pipelines: pipelines,
                            submitcallback: function() {
                                clovrpanel.getLayout().setActiveItem(0);
                            }
                        });
                    }
                    else {
                        clovrpanel.add(protocol_to_pipelines[prot].panel);
                    }
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
        if(this.getLayout().activeItem.setInput) {
            this.getLayout().activeItem.setInput(input_tag);
        }
    }
    });

Ext.reg('clovrpipelineswizard', clovr.ClovrPipelinesWizard);
        
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
                    'type_params': pipe.config[i][1].type_params,
                    'visibility': pipe.config[i][1].visibility
                });
            }
            
            pipelineConfigs[n] = {'fields': c};
        }
    });
    return pipelineConfigs;
}
                                       
