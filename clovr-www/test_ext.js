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





	},
	failure: function(failMsg) {
            Ext.Msg.alert("Failure!", failMsg);
	}
    });

});
