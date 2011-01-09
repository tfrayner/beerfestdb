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

    var ProductOrder = Ext.data.Record.create([
        { name: 'product_order_id',       type: 'int' },
        { name: 'company_id',             type: 'int' },
        { name: 'product_id',             type: 'int' },
        { name: 'order_batch_id',         type: 'int' },
        { name: 'distributor_id',         type: 'int' },
        { name: 'cask_count',             type: 'int' },
        { name: 'container_size_id',      type: 'int' },
        { name: 'currency_id',            type: 'int' },
        { name: 'price',                  type: 'int' },
        { name: 'is_final',               type: 'int' },
        { name: 'is_received',            type: 'int' },
        { name: 'comment',                type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     ProductOrder,
        defaultData: { currency_id: default_currency },
    });

    /* Brewer drop-down */
    var brewer_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}]
    });
    brewer_store.load();
    var brewer_combo = new Ext.form.ComboBox({
        triggerAction:  'all',
        mode:           'local',
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        store:          brewer_store,
        valueField:     'company_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
        listeners: {
            change: function(evt, t, o) {
                /* t is the reference to the brewer_combo.
                   We have evt.record available only because we copied it in
                   the beforeEdit event from myGrid */
                evt.record.set('product_id', null);
                evt.render();
            }
        },
    });

    /* Product drop-down */
    var product_store = new Ext.data.JsonStore({
        url:        url_product_list,
        root:       'objects',
        fields:     [{ name: 'product_id', type: 'int'    },
                     { name: 'company_id', type: 'int'    },
                     { name: 'name',       type: 'string' }]

    });
    product_store.load();

    /* We need this to reload upon brewer reselection.
       See http://stackoverflow.com/questions/3980796/cascading-comboboxes-in-extjs-editorgridpanel */
    var product_combo = new Ext.form.ComboBox({
        triggerAction:  'all',
        mode:           'local',
        lastQuery:      '',  /* to make sure the filter in the store
                                is not cleared the first time the ComboBox trigger is used */
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      false, // bypasses the filter; FIXME in future?
        triggerAction:  'all',
        store:          product_store,
        valueField:     'product_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
        listeners: {
            beforeQuery: function(query) { 
                currentRowId = myGrid.getSelectionModel().getSelected().data.company_id;
                this.store.clearFilter();
                this.store.filter( { property:   'company_id',
                                     value:      currentRowId,
                                     exactMatch: true } );
            }
        }, 
    });
    
    /* Distributor drop-down */
    var distributor_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int'    },
                     { name: 'name',       type: 'string' }]

    });
    distributor_store.load();
    var distributor_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
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
                     { name: 'currency_code', type: 'string' }]

    });
    currency_store.load();
    var currency_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          currency_store,
        valueField:     'currency_id',
        displayField:   'currency_code',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    /* Cask size drop-down */
    var cask_size_store = new Ext.data.JsonStore({
        url:        url_cask_size_list,
        root:       'objects',
        fields:     [{ name: 'container_size_id', type: 'int'    },
                     { name: 'description',       type: 'string' }]

    });
    cask_size_store.load();
    var cask_size_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          cask_size_store,
        valueField:     'container_size_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var content_cols = [
        { id:         'distributor_id',
          header:     'Distributor',
          dataIndex:  'distributor_id',
          width:      130,
          renderer:   MyComboRenderer(distributor_combo),
          editor:     distributor_combo, },
        { id:         'company_id',
          header:     'Brewer',
          dataIndex:  'company_id',
          width:      130,
          renderer:   MyComboRenderer(brewer_combo),
          editor:     brewer_combo, },            
        { id:         'product_id',
          header:     'Product',
          dataIndex:  'product_id',
          width:      130,
          renderer:   MyComboRenderer(product_combo),
          editor:     product_combo, },
        { id:         'container_size_id',
          header:     'Cask Size',
          dataIndex:  'container_size_id',
          width:      50,
          renderer:   MyComboRenderer(cask_size_combo),
          editor:     cask_size_combo, },
        { id:         'cask_count',
          header:     'No. Casks',
          dataIndex:  'cask_count',
          width:      50,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'price',
          header:     'Price',
          dataIndex:  'price',
          width:      30,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'currency_id',
          header:     'Currency',
          dataIndex:  'currency_id',
          width:      40,
          renderer:   MyComboRenderer(currency_combo),
          editor:     currency_combo, },
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'is_final',
          header:     'Ordered',
          dataIndex:  'is_final',
          width:      50,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
        { id:         'is_received',
          header:     'Arrived',
          dataIndex:  'is_received',
          width:      50,
          renderer:   MyCheckboxRenderer(),
          editor:     new Ext.form.Checkbox({
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/productorder/view/{product_order_id}');
        window.location=t.apply({product_order_id: record.get('product_order_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.product_order_id = record.get( 'product_order_id' );
        fields.currency_id      = record.get( 'currency_id' );
        fields.order_batch_id   = order_batch_id;
        return(fields);
    }

    var myGrid = new MyEditorGrid(
        {
            objLabel:           'Product Order',
            idField:            'product_order_id',
            autoExpandColumn:   'product_id',
            store:              store,
            contentCols:        content_cols,
            viewLink:           viewLink,
            deleteUrl:          url_productorder_delete,
            submitUrl:          url_productorder_submit,
            recordChanges:      recordChanges,
            view: new Ext.grid.GridView({

                // Set CSS on disabled records.
                getRowClass: function (rec, idx, rowParams, store){
                    if (rec.get('is_received') == 1 && ! rec.isModified('is_received') ) {
              	        return 'disabled-record';
                    }
                },
            }),
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
                }
            },
        }
    );

    /* Add an extra warning to the user. */
    var sb = myGrid.getTopToolbar().get(1);
    sb.events['click'].clearListeners();
    sb.addListener({
        click:  function(evt) {
            this.grid.stopEditing();
            // Only fire off an alert if there are any is_received==1 records FIXME.
            Ext.Msg.show({
                title:    'Caution',
                msg:      'If products are marked as "Arrived", further editing will be disabled. Continue?',
                buttons:  Ext.Msg.YESNO,
                icon:     Ext.MessageBox.QUESTION,
                fn:       function(btn, text){
                    if (btn == 'yes'){
                        saveGridRecords(sb);
                    };
                },
            });
        },
    });

    var panel = new Ext.Panel({
        title: orderbatchname + ': ' + categoryname,
        layout: 'fit',
        items: myGrid,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
            { text: 'Order Batch', handler: function() { window.location = url_order_batch_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

