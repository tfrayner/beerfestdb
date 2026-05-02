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

    /* gyle form */
    var gyleForm = new MyFormPanel({

        url:         url_gyle_submit,
        title:       'Gyle details',
            
        items: [

            { name:           'festival_name',
              fieldLabel:     'Festival Name',
              xtype:          'textfield',
              allowBlank:     true,
              readOnly:       true, },
            
            { name:           'company_name',
              fieldLabel:     'Brewery',
              xtype:          'textfield',
              allowBlank:     true, 
              readOnly:       true, },
            
            { name:           'abv',
              fieldLabel:     'Gyle ABV',
              xtype:          'numberfield',
              allowBlank:     true, },

            { name:           'int_reference',
              fieldLabel:     'Internal Reference',
              xtype:          'textfield',
              allowBlank:     true, },
                        
            { name:           'ext_reference',
              fieldLabel:     'External Reference',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'comment',
              fieldLabel:     'Comment',
              xtype:          'textarea',
              allowBlank:     true, },

            { name:           'gyle_id',
              value:          gyle_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_gyle_load_form,
        idParams:    { gyle_id: gyle_id },
        waitMsg:     'Loading Gyle details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Gyle Information',
              layout: 'anchor',
              items:  gyleForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Gyle Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Company', handler: function() { window.location = url_company_view; } },
            { text: 'Festival', handler: function() { window.location = url_festival_product_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

