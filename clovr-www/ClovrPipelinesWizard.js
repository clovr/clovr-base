 /*
 * A panel that contains all of the forms for the clovr protocols. In this case they can be 
 * organized like a wizard.
 */


clovr.ClovrPipelinesWizard = Ext.extend(Ext.Panel, {
    
    constructor: function(config) {
        var OTHER_PROTS = true; // Set this to true to show the other protocols dropdown
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
				'panel_xtype': 'clovr16spanel'
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
            },
            'clovr_comparative': {
                'panel_xtype': 'clovrcomparativepanel'
            }            
        };

        var protocol_to_track = clovr.PROTOCOL_TO_TRACK;
        var other_protocols = clovr.OTHER_PROTOCOLS;
        
        var prot_menu = new Ext.menu.Menu({});
        
        var prot_store = new Ext.data.JsonStore({
            fields: ['protocol'],
            filter: {
                fn: function(record) {
                    return !protocol_to_track[record.data.protocol];
                }
            },
            listeners: {
                load: function(store, records, o) {
                    store.filterBy(prot_store.filter.fn);
                }
            }
        });
        var prot_combo = new Ext.form.ComboBox({
            store: prot_store,
            displayField: 'protocol',
//            typeAhead: true,
            mode: 'local',
            triggerAction: 'all',
            emptyText: 'Select a protocol...',
//            selectOnFocus: true,
            submitValue: false,
//            forceSelection: true,
            editable: false,
            lastQuery: '',
//            allowBlank: false,
            width: 160,
            listeners: {
                select: function(cb,rec) {
                    var new_panel = new clovr.ClovrFormPanel({
                        id: 'foobar',
                        protocol: rec.json.protocol,
           	        	fields: rec.json.config,
               	        submitcallback: function() {
                            clovrpanel.getLayout().setActiveItem(0);
                            new_panel.destroy();
                        }
                    });
                    clovrpanel.add(new_panel);
                    new_panel.doLayout();
                    clovrpanel.getLayout().setActiveItem('foobar');
                }
            },    
            iconCls: 'no-icon'
        });  
            
        config.layout = 'card';
//        config.bodyStyle = {background: '#0d5685'};
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
            {text: '<div class="header_button_text">Microbe</div>',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_microbe_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_microbe');
             }
            },
            {text: '<div class="header_button_text">Comparative</div>',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_comparative_form');
             }
            },
            {text: '<div class="header_button_text">Search</div>',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_search_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_search');
             }
            },
            {text: '<div class="header_button_text">Metagenomics</div>',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_metagenomics_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_metagenomics');
             }
            },
            {text: '<div class="header_button_text">16S</div>',
             cls: 'x-btn-text-icon',
             iconAlign: 'left',
             icon: '/clovr/images/clovr_16s_icon_sml.png',
             handler: function() {
                 clovrpanel.getLayout().setActiveItem('clovr_16s');
             }
            }
            ];
            if(OTHER_PROTS) {
                config.tbar.push(('-',
                            {menu: prot_menu,
                             text: 'Other Protocols'
                            }));
          }
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
            height: 400,
            split: true
            //        collapsed: true,
            //        collapseMode: 'mini',
            //        margins: '0 5 0 0'
        });
/*    var taggrid = new clovr.TagGrid({
//        region: 'west',
//        pipelinePanel: pipepanel,
//        title: 'Data Sets',
//        width: 400,
        split: true,
//        margins: '0 5 0 0',
//        margins: '0 0 0 5',
//        pipelineWizard: pipepanel,
//        url: "/vappio/queryTag_ws.py"
//        host: hostname_field.getValue()
    });      
*/
/*        var gangliapanel = new clovr.ClovrGangliaPanel({
            id: 'wizard_ganglia_panel',
            collapsed: true
        });*/
        config.items = [
            {xtype: 'portal',
            bodyStyle: {
            	background: '#0d5685'
            },
            items: [
/*            	{columnWidth: .5,
                style:'padding:10px 5px 10px 10px',
                items: [{
					title: 'Datasets',
					tools: tools.concat(taggrid.parenttools),
					items: taggrid
				}
				]},*/
/*                      {
//                          title: 'Ganglia',
                          tools: tools,
                          name: 'ganglia_portlet',
                          plugins : [ new Ext.plugins.TDGi.PanelHeaderToolbar(gangliapanel.parenttools) ],
//                          height: 200,
                          items: gangliapanel
                      }
                 ]},*/
                 {columnWidth: 1,
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
	                var prot_menu_items = [];
	                Ext.each(pipelines, function(pipe) {
	                	configs_by_protocol[pipe.protocol] = pipe.config;
	                	if(!protocol_to_track[pipe.protocol] && clovr.OTHER_PROTOCOLS[pipe.protocol]) {
	                	    prot_menu_items.push({
                                text: pipe.protocol,
                                handler: function() {
                                    var new_panel = new clovr.ClovrFormPanel({
                                        id: 'foobar',
                                        protocol: pipe.protocol,
                           	        	fields: pipe.config,
                               	        submitcallback: function() {
                                            clovrpanel.getLayout().setActiveItem(0);
                                            new_panel.destroy();
                                        }
                                    });
                                    clovrpanel.add(new_panel);
                                    new_panel.doLayout();
                                    clovrpanel.getLayout().setActiveItem('foobar');
                                }
                            });
                        }
	                });
	                prot_menu_items.sort(function(a,b) {return (a.text > b.text) ? 1 : ((b.text > a.text) ? -1 : 0);});
	                prot_menu.add(prot_menu_items);
					for(track in track_to_panels) {
        	            if(!track_to_panels[track].panel) {
   	        	            clovrpanel.add({
       	        	            xtype: track_to_panels[track].panel_xtype,
//       	        	            style:'padding: 10px 10px 10px 5px',
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
                                       
