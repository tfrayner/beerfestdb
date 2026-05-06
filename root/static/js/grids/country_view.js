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

    /* country form */
    var countryForm = new MyFormPanel({

        url:         url_country_submit,
        title:       'Country details',
            
        items: [

            { name:           'country_name',
              fieldLabel:     'Country Name',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'country_code_iso2',
              fieldLabel:     'ISO 3166-1 alpha-2 code',
              xtype:          'textfield',
              maxLength:      2,
              allowBlank:     false, },

            { name:           'country_code_iso3',
              fieldLabel:     'ISO 3166-1 alpha-3 code',
              xtype:          'textfield',
              maxLength:      3,
              allowBlank:     false, },

            { name:           'country_code_num3',
              fieldLabel:     'ISO 3166-1 numeric code',
              xtype:          'textfield',
              maxLength:      3,
              allowBlank:     false, },

            { name:           'country_id',
              value:          country_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_country_load_form,
        idParams:    { country_id: country_id },
        waitMsg:     'Loading Country details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Country Information',
              layout: 'anchor',
              items:  countryForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Country Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Countries', handler: function() { window.location = url_country_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

