/*
 * A form panel that is used to submit a blast job
 */

clovr.BlastClovrFormPanel = Ext.extend(clovr.ClovrFormPanel, {

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
        clovr.ClovrFormPanel.superclass.constructor.call(this, Ext.apply(config, {
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

Ext.reg('blastclovrormpanel', clovr.BlastClovrFormPanel);
