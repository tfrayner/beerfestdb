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
    
    /* Supplier lookups */
    var brewer_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}],
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
        idProperty: 'company_id',
        isPartial:  1, // slightly lame flag to indicate whether we've loaded the full listing yet.
    });
    brewer_store.load({ params: { brewer_festival_id: festival_id } });

    /* Product lookups */
    var product_store = new Ext.data.JsonStore({
        url:        url_product_list,
        root:       'objects',
        fields:     [{ name: 'product_id', type: 'int' },
                     { name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}],
        idProperty: 'product_id',
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
    });

    /* Sale volume lookups */
    var volume_store = new Ext.data.JsonStore({
        url:        url_sale_volume_list,
        root:       'objects',
        fields:     [{ name: 'sale_volume_id', type: 'int' },
                     { name: 'description',    type: 'string'}],
        idProperty: 'sale_volume_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    volume_store.load();

    /* Currency lookups */
    var currency_store = new Ext.data.JsonStore({
        url:        url_currency_list,
        root:       'objects',
        fields:     [{ name: 'currency_id',   type: 'int'    },
                     { name: 'currency_code', type: 'string' }],
        sortInfo:   {
            field:     'currency_code',
            direction: 'ASC',
        },
    });
    currency_store.load();

    var FestivalProduct = Ext.data.Record.create([
        { name: 'festival_product_id', type: 'int' },
        { name: 'product_id',          type: 'int', sortType: myMakeSortTypeFun(product_store, 'name') },
        { name: 'company_id',          type: 'int', sortType: myMakeSortTypeFun(brewer_store, 'name') },
        { name: 'sale_price',          type: 'float' },
        { name: 'sale_volume_id',      type: 'int', sortType: myMakeSortTypeFun(volume_store, 'description') },
        { name: 'sale_currency_id',    type: 'int', sortType: myMakeSortTypeFun(currency_store, 'currency_code') },
        { name: 'comment',             type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     FestivalProduct,
        defaultData: { sale_currency_id: default_currency,
                       sale_volume_id:   default_sale_volume },
    });

    /* Supplier drop-down */
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
            change: function(combo, newValue, oldValue) {
                /* combo is the reference to the brewer_combo.
                   We have combo.record available only because we copied it in
                   the beforeEdit event from myGrid */
                combo.record.set('product_id', null);
            },
            beforeQuery: function() { 
                if ( this.store.isPartial ) {
                    this.store.reload({ params: { brewer_order_batch_id: null }});
                    this.store.sort();
                }
                this.store.isPartial = 0;
            },
        },
    });

    /* Product drop-down */
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
        store:          product_store,
        valueField:     'product_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
        listeners: {
            beforeQuery: function(query) { 
                currentRowId = myGrid.getSelectionModel().getSelected().data.company_id;
                this.store.reload( { params: { company_id: currentRowId }, add: true } );
                this.store.clearFilter();
                this.store.filter( { property:   'company_id',
                                     value:      currentRowId,
                                     exactMatch: true } );
            }
        }, 
    });

    /* Sale volume drop-down */
    var volume_combo = new Ext.form.ComboBox({
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        forceSelection: true,
        store:          volume_store,
        valueField:     'sale_volume_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Currency drop-down */
    var currency_combo = new Ext.form.ComboBox({
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        forceSelection: true,
        store:          currency_store,
        valueField:     'currency_id',
        displayField:   'currency_code',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var content_cols = [
        { id:         'company_id',
          header:     'Brewer',
          dataIndex:  'company_id',
          width:      100,
          renderer:   MyComboRenderer(brewer_combo),
          editor:     brewer_combo, },
        { id:         'product_id',
          header:     'Product',
          dataIndex:  'product_id',
          width:      100,
          renderer:   MyComboRenderer(product_combo),
          editor:     product_combo, },
        { id:         'sale_price',
          header:     'Sale price',
          dataIndex:  'sale_price',
          width:      40,
          editor:     new Ext.form.TextField({  // FIXME use currency format, reload on change.
              allowBlank:     true,
          })},
        { id:         'sale_currency_id',
          header:     'Currency',
          dataIndex:  'sale_currency_id',
          width:      40,
          renderer:   MyComboRenderer(currency_combo),
          editor:     currency_combo },
        { id:         'sale_volume_id',
          header:     'Sale volume',
          dataIndex:  'sale_volume_id',
          width:      40,
          renderer:   MyComboRenderer(volume_combo),
          editor:     volume_combo },
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      100,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'festivalproduct/view/{festival_product_id}');
        window.location=t.apply({festival_product_id: record.get('festival_product_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.festival_product_id = record.get( 'festival_product_id' );
        fields.sale_currency_id    = record.get( 'sale_currency_id' );
        fields.sale_volume_id      = record.get( 'sale_volume_id' );
        fields.festival_id = festival_id;
        return(fields);
    }

    var reloadStores = new Array();
    reloadStores.push( product_store );

    var myGrid = new MyEditorGrid(
        {
            objLabel:           'Festival Product',
            idField:            'festival_product_id',
            autoExpandColumn:   'product_id',
            store:              store,
            contentCols:        content_cols,
            viewLink:           viewLink,
            deleteUrl:          url_festivalproduct_delete,
            submitUrl:          url_festivalproduct_submit,
            recordChanges:      recordChanges,
            listeners: {
                beforeedit: function(e) {
                    // reference to the currently clicked cell
                    var ed = e.grid.getColumnModel().getCellEditor(e.column, e.row);    
                    if (ed && ed.field) {
                        // copy these references to the current editor (brewer_combo in our case)
                        Ext.copyTo(ed.field, e, 'grid,record,field,row,column');
                    }
                },
            },
            reloadableStores: reloadStores,
        }
    );

    var panel = new MyMainPanel({
        title: festivalname + ' product listing: ' + categoryname,
        layout: 'fit',
        items: myGrid,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

