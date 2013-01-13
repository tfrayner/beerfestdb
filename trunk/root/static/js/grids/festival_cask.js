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
        { name: 'cask_id',              type: 'int' },
        { name: 'product_name',         type: 'string' },
        { name: 'company_name',         type: 'string' },
        { name: 'stillage_location_id', type: 'int' },
        { name: 'int_reference',        type: 'string' },
        { name: 'festival_ref',         type: 'string' },
        { name: 'container_size_id',    type: 'int' },
        { name: 'bar_id',               type: 'int' },
        { name: 'gyle_id',              type: 'int' },
        { name: 'stillage_bay',         type: 'int' },
        { name: 'comment',              type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     Cask
    });

    /* Cask size drop-down */
    var casksize_store = new Ext.data.JsonStore({
        url:        url_cask_size_list,
        root:       'objects',
        fields:     [{ name: 'container_size_id', type: 'int' },
                     { name: 'description',    type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    casksize_store.load();
    var casksize_combo = new Ext.form.ComboBox({
        store:          casksize_store,
        valueField:     'container_size_id',
        displayField:   'description',
        lazyRender:     true,
        triggerAction:  'all',
        mode:           'local',
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
    });

    /* Stillage drop-down */
    var stillage_store = new Ext.data.JsonStore({
        url:        url_stillage_list,
        root:       'objects',
        fields:     [{ name: 'stillage_location_id', type: 'int' },
                     { name: 'description',          type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    stillage_store.load();
    var stillage_combo = new MyComboBox({
        store:          stillage_store,
        valueField:     'stillage_location_id',
        displayField:   'description',
        lazyRender:     true,
        triggerAction:  'all',
        mode:           'local',
        forceSelection: true,
        allowBlank:     true,
        noSelection:    emptySelect,
        typeAhead:      true,
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
        { id:         'container_size_id',
          header:     'Cask size',
          dataIndex:  'container_size_id',
          width:      40,
          renderer:   MyComboRenderer(casksize_combo),
          editor:     casksize_combo },
        { id:         'stillage_location_id',
          header:     'Stillage',
          dataIndex:  'stillage_location_id',
          width:      130,
          renderer:   MyComboRenderer(stillage_combo),
          editor:     stillage_combo, },
        { id:         'stillage_bay',
          header:     'Bay',
          dataIndex:  'stillage_bay',
          width:      40,
          renderer:   function(value) { return value ? value : '' }, // bay zero is non-existent.
          editor:     new Ext.form.NumberField({
              allowDecimals:  false,
              allowBlank:     true,
          })},
        { id:         'festival_ref',
          header:     'Festival Cask ID',
          dataIndex:  'festival_ref',
          width:      40,
          editor:     new Ext.form.NumberField({
              allowDecimals:  false,
              allowBlank:     true,
          })},
        { id:         'int_reference',
          header:     'Cellar Cask No.',
          dataIndex:  'int_reference',
          width:      40,
          editor:     new Ext.form.NumberField({
              allowDecimals:  false,
              allowBlank:     true,
          })},
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      130,
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
        fields.cask_id     = record.get( 'cask_id' );
        fields.festival_id = festival_id;
        return(fields);
    }

    var myGrid = new MyEditorGrid(
        {
            objLabel:           'Cask',
            idField:            'cask_id',
            autoExpandColumn:   'product_id',
            store:              store,
            contentCols:        content_cols,
            viewLink:           viewLink,
            deleteUrl:          url_cask_delete,
            submitUrl:          url_cask_submit,
            recordChanges:      recordChanges,
        }
    );

    var panel = new MyMainPanel({
        title: festivalname + ' cask listing: ' + categoryname,
        layout: 'fit',
        items: myGrid,
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

