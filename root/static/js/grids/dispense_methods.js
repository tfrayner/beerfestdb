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
    
    var DispenseMethod = Ext.data.Record.create([
        { name: 'dispense_method_id', type: 'int' },
        { name: 'description',        type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_dispense_method_list,
        root:       'objects',
        fields:     DispenseMethod
    });
    
    var content_cols = [
        { id:         'description',
          header:     'Description',
          dataIndex:  'description',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'dispensemethod/view/{dispense_method_id}');
        window.location=t.apply({dispense_method_id: record.get('dispense_method_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.dispense_method_id = record.get( 'dispense_method_id' );
        return(fields);
    }

    var panel = new MyMainPanel({
        title: 'All Dispense Methods',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Dispense Method',
                idField:            'dispense_method_id',
                autoExpandColumn:   'description',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_dispense_method_delete,
                submitUrl:          url_dispense_method_submit,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home',
              handler: function() { window.location = url_base; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

