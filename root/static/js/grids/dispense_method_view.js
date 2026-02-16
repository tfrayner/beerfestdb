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

    /* dispense method form */
    var dispenseMethodForm = new MyFormPanel({

        url:         url_dispense_method_submit,
        title:       'Dispense Method details',
            
        items: [

            { name:           'description',
              fieldLabel:     'Description',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'dispense_method_id',
              value:          dispense_method_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_dispense_method_load_form,
        idParams:    { dispense_method_id: dispense_method_id },
        waitMsg:     'Loading Dispense Method details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Dispense Method Information',
              layout: 'anchor',
              items:  dispenseMethodForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Dispense Method Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

