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

    /* Telephone type drop-down */
    var phone_type_store = new Ext.data.JsonStore({
        url:        url_telephone_type_list,
        root:       'objects',
        fields:     [{ name: 'telephone_type_id', type: 'int' },
                     { name: 'description',       type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    /* Telephone form */
    var telephoneForm = new MyFormPanel({

        url:         url_telephone_submit,
        title:       'Telephone details',
            
        items: [

            { name:           'company_name',
              fieldLabel:     'Brewery',
              xtype:          'textfield',
              allowBlank:     true, 
              readOnly:       true, },
            
            { name:           'contact_type_desc',
              fieldLabel:     'Contact Type',
              xtype:          'textfield',
              allowBlank:     true, 
              readOnly:       true, },
            
            { name:           'telephone_type_id',
              fieldLabel:     'Telephone Type',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          phone_type_store,
              valueField:     'telephone_type_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },

            { name:           'international_code',
              fieldLabel:     'International Code',
              xtype:          'textfield',
              allowBlank:     true, },

            { name:           'area_code',
              fieldLabel:     'Area Code',
              xtype:          'textfield',
              allowBlank:     true, },
                        
            { name:           'local_number',
              fieldLabel:     'Local Number',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'extension',
              fieldLabel:     'Extension',
              xtype:          'textfield',
              allowBlank:     true, },

            { name:           'telephone_id',
              value:          telephone_id,
              xtype:          'hidden', },
            
        ],

        comboStores: [ phone_type_store ],
        loadUrl:     url_telephone_load_form,
        idParams:    { telephone_id: telephone_id },
        waitMsg:     'Loading Telephone details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Telephone Information',
              layout: 'anchor',
              items:  telephoneForm, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Telephone Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Company', handler: function() { window.location = url_company_view; } },
            { text: 'Contact', handler: function() { window.location = url_contact_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

