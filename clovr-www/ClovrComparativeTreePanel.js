/*
 * A panel used to select genomes from a taxonomy.
 */
Ext.ns('clovr');

clovr.ClovrComparativeTreePanel = Ext.extend(Ext.Panel, {
    constructor: function(config) {
        var container = this;
//          var URL = 'http://driley-lx.igs.umaryland.edu:8080/cgi-bin/clovr_comparative/cgi-bin/';
        var URL = 'http://cb2.igs.umaryland.edu/cgi-bin/clovr_comparative/cgi-bin/';
        var treeLoader;
        var treeStore;
        var searchStore;
        var gridStore;
        // Config for the tree panel.
        var treepanel;
        var treepanelconf = {
            region : 'west',
            title : 'RefSeq Taxonomy',
            width : 300,
            autoScroll : true,
            collapsible : true,
            split : true,
            frame: false,
            defaults: {frame: false},
            useArrows : true,
                        ddGroup: 'gridDrop',
                        dropConfig: {
                            appendOnly: true
                        },
                        enableDD: true,
            root : new Ext.tree.AsyncTreeNode({
                text : 'Root Node',
                id : '/'
            }),
            listeners: {
                load: function() {
                    treepanel.getRootNode().expand();
                    treepanel.getRootNode().firstChild.expand();
                    treepanel.getRootNode().firstChild.expandChildNodes(false);
                }
            },
            rootVisible : false
        };
        
        if(config.local_data_url) {
            // Create a store for the tree.
            treeLoader = new Ext.tree.TreeLoader({ 
                dataUrl: '../cgi-bin/NcbiJsonSender.cgi'
            });
            treeStore = new Ext.data.JsonStore({
                url : '../cgi-bin/SendGridJson.cgi',
                root : 'info',
                fields : ['orgName', 'refseqId', {
                    name : 'seqLen',
                    type : 'int'
                }]
            });
            
            // Create a store for the search combobox
            searchStore = new Ext.data.ArrayStore({
                url : '../cgi-bin/GetLineage.cgi',
                id : 0,
                fields : ['nodeName']
            });
            gridStore = new Ext.data.JsonStore({
                root: 'info',
                fields: ['orgName', 'refseqId', {
                    name : 'seqLen',
                    type : 'int'
                }],
                url: '../SendGridJson.cgi'
            }); 
        // If we are going to use a remote data source we'll go in here.
        }
        else {

            if(config.remote_data_url) {
                URL = config.remote_data_url;
            }
            // Below is a version of the tree loader that uses ScriptTagProxy instead of a normal http request.
            treeLoader = new Ext.tree.TreeLoader({
                directFn:function(nodeId,callback){
                    var tree = treepanel;//Ext.getCmp('tree-container');
                    container.getEl().mask('Loading Taxonomic Tree...', 'x-mask-loading');

                    // Create a store to read in the results from the proxy.
                    var store = new Ext.data.JsonStore({
                        autoLoad: false,
                        fields: ['id','text','children'],
                        proxy: new Ext.data.ScriptTagProxy({
                            url: URL+'/NcbiJsonSender.cgi'
                        })
                    });

                    store.load({
                        callback: function() {
                            var response = [];
                            // Like to find a better way to do this.
                            for(i=0;i<store.data.items.length;i++){
                                response.push(store.data.items[i].data);
                            }
                            callback(response, {status:true});
                            container.getEl().unmask();
                         },
                         params: {node:nodeId}
                   });
                }
            });
            treeStore = new Ext.data.JsonStore({
                root: 'info',
                autoLoad: false,
                fields: ['orgName', 'refseqId', {
                            name : 'seqLen',
                            type : 'int'
                    }],
                proxy: new Ext.data.ScriptTagProxy({
                    url: URL+'/SendGridJson.cgi'
                })
            });
            
            // Below is a version of the tree store that uses ScriptTagProxy instead of a normal http request.
            searchStore =  new Ext.data.ArrayStore({
                proxy: new Ext.data.ScriptTagProxy({
                    url : URL+'/GetLineage.cgi'
                }),
                id : 0,
                fields : ['nodeName']
            }); 
            gridStore = new Ext.data.JsonStore({
                root: 'info',
                idProperty: 'refseqId',
                fields: ['orgName', 'refseqId', {
                    name : 'seqLen',
                    type : 'int'
                }],
                proxy: new Ext.data.ScriptTagProxy({
                    url: URL+'/SendGridJson.cgi',
                    listeners: {'load' : function(proxy,obj,opts) {
//                              console.log(obj.info);
//                              gridStore.loadData(obj.info,true);
//                              return false;
                        }}
                })
            }); 
        }
        
        // Need to setup some beforeload stuffs.
//          treeLoader.on("beforeload", function(treeLoader,node){
//              treeLoader.baseParams.checked = node.attributes.checked;
//          });
          
        // A combobox for searching the tree.
        var searchCombo = new Ext.form.ComboBox({
            xtype : 'combobox',
            width : 300,
            store: searchStore,
            emptyText : 'Type a node name to auto display',
            displayField : 'nodeName',
            valueField : 'nodeName',
            editable : true,
            lazyRender : true,
            mode : 'remote',
            forceSelection : true,
            triggerAction : 'all',
            typeAhead : true,
            typeAheadDelay : 300
        });
  
        if(config.local_data_url) {
            searchCombo.on('select', function() {
                Ext.Ajax.request({
                    url : '../cgi-bin/GetLineage.cgi',
                    method : 'POST',
                    params : {
                        selectedNode : searchCombo.getValue()
                    },
                    success : function(response) {
                        var treeContainer = treepanel; //Ext.getCmp('tree-container');                
                        var array = Ext.util.JSON.decode(response.responseText);
                        var node;
                        Ext.each(array, function(item, index, allItems) {
                            node = treeContainer.getNodeById(item);
                            node.expand();
                        });
                        node.select();
                        //node.fireEvent('click');
                        gridStore.load({
                            params : {
                                id : node.attributes.id
                            },add: true
                        });
                    }
                });
        
            });
        }
        else {
            searchCombo.on('select', function() {
                var dumbstore = new Ext.data.ArrayStore({
                    proxy: new Ext.data.ScriptTagProxy({
                        url: URL+'/GetLineage.cgi'
                    }),
                    fields: ['name'],
                    listeners: {
                        load: function() {
                            var treeContainer = treepanel; //Ext.getCmp('tree-container');
                            var node;
                            Ext.each(dumbstore.data.items, function(item, index, allItems) {
                                node = treeContainer.getNodeById(item.json);
                                node.expand();
                            });
                            node.select();
                            treeStore.load({
                                params : {
                                    id : node.attributes.id
                                }
                            });
                        }
                    
                    }});
                    dumbstore.load({params : {selectedNode: searchCombo.getValue()}});
            })
        }      
    
    var grid_actions = new Ext.ux.grid.RowActions({
                id: 'grid_actions',
                keepselection: true,
                actions:[{
                                iconCls:'bin_closed',
                                tooltip:'Remove this entry'
                        }]
        });
        grid_actions.on(
            'action',
            function(grid, record, action, row, col) {
                if(action == 'bin_closed') {
                    grid.getStore().remove(record);
                }
            }); 
    var selectedGrid = new Ext.grid.GridPanel({
        title : 'Selected sequences',
        store : gridStore,
        form: true,
        viewConfig: {
            emptyText: 'Drag and drop Genomes from the tree on the left. Any level in the tree can be brought over!',
            deferEmptyText: false
        },
        region: 'center',
        plugins: [grid_actions],
        height : 500,
        autoExpandColumn: 'org-name',
                ddGroup: 'gridDrop',
                enableDragDrop: true,
        //width : 800,
        columns : [ new Ext.grid.RowNumberer(), {
            header : 'ID',
            width : 30,
            dataIndex : 'id',
            sortable : true,
            hidden : true
        }, {
            id : 'org-name',
            header : 'Organism name', 
            width : 100,
            dataIndex : 'orgName',
            sortable : true
        }, {
            header : 'Seq. Length',
            width : 90,
            dataIndex : 'seqLen',
            sortable : true
        }, {
            header : 'Refseq ID',
            width : 100,
            dataIndex : 'refseqId',
            sortable : true,
            align : 'center',
            renderer: function(val) {
                return "<a href='http://www.ncbi.nlm.nih.gov/sites/entrez?db=genome&cmd=search&term="+
                    val+"' target='_blank'>"+val+"</a>";
            }
        },grid_actions],
        autoExpandColumn : 'org-name',
        loadMask : true,
        columnLines : true,
        buttonAlign: 'center',
        buttons: [/*{
            text: 'Save',
            handler: function() {
                var ids = [];
//                  gridStore.each(function(item) {
//                      console.log(item);
//                      ids.push(item.data.refseqId);
//                  });
                console.log(config);
                if(config.id_store) {
                    console.log('here with an id store');
                    console.log(gridStore);
//                      config.id_store.loadData(gridStore.data,true);
                    gridStore.removeAll();
                    if(config.callback) {
                        config.callback();
                    }
                }
//                  console.log(ids);
            }
        },*/
        {text: 'Clear',
        handler: function() {
            gridStore.removeAll();
        }}

        ]
//        bbar : myBar
    });

    selectedGrid.on('render' , function() {
        var gridel = selectedGrid.getView().scroller.dom;
        if(config.id_store) {
//              gridStore.loadData(config.id_store.data);
        }
        var gridtarget = new Ext.dd.DropTarget(gridel, {
        ddGroup: 'gridDrop',
            notifyDrop: function(ddSource, e, data) {
                if(data.node) {
                    gridStore.load({
                        params : {
                            id : data.node.id
                        },
                        add: true
                    });
                }
                Ext.each(data.nodes, function(node,i,all) {
                    gridStore.load({
                        params : {
                            id : node.id
                        },
                        add: true
                    });
        });
        }

    });

    });
    treepanelconf.tbar = [searchCombo];
    treepanelconf.store = treeStore;
    treepanelconf.loader = treeLoader;
//      treepanel = new Ext.ux.MultiSelectTreePanel(treepanelconf);
    treepanel = new Ext.tree.TreePanel(treepanelconf);
    searchStore.load();
    var treeconfig = {
        layout : 'border',
        defaults: {frame: false},
        frame: false,
        items: [selectedGrid,treepanel]
    };
    clovr.ClovrComparativeTreePanel.superclass.constructor.call(this, treeconfig);
    this.grid = selectedGrid;
}});

Ext.reg('clovrcomparativetreepanel', clovr.ClovrComparativeTreePanel);
