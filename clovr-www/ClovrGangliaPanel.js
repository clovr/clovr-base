/*
 * A panel to show images from Ganglia
 *
 */

clovr.ClovrGangliaPanel = Ext.extend(Ext.Panel, {

    constructor: function(config) {
        var GangliaPanel = this;
        var host = '';
        var dh = Ext.DomHelper;
        config.id = 'gangliapanel';
        var combo = clovr.clusterCombo({});
        combo.on({
            'select': {
                fn: function(c) {
                    GangliaPanel.getEl().mask('loading');
                    clovr.getClusterInfo({
                        cluster_name: c.getValue(),
                        callback: function(data) {
                            if(c.getValue() =='local') {
                                host = '';
                            }
                            else {
                                host = 'http://'+data.data.master.privateDNS;
                            }
                            GangliaPanel.loadImage(host);
                            GangliaPanel.getEl().unmask();
                        }
                    });
                }}
        });
        config.tbar = new Ext.Toolbar({
            items: [
                combo
                ]
        
        });

        if(config.cluster_name) {
            combo.setValue(config.cluster_name);
        }
        config.listeners= {
                'render': {
                    fn: function(panel) {
                        dh.append('gangliapanel', {tag: 'img', id:'card1img', src: host+"/ganglia/graph.php?g=load_report&z=medium&c=CloVR&m=load_one&r=hour&s=descending&hc=4&mc=2&st=" + new Date().getTime()});
                    },
                    options: {once: true}
                }
            };
        clovr.ClovrGangliaPanel.superclass.constructor.call(this, config);
    
        Ext.TaskMgr.start({
            run: function() {GangliaPanel.loadImage(host)},
            interval: 10000
        });
    },
    
    loadImage: function(host) {
        if(Ext.get('card1img')) {
            Ext.get('card1img').dom.src = host+ "/ganglia/graph.php?g=load_report&z=medium&c=CloVR&m=load_one&r=hour&s=descending&hc=4&mc=2&st=" + new Date().getTime(); 
            Ext.get('card1img').on('load', function() {this.show()},this,{single:true});
        }
    }
});
Ext.reg('clovrgangliapanel', clovr.ClovrGangliaPanel);
