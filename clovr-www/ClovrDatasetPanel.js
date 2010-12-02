/*
 * A panel to display information about a particular tag 
 * and run an analysis on that tag if applicable. 
 */
Ext.ns('clovr');
clovr.ClovrDatasetPanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {
        
        var datasetpanel = this;
        
        config.layout='border';
        config.frame= true;
        config.autoScroll=true;
        var header_panel = new Ext.Panel({
            region: 'north',
            html: 'Information for the '+config.dataset_name+' dataset'
        });
        var footer_panel = new Ext.Panel({
            region: 'south'
        });

        var pipelines_panel = new Ext.Panel({
            id: 'pipelines_panel',
            autoHeight: true,
            autoScroll: true,
            region: 'center',
            layout: 'anchor',
//            layoutConfig: {
//                align: 'stretch'
//                pack: 'start'
//            }
        });
        var pipelines_wrapper = new Ext.Panel({
            id: 'pipelines_wrapper',
            layout: 'fit',
            region: 'center',
            autoScroll: true,
//            autoHeight: false,
            minSize: 100,
            split: true,
            items: [pipelines_panel]
        });
//        config.items = [pipelines_panel];
        config.items = [header_panel,pipelines_panel,footer_panel];
        config.listeners = {
            render: function() {
                if(config.dataset_name) {
                    datasetpanel.loadDataset(config);
                }
            }};

        datasetpanel.header_panel = header_panel;
        datasetpanel.footer_panel = footer_panel;
        datasetpanel.pipelines_panel = pipelines_panel;
        datasetpanel.pipelines_wrapper = pipelines_wrapper;
        datasetpanel.pipelineCallback = config.pipeline_callback;

        clovr.ClovrFormPanel.superclass.constructor.call(this,config);



    },
    
    loadDataset: function(config) {
        var datasetpanel = this;
        datasetpanel.header_panel.update('Information for the '+config.dataset_name+' dataset');
        datasetpanel.pipelines_panel.removeAll();
        datasetpanel.pipelines_panel.getEl().mask('Loading...');
        clovr.getPipelineInfo({
            callback: function(r) {
                var results_by_protocol = getResultsByProtocol(r.data,config);
                var protocols = clovr.getProtocols();
                Ext.each(protocols, function(p) {
                    
                    if(results_by_protocol[p].length ==0) {
                        datasetpanel.pipelines_panel.add(
                            new Ext.Container({
                                layout: 'column',
                                items: [{
                                    columnWidth: .2,
                                    items: [{
                                        xtype: 'button',
                                        height: '72px',
                                        width: '96px',
                                        scale: 'clovr',
                                        //                                            tooltip: {text: 'Click here to run CloVR Metagenomics'},
                                        tooltipType: 'title',
                                        text: "<img src='/clovr/images/"+p+"_icon.png'>",
                                        handler: function() {
                                            if(datasetpanel.pipelineCallback) {
                                                datasetpanel.pipelineCallback({dataset_name: config.dataset_name,
                                                                               pipeline_name: p
                                                                              });
                                            }
                                            // clovrpanel.getLayout().setActiveItem('clovr_metagenomics');
                                        }
                                    }]},{
                                        columnWidth: .80,
                                        items: [{
                                            html: 'You have not run this protocol yet'
                                        }]
                                    }]  
                            }));
                        
                    }
                    else {
                        var config_data =[];
                        var fields_for_grid = [];
                        // Enormous HACK here but this is necessary because the field names have '.' characters in them.
                        for (var pr in results_by_protocol[p][0])fields_for_grid.push({name: pr, mapping: ('[\"'+pr+'\"]')});
                        Ext.each(results_by_protocol[p], function(res) {
                            config_data.push(res);
                        });

                        var store = new Ext.data.JsonStore({
                            data: config_data,
                            root: function(data) {
                                return data;
                            },
                            fields: fields_for_grid //[{name: "pipeline_name", mapping: '["pipeline.PIPELINE_WRAPPER_NAME"]'}]
                        });
                        
                        datasetpanel.pipelines_panel.add(
                            new Ext.Container({
                                layout: 'column',
                                items: [{
                                    columnWidth: .20,
                                    items: [{
                                        xtype: 'button',
                                        height: '72px',
                                        width: '96px',
                                        scale: 'clovr',
                                        //                                            tooltip: {text: 'Click here to run CloVR Metagenomics'},
                                        tooltipType: 'title',
                                        text: "<img src='/clovr/images/"+p+"_icon.png'>",
                                        handler: function() {
                                            if(datasetpanel.pipelineCallback) {
                                                datasetpanel.pipelineCallback({dataset_name: config.dataset_name,
                                                                               pipeline_name: p
                                                                              });
                                            }
                                        }
                                    }]},{
                                        columnWidth: .80,
                                        items: [{
                                            xtype: 'grid',
                                            store: store,
                                            height: 200,
//                                            autoExpandColumn: 'pipeline',
                                            viewConfig: {
                                                forceFit: true
                                            },
                                            colModel: new Ext.grid.ColumnModel({
                                                columns: [
                                                    {id: 'inputs',
                                                     header: 'Inputs', 
                                                     dataIndex: "taskName",
                                                     renderer: renderInput},
                                                    {id: 'outputs',
                                                     header: 'outputs', 
                                                     dataIndex: "taskName",
                                                     renderer: renderOutput}
                                                ]
                                            })
                                        }]
                                    }]
                            }));
                    }
                });
                datasetpanel.pipelines_panel.doLayout();
                datasetpanel.pipelines_panel.getEl().unmask();
            }
        });
    }

});

