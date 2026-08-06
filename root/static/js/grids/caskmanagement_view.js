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

// This override allows us to avoid zeroes from the database polluting
// our number fields for e.g. year_founded. This affects all
// NumberFields so is set on a per-view basis.
Ext.override(Ext.form.NumberField, {
    setValue : function(v){
        v = v == 0 ? null : v
        return Ext.form.NumberField.superclass.setValue.call(this, v);
    }
});

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();

    /* Stillage drop-down */
    var stillage_store = new Ext.data.JsonStore({
        url:        url_stillage_list,
        root:       'objects',
        fields:     [{ name: 'stillage_location_id', type: 'int' },
                     { name: 'description',          type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    /* Bay position drop-down */
    var bay_position_store = new Ext.data.JsonStore({
        url:        url_bay_position_list,
        root:       'objects',
        fields:     [{ name: 'bay_position_id', type: 'int' },
                     { name: 'description',     type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    /* Cask size drop-down */
    var casksize_store = new Ext.data.JsonStore({
        url:        url_cask_size_list,
        root:       'objects',
        fields:     [{ name: 'container_size_id', type: 'int' },
                     { name: 'description',    type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    /* Currency drop-down */
    var currency_store = new Ext.data.JsonStore({
        url:        url_currency_list,
        root:       'objects',
        fields:     [{ name: 'currency_id',   type: 'int'    },
                     { name: 'currency_code', type: 'string' }],
	idProperty: 'currency_id',
        sortInfo:   {
            field:     'currency_code',
            direction: 'ASC',
        },
    });

    /* Distributor drop-down */
    var dist_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}],
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
    });

    /* CaskManagement form */
    var caskManagementForm = new MyFormPanel({

        url:         url_caskmanagement_submit,
        title:       'Cask Management',
            
        items: [

            { name:           'company_name',
              fieldLabel:     'Company',
              lazyRender:     true,
              xtype:          'textfield',
              readOnly:       true},
            
            { name:           'product_name',
              fieldLabel:     'Product',
              lazyRender:     true,
              xtype:          'textfield',
              readOnly:       true},
            
            { name:           'container_size_id',
              fieldLabel:     'Cask Size',
              typeAhead:      true,
              triggerAction:  'all',
              store:          casksize_store,
              valueField:     'container_size_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              allowBlank:     false, },
            
            { name:           'distributor_id',
              fieldLabel:     'Distributor',
              typeAhead:      true,
              triggerAction:  'all',
              store:          dist_store,
              valueField:     'company_id',
              displayField:   'name',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },
            
            { name:           'price',
              fieldLabel:     'Cask Price',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'currency_id',
              fieldLabel:     'Currency',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          currency_store,
              forceSelection: true,
              valueField:     'currency_id',
              displayField:   'currency_code',
              lazyRender:     true,
              xtype:          'mycombo',
              allowBlank:     false, },
            
            { name:           'festival_name',
              fieldLabel:     'Festival',
              lazyRender:     true,
              xtype:          'textfield',
              readOnly:       true},
            
            { name:           'festival_ref',
              fieldLabel:     'Festival Cask ID',
              lazyRender:     true,
              xtype:          'numberfield',
              allowBlank:     true},
            
            { name:           'int_reference',
              fieldLabel:     'Cellar Cask No.',
              lazyRender:     true,
              xtype:          'numberfield',
              allowBlank:     true},
            
            { name:           'is_sale_or_return',
              fieldLabel:     'Is SOR',
              lazyRender:     true,
              xtype:          'checkbox',
              allowBlank:     true },

            { name:           'stillage_location_id',
              fieldLabel:     'Stillage',
              typeAhead:      true,
              triggerAction:  'all',
              store:          stillage_store,
              valueField:     'stillage_location_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },

            { name:           'stillage_bay',
              fieldLabel:     'Bay No.',
              lazyRender:     true,
              xtype:          'numberfield',
              allowBlank:     true},
            
            { name:           'bay_position_id',
              fieldLabel:     'Bay position',
              typeAhead:      true,
              triggerAction:  'all',
              store:          bay_position_store,
              valueField:     'bay_position_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },

            { name:           'cask_graveyard',
              fieldLabel:     'Cask Graveyard',
              xtype:          'textfield',
              allowBlank:     true, },

            { name:           'cask_management_id',
              value:          cask_management_id,
              xtype:          'hidden', },
        ],

        comboStores: [ dist_store, casksize_store, stillage_store, bay_position_store, currency_store ],
        loadUrl:     url_caskmanagement_load_form,
        idParams:    { cask_management_id: cask_management_id },
        waitMsg:     'Loading Cask Management details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Cask Management',
              layout: 'anchor',
              items:  caskManagementForm, },
        ],
    });

    var panel = new MyMainPanel({
        title: 'Cask Management',
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
            { text: 'Stillage Planning', handler: function() { window.location = url_stillage_planning_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

