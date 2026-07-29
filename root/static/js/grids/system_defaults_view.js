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

    var festival_store = new Ext.data.JsonStore({
        url:        url_festival_list,
        root:       'objects',
        fields:     ['festival_id', 'name'],
    });

    var festival_combo = new Ext.form.ComboBox({
        store:          festival_store,
        displayField:   'name',
        valueField:     'festival_id',
        mode:           'local',
        triggerAction:  'all',
        editable:       false,
        forceSelection: true,
        allowBlank:     false,
    });

    var currency_store = new Ext.data.JsonStore({
        url:        url_currency_list,
        root:       'objects',
        fields:     ['currency_id', 'currency_code'],
    });

    var currency_combo = new Ext.form.ComboBox({
        store:          currency_store,
        displayField:   'currency_code',
        valueField:     'currency_id',
        mode:           'local',
        triggerAction:  'all',
        editable:       false,
        forceSelection: true,
        allowBlank:     false,
    });

    var sale_volume_store = new Ext.data.JsonStore({
        url:        url_sale_volume_list,
        root:       'objects',
        fields:     ['sale_volume_id', 'description'],
    });

    var sale_volume_combo = new Ext.form.ComboBox({
        store:          sale_volume_store,
        displayField:   'description',
        valueField:     'sale_volume_id',
        mode:           'local',
        triggerAction:  'all',
        editable:       false,
        forceSelection: true,
        allowBlank:     false,
    });

    var product_category_store = new Ext.data.JsonStore({
        url:        url_product_category_list,
        root:       'objects',
        fields:     ['product_category_id', 'description'],
    });

    var product_category_combo = new Ext.form.ComboBox({
        store:          product_category_store,
        displayField:   'description',
        valueField:     'product_category_id',
        mode:           'local',
        triggerAction:  'all',
        editable:       false,
        forceSelection: true,
        allowBlank:     false,
    });

    var container_size_store = new Ext.data.JsonStore({
        url:        url_container_size_list,
        root:       'objects',
        fields:     ['container_size_id', 'description'],
    });

    var container_size_combo = new Ext.form.ComboBox({
        store:          container_size_store,
        displayField:   'description',
        valueField:     'container_size_id',
        mode:           'local',
        triggerAction:  'all',
        editable:       false,
        forceSelection: true,
        allowBlank:     false,
    });

    /* system defaults form */
    var systemDefaultsForm = new MyFormPanel({

        url:         url_system_defaults_submit,
        title:       'System Defaults',
            
        items: [
            { name:           'festival_id',
              fieldLabel:     'Festival',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          festival_store,
              valueField:     'festival_id',
              displayField:   'name',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },
            
            { name:           'currency_id',
              fieldLabel:     'Currency',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          currency_store,
              valueField:     'currency_id',
              displayField:   'currency_code',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },

            { name:           'sale_volume_id',
              fieldLabel:     'Sale Volume',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          sale_volume_store,
              valueField:     'sale_volume_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },

            { name:           'product_category_id',
              fieldLabel:     'Product Category',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          product_category_store,
              valueField:     'product_category_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },
            
            { name:           'container_size_id',
              fieldLabel:     'Container Size',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          container_size_store,
              valueField:     'container_size_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },
        ],

        comboStores: [festival_store, currency_store, sale_volume_store, product_category_store, container_size_store],

        loadUrl:     url_system_defaults_load_form,
        idParams:    { id: 1 },
        waitMsg:     'Loading System Defaults details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'System Defaults',
              layout: 'anchor',
              items:  systemDefaultsForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'System Defaults',
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

