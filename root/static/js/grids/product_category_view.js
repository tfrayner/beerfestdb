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

    var ProductStyle = Ext.data.Record.create([
        { name: 'product_style_id',    type: 'int' },
        { name: 'product_category_id', type: 'int' },
        { name: 'description',         type: 'string' },
    ]);

    var style_store = new Ext.data.JsonStore({
        url:        url_product_style_list,
        root:       'objects',
        fields:     ProductStyle,
	    idProperty: 'product_style_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    
    /* Style grid */
    var styleGrid = new MyEditorGrid(
        {
            objLabel:           'Product Style',
            idField:            'product_style_id',
            autoExpandColumn:   'description',
            deleteUrl:          url_productstyle_delete,
            submitUrl:          url_productstyle_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.product_style_id    = record.get( 'product_style_id' );
                fields.product_category_id = product_category_id;
                return(fields);
            },
            store:              style_store,
            contentCols: [
                { id:        'description',
                  header:    'Style Name',
                  dataIndex: 'description',
                  width:      150,
                  editor:     new Ext.form.TextField({
                      allowBlank: false,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate(url_base + 'productstyle/view/{product_style_id}');
                window.location=t.apply({
                    product_style_id: record.get('product_style_id'),
                })
            },
        }
    );
    
    var ProductCharacteristicType = Ext.data.Record.create([
        { name: 'product_characteristic_type_id',    type: 'int' },
        { name: 'product_category_id', type: 'int' },
        { name: 'description',         type: 'string' },
    ]);

    var characteristic_store = new Ext.data.JsonStore({
        url:        url_product_characteristic_type_list,
        root:       'objects',
        fields:     ProductCharacteristicType,
	    idProperty: 'product_characteristic_type_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    
    /* Characteristic grid */
    var characteristicGrid = new MyEditorGrid(
        {
            objLabel:           'Product Characteristic Type',
            idField:            'product_characteristic_type_id',
            autoExpandColumn:   'description',
            deleteUrl:          url_product_characteristic_type_delete,
            submitUrl:          url_product_characteristic_type_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.product_characteristic_type_id    = record.get( 'product_characteristic_type_id' );
                fields.product_category_id = product_category_id;
                return(fields);
            },
            store:              characteristic_store,
            contentCols: [
                { id:        'description',
                  header:    'Characteristic Name',
                  dataIndex: 'description',
                  width:      150,
                  editor:     new Ext.form.TextField({
                      allowBlank: false,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate(url_base + 'productcharacteristictype/view/{product_characteristic_type_id}');
                window.location=t.apply({
                    product_characteristic_type_id: record.get('product_characteristic_type_id'),
                })
            },
        }
    );
    
    /* product category form */
    var productCategoryForm = new MyFormPanel({

        url:         url_product_category_submit,
        title:       'Product Category details',
            
        items: [

            { name:           'description',
              fieldLabel:     'Description',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'product_category_id',
              value:          product_category_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_product_category_load_form,
        idParams:    { product_category_id: product_category_id },
        waitMsg:     'Loading Product Category details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Product Category Information',
              layout: 'anchor',
              items:  productCategoryForm, },
            { title: 'Product Styles',
              layout: 'fit',
              items:  styleGrid, },
            { title: 'Product Characteristic Types',
              layout: 'fit',
              items:  characteristicGrid, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Product Category Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Product Categories', handler: function() { window.location = url_product_category_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

