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

    /* currency form */
    var currencyForm = new MyFormPanel({

        url:         url_currency_submit,
        title:       'Currency details',
            
        items: [

            { name:           'currency_code',
              fieldLabel:     'Currency Code',
              xtype:          'textfield',
              maxLength:      3,
              allowBlank:     false, },

            { name:           'currency_number',
              fieldLabel:     'Currency Number',
              xtype:          'textfield',
              maxLength:      3,
              allowBlank:     false, },

            { name:           'currency_format',
              fieldLabel:     'Currency Format',
              xtype:          'textfield',
              maxLength:      20,
              allowBlank:     false, },

            { name:           'exponent',
              fieldLabel:     'Exponent',
              xtype:          'numberfield',
              allowDecimals:  false,
              allowNegative:  false,
              minValue:       0,
              maxValue:       10,
              allowBlank:     false, },

            { name:           'currency_symbol',
              fieldLabel:     'Currency Symbol',
              xtype:          'textfield',
              maxLength:      10,
              allowBlank:     false, },

            { name:           'currency_id',
              value:          currency_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_currency_load_form,
        idParams:    { currency_id: currency_id },
        waitMsg:     'Loading Currency details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Currency Information',
              layout: 'anchor',
              items:  currencyForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Currency Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Currencies', handler: function() { window.location = url_currency_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

