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

// Workaround for odd Ext.ux.form.LovCombo clear-on-blur bug when using ExtJS3.
Ext.override(Ext.ux.form.LovCombo, {
    beforeBlur: Ext.emptyFn
})

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();

    /* Role drop-down */
    var role_store = new Ext.data.JsonStore({
        url:        url_role_list,
        root:       'objects',
        fields:     [{ name: 'role_id',  type: 'int' },
                     { name: 'rolename', type: 'string'}],
        sortInfo:   {
            field:     'rolename',
            direction: 'ASC',
        },
    });
    role_store.load();

    /* User form */
    var userForm = new MyFormPanel({

        url:         url_user_submit,
        title:       'User details',
            
        items: [
            
            { name:           'username',
              fieldLabel:     'Username',
              xtype:          'textfield',
              readOnly:       true, },
            
            { name:           'password',
              fieldLabel:     'Password',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'name',
              fieldLabel:     'Real name',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'email',
              fieldLabel:     'Email',
              xtype:          'textfield',
              allowBlank:     true, },

            { name:           'roles',  // FIXME this still doesn't pre-check the right boxes.
              fieldLabel:     'Roles',
              store:          role_store,
              triggerAction:  'all',
              mode:           'local',
              lazyRender:     true,
              valueField:     'role_id',
              displayField:   'rolename',
              xtype:          'lovcombo',
              allowBlank:     true, },

            { name:           'user_id',
              value:          user_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_user_load_form,
        idParams:    { user_id: user_id },
        waitMsg:     'Loading User details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'User Information',
              layout: 'anchor',
              items:  userForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'User Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Users', handler: function() { window.location = url_user_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

