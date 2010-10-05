/*
 * A form panel that can take the parameter hash from the clovr web services
 * and make a form out of it.
 */

clovr.ClovrFormPanel = Ext.extend(Ext.form.FormPanel, {

    constructor: function(config) {

        var clovrform = this;
        
        // We'll use this field to store a reference to the field that is used for tag input.
        this.tag_field = null;

        var itemsArray = [];
        var input_regexp = /^input.INPUT_/;
        Ext.each(config.fields, function(field, i, props) {
            if(!field.display) {
                field.default_hidden=true;
            }
            
            if(input_regexp.exec(field.field)) {
                this.tag_field = field.field;
            }
            itemsArray.push(
                {
                    hidden: field.default_hidden,
                    hideLabel: field.default_hidden,
                    fieldLabel: field.display,
                    name: field.field,
                    value: field['default']
                });
        });
        config.items = itemsArray;
        clovr.ClovrFormPanel.superclass.constructor.call(this, Ext.apply(config, {
            itesm: itemsArray,
            buttonAlign: 'center',
            autoScroll: true,
            frame: true,
            buttons: [{text: 'Submit',
                       handler: function(b,e) {
                           console.log(clovrform.tag_field);
                           console.log(clovrform.tag_field);
                           console.log(clovrform.getForm().getValues());
                       }}],
            defaultType: 'textfield'
        }));

        // First step is to not display the INPUT_TAG parameter
        // as this parameter will be set based on the selected 
        // data set.
        
    },
    setInput: function(input_tag) {
        console.log(this.tag_field);
        this.getForm().setValues([{id: this.tag_field,
                                  value: input_tag}]);
    }
});

Ext.reg('clovrformpanel', clovr.ClovrFormPanel);
