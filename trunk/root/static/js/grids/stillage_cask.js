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
    
    var Cask = Ext.data.Record.create([
        { name: 'cask_id',           type: 'int' },
        { name: 'festival_id',       type: 'int' },
        { name: 'company_id',        type: 'int' },
        { name: 'product_id',        type: 'int' },
        { name: 'container_size_id', type: 'int' },
        { name: 'stillage_location_id', type: 'int' },
        { name: 'gyle_id',           type: 'int' },
        { name: 'int_reference',     type: 'string' },
        { name: 'comment',           type: 'string' },
        { name: 'is_vented',         type: 'int' },
        { name: 'is_tapped',         type: 'int' },
        { name: 'is_ready',          type: 'int' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     Cask
    });

    var brewer_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int'    },
                     { name: 'name',       type: 'string' }],
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
    });
    var brewer_combo = new Ext.form.ComboBox({
        store:          brewer_store,
        valueField:     'company_id',
        displayField:   'name',
        lazyRender:     true,
    });
    brewer_store.load();

    var product_store = new Ext.data.JsonStore({
        url:        url_product_list,
        root:       'objects',
        fields:     [{ name: 'product_id', type: 'int'    },
                     { name: 'name',       type: 'string' }],
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
    });
    var product_combo = new Ext.form.ComboBox({
        store:          product_store,
        valueField:     'product_id',
        displayField:   'name',
        lazyRender:     true,
    });
    product_store.load();

    var content_cols = [
        { id:         'company_id',
          header:     'Brewer',
          dataIndex:  'company_id',
          width:      130,
          renderer:   MyComboRenderer(brewer_combo),
          editable:   false, },            
        { id:         'product_id',
          header:     'Product',
          dataIndex:  'product_id',
          width:      130,
          renderer:   MyComboRenderer(product_combo),
          editable:     false, },
        { id:         'int_reference',
          header:     'Cask No.',
          dataIndex:  'int_reference',
          width:      50,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'is_vented',
          header:     'Vented',
          dataIndex:  'is_vented',
          width:      50,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
        { id:         'is_tapped',
          header:     'Tapped',
          dataIndex:  'is_tapped',
          width:      50,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
        { id:         'is_ready',
          header:     'Ready',
          dataIndex:  'is_ready',
          width:      50,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/cask/view/{cask_id}');
        window.location=t.apply({cask_id: record.get('cask_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.cask_id = record.get( 'cask_id' );
        return(fields);
    }

    var panel = new Ext.Panel({
        title: stillagename + ' cask listing',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Cask',
                idField:            'cask_id',
                autoExpandColumn:   'name',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_cask_delete,
                submitUrl:          url_cask_submit,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

