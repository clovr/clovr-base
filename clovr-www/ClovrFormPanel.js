/*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrFormPanel = Ext.extend(Ext.Container, {

    constructor: function(config) {
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
        var clovrform = this.createForm();
        config.form = clovrform
        // Fields that won't be drawn
        config.ignore_fields = [];
        
        // We'll use this field to store a reference to the field that is used for tag input.
        this.tag_field = null;
        
        // Generate the input fields
        var input_fieldset = this.createInputFields(config);
        
        var itemsArray = [input_fieldset];
        
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
        clovr.ClovrFormPanel.superclass.constructor.call(this, Ext.apply(config, {
            items: [title,clovrform],
            buttonAlign: 'center',
            style: {
                padding: '0px'
            },
            autoScroll: true,
            frame: true,
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
        clovr.validatePipeline({
            pipeline: 'clovr_wrapper',
            wrappername: this.wrappername,
            cluster: this.cluster_name,
            params: this.form.getForm().getValues()
        });    
    
    },
    run: function() {
        var panel = this;
        clovr.runPipeline({
            pipeline: 'clovr_wrapper',
            wrappername: this.wrappername,
            cluster: this.cluster_name,
            params: this.form.getForm().getValues(),
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
        var input_fieldset = {xtype: 'fieldset',
             title: 'Input Data Sets'
            };
        var input_regexp = /^input.INPUT_/;
        var tag_regex = /.*TAG$/;

        var input_fields = [];
        Ext.each(config.fields, function(field, i, fields) {
            if(tag_regex.exec(field.name) && field.visibilty != 'default_hidden') {
                config.ignore_fields[field.name] = 1;
                var tag_combo = clovr.tagCombo({
                    fieldLabel: field.display,
                    width: 225,
                    triggerAction: 'all',
                    mode: 'local',
                    valueField: 'name',
                    displayField: 'name',
                    forceSelection: true,
                    editable: false,
//                    submitValue: false,
                    lastQuery: '',
                    allowBlank: false,
                    name: field.name,
                    tpl: '<tpl for="."><div class="x-combo-list-item"><b>{name}</b><br/>Format: {[values["metadata.format_type"]]}</div></tpl>',
                    filter: {
                        fn: function(record) {
                            var re_types = [];
                            Ext.each(field.type_params, function(type,i,params) {
                                re_types.push(type.format_type);
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
        }});
        
        // add the input tag parameters to the input_fieldset
        input_fieldset.items = [input_fields];
        return input_fieldset;
    },
    createForm: function() {
        var panel = this;
        return new Ext.form.FormPanel({
            region: 'center',
            style: {
                'padding': '3px 3px 3px 3px'
            },
            frame: true,
            buttonAlign: 'center',
            buttons: [{
                text: 'Validate',
                handler: function(b,e) {
                    panel.validate();
                }},{
                text: 'Run',
                handler: function(b,e) {
                    panel.run();
            }}]
        });    
    }
});

Ext.reg('clovrformpanel', clovr.ClovrFormPanel);
