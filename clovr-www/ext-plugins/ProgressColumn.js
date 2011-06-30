/**
 * @class Ext.ux.ProgressColumn
 * <p>Copyright Nige (Animal) White and Athena Capital Research, LLC. This software may be used under
 * the terms of the <a href="http://en.wikipedia.org/wiki/BSD_licenses">BSD licence.</a></p>
 * <p>This class renders a progress bar in its cells. The proportion may be calculated by configuring:</p><ul>
 * <li>A {@link #divisor}. This divides the cell's value by the specified Field's value.</li>
 * <li>A {@link #dividend}. This divides the specified Field's value by the cell's value.</li>
 * <li>An injected implementation of {@link getFraction}.</li>
 * </ul>
 * <p>A renderer function may be specified in the usual way to produce a string value to display within the bar.</p>
 * <p>The precise appearance of the background area of the cell may be specified by creating CSS rules which apply
 * to the class <code>ux-progress-cell-background</code>.</p>
 * <p>The precise appearance of the filled area of the bar may be specified by creating CSS rules which apply
 * to the class name returned from the {@link getBarClass} method.</p>
 */
Ext.ux.ProgressColumn = Ext.extend(Ext.grid.Column, {
    /**
     * @cfg {String} align Optional. Set the CSS text-align property of the column.  Defaults to 'left'.
     */
    /**
     * @cfg {String} divisor Optional. The name of a Field by which to divide this column's value to yield the proportional width of the filled bar.
     */
    /**
     * @cfg {String} dividend Optional. The name of a Field to divide by this column's value to yield the proportional width of the filled bar.
     */

    tpl: new Ext.XTemplate(
        '<tpl if="align == \'left\'">',
            '<div class="ux-progress-cell-inner ux-progress-cell-inner-{align} ux-progress-cell-background">',
                '<div>{value}</div>',
            '</div>',
            '<div class="ux-progress-cell-inner ux-progress-cell-inner-{align} ux-progress-cell-foreground {cls}" style="width:{pct}%" ext:qtip="{qtip}">',
                '<div ext:qtip="{qtip}">{value}</div>',
            '</div>',
        '</tpl>',
        '<tpl if="align != \'left\'">',
            '<div class="ux-progress-cell-inner ux-progress-cell-inner-{align} ux-progress-cell-foreground {cls}" ext:qtip="{qtip}">',
                '<div ext:qtip="{qtip}">{value}</div>',
            '</div>',
            '<div class="ux-progress-cell-inner ux-progress-cell-inner-{align} ux-progress-cell-background" style="left:{pct}%">',
                '<div style="left:-{pct}%">{value}</div>',
            '</div>',
        '</tpl>'
    ),

    constructor: function(config) {
        if (config.renderer) {
            this.baseRenderer = config.renderer;
            config = Ext.apply({}, config);
            delete config.renderer;
        }
        Ext.grid.Column.call(this, config);
        this.renderer = Ext.ux.ProgressColumn.prototype.renderer.createDelegate(this);
    },

    /**
     * This function returns a class name to add to the filled section of the bar which may then be used
     * to provide different appearances depending upon the fraction the cell represents. The default
     * implementation which may be overridden returns:<ul>
     * <li>'high' if fraction > 0.98</li>
     * <li>'medium' if fraction > 0.75</li>
     * <li>'low' otherwise</li>
     * </ul>
     * @param {Number} fraction The fraction represented by this Column.
     */
    getBarClass: function(fraction) {
        return (fraction > 0.98) ? 'high' : (fraction > 0.75) ? 'medium' : 'low';
    },

    /**
     * <p>This function returns the proportion to render as the filled section of the bar as a floating
     * point value between zero and one.</p>
     * <p>The provided implementation either divides this Column's value by a configured {@link @divisor}
     * or divides a configured {@dividend} by this Column's value. A custom implementation may be injected
     * as a configuration option.</p>
     * This function is called with the following parameters:<ul>
     * <li><b>value</b> : Object<p class="sub-desc">The data value for the cell.</p></li>
     * <li><b>metadata</b> : Object<p class="sub-desc">An object in which you may set the following attributes:<ul>
     * <li><b>css</b> : String<p class="sub-desc">A CSS class name to add to the cell's TD element.</p></li>
     * <li><b>attr</b> : String<p class="sub-desc">An HTML attribute definition string to apply to the data container element <i>within</i> the table cell
     * (e.g. 'style="color:red;"').</p></li></ul></p></li>
     * <li><b>record</b> : Ext.data.record<p class="sub-desc">The {@link Ext.data.Record} from which the data was extracted.</p></li>
     * <li><b>rowIndex</b> : Number<p class="sub-desc">Row index</p></li>
     * <li><b>colIndex</b> : Number<p class="sub-desc">Column index</p></li>
     * <li><b>store</b> : Ext.data.Store<p class="sub-desc">The {@link Ext.data.Store} object from which the Record was extracted.</p></li></ul>
     * @return {Number} The fraction represented by this Column.
     */
    getFraction: function(value, meta, record, rowIndex, colIndex, store) {
       var fraction = 0;
        if (record) {
            if (this.dividend) {
                fraction = record.get(this.dividend) / value;
            } else if (this.divisor) {
                fraction = value / record.get(this.divisor);
            }
            if (fraction < 0) {
                fraction = 0;
            } else if (fraction > 1) {
                fraction = 1;
            }
        }
        return fraction;
    },

    /**
     * <p>This function returns a string to use as the tooltip when hovering over the filled bar.</p>
     * <p>The provided implementation displays the proportion as a percentage value rounded to two decimal places.
     * A custom implementation may be injected as a configuration option.</p>
     * This function is called with the following parameters:<ul>
     * <li><b>value</b> : Object<p class="sub-desc">The data value for the cell.</p></li>
     * <li><b>metadata</b> : Object<p class="sub-desc">An object in which you may set the following attributes:<ul>
     * <li><b>css</b> : String<p class="sub-desc">A CSS class name to add to the cell's TD element.</p></li>
     * <li><b>attr</b> : String<p class="sub-desc">An HTML attribute definition string to apply to the data container element <i>within</i> the table cell
     * (e.g. 'style="color:red;"').</p></li></ul></p></li>
     * <li><b>record</b> : Ext.data.record<p class="sub-desc">The {@link Ext.data.Record} from which the data was extracted.</p></li>
     * <li><b>rowIndex</b> : Number<p class="sub-desc">Row index</p></li>
     * <li><b>colIndex</b> : Number<p class="sub-desc">Column index</p></li>
     * <li><b>store</b> : Ext.data.Store<p class="sub-desc">The {@link Ext.data.Store} object from which the Record was extracted.</p></li></ul>
     * <li><b>pct</b> : Number<p class="sub-desc">The calculated percentage.</p></li></ul>
     * @return {String} The message to display as a tooltip when hovering over the filled bar.
     */
    getQtip: function(value, meta, record, rowIndex, colIndex, store, pct) {
        return Ext.util.Format.number(pct, "0.00%");
    },

    // private
    baseRenderer: function(v) {
        return v;
    },

    // private
    renderer: function(value, meta, record, rowIndex, colIndex, store) {
    
    	if(record.json.state == 'running' || record.json.state == 'failed') {
        var fraction = this.getFraction.apply(this, arguments),
            pct = fraction * 100,
            displayVal;

        Array.prototype.push.call(arguments, pct);
        displayVal = this.baseRenderer.apply(this, arguments);
        if (record) {
            meta.css += ' x-grid3-td-progress-cell';
            return this.tpl.apply({
                align: this.align || 'left',
                value: displayVal,
                pct: fraction * 100,
                qtip: this.getQtip.apply(this, arguments),
                cls: this.getBarClass(fraction)
            });
        } else {
            return displayVal;
        }
        }
        else { 
        	return record.json.state;
        }
    }
});