/*
 * A form panel that is used to submit a blast job
 */

clovr.BlastOutputPanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {

        var thisPanel = this;

        Ext.Msg.show({
            title: 'Retrieving pipeline information...',
            width: 200,
            mask: true,
            closable: false,
            wait: true,
            progressText: 'Retrieving Info'
        });
        config.layout = 'fit';
        clovr.BlastOutputPanel.superclass.constructor.call(this,config);
        this.doLayout();
        var task = {
            run: function() {
                getWrapperInfo(task, thisPanel, config.pipeData)
            },
            interval: 10000
        };
        Ext.TaskMgr.start(task);
    },

    makePanel: function(pipeInfo) {
//        var markup = 'The output to your pipeline is available here: '+
//            '<a href="'pipeInfo.config['input.TAGS_TO_DOWNLOAD']+
//            '">Your output File</a>';
        if(pipeInfo.status = 'complete') {
//            this.update(markup);
            this.add({xtype: 'container',
                      layout: 'vbox',
                      layoutConfig: {align: 'center',pack: 'center'},
                      defaults: {margins: '5 5 5 5'},
                      items: [
                          {xtype: 'button',
                           handler: function() {
                               document.location= ('/clovr/output/'+pipeInfo.config['input.TAGS_TO_DOWNLOAD']);
                           },
                           text: 'Download Output File'
                          },
                          {xtype: 'button',
                           handler: function() {
                               document.location=('/clovr/blast/');
                           },
                           text: 'Run Another Search'
                          }
                          
                      ]});
            this.doLayout();
        }
    }
});

Ext.reg('blastoutputpanel', clovr.BlastOutputPanel);


function getWrapperInfo(task, panel, pipeData) {

    // First let's pull back the info for the pipeline
    Ext.Ajax.request({
        url: '/vappio/pipelineStatus_ws.py',
        params: {request: 
                 Ext.util.JSON.encode(
                     {'name': 'local',
                      'pipelines': [pipeData.wrappername]
                     })},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            if(rjson.success) {
                var rdata = rjson.data[0][1];
                if(rjson.success) {
                    if(rdata.state =="complete") {
                        Ext.TaskMgr.stop(task);
                        Ext.Msg.hide();
                        panel.makePanel(rdata);
                    }
                    else if(rdata.state =="error") {
                        Ext.TaskMgr.stop(task);
                        Ext.Msg.show({
                            title: 'Pipeline Failed!',
                            width: 200,
                            mask:true,
                            msg: 'This Pipeline Failed'
                                +'<br/>Go to <a href=/clovr/blast/>Blast Form</a> to Retry.',
                            icon: Ext.Msg.ERROR,
                            closable: false
                        });
                    }
                    else {
                        Ext.Msg.show({
                            title: 'Pipeline is Running',
                            progress: true,
                            width: 200,
                            mask: true,
                            msg: 'This Pipeline is running'
                                +'<br/>Go to <a href=/clovr/blast/>Blast Form</a> to Retry.',
                        });
                        Ext.Msg.updateProgress(rdata.complete/rdata.total);
                    }
                }
            }
            else {
                console.log('Failure for some reason');
            }
        }
    });
}


function getTaskInfo(task_name) {
    Ext.Ajax.request({
        url: '/vappio/task_ws.py',
        params: {request: Ext.util.JSON.encode({'name': 'local','task_name': data.data})},
        success: function(r,o) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            var rdata = rjson.data[0];
            if(rjson.success) {
                if(rdata.state =="completed") {
                    Ext.Msg.hide();
                    seqcombo.getStore().loadData([[tagName]],true);
                    seqcombo.setValue(tagName);
                    Ext.TaskMgr.stop(task);
                    uploadWindow.hide();
                }
                else if(rdata.state =="failed") {
                }
            }
            else {
            }
        }
    });
}