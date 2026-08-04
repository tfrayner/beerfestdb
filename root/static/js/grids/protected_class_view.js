/*
 * This file is part of BeerFestDB, a beer festival product management
 * system.
 * 
 * Copyright (C) 2026 Tim F. Rayner
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

    /* protected form */
    var protectedForm = new MyFormPanel({

        url:         url_protected_submit,
        title:       'Protected Class details',
            
        items: [

            { name:           'classname',
              fieldLabel:     'Class Name',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'loader',
              fieldLabel:     'Loader Protected',
              xtype:          'checkbox',
              allowBlank:     true, },

            { name:           'protected_id',
              value:          protected_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_protected_load_form,
        idParams:    { protected_id: protected_id },
        waitMsg:     'Loading Protected Class details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Protected Class Information',
              layout: 'anchor',
              items:  protectedForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Protected Class Details',
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Protected Classes', handler: function() { window.location = url_protected_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

