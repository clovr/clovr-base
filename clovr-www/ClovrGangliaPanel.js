/*
 * A panel to show images from Ganglia
 *
 */

clovr.ClovrGangliaPanel = Ext.extend(Ext.Container, {

    constructor: function(config) {

        var dh = Ext.DomHelper;
        config.id = 'gangliapanel';
        config.hidden=true;
//        config.layout = 'card';
//        var card1 = new Ext.Container({id: 'card1',
        config.listeners= {
                'render': {
                    fn: function(panel) {
//                        dh.append('gangliapanel', {tag: 'img', id:'card1img', src: "/ganglia/graph.php?g=load_report&z=medium&c=CloVR&m=load_one&r=hour&s=descending&hc=4&mc=2&st=" + new Date().getTime()});
                        
                    },
                    options: {once: true}
                }
            };

//        var card2 = new Ext.Container({id: 'card2',
//            listeners: {
//                'render': function() {dh.append('card2', {tag: 'img', id:'card2img', src: "/ganglia/graph.php?g=load_report&z=medium&c=CloVR&m=load_one&r=hour&s=descending&hc=4&mc=2&st=" + new Date().getTime()})
//                 }
//            }});
//        config.items = [card1,card2];
//        config.activeItem = 'card1';
        var GangliaPanel = this;
        clovr.ClovrGangliaPanel.superclass.constructor.call(this, config);
    
        Ext.TaskMgr.start({
            run: function() {
//                if(GangliaPanel.getLayout().activeItem =='card1') {
//                    Ext.get('card2img').dom.src ="/ganglia/graph.php?g=load_report&z=medium&c=CloVR&m=load_one&r=hour&s=descending&hc=4&mc=2&st=" + new Date().getTime();
//                }
//                else {
                    Ext.get('card1img').dom.src ="/ganglia/graph.php?g=load_report&z=medium&c=CloVR&m=load_one&r=hour&s=descending&hc=4&mc=2&st=" + new Date().getTime(); 
                    Ext.get('card1img').on('load', function() {GangliaPanel.show()},this,{single:true});
//                }
            },
            interval: 10000
        });
    }
});
Ext.reg('clovrgangliapanel', clovr.ClovrGangliaPanel);
