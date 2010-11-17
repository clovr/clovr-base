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
                getWrapperTaskInfo(task, thisPanel, config.pipeData)
            },
            interval: 10000
        };
        Ext.TaskMgr.start(task);
    },

    makePanel: function(pipeInfo,pipeNames) {
//        var markup = 'The output to your pipeline is available here: '+
//            '<a href="'pipeInfo.config['input.TAGS_TO_DOWNLOAD']+
//            '">Your output File</a>';
        if(pipeInfo.state == 'complete') {
//            this.update(markup);
            this.add({xtype: 'container',
                      layout: 'vbox',
                      layoutConfig: {align: 'center',pack: 'center'},
                      defaults: {margins: '5 5 5 5'},
                      items: [
                          {xtype: 'button',
                           handler: function() {
/*                               Ext.Ajax.request({
                                   url: '/vappio/downloadPipelineOutput_ws.py',
                                   params: {request: Ext.util.JSON.encode(
                                       {'name':'local',
                                        pipeline_name: pipeNames.pipename,
                                        output_dir: '/var/www/output',
                                        overwrite: false
                                       })},
                                   success: function(r,o) {
                                       var rdata = Ext.util.JSON.decode(r.responseText);
                                       Ext.Msg.show({
                                           title: 'Preparing Download',
                                           progress: true,
                                           text: 'Preparing the download file'
                                       });
                                       var task = {
                                           run: function() {
                                              getDlTaskInfo(rdata.data,'/output/'+pipeInfo.config['input.TAGS_TO_DOWNLOAD']);
                                           },
                                           interval: 10000
                                       }
                                       Ext.TaskMgr.start(task);
                                   }
                               });*/
                               document.location = ('/output/' + pipeNames.pipename + '_' + pipeInfo.config['output.TAGS_TO_DOWNLOAD'] + '.tar.gz');
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

function getWrapperTaskInfo(task, panel, pipeData) {
    clovr.getTaskInfo(
        pipeData.taskname,
        function(r) {
            var rjson = Ext.util.JSON.decode(r.responseText);
            if(rjson.success) {
                var rdata = rjson.data[0];
                if(rjson.success) {
                    if(rdata.state =="completed") {
                        Ext.TaskMgr.stop(task);
                        Ext.Msg.hide();
                        clovr.getPipelineStatus({
                            cluster_name: 'local',
                            pipe_name: pipeData.wrappername,
                            callback: function(r) {
                                panel.makePanel(r,pipeData);
                            }});
                    }
                    else if(rdata.state =="error" || rdata.state == "failed") {
                        Ext.TaskMgr.stop(task);
                        Ext.Msg.show({
                            title: 'Pipeline Failed!',
                            width: 400,
                            mask:true,
                            msg: 'This Pipeline Failed with error:'
                                +'<br/>'+rdata.messages[rdata.messages.length - 1].text
                                +'<br/>Go to the <a href=/clovr/blast/>Blast Form</a> to Retry.',
                            icon: Ext.Msg.ERROR,
                            closable: false
                        });
                    }
                    else {
                        clovr.getPipelineStatus({
                            cluster_name: 'local',
                            pipe_name: pipeData.wrappername,
                            callback: function(r) {
                                var conf = r.config;
                                Ext.Msg.show({
                                    title: 'Pipeline is Running',
                                    progress: true,
                                    width: 300,
                                    mask: true,
                                    msg: 'The Search with query '+conf['input.INPUT_TAG']+' is running'
                                        +'<br/>Go to the <a href=/clovr/blast/>Blast Form</a> to submit a new search.'
                                });
                                Ext.Msg.updateProgress(rdata.completedTasks/rdata.numTasks);
                            }});
                    }
                }
            }
            else {
            }
        });
}

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
                        panel.makePanel(rdata,pipeData);
                    }
                    else if(rdata.state =="error") {
                        Ext.TaskMgr.stop(task);
                        Ext.Msg.show({
                            title: 'Pipeline Failed!',
                            width: 300,
                            mask:true,
                            msg: 'This Pipeline Failed'
                                +'<br/>Go to the <a href=/clovr/blast/>Blast Form</a> to Retry.',
                            icon: Ext.Msg.ERROR,
                            closable: false
                        });
                    }
                    else {
                        var conf = rdata.config;
                        Ext.Msg.show({
                            title: 'Pipeline is Running',
                            progress: true,
                            width: 300,
                            mask: true,
                            msg: 'The Search with query '+conf['input.INPUT_TAG']+' is running'
                                +'<br/>Go to the <a href=/clovr/blast/>Blast Form</a> to submit a new search.'
                        });
                        Ext.Msg.updateProgress(rdata.complete/rdata.total);
                    }
                }
            }
            else {
            }
        }
    });
}

function getDlTaskInfo(task_name,file) {

    var callback = function(r) {
        var rjson = Ext.util.JSON.decode(r.responseText);
        var rdata = rjson.data[0];
        if(rjson.success) {
            if(rdata.state =="completed") {
                Ext.Msg.hide();
                Ext.TaskMgr.stop(task);
                document.location = file;
            }
            else if(rdata.state =="failed") {
            }
        }
        else {
        }
    };

    clovr.getTaskInfo(task_name,callback);
}
