/*
 * A portal for the CLoVR dashboard
 */
Ext.onReady(function(){
    Ext.QuickTips.init();    
    
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

    var hostname_field = new Ext.form.TextField({
        width: 150,
        value: 'localhost',
        id: 'hostname',
        fieldLabel: 'Host',
    });
    var proxy = new Ext.data.ScriptTagProxy({
//            url: hostname+'/vappio/listPipelines_ws.py',
            listeners: {
                load: {scope:this, fn:function(s, o, opts) {
                }}
            },
    });
    // This is the host that we're going to pull data from

    var pipelines = new Ext.data.Store({
//        proxy: proxy,
    });

    // Panel to house the pipeline configurations.
    var pipepanel = new clovr.ClovrPipelinesWizard({
//        host: hostname_field.getValue(),
        collapseMode: 'mini',
        header: true,
        enableTabScroll: true,
//        width: 400,
//        split: true,
//        margins: '0 5 0 0',
        region: 'center',
//        title: 'Dashboard'
    });
    

    // Grid to store tagged data sets.
    var taggrid = new clovr.TagGrid({
//        region: 'west',
        pipelinePanel: pipepanel,
        title: 'Data Sets',
//        width: 400,
        split: true,
//        margins: '0 5 0 0',
//        margins: '0 0 0 5',
        pipelineWizard: pipepanel,
        url: "/vappio/queryTag_ws.py"
//        host: hostname_field.getValue()
    });

    var credgrid = new clovr.ClovrCredentialGrid({
        title: 'Credentials'
    });

    var westpanel = new Ext.TabPanel({
        region: 'west',
        collapseMode: 'mini',
        defaults: {
            frame: true
        },
        activeTab: 0,
        split: true,
        width: 400,
//        margins: '0 0 0 5',
        items: [
            taggrid,
            credgrid
        ]
    });
    // Grid with running/complete pipelines in it
    var pipegrid = new clovr.ClovrPipelinesGrid({
//        height: 200,
        split: true,
//        collapsed: true,
//        collapseMode: 'mini',
//        margins: '0 5 0 0'
    });


    var viewport = new Ext.Viewport({
        layout:'border',
        items:[
            {region: 'north',
             baseCls: 'dashboard_header',
             height: 75,
             html: '<div id="clovr-vm-header"><div id="clovr-vm-masthead"><h1><a href="/clovr" title="CloVR"><span>CloVR</span></a></h1></div></div>'


//<div class=header_adapter><a class='clovr_logo' title='CloVR' href='http://clovr.org'></a></div>"
/*             bbar: [{layout: 'form',
                     xtype: 'container',
                     labelWidth: 30,
                     style: 'padding-top: 5px;padding-left: 5px;',
                     items:[hostname_field]
                    }]*/
            },
/*            {title: 'CloVR Widgets',
             region: 'south',
             height: 300,
             xtype: 'portal',
             collapseMode: 'mini',
             collapsed: true,
             split: true,
             items: [{
                 columnWidth: 0.33,
                 style:'padding:10px 0 10px 10px',
                 items:[{title: 'Ganglia',
                         tools: tools,
                         items: [new clovr.ClovrGangliaPanel({})]},
                 ]},
                     {columnWidth: 0.33,
                      style:'padding:10px 0 10px 10px',
                      items:[{
                          title: 'Pipelines',
                          layout: 'fit',
                          tools: tools.concat(pipegrid.parenttools),
                          items: pipegrid
                      }]},
                     {columnWidth: 0.33,
                      style:'padding:10px 0 10px 10px',
                      items:[{ 
                          title: 'Smaller element2',
                          layout: 'fit',
                          tools: tools,
                          html: 'bogus markup'
                      }]}
                    ]},*/
            westpanel,
            pipepanel
        ]
    });
});
