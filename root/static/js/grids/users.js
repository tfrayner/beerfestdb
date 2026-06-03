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

    var user_store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     User
    });
    
    var user_content_cols = [
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
              allowBlank:     false,
              vtype:          'email',
          })},
    ];

    function viewUserLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'user/view/{user_id}');
        window.location=t.apply({user_id: record.get('user_id')});
    };

    function recordUserChanges (record) {
        var fields = record.getChanges();
        fields.user_id = record.get( 'user_id' );
        return(fields);
    }

    var userGrid = new MyEditorGrid(
        {
            objLabel:           'User',
            idField:            'user_id',
            autoExpandColumn:   'username',
            store:              user_store,
            contentCols:        user_content_cols,
            viewLink:           viewUserLink,
            deleteUrl:          url_user_delete,
            submitUrl:          url_user_submit,
            recordChanges:      recordUserChanges,
        }
    );

    var Role = Ext.data.Record.create([
        { name: 'role_id',   type: 'int' },
        { name: 'rolename',      type: 'string' },
    ]);

    var role_store = new Ext.data.JsonStore({
        url:        url_role_list,
        root:       'objects',
        fields:     Role
    });
    
    var role_content_cols = [
        { id:         'rolename',
          header:     'Role Name',
          dataIndex:  'rolename',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
    ];

    function viewRoleLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'role/view/{role_id}');
        window.location=t.apply({role_id: record.get('role_id')});
    };

    function recordRoleChanges (record) {
        var fields = record.getChanges();
        fields.role_id = record.get( 'role_id' );
        return(fields);
    }

    var roleGrid = new MyEditorGrid(
        {
            objLabel:           'Role',
            idField:            'role_id',
            autoExpandColumn:   'name',
            store:              role_store,
            contentCols:        role_content_cols,
            viewLink:           viewRoleLink,
            deleteUrl:          url_role_delete,
            submitUrl:          url_role_submit,
            recordChanges:      recordRoleChanges,
        }
    ); 

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            {
                title: 'Users',
                layout: 'fit',
                items: userGrid,
            },
            {
                title: 'Roles',
                layout: 'fit',
                items: roleGrid,
            }
        ],
    });


    var panel = new MyMainPanel({
        title: 'Database Users and Roles',
        layout: 'fit',
        items: tabpanel,
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

