Ext.ns('Ext.ux.form');
Ext.ux.form.FieldTip = Ext.extend(Object, {
    init: function(field){
        field.on({
            focus: function(){
                if(!this.tip){
                    var tipCfg = {
                        autoHide: false,
                        anchor: this.qanchor
                    };
                    if (Ext.isString(this.qtip)) {
                        tipCfg.html = this.qtip;
                    } else {
                        tipCfg.html = this.qtip.text;
                        Ext.apply(tipCfg, this.qtip);
                    }
                    this.tip = new Ext.ToolTip(tipCfg);
                    this.tip.target = this.tip.anchorTarget = this.el;
                }
                if(!this.qshowfn) {
                    this.tip.show();
                } else {
                    this.qshowfn();
                }
            },
            blur: function(){
                if(this.tip){
                    if(!this.qblurhidefn) {
                        this.tip.hide();
                    } else {
                        this.qblurhidefn();
                    }
                    this.tip.hide();
                }
            },
            destroy: function(){
                if(this.tip){
                    this.tip.destroy();
                    delete this.tip;
                }
            }
        });
    }
});
Ext.preg('fieldtip', Ext.ux.form.FieldTip);
