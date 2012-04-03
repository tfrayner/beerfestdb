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
    
    var User = Ext.data.Record.create([
        { name: 'user_id',   type: 'int' },
        { name: 'username',  type: 'string' },
        { name: 'password',  type: 'string' },
        { name: 'name',      type: 'string' },
        { name: 'email',     type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     User
    });
    
    var content_cols = [
        { id:         'username',
          header:     'Username',
          dataIndex:  'username',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
        { id:         'name',
          header:     'Real name',
          dataIndex:  'name',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'email',
          header:     'Email',
          dataIndex:  'email',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/user/view/{user_id}');
        window.location=t.apply({user_id: record.get('user_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.user_id = record.get( 'user_id' );
        return(fields);
    }

    var panel = new MyMainPanel({
        title: 'Database user listing: ',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'User',
                idField:            'user_id',
                autoExpandColumn:   'username',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_user_delete,
                submitUrl:          url_user_submit,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home',
              handler: function() { window.location = '/'; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

