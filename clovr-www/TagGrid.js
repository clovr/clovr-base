/*
 * A grid to store tagged data sets
 */
Ext.ns('clovr');
clovr.TagGrid = Ext.extend(Ext.grid.GridPanel, {

    constructor: function(config) {
        var jstore = new Ext.data.JsonStore({
//            root: 'rows',
            fields: [
                {name: "name"}, 
                {name: "fileCount"},
                {name: "phantom_tag",type: "boolean"}]
//            url: config.url,
//            baseParams: {"name": "local"}
        });

        var taggrid = this;
        clovr.TagGrid.superclass.constructor.call(this, Ext.apply(config, {
            store: jstore,
            ddGroup: 'tagDDGroup',
            enableDragDrop: true,
            autoExpandColumn: 'name',
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    sortable: true
                },
                columns: [
                    {id: 'name', header: "Name", width: 300, dataIndex: 'name'},
                    {id: 'fileCount', header: "File Count", dataIndex: 'fileCount'},
                    {id: 'phantom', header: "Is Phantom", dataIndex: 'phantom_tag'}
                
                ]
            }),
            defaults: {
                locked: false,
                sortable: true,
                width: 100
            },
            sm: new Ext.grid.RowSelectionModel({
                singleSelect: false,
                listeners: {
                    selectionchange: function(sm) {
                        var selects = [];
                        Ext.each(sm.getSelections(), function(val) {
                            selects.push(val.data.name);
                        });
                        taggrid.pipelinePanel.setInput(selects.join(','));
                    }
                }
            })
            }));
        if(config.host == 'localhost') {
            Ext.Ajax.request({
                url: config.url,
                params: {request: Ext.util.JSON.encode({name: 'local'})},
                success: function(response) {
                    var tags = Ext.util.JSON.decode(response.responseText).data;
                    var fields = [];
                    var cols = [];
                    var keys = [];
                    Ext.each(tags, function(elm) {
                        for(key in elm) {
                            if(!keys[key]) {
                                cols.push({'header': key, 'dataIndex': key});
                                fields.push({'name': key});
                            }
                            keys[key]=true;
                        }});
                    var data_to_load = {
                        'metaData': {
                            'fields': fields,
                            'sortInfo': {'field': 'name'},
                            'root': 'rows'
                        },
                        'rows': tags};
                    jstore.loadData(tags);
//                    taggrid.reconfigure(jstore,new Ext.grid.ColumnModel(cols));

                },
                failure: function(response) {
                    Ext.Msg.show({
                        title: 'Server Error',
                        msg: response.responseText,
                        icon: Ext.MessageBox.ERROR});
                }
                        
            });
        }


    }
});

Ext.reg('taggrid', clovr.TagGrid);
