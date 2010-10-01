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
                    {name: "phantom"}
                ],
            url: config.url,
            baseParams: {"name": "local"}
        });
        console.log(jstore.getRange());
        clovr.TagGrid.superclass.constructor.call(this, Ext.apply(config, {
            columns: [
                {id: 'name', header: "Name", width: 300, dataIndex: 'name'},
                {id: 'fileCount', header: "File Count", dataIndex: 'fileCount'},
                {id: 'phantom', header: "Is Phantom", dataIndex: 'phantom'}
            ],
            store: jstore,
            defaults: {
                locked: false,
                sortable: true,
                width: 100
            }
        }))

    }
});

Ext.reg('taggrid', clovr.TagGrid);
