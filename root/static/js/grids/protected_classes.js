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
    
    var Protected = Ext.data.Record.create([
        { name: 'protected_id', type: 'int' },
        { name: 'classname',    type: 'string' },
        { name: 'loader',       type: 'boolean' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_protected_list,
        root:       'objects',
        fields:     Protected,
        sortInfo:   {
            field:     'classname',
            direction: 'ASC',
        },
        idProperty: 'protected_id',
    });
    
    var content_cols = [
        { id:         'classname',
          header:     'Class Name',
          dataIndex:  'classname',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'loader',
          header:     'Loader Protected',
          dataIndex:  'loader',
          width:      100,
          editor:     new Ext.form.Checkbox({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'protected/view/{protected_id}');
        window.location=t.apply({protected_id: record.get('protected_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.protected_id = record.get( 'protected_id' );
        return(fields);
    }

    var panel = new MyMainPanel({
        title: 'All Protected Classes',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Protected Class',
                idField:            'protected_id',
                autoExpandColumn:   'classname',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_protected_delete,
                submitUrl:          url_protected_submit,
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

});

