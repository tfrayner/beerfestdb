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

    /* Distributor drop-down */
    var distributor_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}],
	idProperty: 'company_id',
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
    });

    var distributor_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          distributor_store,
        valueField:     'company_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
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

    var currency_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          currency_store,
        valueField:     'currency_id',
        displayField:   'currency_code',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Casksize drop-down */
    var casksize_store = new Ext.data.JsonStore({
        url:        url_cask_size_list,
        root:       'objects',
        fields:     [{ name: 'container_size_id',   type: 'int' },
                     { name: 'description', type: 'string' }],
	idProperty: 'container_size_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    var casksize_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          casksize_store,
        valueField:     'container_size_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* FestivalProduct form */
    var poForm = new MyFormPanel({

        url:         url_productorder_submit,
        title:       'Product Order details',
            
        items: [

            { name:           'company_name',
              fieldLabel:     'Brewery',
              xtype:          'textfield',
              readOnly:       true, },
            
            { name:           'product_name',
              fieldLabel:     'Product',
              xtype:          'textfield',
              readOnly:       true, },
            
            { name:           'distributor_id',
              fieldLabel:     'Distributor',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          distributor_store,
              forceSelection: true,
              valueField:     'company_id',
              displayField:   'name',
              lazyRender:     true,
              xtype:          'combo',
              allowBlank:     false, },

            { name:           'cask_count',
              fieldLabel:     'Cask Count',
              xtype:          'numberfield',
              allowBlank:     false, },

            { name:           'container_size_id',
              fieldLabel:     'Container Size',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          casksize_store,
              forceSelection: true,
              valueField:     'container_size_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'combo',
              allowBlank:     false, },
            
            { name:           'is_sale_or_return',
              fieldLabel:     'Is Sale or Return',
              lazyRender:     true,
              xtype:          'checkbox',
              allowBlank:     true },

            { name:           'sale_price',
              fieldLabel:     'Sale Price',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'sale_currency_id',
              fieldLabel:     'Sale Currency',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          currency_store,
              forceSelection: true,
              valueField:     'currency_id',
              displayField:   'currency_code',
              lazyRender:     true,
              xtype:          'combo',
              allowBlank:     false, },
// Deliberately omitting is_received flag so we don't have to implement javascript warnings etc.            
            { name:           'is_final',
              fieldLabel:     'Is Final',
              lazyRender:     true,
              xtype:          'checkbox',
              allowBlank:     true },

            { name:           'comment',
              fieldLabel:     'Comment',
              xtype:          'textarea',
              allowBlank:     true, },

            { name:           'product_order_id',
              value:          product_order_id,
              xtype:          'hidden', },
            
            { name:           'order_batch_id',
              value:          order_batch_id,
              xtype:          'hidden', },
            
        ],

        comboStores: [ currency_store, casksize_store, distributor_store ],
        loadUrl:     url_po_load_form,
        idParams:    { product_order_id: product_order_id },
        waitMsg:     'Loading Product Order details...',
/*        setReadOnlyForAll: function (bReadOnly) {
            this.getForm().getFields().each (function (field) {
                field.setReadOnly (bReadOnly);
            });
        }

            view: new Ext.form.Vgrid.GridView({

                // Set CSS on disabled records.
                getRowClass: function (rec, idx, rowParams, store){
                    if (rec.get('is_received') == 1 && ! rec.isModified('is_received') ) {
              	        return 'disabled-record';
                    }
                },
            }),
            listeners: {
                beforeedit: function(e) {
                    
         if (booleanVariable === true) Ext.getCmp('your-textbox-id').setReadOnly(true);
        else Ext.getCmp('your-textbox-id').setReadOnly(false);
    }
 }
            listeners: {
                beforeedit: function(e) {

                    // reference to the currently clicked cell
                    var ed = e.grid.getColumnModel().getCellEditor(e.column, e.row);    
                    if (ed && ed.field) {
                        // copy these references to the current editor (brewer_combo in our case)
                        Ext.copyTo(ed.field, e, 'grid,record,field,row,column');
                    }

                    // Disallow editing of records which we've physically received.
                    rec = e.record;
                    if (rec.get('is_received') == 1 && ! rec.isModified('is_received') ) {
                        return false;
                    }
                },
            },
            */
    });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Festival Product Information',
              layout: 'anchor',
              items:  poForm, },
        ],
    });

    var panel = new MyMainPanel({
        title: poname,            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
            { text: 'Order Batch', handler: function() { window.location = url_order_batch_view; } },
            { text: 'Product', handler: function() { window.location = url_product_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

