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

    var CaskMeasurement = Ext.data.Record.create([
        { name: 'cask_measurement_id',    type: 'int' },
        { name: 'cask_id',                type: 'int' },
        { name: 'measurement_batch_id',   type: 'int' },
        { name: 'cask_comment',           type: 'string' },
        { name: 'comment',                type: 'string' },
        { name: 'internal_reference',     type: 'string' },
        { name: 'cellar_reference',       type: 'string' },
        { name: 'is_vented',              type: 'int' },
        { name: 'is_tapped',              type: 'int' },
        { name: 'is_ready',               type: 'int' },
        { name: 'is_condemned',           type: 'int' },
        { name: 'container_measure',      type: 'string' },
        { name: 'volume',                 type: 'string' }, // allows undef to be displayed correctly.
        { name: 'previous_volume',        type: 'float' },
        { name: 'brewer',                 type: 'string' },
        { name: 'product',                type: 'string' },        
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     CaskMeasurement,
    });
        
    var content_cols = [
        { id:         'brewer',
          header:     'Brewer',
          dataIndex:  'brewer',
          width:      50,
          editor:     new Ext.form.TextField({
              readOnly: true,
          })},
        { id:         'product',
          header:     'Beer',
          dataIndex:  'product',
          width:      70,
          editor:     new Ext.form.TextField({
              readOnly: true,
          })},
        { id:         'is_vented',
          header:     'Vented',
          dataIndex:  'is_vented',
          width:      30,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
        { id:         'is_tapped',
          header:     'Tapped',
          dataIndex:  'is_tapped',
          width:      30,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
        { id:         'is_ready',
          header:     'Ready',
          dataIndex:  'is_ready',
          width:      30,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
        { id:         'internal_reference',
          header:     'Cellar No.',
          dataIndex:  'internal_reference',
          width:      50,
          editor:     new Ext.form.NumberField({
              allowDecimals: false,
              readOnly: true,
          })},
        { id:         'cellar_reference',
          header:     'Festival ID',
          dataIndex:  'cellar_reference',
          width:      50,
          editor:     new Ext.form.NumberField({
              allowDecimals: false,
              readOnly: true,
          })},
        { id:         'previous_volume',
          header:     'Previous',
          dataIndex:  'previous_volume',
          width:      30,
          editor:     new Ext.form.NumberField({
              readOnly: true,
          })},
        { id:         'volume',
          header:     'Latest',
          dataIndex:  'volume',
          width:      30,
          renderer:   function(value) { return undefined != value ? value : '' },
          editor:     new Ext.form.NumberField({
              decimalPrecision: 1,
          })},
        { id:         'container_measure',
          header:     'Units',
          dataIndex:  'container_measure',
          width:      30,
          editor:     new Ext.form.TextField({
              readOnly: true,
          })},
        { id:         'cask_comment',
          header:     'Cask Comment',
          dataIndex:  'cask_comment',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'is_condemned',
          header:     'Condemned',
          dataIndex:  'is_condemned',
          width:      40,
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
        fields.cask_measurement_id  = record.get( 'cask_measurement_id' );
        fields.cask_id              = record.get( 'cask_id' );
        fields.measurement_batch_id = batch_id;
        return(fields);
    }

    var myGrid = new MyEditorGrid(
        {
            objLabel:           'Dip',
            idField:            'cask_measurement_id',
            autoExpandColumn:   'volume',
            store:              store,
            contentCols:        content_cols,
            viewLink:           viewLink,
            deleteUrl:          url_caskmeasurement_delete,
            submitUrl:          url_caskmeasurement_submit,
            recordChanges:      recordChanges,
        }
    );

    var panel = new Ext.Panel({
        title: stillagename + ': ' + batchtime,
        layout: 'fit',
        items: myGrid,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
            { text: 'Stillages', handler: function() { window.location = url_stillage_list; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

