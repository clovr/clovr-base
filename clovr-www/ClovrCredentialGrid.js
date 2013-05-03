/*
 * A grid to store credentials
 */
Ext.ns('clovr');
clovr.ClovrCredentialGrid = Ext.extend(Ext.grid.GridPanel, {

    constructor: function(config) {
    
    	var credgrid = this;
        var jstore = new Ext.data.Store({
            reader: new Ext.data.JsonReader({
            	fields: [
                	{name: "name"}, 
                    {name: "description"},
                    {name: "num_instances"},
                	{name: "ctype"}
                ]
            }),
            root : function(data) {
            	return data.data;
            }
        });
        clovr.credStores.push(jstore);

        clovr.getCredentialInfo({
            cluster_name: 'local',
            callback: function(json) {
                jstore.loadData(json.data);
            }
        });

        clovr.ClovrCredentialGrid.superclass.constructor.call(this, Ext.apply(
            config, {
                store: jstore,
                autoExpandColumn: 'name',
                colModel: new Ext.grid.ColumnModel({
                    columns: [
                        {id: 'name', 
                         header: "Name", 
                         width: 300, 
                         dataIndex: 'name', 
                         renderer: renderCredName
                         },
                         {header: "Type",
                         width: 100,
                         dataIndex: 'ctype'
                         }
                    ]
                }),
                buttons: [
                    {text: 'Add',
                     handler: function() {
                         clovr.addCredentialWindow();
                     }},
            		{text: 'Refresh',
	                 handler: function() {
    	             	credgrid.body.mask('Loading','x-mask-loading');
        	         	clovr.reloadCredStores({
            	     		callback: function() {
                	 			credgrid.body.unmask();
                 			}
	                 	})
	                 }
    	            }
                ]

            }));
    }
});

Ext.reg('credentialgrid', clovr.TagGrid);

function renderCredName(value, p, record) {
	return String.format(
        '<div class=taggrid-title><b>{0}</b>: <i>{1} instances</i><br/>{2}</div>',
        value,record.data.num_instances,record.data.description);
}
