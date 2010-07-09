
	function clovrQuery(req) {
		var reqObj = {
			url: req.url,
			method: 'POST',
			success: function(response) {
				var j = Ext.util.JSON.decode(response.responseText);
				
				if(j[0]) {
					req.success(j[1])
				} else {
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
		
		// container for all pipeline names
		var availablePipelines = new Array();
		
		// container for all pipeline configs
		var pipelineConfigs = new Array();
		
		function clovrParsePipelines( r ) {
			
			r.map( function( pipe ) {
				
				var n = pipe.name;
				var c = new Array();
				
				// add pipeline to global list
				availablePipelines.push(n);
				
				//console.group(n);
				
				if ( pipe.config != null ) {
					
					//console.log( pipe.config );
					
					//console.log( 'config length: ' + pipe.config.length );
					
					c = new Array();
					
					for ( i=0; i<pipe.config.length; i++ ) {
						//console.log( pipe.config[i] );
						c.push({
							'field': pipe.config[i][0], 
							'display': pipe.config[i][1].display,
							'desc': pipe.config[i][1].desc,
							'default': pipe.config[i][1]['default'],
							'default_hidden': pipe.config[i][1].default_hidden
						});
					}
					
					pipelineConfigs[n] = c;
					
					//console.log( pipelineConfigs[n] );
					
				}
				
				//console.groupEnd();
				
			});
		}
		
		clovrQuery({
			url: '../vappio/listPipelines_ws.py',
			success: function( response ) {
				clovrParsePipelines( response );
			}
				
				/*
				function( response ) {
					var p = response.map( function( val ) {
						console.info(val.name);
						
						for ( var i in val.config ) {
							console.info(val.config[i][0]);
						}
						
						return [val.name, val.config];
					});
				}
				*/
		});
		
		
		
		clovrQuery({
			url: '../vappio/queryTag_ws.py',
			//params: {name: "local",tag_name: "mytag"}, // filter specific tags
			params: {name: "local"},
			success: function(response) {
				
				/*
				console.info( 'availablePipelines:' );
				console.info( availablePipelines );
				
				console.info( 'pipelineConfigs:' );
				console.info( pipelineConfigs );
				*/

				var v = response.map(function(val) {
					var numFiles = 0;
					if ("files" in val) {
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
				
				var windows = new Ext.WindowGroup();
				
				
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
				
				var details = new Ext.Panel({
					//renderTo: 'clovr-form-grid',
					frame: true,
					title: 'CloVR Data Sets',
					region: 'center',
					width: 960,
					height: 400,
					buttons:[
						/*
						{
							text: 'CloVR Search Blast',
							handler: function() {
								// mainContainer.layout.setActiveItem(gridFormBlast);
								// new Ext.Window({title: 'Win', items: [gridFormBlast], manager: windows}).show();
								blastWin.show(details);
							}

						}
						*/
						{
							text: 'clovr_microbe454',
							handler: function() {
								// mainContainer.layout.setActiveItem(gridFormClovrMicrobe454);
								// new Ext.Window({title: 'Win', items: [gridFormClovrMicrobe454], manager: windows}).show();
								
								var itemArray = new Array();

								Ext.each( pipelineConfigs['clovr_microbe454'], function( arg, index, arr  ) {
									itemArray.push( {
										hidden: arg.default_hidden,
										fieldLabel: arg.display,
										name: arg.field,
										value: arg['default']
									} );
								});

								Ext.getCmp('form_clovr_microbe454').add(itemArray);


								//console.info( pipelineConfigs['clovr_microbe454'] );
								win_clovr_microbe454.show(details);
							}
						}
					],
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
				
				var blankTpl = new Ext.Template([
					'<div id="clovr-details"><p>Please select a row to see details. <a href="index.html">Reset</a></p></div>'
				]);
				
				var detailTpl = new Ext.Template([
					'<div id="clovr-details">',
					'<p>Please select a row to see details. <a href="index.html">Reset</a></p>',
					'<dl>',
					'<dt>Name:</dt><dd>{name}</dd>',
					'<dt>File Count:</dt><dd>{fileCount}</dd>',
					'<dt>Is Phantom:</dt><dd>{phantom}</dd>',
					'</dl>',
					'</div>'
				]);
				
				var summaryTpl = new Ext.XTemplate([
					'<div id="clovr-details">',
					'<p>Please select a row to see details. <a href="index.html">Reset</a></p>',
					'<h3>You have selected:</h3>',
					'<ul>{names}</ul>',
					'<h3>Total Files: {fileCountTotal}</h3>',
					'</div>'
				]);
				
				/*
					'<h3>Available Pipelines:</h3>',
					'<ul>',
					'<li><a href="#" id="clovr-search-blast">CloVR Search (blast)</a></li>',
					'<li><a href="#" id="clovr-microbe">CloVR Microbe</a></li>',
					'</ul>',
				*/
				
				
				// initialize the config data container
				dataToConfig = new Array();
				
				grid.getSelectionModel().addListener({
					
					'selectionchange' : {
						fn: function(sm) {
							
							// initialize and reset config array on each row selection
							dataToConfig = new Array();
							
							if ( sm.getCount() == 1 ) {
								
								// one row selected
								var detailPanel = Ext.getCmp('detailPanel');
								detailTpl.overwrite(detailPanel.body, sm.getSelected().data);
								
								dataToConfig.push( [sm.getSelected().data.name,sm.getSelected().data.fileCount,sm.getSelected().data.phantom] );
								
							} else if ( sm.getCount() > 1 ) {
								
								// multiple rows selected
								var rows = sm.getSelections();
								var names = '';
								var fileCountTotal = 0;
								
								for ( i=0; i<rows.length; i++ ) {
									names = names + '<li>'+rows[i].data.name+'</li>';
									fileCountTotal = fileCountTotal + rows[i].data.fileCount;
									
									dataToConfig.push( [rows[i].data.name, rows[i].data.fileCount, ] );
								}
								
								var detailPanel = Ext.getCmp('detailPanel');
								summaryTpl.overwrite(detailPanel.body, {names:names, fileCountTotal:fileCountTotal});
								
							} else {
								
								// no rows selected
								var detailPanel = Ext.getCmp('detailPanel');
								blankTpl.overwrite(detailPanel.body);
								
							}
							
							// manually load local data
							configStore.loadData(dataToConfig);
							
						}
					}
					
				});
				
				// create the data store
				var configStore = new Ext.data.ArrayStore({
					fields: [
					   {name: 'cName'},
					   {name: 'cFileCount', type: 'int'},
					   {name: 'cPhantom', type: 'boolean'}
					]
				});
				
				var configColModel = new Ext.grid.ColumnModel({
					columns: [
						{id: 'cName', header: "Name", dataIndex: 'cName'},
						{id: 'cFileCount', header: "File Count", dataIndex: 'cFileCount'},
						{id: 'cPhantom', header: "Is Phantom", dataIndex: 'cPhantom'}
					],
					defaults: {
						locked: false,
						sortable: true,
						width: 150
					}
				});
				
				var gridFormBlast = new Ext.FormPanel({
					id: 'pipeConfig',
					hidden: false,
					frame: true,
					labelAlign: 'left',
					//title: 'Pipeline Configuration: Blast',
					bodyStyle:'padding:5px',
					width: 960,
					layout: 'column',    // Specifies that the items will now be arranged in columns
					items: [
						{
							columnWidth: 0.60,
							layout: 'fit',
							items: {
								xtype: 'grid',
								ds: configStore,
								cm: configColModel,
								sm: new Ext.grid.RowSelectionModel({
									singleSelect: true,
									listeners: {
										rowselect: function(sm, row, rec) {
											Ext.getCmp("pipeConfig").getForm().loadRecord(rec);
										}
									}
								}),
								autoExpandColumn: 'cName',
								height: 350,
								//title:'Company Data',
								border: true,
								listeners: {
									viewready: function(g) {
										g.getSelectionModel().selectRow(0);
									} // Allow rows to be rendered.
								}
							}
						},
						{
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
								//{fieldLabel: 'Name', name: 'cName'},
								{fieldLabel: 'Trim', name: 'trim'},
								{fieldLabel: 'Chop', name: 'chop'},
								{fieldLabel: 'Time', name: 'time'}
							]
						}
					]
					//, renderTo: 'clovr-form-grid'
				});
				
				
				
				
				
				var gridForm_clovr_microbe454 = new Ext.Panel({
					id: 'pipe_clovr_microbe454',
					hidden: false,
					frame: true,
					//autoScroll: true,
					labelAlign: 'left',
					//title: 'Pipeline Configuration: CloVR Microbe 454',
					bodyStyle:'padding:5px',
					width: 960,
					height: 400,
					layout: 'column',    // Specifies that the items will now be arranged in columns
					items: [{
						columnWidth: 0.60,
						layout: 'fit',
						items: {
							xtype: 'grid',
							ds: configStore,
							cm: configColModel,
							sm: new Ext.grid.RowSelectionModel({
								singleSelect: true,
								listeners: {
									rowselect: function(sm, row, rec) {
										//Ext.getCmp("pipe_clovr_microbe454").getForm().loadRecord(rec);
									}
								}
							}),
							autoExpandColumn: 'cName',
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
						id: 'form_clovr_microbe454',
						autoScroll: true,
						columnWidth: 0.4,
						xtype: 'fieldset',
						labelWidth: 120,
						height: 350,
						title:'Click a row to view details or make changes.',
						defaults: {width: 160, border:false},    // Default config options for child items
						defaultType: 'textfield',
						//autoHeight: true,
						bodyStyle: Ext.isIE ? 'padding:0 0 5px 15px;' : 'padding:10px 15px;',
						border: false,
						style: {
							"margin-left": "10px", // when you add custom margin in IE 6...
							"margin-right": Ext.isIE6 ? (Ext.isStrict ? "-10px" : "-13px") : "0"  // you have to adjust for it somewhere else
						}
						/*
						,
						items: [
							{fieldLabel: 'Trim', name: 'trim'},
							{fieldLabel: 'Chop', name: 'chop'},
							{fieldLabel: 'Time', name: 'time'}
						]
						*/
					}]
					//, renderTo: 'clovr-form-grid'
				});
				
				
				
				var mainContainer = new Ext.Panel({
					id: 'top-container',
					layout: 'border',
					renderTo: 'clovr-form-grid',
					items: [
						details
					],
					height: 400,
					frame: false
				});
				
				//var blastWin = new Ext.Window({title: 'Pipeline Configuration: Blast', items: [gridFormBlast], manager: windows, closeAction: 'hide', modal: true});
				var win_clovr_microbe454  = new Ext.Window({title: 'Pipeline Configuration: CloVR Microbe 454', items: [gridForm_clovr_microbe454], manager: windows, closeAction: 'hide', modal: true, height: 400 });
				
			},
			
			failure: function(failMsg) {
				Ext.Msg.alert("Failure!", failMsg);
			}
		});

	});
	
	// clearly, this is a work in progress...




