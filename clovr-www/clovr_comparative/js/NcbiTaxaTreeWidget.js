Ext.onReady(buildTree);

function buildTree() {
	new Ext.Viewport({
		layout : 'border',
		items : [
			{
				region : 'west',
				title : 'Navigation',
				width : 300,
				xtype : 'treepanel',
				autoScroll : true,
				collapsible : true,
				split : true,
				loader : new Ext.tree.TreeLoader({
					//url : 'cgi-bin/NcbiJsonSender.cgi'
					url : '../cgi-bin/FilteredNcbiJsonSender.cgi'
				}),
				root : new Ext.tree.AsyncTreeNode({
					text : 'Root Node',
					id : '/',
					expanded : true
				}),
				rootVisible : false,
				listeners : {
					click : function(n) {
						Ext.Msg.alert("You have clicked: ", "'" + n.attributes.id + "'");
					}
				}
			},
			{
				region : 'center',
				title : 'Clovr Comparative',
			}
		]
	});
}
