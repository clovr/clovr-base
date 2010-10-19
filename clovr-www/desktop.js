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

    // Panel to house the pipeline configurations.
    var pipepanel = new clovr.ClovrPipelinePanel({
        host: hostname_field.getValue(),
//        collapseMode: 'mini',
        header: true,
        enableTabScroll: true,
        width: 400,
        split: true,
        margins: '0 5 0 0',
//        region: 'east',
        title: 'Configure Analysis'
    });
    var pipeWindow = new Ext.Window({
        items: [pipepanel],
        title: 'Protocols',
        layout: 'fit',
        height: 300,
        width: 350,
        x: 10,
        y: 20,
        autoShow: true
    });

    // Grid to store tagged data sets.
    var taggrid = new clovr.TagGrid({
//        region: 'center',
        pipelinePanel: pipepanel,


        url: "/vappio/queryTag_ws.py",
        host: hostname_field.getValue()
    });

    var tagWindow = new Ext.Window({
        title: 'Data Sets',
        layout: 'fit',
        items: [taggrid],
        height: 300,
        width: 300,
        x: 0,
        y: 0,
        autoShow: true
    });

    // Grid with running/complete pipelines in it
    var pipegrid = new clovr.ClovrPipelinesGrid({
//        region: 'west',

        header: true,
//        split: true,
        collapseMode: 'mini',
        margins: '0 0 0 5',
    });

    var pipegridWindow = new Ext.Window({
        items: [pipegrid],
        title: 'Pipelines',
        layout: 'fit',
        height: 300,
        width: 300,
        x: 20,
        y: 40,
        autoShow: true
    });


    // Panel with ganglia info in it.
    var gangliaPanel = new clovr.ClovrGangliaPanel({});
    
    var gangliaWindow = new Ext.Window({
        items: [gangliaPanel],
        title: 'Cluster Load',
        layout: 'fit',
        height: 200,
        width: 400,
        x: 30,
        y: 60,
        autoShow: true
    });

    // Panel with ganglia info in it.
    var pipelineWizard = new clovr.ClovrPipelinesWizard({});
    
    var wizardWindow = new Ext.Window({
        items: [pipelineWizard],
        title: 'PipelineWizard',
        layout: 'fit',
        height: 400,
        width: 500,
        autoScroll: true,
        x: 50,
        y: 90,
        autoShow: true
    });
    var viewport = new Ext.Viewport({
        layout:'border',
        items:[
            {region: 'north',
             baseCls: 'dashboard_header',
             height: 75,
             html: "<div class=header_adapter><a class='clovr_logo' title='CloVR' href='http://clovr.org'></a></div>",
             bbar: [{layout: 'form',
                     xtype: 'container',
                     labelWidth: 30,
                     style: 'padding-top: 5px;padding-left: 5px;',
                     items:[hostname_field]
                    }]
            },
            {title: 'CloVR Widgets',
             region: 'south',
             height: 150,
             xtype: 'portal',
             collapseMode: 'mini',
             collapsed: true,
             split: true,
             items: [{
                 columnWidth: 0.33,
                 style:'padding:10px 0 10px 10px',
                 items:[{
                     title: 'Large element',
                     layout: 'fit',
                     colspan:"2",
                     tools: tools,
                     html: 'bogus markup'
                 }]},
                     {columnWidth: 0.33,
                      style:'padding:10px 0 10px 10px',
                      items:[{
                          title: 'Smaller element1',
                          layout: 'fit',
                          tools: tools,
                          html: 'bogus markup'
                      }]},
                     {columnWidth: 0.33,
                      style:'padding:10px 0 10px 10px',
                      items:[{ 
                          title: 'Smaller element2',
                          layout: 'fit',
                          tools: tools,
                          html: 'bogus markup'
                      }]}
                    ]},
            {region: 'center',
             layout: 'absolute',
             frame: true,
             items: [
                 tagWindow,
                 pipeWindow,
                 pipegridWindow,
                 gangliaWindow,
                 wizardWindow
             ]}
        ]
    });

    tagWindow.show();
    pipeWindow.show();
    pipegridWindow.show();
    gangliaWindow.show();
    wizardWindow.show();
});
