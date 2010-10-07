 /*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrPipelinesGrid = Ext.extend(Ext.grid.GridPanel, {
    
    constructor: function(config) {
        var pipeGrid = this;
        var jstore = new Ext.data.JsonStore({
            //            root: 'rows',
            fields: [
                {name: "name"}, 
                {name: "state"}
            ]
        });

        clovr.ClovrPipelinesGrid.superclass.constructor.call(this, Ext.apply(config, {
            title: 'Pipelines',
            store: jstore,
            autoExpandColumn: 'name',
            colModel: new Ext.grid.ColumnModel({
                defaults: {
                    width: 50,
                    sortable: true
                },
                columns: [
                    {id: 'name', header: 'Pipeline Name', dataIndex: 'name'},
                    {id: 'status', header: 'Status', dataIndex: 'state'}
                ]
            }),
            tools: [
                {id: 'refresh',
                 handler: function() {getPipelineStatus()}
                }]
        }));


        function getPipelineStatus() {
            // Making a request here to get the pipeline status(s).
            Ext.Ajax.request({
                url: '/vappio/pipelineStatus_ws.py',
                params: {request: Ext.util.JSON.encode({name: 'local',pipelines: []})},
                success: function(response) {
                    var pipes = Ext.util.JSON.decode(response.responseText).data;
                    var fields = [];
                    var cols = [];
                    var keys = [];
                    var pipes_to_load = [];
                    Ext.each(pipes, function(elm) {
                        var pipe = elm[1];
                        pipes_to_load.push(pipe);
                        for(key in pipe) {
                            if(key == 'files') {
                                pipe.fileCount = pipe[key].length;
                            }
                            if(!keys[key]) {
                                cols.push({'header': key, 'dataIndex': key});
                                fields.push({'name': key});
                            }
                            keys[key]=true;
                        }});
                    var data_to_load = {
                        'metaData': {
                            'fields': fields,
                            'sortInfo': {'field': 'name'},
                            'root': 'rows'
                        },
                        'rows': pipes};
                    jstore.loadData(pipes_to_load);
                    //                    taggrid.reconfigure(jstore,new Ext.grid.ColumnModel(cols));
                    
                },
                failure: function(response) {
                    Ext.Msg.show({
                    title: 'Server Error',
                        msg: response.responseText,
                        icon: Ext.MessageBox.ERROR});
                }
                
            });
        }
        getPipelineStatus();
    }
});

Ext.reg('clovrpipelinesgrid', clovr.ClovrPipelinesGrid);
