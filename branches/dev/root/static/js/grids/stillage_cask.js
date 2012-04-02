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
        { name: 'company_name',      type: 'string' },
        { name: 'product_name',      type: 'string' },
        { name: 'container_size_id', type: 'int' },
        { name: 'stillage_location_id', type: 'int' },
        { name: 'bay_position_id',   type: 'int' },
        { name: 'gyle_id',           type: 'int' },
        { name: 'int_reference',     type: 'string' },
        { name: 'ext_reference',     type: 'string' },
        { name: 'festival_ref',      type: 'string' },
        { name: 'comment',           type: 'string' },
        { name: 'is_vented',         type: 'int' },
        { name: 'is_tapped',         type: 'int' },
        { name: 'is_ready',          type: 'int' },
        { name: 'is_condemned',      type: 'int' },
        { name: 'is_sale_or_return', type: 'int' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     Cask
    });

    /* Bay position drop-down */
    var bay_position_store = new Ext.data.JsonStore({
        url:        url_bay_position_list,
        root:       'objects',
        fields:     [{ name: 'bay_position_id', type: 'int' },
                     { name: 'description',     type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    bay_position_store.load();
    var bay_position_combo = new MyComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        allowBlank:     true,
        noSelection:    emptySelect,
        forceSelection: true,
        store:          bay_position_store,
        valueField:     'bay_position_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    var content_cols = [
        { id:         'company_name',
          header:     'Brewer',
          dataIndex:  'company_name',
          width:      130,
          editor:     new Ext.form.TextField({
              readOnly:  true,
          })},            
        { id:         'product_name',
          header:     'Product',
          dataIndex:  'product_name',
          width:      130,
          editor:     new Ext.form.TextField({
              readOnly:  true,
          })},
        { id:         'festival_ref',
          header:     'Festival Cask ID',
          dataIndex:  'festival_ref',
          width:      50,
          editor:     new Ext.form.NumberField({
              allowDecimals:  false,
              allowBlank:     true,
          })},
        { id:         'int_reference',
          header:     'Cellar Cask No.',
          dataIndex:  'int_reference',
          width:      50,
          editor:     new Ext.form.NumberField({
              allowDecimals:  false,
              allowBlank:     true,
          })},
        { id:         'bay_position_id',
          header:     'Bay Position',
          dataIndex:  'bay_position_id',
          width:      70,
          renderer:   MyComboRenderer(bay_position_combo),
          editor:     bay_position_combo,
        },
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
        { id:         'is_sale_or_return',
          header:     'SOR',
          dataIndex:  'is_sale_or_return',
          width:      40,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
        { id:         'is_condemned',
          header:     'Condemned',
          dataIndex:  'is_condemned',
          width:      50,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
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

    var panel = new MyMainPanel({
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

