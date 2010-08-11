Ext.onReady(buildTree);

function buildTree() {
	
	var treeLoader = new Ext.tree.TreeLoader({ 
		dataUrl: '../cgi-bin/NcbiJsonSender.cgi'
	});
	
	treeLoader.on("beforeload", function(treeLoader,node){
		treeLoader.baseParams.checked = node.attributes.checked;
	});
	
	var clovr_pan = new Ext.form.FormPanel({
		title : 'clovr_pangenome',
		padding : 10,
		frame : true,
		labelWidth : 150,
		buttons : [{
			text : 'Run Clovr Pangenome',
			handler : function() {
				var tree = Ext.getCmp('tree-container');
				var nodeIds = '',selNodes = tree.getChecked();
				Ext.each(selNodes, function(node){
					if(nodeIds.length > 0){
						nodeIds += ', ';
					}
					nodeIds += node.id;
				});
       		
				if(!nodeIds){
					Ext.MessageBox.show({
						title : 'Message',
						msg : 'You have not selected any ref seq, ' + 
							'please select the organims of interest in the tree widget beside',
						icon : Ext.MessageBox.INFO,
						buttons : Ext.Msg.OK,
						closable : false
		       		});
				}
				else {
					Ext.Ajax.request({
						url : '../cgi-bin/NcbiJsonSender.cgi',
						form : 'clovr_pan',
						params : {
							IDs : nodeIds,
							pipeline : 'clovr_pangenome'
						},
						success : function(response) {
							var jsonText = response.responseText;
							Ext.Ajax.request({
								url : '/vappio/runPipeline_ws.py',
								params : {
									request : jsonText
								},
								success : function(mess) {
									var serverResponse = mess.responseText;
									if(serverResponse[1] === 't') {
										Ext.MessageBox.alert('Message', 'Pipeline invocation successful');
									} else {
										Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
									}
								},
								failure : function() {
									Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
								}
							});
						},
						failure : function(response) {
							Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
						}
					});
				}
			}
		}],
		
		defaults : {anchor : '40%'},
		defaultType : 'textfield',
		items : [{
			name : 'genbank_file',
			fieldLabel : 'Genbank File List ',
			emptyText : 'optional'
		},{
			name : 'map_file',
			fieldLabel : 'Organism Map File ',
			emptyText : 'optional'
		},{
			fieldLabel : 'Pipeline Name ',
			name : 'pipeline_name',
			emptyText : 'optional'
		}]
	});
	
	var clovr_joc = new Ext.form.FormPanel({
		title : 'clovr_JOC',
		padding : 10,
		frame : true,
		labelWidth : 150,
		buttons : [{
			text : 'Run Clovr JOC',
			handler : function() {
				var tree = Ext.getCmp('tree-container');
				var nodeIds = '',selNodes = tree.getChecked();
				Ext.each(selNodes, function(node){
					if(nodeIds.length > 0){
						nodeIds += ', ';
					}
					nodeIds += node.id;
				});
       		
				if(!nodeIds){
					Ext.MessageBox.show({
						title : 'Message',
						msg : 'You have not selected any ref seq, ' + 
							'please select the organims of interest in the tree widget beside',
						icon : Ext.MessageBox.INFO,
						buttons : Ext.Msg.OK,
						closable : false
		       		});
				}
				else {
					Ext.Ajax.request({
						url : '../cgi-bin/NcbiJsonSender.cgi',
						form : 'clovr_pan',
						params : {
							IDs : nodeIds,
							pipeline : 'clovr_comparative'
						},
						success : function(response) {
							var jsonText = response.responseText;
							Ext.Ajax.request({
								url : '/vappio/runPipeline_ws.py',
								params : {
									request : jsonText
								},
								success : function(mess) {
									var serverResponse = mess.responseText;
									if(serverResponse[1] === 't') {
										Ext.MessageBox.alert('Message', 'Pipeline invocation successful');
									} else {
										Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
									}
								},
								failure : function() {
									Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
								}
							});
						},
						failure : function(response) {
							Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
						}
					});
				}
			}
		}],
		
		defaults : {anchor : '40%'},
		defaultType : 'textfield',
		items : [{
			name : 'genbank_file',
			fieldLabel : 'Genbank File List ',
			emptyText : 'optional'
		},{
			name : 'map_file',
			fieldLabel : 'Organism Map File ',
			emptyText : 'optional'
		},{
			fieldLabel : 'Pipeline Name ',
			name : 'pipeline_name',
			emptyText : 'optional'
		}]
	});
	
	var clovr_mug = new Ext.form.FormPanel({
		title : 'clovr_mugsy',
		padding : 10,
		frame : true,
		labelWidth : 150,
		buttons : [{
			text : 'Run Clovr Mugsy',
			handler : function() {
				var tree = Ext.getCmp('tree-container');
				var nodeIds = '',selNodes = tree.getChecked();
				Ext.each(selNodes, function(node){
					if(nodeIds.length > 0){
						nodeIds += ', ';
					}
					nodeIds += node.id;
				});
       		
				if(!nodeIds){
					Ext.MessageBox.show({
						title : 'Message',
						msg : 'You have not selected any ref seq, ' + 
							'please select the organims of interest in the tree widget beside',
						icon : Ext.MessageBox.INFO,
						buttons : Ext.Msg.OK,
						closable : false
		       		});
				}
				else {
					Ext.Ajax.request({
						url : '../cgi-bin/NcbiJsonSender.cgi',
						form : 'clovr_mug',
						params : {
							IDs : nodeIds,
							pipeline : 'clovr_mugsy'
						},
						success : function(response) {
							var jsonText = response.responseText;
							Ext.Ajax.request({
								url : '/vappio/runPipeline_ws.py',
								params : {
									request : jsonText
								},
								success : function(mess) {
									var serverResponse = mess.responseText;
									if(serverResponse[1] === 't') {
										Ext.MessageBox.alert('Message', 'Pipeline invocation successful');
									} else {
										Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
									}
								},
								failure : function() {
									Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
								}
							});
						},
						failure : function(response) {
							Ext.MessageBox.alert('Message', 'Pipeline invocation failed');
						}
					});
				}
			}
		}],
		
		defaults : {anchor : '40%'},
		defaultType : 'textfield',
		items : [{
			name : 'genbank_file',
			fieldLabel : 'Genbank File List ',
			emptyText : 'optional'
		},{
			name : 'map_file',
			fieldLabel : 'Organism Map File ',
			emptyText : 'optional'
		},{
			fieldLabel : 'Pipeline Name ',
			name : 'pipeline_name',
			emptyText : 'optional'
		}]
	});
	
	new Ext.Viewport({
		layout : 'border',
		items : [ {
			region : 'west',
		   	title : 'Navigation',
		   	id : 'tree-container',
		   	width : 300,
		   	xtype : 'treepanel',
		   	autoScroll : true,
		   	collapsible : true,
		   	split : true,
		   	loader : treeLoader,
		   	root : new Ext.tree.AsyncTreeNode({
				text : 'Root Node',
				id : '/',
		   		checked : false
		   	}),
		   	rootVisible : false,
		   	listeners : {					
				'checkchange' : function(node, checked){
		 			node.eachChild(function(n) {
		    			n.getUI().toggleCheck(checked);
		    		});
		    	}
		    } 
	 	}, {
	 			region : 'center',
	 			title : 'Clovr Comparative',
	 			id : 'mainPanel',
	 			xtype : 'tabpanel',
	 			activeTab : 0,
	 			items : [clovr_pan, clovr_joc, clovr_mug]
		}]
	});
}
