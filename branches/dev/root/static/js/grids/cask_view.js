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
    stillage_store.load();
    var stillage_combo = new Ext.form.ComboBox({
        store:          stillage_store,
        valueField:     'stillage_location_id',
        displayField:   'description',
        lazyRender:     true,
        triggerAction:  'all',
        forceSelection: true,
        allowBlank:     true,
        typeAhead:      true,
    });

    /* Cask form */
    var caskForm = new MyFormPanel({

        url:         url_cask_submit,
        title:       'Cask details',
            
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
            
            { name:           'ext_reference',
              fieldLabel:     'Brewery Cask ID',
              lazyRender:     true,
              xtype:          'textfield',
              allowBlank:     true},
            
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
            
            { name:           'stillage_location_id',
              fieldLabel:     'Stillage',
              typeAhead:      true,
              triggerAction:  'all',
              store:          stillage_store,
              valueField:     'stillage_location_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'combo',
              allowBlank:     true, },

            { name:           'comment',
              fieldLabel:     'Comment',
              xtype:          'textarea',
              allowBlank:     true, },
            
        ],

        loadUrl:     url_cask_load_form,
        idParams:    { cask_id: cask_id },
        waitMsg:     'Loading Cask details...',
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Cask Information',
              layout: 'anchor',
              items:  caskForm, },
        ],
    });

    var panel = new Ext.Panel({
        title: 'Cask Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
            { text: 'Festival Product', handler: function() { window.location = url_festival_product_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

