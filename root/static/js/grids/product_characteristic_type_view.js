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

    /* product characteristic type form */
    var productCharacteristicTypeForm = new MyFormPanel({

        url:         url_product_characteristic_type_submit,
        title:       'Product Characteristic Type details',
            
        items: [

            { name:           'description',
              fieldLabel:     'Description',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'product_characteristic_type_id',
              value:          product_characteristic_type_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_product_characteristic_type_load_form,
        idParams:    { product_characteristic_type_id: product_characteristic_type_id },
        waitMsg:     'Loading Product Characteristic Type details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Product Characteristic Type Information',
              layout: 'anchor',
              items:  productCharacteristicTypeForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Product Characteristic Type Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Product Categories', handler: function() { window.location = url_category_view; } },
            { text: 'Characteristic Types', handler: function() { window.location = url_product_characteristic_type_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

