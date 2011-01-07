/*
 * This file is part of BeerFestDB, a beer festival product management
 * system.
 * 
 * Copyright (C) 2010 Tim F. Rayner
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

    /* Company drop-down */
    var company_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}]
    });
    company_store.load();

    /* Product drop-down */
    var product_store = new Ext.data.JsonStore({
        url:        url_product_list,
        root:       'objects',
        fields:     [{ name: 'product_id', type: 'int' },
                     { name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}]
    });
    product_store.load();

    /* Sale volume drop-down */
    var volume_store = new Ext.data.JsonStore({
        url:        url_sale_volume_list,
        root:       'objects',
        fields:     [{ name: 'sale_volume_id', type: 'int' },
                     { name: 'description',    type: 'string'}]
    });
    volume_store.load();

    /* Currency drop-down */
    var currency_store = new Ext.data.JsonStore({
        url:        url_currency_list,
        root:       'objects',
        fields:     [{ name: 'currency_id',   type: 'int'    },
                     { name: 'currency_code', type: 'string' }]
    });
    currency_store.load();

    var fpForm = new MyFormPanel({

        url:         url_object_submit,
        title:       'Festival Product details',
            
        items: [
            { name:         'company_id',
              fieldLabel:   'Company',
              typeAhead:    true,
              store:        company_store,
              valueField:   'company_id',
              displayField: 'name',
              lazyRender:   true,
              xtype:        'combo',
              disabled:     true, },
            { name:         'product_id',
              fieldLabel:   'Product',
              typeAhead:    true,
              store:        product_store,
              valueField:   'product_id',
              displayField: 'name',
              lazyRender:   true,
              xtype:        'combo',
              disabled:     true, },
            { name:         'sale_price',
              fieldLabel:   'Sale Price',
              allowBlank:   true, },
            { name:         'sale_currency_id',
              fieldLabel:   'Sale Currency',
              typeAhead:    true,
              store:        currency_store,
              valueField:   'currency_id',
              displayField: 'currency_code',
              lazyRender:   true,
              xtype:        'combo',
              allowBlank:   false, },
            { name:         'sale_volume_id',
              fieldLabel:   'Sale Volume',
              typeAhead:    true,
              store:        volume_store,
              valueField:   'sale_volume_id',
              displayField: 'description',
              lazyRender:   true,
              xtype:        'combo',
              allowBlank:   false, },
            { name:       'festival_product_id',
              value:      festival_product_id,
              xtype:      'hidden', },
            { name:       'festival_id',
              value:      festival_id,
              xtype:      'hidden', },
        ],

        loadUrl:     url_fp_load_form,
        idParams:    { festival_product_id: festival_product_id },
        waitMsg:     'Loading Festival Product details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Festival Product Information',
              layout: 'anchor',
              items:  fpForm, },
        ],
    });

    var panel = new Ext.Panel({
        title: fpname,            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
            { text: 'Products', handler: function() { window.location = url_fp_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

