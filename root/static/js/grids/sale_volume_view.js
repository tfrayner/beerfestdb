/*
 * This file is part of BeerFestDB, a beer festival product management
 * system.
 * 
 * Copyright (C) 2026 Tim F. Rayner
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();

    /* Container measure lookups */
    var measure_store = new Ext.data.JsonStore({
        url:        url_container_measure_list,
        root:       'objects',
        fields:     [{ name: 'container_measure_id',  type: 'int'    },
                     { name: 'description', type: 'string' }],
        idProperty: 'container_measure_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    /* sale volume form */
    var saleVolumeForm = new MyFormPanel({

        url:         url_sale_volume_submit,
        title:       'Sale Volume details',
            
        items: [

            { name:           'description',
              fieldLabel:     'Description',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'volume',
              fieldLabel:     'Volume',
              lazyRender:     true,
              xtype:          'numberfield',
              allowBlank:     false},
            
            { name:           'container_measure_id',
              fieldLabel:     'Container Measure',
              typeAhead:      true,
              triggerAction:  'all',
              store:          measure_store,
              valueField:     'container_measure_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'combo',
              allowBlank:     false, },
            
            { name:           'sale_volume_id',
              value:          sale_volume_id,
              xtype:          'hidden', },
            
        ],

        comboStores: [ measure_store, ],
        loadUrl:     url_sale_volume_load_form,
        idParams:    { sale_volume_id: sale_volume_id },
        waitMsg:     'Loading Sale Volume details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Sale Volume Information',
              layout: 'anchor',
              items:  saleVolumeForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Sale Volume Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

