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
    
    var category_store = new Ext.data.JsonStore({
        url:        url_category_list,
        root:       'objects',
        fields:     [{ name: 'product_category_id', type: 'int' },
                     { name: 'description',          type: 'string'}],
        idProperty: 'product_category_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    var ProductCharacteristicType = Ext.data.Record.create([
        { name: 'product_characteristic_type_id', type: 'int' },
        { name: 'product_category_id',            type: 'int' },
        { name: 'description',                    type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_product_characteristic_type_list,
        root:       'objects',
        fields:     ProductCharacteristicType
    });

    var category_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        allowBlank:     true,
        noSelection:    emptySelect,
        forceSelection: true,
        store:          category_store,
        valueField:     'product_category_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var content_cols = [
        { id:         'description',
          header:     'Description',
          dataIndex:  'description',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'product_category_id',
          header:     'Product Category',
          dataIndex:  'product_category_id',
          width:      150,
          renderer:    MyComboRenderer(category_combo),
          editor:      category_combo,
        },
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'productcharacteristictype/view/{product_characteristic_type_id}');
        window.location=t.apply({product_characteristic_type_id: record.get('product_characteristic_type_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.product_characteristic_type_id = record.get( 'product_characteristic_type_id' );
        return(fields);
    }

    var panel = new MyMainPanel({
        title: 'All Product Characteristic Types',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Product Characteristic Type',
                idField:            'product_characteristic_type_id',
                autoExpandColumn:   'description',
                store:              store,
                comboStores:        [ category_store ],
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_product_characteristic_type_delete,
                submitUrl:          url_product_characteristic_type_submit,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home',
              handler: function() { window.location = url_base; } },
            { text: 'Product Categories',
              handler: function() { window.location = url_category_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

