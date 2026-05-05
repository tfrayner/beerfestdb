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

    /* product allergen type form */
    var productAllergenTypeForm = new MyFormPanel({

        url:         url_product_allergen_submit,
        title:       'Product Allergen Type details',
            
        items: [

            { name:           'description',
              fieldLabel:     'Description',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'product_allergen_type_id',
              value:          product_allergen_type_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_product_allergen_type_load_form,
        idParams:    { product_allergen_type_id: product_allergen_type_id },
        waitMsg:     'Loading Product Allergen Type details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Product Allergen Type Information',
              layout: 'anchor',
              items:  productAllergenTypeForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Product Allergen Type Details',            
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

