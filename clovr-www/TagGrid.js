/*
 * A grid to store tagged data sets
 */
Ext.ns('clovr');
clovr.TagGrid = Ext.extend(Ext.grid.GridPanel, {

    constructor: function(config) {
        var jstore = new Ext.data.GroupingStore({
            reader: new Ext.data.JsonReader({
            	fields: [
                	{name: "name"}, 
                	{name: "fileCount"},
                	{name: "phantom_tag",type: "boolean"},
	                {name: "type", mapping: ('[\"metadata.format_type"\]')},
                    {name: 'metadata.tag_base_dir', mapping: ('[\"metadata.tag_base_dir"\]')}
            	],
            	root : function(data) {
            	    Ext.each(data.data, function(elm) {
                	    for(key in elm) {
                    	    if(key == 'files') {
                            elm.fileCount = elm[key].length;
                        }
                    	}});
                	return data.data;
            	},
            }),
            groupField: "type",
            groupDir: "DESC",
            url: config.url,
            autoLoad: true,
            baseParams: {request: Ext.util.JSON.encode({name: 'local'})},
            listeners: {
                load: function(store,records,o) {
                    store.filter([{
                        property: 'phantom_tag',
                        value: false
                    }])
                    store.groupBy('type');
                },
                loadexception: function() {
                }
            }
        });
        clovr.tagStores.push(jstore);		
		var uploadWin = clovr.uploadFileWindow({store: jstore});
        var taggrid = this;
        clovr.TagGrid.superclass.constructor.call(this, Ext.apply(config, {
            store: jstore,
            ddGroup: 'tagDDGroup',
            enableDragDrop: true,
            autoExpandColumn: 'name',
            listeners: {
                rowclick: function(grid,index,e) {
                    create_details_view(config,grid.store.getAt(index).data);
                }
            },
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    sortable: true
                },
                columns: [
                    {id: 'name', header: "Name", width: 300, dataIndex: 'name',
                     renderer: renderName},
                     {id: 'type', header: "Type", width: 70, dataIndex: 'type'}
                ]
            }),
            view: new Ext.grid.GroupingView({
            	forceFit:true,
            	startCollapsed: true,
            	groupTextTpl: '{text} ({[values.rs.length]} {[values.rs.length > 1 ? "Items" : "Item"]})'
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
                     uploadWin.show();
                 }},
                {text: 'Get Details',
                 handler: function() {
                     var selections = taggrid.getSelectionModel().getSelections();
                     create_details_view(config,selections[0].data);
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

function create_details_view(config,dataset) {
    if(config.pipelineWizard) { 
        config.pipelineWizard.getLayout().setActiveItem('dataset');
        Ext.getCmp('dataset').loadDataset({dataset_name: dataset.name,
                                           dataset: dataset});
    }
    else {
        var win = new Ext.Window({
            layout: 'fit',
            height: 400,
            width: 400,
            items: [
                new clovr.ClovrDatasetPanel({
                    dataset_name: dataset_name,
                    dataset: dataset
                })
            ]
        });
        win.show();
    }
}
