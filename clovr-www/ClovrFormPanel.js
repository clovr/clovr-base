/*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrFormPanel = Ext.extend(Ext.form.FormPanel, {

    constructor: function(config) {

        var clovrform = this;
        
        // We'll use this field to store a reference to the field that is used for tag input.
        this.tag_field = null;

        var input_fieldset = {xtype: 'fieldset',
             title: 'Input Data Sets'
            };
        var itemsArray = [input_fieldset];

        var input_regexp = /^input.INPUT_/;
        var tag_regex = /.*TAG$/;

        var advanced_params = [];
        var hidden_params = [];
        var input_params = [];
        
        Ext.each(config.fields, function(field, i, fields) {
            if(tag_regex.exec(field.field) && field.visibilty != 'default_hidden') {

                var fieldValue = field['default'];
                if(!fieldValue) {
                    fieldValue = 'Drag a data set here';
                }
                var dragCont = new Ext.Container({
                    fieldLabel: field.display,
                    ddGroup: 'tagDDGroup',
                    cls: 'input_drag_area',
                    width: 200,
                    html: fieldValue,
                    name: field.field,
                    listeners: {
                        render: function(container) {
                            var dropZone = new Ext.dd.DropTarget(container.el,{
                                ddGroup: 'tagDDGroup',
                                notifyEnter: function(s, e, d) {
                                    
                                    container.el.dom.style.backgroundColor = 'red';
                                    //                                    container.el.highlight();;
                                },
                                notifyOut: function(s, e, d) {
                                    container.el.dom.style.backgroundColor = '';
                                },
                                notifyDrop: function(s, e, d) {
                                    var tags = [];
                                    Ext.each(d.selections, function(row) {
                                        tags.push(row.data.name);
                                    });
                                    clovrform.getForm().setValues([{id: container.name, value: tags}]);
                                    container.update(tags.join(', '));
                                }
                            });
                        }}
                });
                input_params.push(dragCont);
                field.default_hidden=true;
            }
            if(field.visibility == 'default_hidden' && field.display) {
                advanced_params.push({xtype: 'textfield',
                                      fieldLabel: field.display,
                                      name: field.field,
                                      value: field['default'],
                                      disabled: false,
                                      toolTip: field.desc});
            }
            else if(field.visibility == 'always_hidden' || !field.visibility || !field.display) {
                hidden_params.push({xtype: 'textfield',
                                    fieldLabel: field.display,
                                    name: field.field,
                                    value: field['default'],
                                    hidden: true,
                                    hideLabel: true
                                   });
            }
            else {
                itemsArray.push(
                    {
                        hidden: field.default_hidden,
                        hideLabel: field.default_hidden,
                        fieldLabel: field.display,
                        name: field.field,
                        value: field['default']
                    });

            }
        });
        
        // add the input tag parameters to the input_fieldset
        input_fieldset.items = input_params;
        
        // add the advanced parameters to the items array
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
             items: advanced_params
            });

        // add the hidden params to the items array
        itemsArray.push(hidden_params);
        config.items = itemsArray;
        clovr.ClovrFormPanel.superclass.constructor.call(this, Ext.apply(config, {
            items: itemsArray,
            buttonAlign: 'center',
            autoScroll: true,
            frame: true,
            buttons: [{text: 'Submit',
                       handler: function(b,e) {
                           Ext.Ajax.request({
                               url: '/vappio/runPipeline_ws.py',
                               params: {
                                   'request': Ext.util.JSON.encode(
                                       {'pipeline_config':clovrform.getForm().getValues(),
                                        'pipeline': 'clovr_wrapper',
                                        'name': 'local',
                                        'pipeline_name': 'clovr_wrapper'+new Date().getTime()
                                       })
                               },
                               success: function(response) {
                                   Ext.Msg.show({
                                       title: 'Pipeline Submitted',
                                       msg: response.responseText
                                   })
                               },
                               failure: function(response) {
                                   Ext.Msg.show({
                                       title: 'Server Error',
                                       msg: response.responseText,
                                       icon: Ext.MessageBox.ERROR});
                               }                               
                           });
                       }}],
            defaultType: 'textfield'
        }));
    },
    setInput: function(input_tag) {
//        console.log(this.tag_field);
//        this.getForm().setValues([{id: this.tag_field,
//                                  value: input_tag}]);
    }
});

Ext.reg('clovrformpanel', clovr.ClovrFormPanel);
