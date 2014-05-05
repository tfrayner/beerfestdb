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

    /* Dip form */
    var caskmeasForm = new MyFormPanel({

        url:         url_caskmeasurement_submit,
        title:       'Cask Measurement details',
            
        items: [

            { name:           'measurement_batch_name',
              fieldLabel:     'Batch Name',
              lazyRender:     true,
              xtype:          'textfield',
              readOnly:       true},
            
            { name:           'measurement_time',
              fieldLabel:     'Measurement Time',
              lazyRender:     true,
              xtype:          'textfield',
              readOnly:       true},
            
            { name:           'volume',
              fieldLabel:     'Volume',
              lazyRender:     true,
              xtype:          'numberfield',
              allowBlank:     false},
            
            { name:           'comment',
              fieldLabel:     'Comment',
              lazyRender:     true,
              xtype:          'textarea',
              allowBlank:     true, },

            { name:           'cask_id',
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_cask_measurement_load_form,
        idParams:    { cask_measurement_id: cask_measurement_id },
        waitMsg:     'Loading Cask Measurement details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Cask Measurement',
              layout: 'anchor',
              items:  caskmeasForm, },
        ],
    });

    var panel = new MyMainPanel({
        title: 'Cask Measurement Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
            { text: 'Measurement Batch', handler: function() { window.location = url_measurement_batch_view; } },
            { text: 'Cask', handler: function() { window.location = url_cask_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

