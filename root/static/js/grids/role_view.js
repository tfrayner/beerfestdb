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

    /* Product Category drop-down */
    var product_category_store = new Ext.data.JsonStore({
        url:        url_product_category_list,
        root:       'objects',
        fields:     [{ name: 'product_category_id',  type: 'string' }, // Technically int, but we cast to string for lovcombo handling.
                     { name: 'description', type: 'string' },],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    /* Role form */
    var roleForm = new MyFormPanel({

        url:         url_role_submit,
        title:       'Role details',
            
        items: [
            
            { name:           'rolename',
              fieldLabel:     'Role Name',
              xtype:          'textfield',
              readOnly:       true, },
            
            { name:           'categories',
              fieldLabel:     'Categories',
              store:          product_category_store,
              triggerAction:  'all',
              mode:           'local',
              lazyRender:     true,
              valueField:     'product_category_id',
              displayField:   'description',
              emptyText:      'Select categories...',
              hideOnSelect:   false,
              queryMode:      'local',
              multiSelect:    true,
              xtype:          'lovcombo',
              allowBlank:     true, },

            { name:           'role_id',
              value:          role_id,
              xtype:          'hidden', },
            
        ],

        comboStores: [ product_category_store ],
        loadUrl:     url_role_load_form,
        idParams:    { role_id: role_id },
        waitMsg:     'Loading Role details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Role Information',
              layout: 'anchor',
              items:  roleForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Role Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Users and Roles', handler: function() { window.location = url_user_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

