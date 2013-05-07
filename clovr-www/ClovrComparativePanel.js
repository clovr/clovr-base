/*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrComparativePanel = Ext.extend(Ext.Container, {

    constructor: function(config) {
        config.fields = config.pipelines['clovr_comparative'];
        config.protocol = 'clovr_comparative';
        config.id = 'clovr_comparative_form';
        var title = new Ext.Container({
            height: '30px',
            name: 'form_title',
            style: {
                'padding': '3px 0 2px 5px',
                'vertical-align': 'baseline', 
                'font-size': '16pt',
                'font-family': 'Trebuchet MS,helvetica,sans-serif',
                'line-height': '33px',
                'background': 'url("/clovr/images/clovr-vm-header-bg-short.png") repeat-x scroll center top'
            },
            region: 'north',
            html: config.protocol
        });
        var thispanel = this;
        var clovrform = this.createForm();
        config.form = clovrform
        // Fields that won't be drawn
        config.ignore_fields = [];
        this.protocol = config.protocol;
        // We'll use this field to store a reference to the field that is used for tag input.
        this.tag_field = null;
        
        // Generate the input fields
        var rets = this.createInputFields(config);
        var input_fieldset = rets[0];
        var genbank_fieldset = rets[1];
        var itemsArray = [input_fieldset,genbank_fieldset];
        
        // Generate the cluster fields
        var cluster_fieldset = this.createClusterFields(config);
        itemsArray.push(cluster_fieldset);
        
        // Generate all the other fields
        var other_fields = clovr.makeDefaultFieldsFromPipelineConfig(config.fields,config.ignore_fields);
        // add the normal ones...
        itemsArray.push(other_fields.normal);
        
        // add the advanced ones...
        itemsArray.push(
            {xtype: 'fieldset',
             title: 'Advanced',
             collapsible: true,
             listeners: {
                 afterlayout: {
                    fn: function(set) {
                        set.collapse();
                    },
                    single: true
                 }
             },
             items: other_fields.advanced
            });

        // add the hidden ones
        itemsArray.push(other_fields.hidden);
        
        // Add the fields to the form
        clovrform.add(itemsArray);
        
        // Call the parent constructor.
        clovr.ClovrComparativePanel.superclass.constructor.call(this, Ext.apply(config, {
            items: [title,clovrform],
            buttonAlign: 'center',
            style: {
                padding: '0px'
            },
            autoScroll: true,
//            frame: true,
//            defaults: {frame: false},
            style: {
                background: '#0D5685'
            },
            defaultType: 'textfield'
        }));
    },
    setInput: function(input_tag) {
//        console.log(this.tag_field);
//        this.getForm().setValues([{id: this.tag_field,
//                                  value: input_tag}]);
    },
    validate: function() {
        var panel = this;
        var credential = this.form.getForm().findField('cluster.CLUSTER_CREDENTIAL').getValue();
        var cluster_name = clovr.getClusterName({
            protocol: this.protocol+'_',
            credential: credential
        });
        var params = this.form.getForm().getValues();
        Ext.apply(params,{'cluster.CLUSTER_NAME': cluster_name,
                          'cluster.CLUSTER_CREDENTIAL': credential
                          });
        var genbank_ids = [];

        var store = panel.selectedseqsgrid.getStore();

        store.each(function(r,i,a) {
            genbank_ids.push(r.id);
        });

        Ext.apply(params,{'input.GENBANK_IDS': genbank_ids.join(',')});
        clovr.validatePipeline({
            pipeline: 'clovr_wrapper',
            wrappername: this.wrappername,
            cluster: cluster_name,
            params: params
        });    
    
    },
    run: function() {
        var panel = this;
        var credential = this.form.getForm().findField('cluster.CLUSTER_CREDENTIAL').getValue();
        var cluster_name = clovr.getClusterName({
            protocol: this.protocol+'_',
            credential: credential
        });
	    var params = this.form.getForm().getValues();
        Ext.apply(params,{'cluster.CLUSTER_NAME': cluster_name,
                          'cluster.CLUSTER_CREDENTIAL': credential
                          });
        var genbank_ids = [];
        panel.selectedseqsgrid.getStore().each(function(r,i,a) {
            genbank_ids.push(r.id);
        })
            Ext.apply(params,{'input.GENBANK_IDS': genbank_ids.join(',')});
            clovr.runPipeline({
            pipeline: 'clovr_wrapper',
            wrappername: this.wrappername,
            cluster: cluster_name,
            params: params,
            submitcallback: function(r) {
                panel.form.getForm().reset();
                panel.submitcallback(r);         
            }
        });
    
    },
    createClusterFields: function(config) {
        var credential_combo = clovr.credentialCombo({
            name: 'cluster.CLUSTER_CREDENTIAL',
            default_value: config.default_credential,
            hidden: config.hide_credential});
/*        var cluster_combo = clovr.clusterCombo({
            name: 'cluster.CLUSTER_NAME',
            default_value: config.default_cluster,
            hidden: config.hide_cluster
        });*/
        var cluster_fieldset = {
            xtype: 'fieldset',
            hideMode: 'visibility',
            title: 'CLoVR Cluster Selection',
            items: [credential_combo]};
        config.ignore_fields['cluster.CLUSTER_CREDENTIAL'] = 1;
        return cluster_fieldset;
    
    },
    createInputFields: function(config) {
        var thispanel = this;
        var input_fieldset = {xtype: 'fieldset',
             title: 'Input Data Sets'
        };
        var genbank_fieldset = {xtype: 'fieldset',
            title: 'Select Genomes from RefSeq',
//            layout: 'fit',
            layout: 'anchor',
            anchorSize: {height: 300}
        };
        var input_regexp = /^input.INPUT_/;
        var tag_regex = /.*TAG$/;

        var input_fields = [];
        Ext.each(config.fields, function(field, i, fields) {
            
            // This is a HACK to detect fields that are tags/datasets.
            if((field.type=='dataset' && field.visibility != 'default_hidden')) { //|| tag_regex.exec(field.name)) && field.visibilty != 'default_hidden') {
                var tag_combo = clovr.tagCombo({
                    fieldLabel: field.display,
                    field: field,
                    width: 225,
                    triggerAction: 'all',
                    mode: 'local',
                    valueField: 'name',
                    displayField: 'name',
                    forceSelection: true,
                    editable: false,
//                    submitValue: false,
                    lastQuery: '',
                    allowBlank: ! field.require_value,
                    listEmptyText: 'No available data of this type',
                    //emptyText: 'Nothing selected',
                    name: field.name,
                    tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>Format: {[values["metadata.format_type"]]}</div></tpl>',
                    filter: {
                        fn: function(record) {
                            var re_types = [];
                            Ext.each(field.type_params, function(type,i,params) {
                                if(type.format_type) {
                                    re_types.push(type.format_type.join('|'));
                                }
                            });
                            var restr = re_types.join('|');
                            var re = new RegExp(restr);
                            return re.test(record.data['metadata.format_type']);
                        }
                    },
                    listeners: {
                        select: function(combo,rec) {
    //                        wrapper_panel.load_pipeline_subform(config.pipelines);
                	    }
                    },
                    afterload: function() {
                       	tag_combo.fireEvent('select');
                    } 
                });
                input_fields.push(tag_combo);
		config.ignore_fields[field.name] = 1;
            }
			else if(field.name=='input.GENBANK_IDS') {


				config.ignore_fields[field.name] = 1;
				var genbank_id_store = new Ext.data.JsonStore({
					fields: ['orgName', 'refseqId', {
						name : 'seqLen',
						type : 'int'
					}],
					mode: 'local',
					autoLoad: false
				});
				var genbank_combo = new Ext.ux.form.SuperBoxSelect({
					field: field,
					mode: 'local',
					editable: true,
					returnString: true,
					store: genbank_id_store
				});
				var genbank_field = new Ext.form.CompositeField({
					fieldLabel: 'Genbank IDs to download',
					msgTarget: 'under',
					invalidClass: '',
					items: [
					    genbank_combo,
					    {xtype: 'button',
					    text: 'Select Sequences',
						    handler: function() {
						        thispanel.showComparativeTreeWindow({id_store: genbank_id_store});
						   }
					   }
				   ]
				});
				var newpanel = new clovr.ClovrComparativeTreePanel({width: '500px',height: '300px'});
				thispanel.selectedseqsgrid = newpanel.grid;
				var container = new Ext.Container({
				    anchor: '100%',
				    layout: 'fit',
				    height: 300,
				    items: [newpanel]
				});
				genbank_fieldset.items = [container];
//			    input_fields.push(container);
			}
            else if(field.type=='dataset list' && field.visibilty != 'default_hidden') {
                config.ignore_fields[field.name] = 1;                
                var tag_combo = clovr.tagSuperBoxSelect({
                    fieldLabel: field.display,
                    field: field,
                    width: 225,
                    triggerAction: 'all',
                    mode: 'local',
                    valueField: 'name',
                    displayField: 'name',
                    forceSelection: true,
                    editable: false,
                    returnString: true,
//                    submitValue: false,
                    lastQuery: '',
                    allowBlank: false,
                    name: field.name,
                    tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>Format: {[values["metadata.format_type"]]}</div></tpl>',
                    filter: {
                        fn: function(record) {
                            var re_types = [];
                            Ext.each(field.type_params, function(type,i,params) {
                                if(type.format_type) {
                                    re_types.push(type.format_type.join('|'));
                                }
                            });
                            var restr = re_types.join('|');
                            var re = new RegExp(restr);
                            return re.test(record.data['metadata.format_type']);
                        }
                    },
                    listeners: {
                        select: function(combo,rec) {
    //                        wrapper_panel.load_pipeline_subform(config.pipelines);
                	    }
                    },
                    afterload: function() {
                       	tag_combo.fireEvent('select');
                    } 
                });
                input_fields.push(tag_combo);
            }            
        });
        
        // add the input tag parameters to the input_fieldset
        input_fieldset.items = [input_fields];
        return [input_fieldset,genbank_fieldset];
    },
    createForm: function() {
        var panel = this;
        return new Ext.form.FormPanel({
            region: 'center',
            style: {
                'padding': '3px 3px 3px 3px'
            },
            frame: true,
//            defaults: {frame: true},
            buttonAlign: 'center',
            buttons: [{
                text: 'Clear',
                handler: function(b,e) {
                    panel.form.getForm().reset();
                }},{
                text: 'Validate',
                handler: function(b,e) {
                    panel.validate();
                }},{
                text: 'Run',
                handler: function(b,e) {
                    panel.run();
            }}]
        });    
    },
    // Display a window for selection of genomes
    showComparativeTreeWindow: function(config) {
        var win = new Ext.Window({
            layout: 'fit',
            height: 400,
            width: 600,
            closeAction: 'hide',
            autoScroll: true,
            title: 'CLoVR Comparative RefSeq selection'
        });

        var panel = new clovr.ClovrComparativeTreePanel({
            id_store: config.id_store,
            callback: function() {
                win.close();
            }
            });
        win.add(panel);
        win.show();
    }

});

Ext.reg('clovrcomparativepanel', clovr.ClovrComparativePanel);
