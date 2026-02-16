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

    /* company region form */
    var companyRegionForm = new MyFormPanel({

        url:         url_company_region_submit,
        title:       'Company Region details',
            
        items: [

            { name:           'description',
              fieldLabel:     'Description',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'company_region_id',
              value:          company_region_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_company_region_load_form,
        idParams:    { company_region_id: company_region_id },
        waitMsg:     'Loading Company Region details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Company Region Information',
              layout: 'anchor',
              items:  companyRegionForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Company Region Details',            
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

