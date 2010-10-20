/*
 * A grid to store tagged data sets
 */
Ext.ns('clovr');
clovr.TagGrid = Ext.extend(Ext.grid.GridPanel, {

    constructor: function(config) {
        var jstore = new Ext.data.JsonStore({
            fields: [
                {name: "name"}, 
                {name: "fileCount"},
                {name: "phantom_tag",type: "boolean"},
            ],
            root : function(data) {
                console.log(data);
                Ext.each(data.data, function(elm) {
                    for(key in elm) {
                        if(key == 'files') {
                            elm.fileCount = elm[key].length;
                        }
                    }});
                return data.data;
            },
            url: config.url,
            autoLoad: true,
            baseParams: {request: Ext.util.JSON.encode({name: 'local'})},
            listeners: {
                load: function(store,records,o) {
                    console.log('fooo');
                    store.filter([{
                        property: 'phantom_tag',
                        value: false
                    }])
                },
                loadexception: function() {
                    console.log('failed to load');
                }
            }
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
                    {id: 'name', header: "Name", width: 300, dataIndex: 'name',
                     renderer: renderName}
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
            }),
            buttons: [
                {text: 'Add',
                 handler: function() {
                     clovr.uploadFileWindow({'store': jstore});
                 }}
            ],
            tools: [
                {id: 'refresh',
                 handler: function() {jstore.reload()}
                }]
            
        }));
    }
});

Ext.reg('taggrid', clovr.TagGrid);

function renderName(value, p, record) {
    var desc = '';
    if(record.json['metadata.description']) {
        desc = record.json['metadata.description'];
    }
    var fileWord = 'files';
    if(record.data.fileCount ==1) {
        fileWord = 'file';
    }
    return String.format(
        '<div class=taggrid-title><b>{0}: {1} '+fileWord+'</b><br/>{2}</div>',
        value,record.data.fileCount,desc);
}
