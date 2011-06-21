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
        var track_to_panels = {
            'clovr_metagenomics': {
                'panel_xtype': 'clovrmetapanel'
            },
            'clovr_16s': {
				'panel_xtype': 'clovr16spanel',
//                'panel': new Ext.TabPanel({
//                    title: 'CloVR 16s',
//                    activeTab: 0,
//                    id: 'clovr_16s'
//                })
            },
            'clovr_search': {
                'panel_xtype': 'clovrblastpanel'
            },
            'clovr_microbe': {
                'panel_xtype': 'clovrmicrobepanel'
            }
        };

        var protocol_to_track = clovr.PROTOCOL_TO_TRACK;
        
        config.layout = 'card';
        config.layoutConfig = {
            layoutOnCardChange: true
        };
        config.tbar = [
            {text: 'Home',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem(0);
             }
            },
            '-',
            'Click to configure a pipeline:',
            {text: 'CLoVR Microbe',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_microbe_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_microbe');
             }
            },
            {text: 'CLoVR Search',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_search_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_search');
             }
            },
            {text: 'CLoVR Metagenomics',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_metagenomics_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_metagenomics');
             }
            },
            {text: 'CLoVR 16s',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_16s_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_16s');
             }
            }
            ];
        // Stuff that will go in the header of each portal.
        var tools = [{
            id:'gear',
            handler: function(e, target, panel){
                // Need to implement a settings panel.
            }
        },{
            id:'close',
            handler: function(e, target, panel){
                panel.ownerCt.remove(panel, true);
            }
        }];
        
        // Grid with running/complete pipelines in it
        var pipegrid = new clovr.ClovrPipelinesGrid({
            height: 300,
            split: true
            //        collapsed: true,
            //        collapseMode: 'mini',
            //        margins: '0 5 0 0'
        });
        
        var gangliapanel = new clovr.ClovrGangliaPanel({
            id: 'wizard_ganglia_panel'
        });
        config.items = [
            {xtype: 'portal',
            bodyStyle: {
            	background: '#0d5685'
            },
             items: [
                 {columnWidth: .5,
                  style:'padding:10px 5px 10px 10px',
                  items: [
                      {
//                          title: 'Ganglia',
                          tools: tools,
                          name: 'ganglia_portlet',
                          plugins : [ new Ext.plugins.TDGi.PanelHeaderToolbar(gangliapanel.parenttools) ],
//                          height: 200,
                          items: gangliapanel
                      }
                 ]},
                 {columnWidth: .5,
                  style:'padding: 10px 10px 10px 5px',
                  items: [{
                      title: 'Pipelines',
                      layout: 'fit',
                      tools: tools.concat(pipegrid.parenttools),
                      items: pipegrid
                  }]}
             ]},
            new clovr.ClovrDatasetPanel({
                'id': 'dataset',
                parentPanel: clovrpanel,
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
                   
                   var fooo= [
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
/*            new clovr.ClovrDatasetPanel({
                'id': 'dataset',
                pipelineCallback: function(conf) {
                    clovrpanel.getLayout().setActiveItem(conf.pipeline_name);
                    
                    // HACK here to find a reference to the underlying form. 
                    // Should probably have an accessor as part of the surrounding panel.
                    if(clovrpanel.getLayout().activeItem.changeInputDataSet) {
                        clovrpanel.getLayout().activeItem.changeInputDataSet(conf);
                    }
                }
            })*/
        ];
        clovr.ClovrPipelinesWizard.superclass.constructor.call(clovrpanel,config);
        
        Ext.Ajax.request({
            url: '/vappio/protocol_list',
            params: {
            	request: Ext.util.JSON.encode({
            		'cluster': 'local',
            		'detail': true
            	})
            },
            success: function(response) {
            	var rdata = Ext.util.JSON.decode(response.responseText);
            	if(rdata.success) {
	                var pipelines = rdata.data;
	                var configs_by_protocol = [];
	                Ext.each(pipelines, function(pipe) {
	                	configs_by_protocol[pipe.protocol] = pipe.config;
	                });
					for(track in track_to_panels) {
        	            if(!track_to_panels[track].panel) {
   	        	            clovrpanel.add({
       	        	            xtype: track_to_panels[track].panel_xtype,
           	        	        pipelines: configs_by_protocol,
               	        	    submitcallback: function() {
                   	        	    clovrpanel.getLayout().setActiveItem(0);
                    	        }
   	                    	});
        	            }
   	        	        else {
       	        	        clovrpanel.add(track_to_protocols[track].panel);
           	        	}
           	        }
	            }
	            else {
	                Ext.Msg.show({
    	                title: 'Error getting protocol information',
        	            msg: rdata.data.msg,
            	        icon: Ext.MessageBox.ERROR});
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
                                       
