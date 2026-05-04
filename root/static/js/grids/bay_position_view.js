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

    /* bay position form */
    var bayPositionForm = new MyFormPanel({

        url:         url_bay_position_submit,
        title:       'Bay Position details',
            
        items: [

            { name:           'description',
              fieldLabel:     'Description',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'bay_position_id',
              value:          bay_position_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_bay_position_load_form,
        idParams:    { bay_position_id: bay_position_id },
        waitMsg:     'Loading Bay Position details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Bay Position Information',
              layout: 'anchor',
              items:  bayPositionForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Bay Position Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Bay Positions', handler: function() { window.location = url_bay_position_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