Ext.reg('clovrdatasetpanel', clovr.TagGrid);

var getResultsByProtocol = function(data,config) {
    var results_by_protocol ={};
    Ext.each(clovr.getProtocols(), function(elm) {
        results_by_protocol[elm] = [];
    });
        
    var tag_regex = /.*TAG$/;
    Ext.each(data, function(elm) {
        var pipeconf = elm[1].config;
        for(key in pipeconf) {
            if(tag_regex.exec(key)) {
                if(pipeconf[key] == config.dataset_name) {
                    var prot = clovr.getPipelineToProtocol(pipeconf['pipeline.PIPELINE_TEMPLATE']);
                    results_by_protocol[prot].push(elm[1]);
                }
            }
        }
    })
    return results_by_protocol;
}

function renderInput(value, p, record) {
    var return_string="";
    var input_regexp = /^input/;
    var clean_input = /input\./;
    var inputs = [];
    for (field in record.json.config) {
        if(input_regexp.exec(field)) {
            inputs.push(field.replace(clean_input,"")+": "+ record.json.config[field]);
        }
    };

    if(record.data.state == "error") {
        return_string="Failed Pipeline "+ record.json.config['input.PIPELINE_NAME'];
    }
    else {
        return_string = "<div>"+inputs.join("<br/>")+"</div>";

//        return_string = String.format('output: {0}',record.data["output.TAGS_TO_DOWNLOAD"]);
    }
    return return_string;
}

function renderOutput(value, p, record) {
    var return_string="";
    var input_regexp = /^input/;
    var clean_input = /input\./;
    var inputs = [];
    for (field in record.json.config) {
        if(input_regexp.exec(field)) {
            inputs.push(field.replace(clean_input,"")+": "+ record.json.config[field]);
        }
    };

    var outputs = ["<a href='/output/"+record.json.config['input.PIPELINE_NAME']+"_"+
                   record.json.config["output.TAGS_TO_DOWNLOAD"]+".tar.gz'>"+record.json.config["output.TAGS_TO_DOWNLOAD"]+"</a>"];
    if(Ext.isArray(record.json.config["output.TAGS_TO_DOWNLOAD"])) {
        outputs = record.json.config["output.TAGS_TO_DOWNLOAD"];
    }
    
    if(record.data.state == "error") {
        return_string="Failed Pipeline "+ record.json.config['input.PIPELINE_NAME'];
    }
    else {
        return_string = "<div>"+outputs.join("<br/>")+"</div>";
    }
    return return_string;
}