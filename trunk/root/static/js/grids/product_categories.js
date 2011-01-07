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
    
    var ProductCategory = Ext.data.Record.create([
        { name: 'product_category_id',  type: 'int' },
        { name: 'description',          type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_category_list,
        root:       'objects',
        fields:     ProductCategory
    });
    
    var content_cols = [
        { id:         'description',
          header:     'Category Name',
          dataIndex:  'description',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/productcategory/grid/{product_category_id}');
        window.location=t.apply({product_category_id: record.get('product_category_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.product_category_id = record.get( 'product_category_id' );
        return(fields);
    }

    var panel = new Ext.Panel({
        title: 'All Product Categories',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Product Category',
                idField:            'product_category_id',
                autoExpandColumn:   'description',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_category_delete,
                submitUrl:          url_category_submit,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

