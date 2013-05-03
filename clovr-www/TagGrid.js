/*
 * A grid to store tagged data sets
 */
Ext.ns('clovr');
clovr.TagGrid = Ext.extend(Ext.grid.GridPanel, {

    constructor: function(config) {
    
    	var taggrid = this;
    	taggrid.parenttools = [{id: 'refresh',
        	handler: function() {clovr.reloadTagStores();}
        }];

        var jstore = new Ext.data.GroupingStore({
            reader: new Ext.data.JsonReader({
            	fields: [
                	{name: "name", mapping: "tag_name"}, 
                	{name: "file_count"},
//                	{name: "phantom", mapping: 'phantom'},
	                {name: "type", mapping: ('metadata.format_type')},
                    {name: 'tag_base_dir', mapping: ('metadata.tag_base_dir')}
            	],
            	root : function(data) {
/*            	    Ext.each(data, function(elm) {
                	    for(key in elm) {
                    	    if(key == 'files') {
                            elm.fileCount = elm[key].length;
                        }
                    	}});*/
                	return data;
            	}
            }),
            groupField: "type",
            groupDir: "DESC",
//            url: config.url,
//            autoLoad: true,
//            baseParams: {request: Ext.util.JSON.encode({name: 'local'})},
            listeners: {
                load: function(store,records,o) {
                    store.filterBy(
                    	function(r,id) {
                    		var retval = false;
                    		if(r.json.phantom == null) {
                    			retval = true;
                    		};
                    		return retval;
                    	}
                    );
                    store.groupBy('type');
                },
                loadexception: function() {
                }
            }
        });
		var uploadWin = clovr.uploadFileWindow({store: jstore});
        var taggrid = this;
        clovr.TagGrid.superclass.constructor.call(this, Ext.apply(config, {
            store: jstore,
            ddGroup: 'tagDDGroup',
            enableDragDrop: true,
            autoExpandColumn: 'name',
            listeners: {
                rowclick: function(grid,index,e) {
					if(!grid.select_fired) {
    	            	grid.clicked = true;
        	            create_details_view(config,grid.store.getAt(index).data);
        	        }
        	        grid.select_fired = false;
                },
                mouseout: function(e) {

                },
                afterlayout: {
                	fn: function(grid) {
                		grid.body.mask('Loading','x-mask-loading');
                		clovr.tagStores.push(jstore);
        				clovr.getDatasetInfo({
            				dataset_name: config.dataset_name,
							callback: function(d) {
								jstore.loadData(d.data);
								taggrid.body.unmask();
							}
						});
					},
               		single: true
            	}},
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
                    },
                    rowselect: function(sm,index,rec) {
                    	taggrid.select_fired = true;
	                    create_details_view(config,rec.data);
                    }
                }
            }),
            buttons: [
                {text: 'Add',
                 handler: function() {
                     uploadWin.show();
                 }},
                 
                 // This was only useful when clicking a dataset did nothing
/*                {text: 'Get Details',
                 handler: function() {
                     var selections = taggrid.getSelectionModel().getSelections();
                     create_details_view(config,selections[0].data);
                 }},*/
            	{text: 'Refresh',
                 handler: function() {
                 	taggrid.body.mask('Loading','x-mask-loading');
                 	clovr.reloadTagStores({
                 		callback: function() {
                 			taggrid.body.unmask();
                 		}
                 	})}
                }
            ]
//            ,
//            tools: [
//                {id: 'refresh',
//                 handler: function() {jstore.reload()}
//                }]
//            
        }));
    }
});

Ext.reg('taggrid', clovr.TagGrid);

function renderName(value, p, record) {
    var desc = '';
    if(record.json.metadata.description) {
        desc = record.json.metadata.description;
    }
    var fileWord = 'files';
    if(record.data.file_count ==1) {
        fileWord = 'file';
    }
    var fc = record.data.file_count+ ' '+fileWord;
    if(record.data.file_count == 0 && record.json.metadata.urls) {
       fc = 'remote file(s)';
    }
    if(record.json.metadata.website) {
        value = '<a target=_blank href='+record.json.metadata.website+'>'+value+'</a>'
        fc='<-Click Here';
    } 

    return String.format(
        '<div class=taggrid-title><b>{0}: {1}</b><br/>{2}</div>',
        value,fc,desc);
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
