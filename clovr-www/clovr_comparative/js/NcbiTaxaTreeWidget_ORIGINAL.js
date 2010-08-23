Ext.onReady(buildTree);

function buildTree() {
	
	var treeLoader = new Ext.tree.TreeLoader({ 
		dataUrl: '../cgi-bin/NcbiJsonSender.cgi'
	});
	
	treeLoader.on("beforeload", function(treeLoader,node){
		treeLoader.baseParams.checked = node.attributes.checked;
	});
	
	var myStore = new Ext.data.JsonStore({
		url : '../cgi-bin/SendGridJson.pl',
		root : 'info',
		fields : ['orgName', 'seqLen', 'refseqId']
	});
	
	var clovrMug = new Ext.Button({
		text : 'CloVR-mugsy',
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
	});
	
	var clovrJoc = new Ext.Button({
		text : 'CloVR-JOC',
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
	});
	
	var clovrPan = new Ext.Button({
		text : 'CloVR-pangenome',
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
	});
	
	var myBar = new Ext.Toolbar({
		items : [{
			xtype : 'button',
			text : 'CloVR-comparative',
			handler : function() {
				Ext.Msg.alert('Message','clovr comparative is under construction');
			}
		}, '->', clovrPan, '-', clovrJoc, '-', clovrMug]
	});
	
	var myGrid = new Ext.grid.GridPanel({
		title : 'User Selected Ncbi Refseq Information',
		store : myStore,
		renderTo : Ext.get('mainPanel'),
		height : 500,
		width : 800,
		columns : [ new Ext.grid.RowNumberer(), {
			header : 'ID',
			width : 30,
			dataIndex : 'id',
			sortable : true,
			hidden : true
		}, {
			id : 'org-name',
			header : 'Organism name', 
			width : 100,
			dataIndex : 'orgName',
			sortable : true
		}, {
			header : 'Sequence Length',
			width : 120,
			dataIndex : 'seqLen',
			sortable : true
		}, {
			header : 'Refseq ID',
			width : 75,
			dataIndex : 'refseqId',
			sortable : true,
			align : 'center'
		}],
		autoExpandColumn : 'org-name',
		loadMask : true,
		columnLines : true,
		bbar : myBar
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
				'click' : function(node) {
					myStore.load({
						params : {
							id : node.attributes.id
						}
					});
				},
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
	 			items : [myGrid]
		}]
	});
}
