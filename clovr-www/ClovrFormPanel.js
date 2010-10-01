/*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrFormPanel = Ext.extend(Ext.Form.FormPanel, {

    constructor: function(config) {
        if(config.url) {
            console.log(url);
        }
        else if(config.fields) {
            console.log(fields);
            
            
        }
        Ext.Form.FormPanel.superclass.constructor.call(this, Ext.apply(config, {
            columns: [
                {id: 'name', header: "Name", width: 300, dataIndex: 'name'},
                {id: 'fileCount', header: "File Count", dataIndex: 'fileCount'},
                {id: 'phantom', header: "Is Phantom", dataIndex: 'phantom'}
            ],
        }))

    }
});

Ext.reg('clovrformpanel', clovr.ClovrFormPanel);
