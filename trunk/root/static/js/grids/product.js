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
    
    var Product = Ext.data.Record.create([
        { name: 'product_id',       type: 'int' },
        { name: 'company_id',       type: 'int' },
        { name: 'name',             type: 'string',   allowBlank: false },
        { name: 'description',      type: 'string' },
        { name: 'comment',          type: 'string' },
        { name: 'nominal_abv',      type: 'float' },
        { name: 'product_style_id', type: 'int' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     Product
    });

    /* Supplier drop-down */
    var supplier_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}]
    });
    supplier_store.load();
    var brewer_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          supplier_store,
        valueField:     'company_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Product Style drop-down */
    var style_store = new Ext.data.JsonStore({
        url:        url_product_style_list,
        root:       'objects',
        fields:     [{ name: 'product_style_id', type: 'int'    },
                     { name: 'description',      type: 'string' }]
    });
    style_store.load();
    var style_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        forceSelection: true,
        store:          style_store,
        valueField:     'product_style_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var content_cols = [
        { id:         'company_id',
          header:     'Brewer',
          dataIndex:  'company_id',
          width:      130,
          renderer:   MyComboRenderer(brewer_combo),
          editor:     brewer_combo, },
        { id:         'name',
          header:     'Name',
          dataIndex:  'name',
          width:      130,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
        { id:         'nominal_abv',
          header:     'Advertised ABV',
          dataIndex:  'nominal_abv',
          width:      130,
          renderer:   function(value) { return value ? value : '' },
          editor:     new Ext.form.NumberField({
              allowBlank:     true,
          })},
        { id:         'description',
          header:     'Description',
          dataIndex:  'description',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'product_style_id',
          header:     'Style',
          dataIndex:  'product_style_id',
          width:      70,
          renderer:   MyComboRenderer(style_combo),
          editor:     style_combo },
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/product/view/{product_id}');
        window.location=t.apply({product_id: record.get('product_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.product_id = record.get( 'product_id' );
        fields.product_category_id = category_id;
        return(fields);
    }

    var panel = new Ext.Panel({
        title: festivalname + ' product listing: ' + categoryname,
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Product',
                idField:            'product_id',
                autoExpandColumn:   'name',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_product_delete,
                submitUrl:          url_product_submit,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
//            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

