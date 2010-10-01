/*
 * A portal for the CLoVR dashboard
 */
Ext.onReady(function(){
    
    
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
                    console.log(o);
                }}
            },
    });
    // This is the host that we're going to pull data from

    var pipelines = new Ext.data.Store({
//        proxy: proxy,
    });
    var viewport = new Ext.Viewport({
        layout:'border',
        items:[{
            region: 'north',
            baseCls: 'dashboard_header',
            height: 100,
            html: "<div class=header_adapter><a class='clovr_logo' title='CloVR' href='http://clovr.org'></a></div>",
            bbar: [{layout: 'form',
                    xtype: 'container',
                    labelWidth: 30,
                    style: 'padding-top: 5px',
                    items:[hostname_field]
                   }]
        },
        {
                region: 'south',
                height: 150,
                xtype: 'portal',
            collapsible: true,
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
                    {
                    columnWidth: 0.33,
                    style:'padding:10px 0 10px 10px',
                    items:[{
                        title: 'Smaller element1',
                        layout: 'fit',
                        tools: tools,
                        html: 'bogus markup'
                    }]},
                    {
                    columnWidth: 0.33,
                    style:'padding:10px 0 10px 10px',
                    items:[{ 
                        title: 'Smaller element2',
                        layout: 'fit',
                        tools: tools,
                        html: 'bogus markup'
                    }
                          ]}
                ]
        },
               new clovr.TagGrid({
                   region: 'west',
                   title: 'Data Sets',
                   collapsible: true,
                   width: 200,
                   split: true,
//                   url: hostname + "/vappio/queryTag_ws.py"
               }),
               new clovr.ClovrPipelinePanel({
                   host: hostname_field.getValue(),
                   region: 'center',
               })
          ]
    });
});