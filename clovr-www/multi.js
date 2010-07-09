function clovrQuery(req) {
    var reqObj = {
	url: req.url,
	method: 'POST',
	success: function(response) {
	    var j = Ext.util.JSON.decode(response.responseText);
	    if(j[0]) {
		req.success(j[1])
	    }
	    else {
		req.failure(j[1])
	    }
	},
	failure: function() {
	    req.failure("Connection failed")
	}
    };
    
    if("params" in req) {
	reqObj.params = {request: Ext.util.JSON.encode(req.params)}
    }
    var conn = new Ext.data.Connection();
    conn.request(reqObj)
}




Ext.onReady(function() {
    clovrQuery({
	url: '../vappio/queryTag_ws.py',
	//params: {name: "local",tag_name: "samtag"},
	params: {name: "local"},
	success: function(response) {
	    var v = response.map(function(val) {
		var numFiles = 0;
		if("files" in val) {
		    numFiles = val.files.length;
		}
		return [val.name, numFiles, "phantom_tag" in val];
	    });

	    var ds = new Ext.data.ArrayStore({
		fields: [
		    {name: "name"},
		    {name: "fileCount"},
		    {name: "phantom"}
		]
	    });
	    
	    ds.loadData(v);
	    
	    var colModel = new Ext.grid.ColumnModel({
    		columns: [
			{id: 'name', header: "Name", width: 300, dataIndex: 'name'},
			{id: 'fileCount', header: "File Count", dataIndex: 'fileCount'},
			{id: 'phantom', header: "Is Phantom", dataIndex: 'phantom'}
		],
		defaults: {
			locked: false,
			sortable: true,
			width: 100
		}
	    });
	


		
		
		var grid = new Ext.grid.GridPanel({
			store: ds,
			colModel: colModel,
			height: 400,
			width: 600,
			//title: 'CloVR Data Sets',
			sm: new Ext.grid.RowSelectionModel({singleSelect: false}),
			viewConfig: {
				forceFit: true
			},
			split: true,
			region: 'west',
			border: true
		});

		var blankTpl = new Ext.Template([
			'<div id="clovr-details"><p>Please select a row to see details. <a href="multi.html">Reset</a></p></div>'
		]);

		var detailTpl = new Ext.Template([
			'<div id="clovr-details">',
			'<p>Please select a row to see details. <a href="multi.html">Reset</a></p>',
			'<dl>',
			'<dt>Name:</dt><dd>{name}</dd>',
			'<dt>File Count:</dt><dd>{fileCount}</dd>',
			'<dt>Is Phantom:</dt><dd>{phantom}</dd>',
			'</dl>',
			'</div>'
		]);
		/*	
			'<h3>Available Pipelines</h3>',
			'<ul>',
			'<li>CloVR Search (blast) [<a href="">help</a>]</li>',
			'<li>CloVR Microbe [<a href="">help</a>]</li>',
			'</ul>',
		*/
		
		
		var summaryTpl = new Ext.Template([
                        '<div id="clovr-details">',
                        '<p>Please select a row to see details. <a href="multi.html">Reset</a></p>',
			'<h3>You have selected:</h3>',
			'<ul>{names}</ul>',
			'<h3>Total Files: {fileCountTotal}</h3>',
                        '</div>'
                ]);
		
		
		var details = new Ext.Panel({
			renderTo: 'clovr-form-grid',
			frame: true,
			title: 'CloVR Data Sets',
			width: 960,
			height: 400,
			layout: 'border',
			items: [
				grid,
				{
					id: 'detailPanel',
					region: 'center',
					html: '<div id="clovr-details"><p>Please select a row to see details.</p></div>',
					bodyStyle: {
						background: '#ffffff',
						padding: '5px'
					}
				}
			]
		});
		
		grid.getSelectionModel().addListener({
			'selectionchange' : {
				fn: function(sm) {
					if ( sm.getCount() == 1 ) {
						
						// one row selected
						// console.info( sm.getSelections() );
						var detailPanel = Ext.getCmp('detailPanel');
						detailTpl.overwrite(detailPanel.body, sm.getSelected().data);

					} else if ( sm.getCount() > 1 ) {
						
						// multiple rows selected
						var rows = sm.getSelections();
						var names = '';
						var fileCountTotal = 0;

						for( i=0; i<rows.length; i++ ) {
							// console.info( rows[i].data );
							names = names + '<li>'+rows[i].data.name+'</li>';
							fileCountTotal = fileCountTotal + rows[i].data.fileCount;
						}
						
						var detailPanel = Ext.getCmp('detailPanel');
						summaryTpl.overwrite(detailPanel.body, {names:names, fileCountTotal:fileCountTotal});

					} else {
						
						// no rows selected
						var detailPanel = Ext.getCmp('detailPanel');
						blankTpl.overwrite(detailPanel.body);

					}
				}
			}
			
			/*
			'rowselect' : {
				fn: function(sm, rowIndx, r) {
                        		if ( sm.getCount() == 1 ) {
		                                var detailPanel = Ext.getCmp('detailPanel');
                		                detailTpl.overwrite(detailPanel.body, r.data);
		                        } else {
                		                console.info( sm.getSelections() );
						
		                        }
                		}
			}
			*/
		});
		
		/*
		grid.getSelectionModel().addListener('rowselect', function(sm, rowIndx, r) {
                        if ( sm.getCount() == 1 ) {
                                var detailPanel = Ext.getCmp('detailPanel');
                                detailTpl.overwrite(detailPanel.body, r.data);
                        } else {
                                console.info( sm.getSelections() );
                        }
                });
		*/
		
		/* fork the selection for single row select and multi-row select
		grid.getSelectionModel().on('rowselect', function(sm, rowIdx, r) {
			var detailPanel = Ext.getCmp('detailPanel');
			detailTpl.overwrite(detailPanel.body, r.data);
		});
		*/

		//grid.render('clovr-form-grid');



	/*
	var gridForm = new Ext.FormPanel({
		id: 'clovr-form',
		frame: true,
        labelAlign: 'left',
        title: 'CloVR Data Sets',
        bodyStyle:'padding:5px',
        width: 750,
        layout: 'column',    // Specifies that the items will now be arranged in columns
        items: [{
            columnWidth: 0.60,
            layout: 'fit',
            items: {
                xtype: 'grid',
                ds: ds,
                cm: colModel,
                sm: new Ext.grid.RowSelectionModel({
                    singleSelect: false,
                    listeners: {
                        rowselect: function(sm, row, rec) {
                            Ext.getCmp("clovr-form").getForm().loadRecord(rec);
                        }
                    }
                }),
                autoExpandColumn: 'name',
                height: 350,
                //title:'Company Data',
                border: true,
                listeners: {
                    viewready: function(g) {
                        g.getSelectionModel().selectRow(0);
                    } // Allow rows to be rendered.
                }
            }
        },{
            columnWidth: 0.4,
            xtype: 'fieldset',
            labelWidth: 90,
            title:'Click a row to view details or make changes.',
            defaults: {width: 140, border:false},    // Default config options for child items
            defaultType: 'textfield',
            autoHeight: true,
            bodyStyle: Ext.isIE ? 'padding:0 0 5px 15px;' : 'padding:10px 15px;',
            border: false,
            style: {
                "margin-left": "10px", // when you add custom margin in IE 6...
                "margin-right": Ext.isIE6 ? (Ext.isStrict ? "-10px" : "-13px") : "0"  // you have to adjust for it somewhere else
            },
            items: [
				{fieldLabel: 'Name', name: 'name'},
				{fieldLabel: 'Phantom Tag?', name: 'phantom'},
				{fieldLabel: 'Files', name: 'fileCount'}
				//{fieldLabel: 'Base Directory', name: 'baseDir'}
			]
        }]	//, renderTo: 'clovr-form-grid'
    });
    gridForm.render('clovr-form-grid');
	*/




	},
	failure: function(failMsg) {
            Ext.Msg.alert("Failure!", failMsg);
	}
    });

});
