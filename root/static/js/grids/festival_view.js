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

    /* Category listing */
    var category_store = new Ext.data.JsonStore({
        url:        url_category_list,
        root:       'objects',
        fields:     [{ name: 'product_category_id',   type: 'int'    },
                     { name: 'description',           type: 'string' }]
    });
    category_store.load();

    /* Stillage listing */
    var stillage_store = new Ext.data.JsonStore({
        url:        url_stillage_list,
        root:       'objects',
        fields:     [{ name: 'stillage_location_id',  type: 'int'    },
                     { name: 'description',           type: 'string' }]
    });
    stillage_store.load();
    
    /* Order Batch listing */
    var order_batch_store = new Ext.data.JsonStore({
        url:        url_order_batch_list,
        root:       'objects',
        fields:     [{ name: 'order_batch_id',        type: 'int'    },
                     { name: 'description',           type: 'string' },
                     { name: 'order_date',            type: 'date', dateFormat: 'Y-m-d'}]
    });
    order_batch_store.load();
    
    var orderBatchGrid = new MyEditorGrid(
        {
            objLabel:           'Order Batch',
            idField:            'order_batch_id',
            autoExpandColumn:   'description',
            deleteUrl:          url_order_batch_delete,
            submitUrl:          url_order_batch_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.order_batch_id = record.get( 'order_batch_id' );
                fields.festival_id = festival_id;
                return(fields);
            },
            store:              order_batch_store,
            contentCols: [
                { id:        'description',
                  header:    'Order Batch Description',
                  dataIndex: 'description',
                  editor:     new Ext.form.TextField({
                      allowBlank: false,
                  })},
                { id:         'order_date',
                  header:     'Order date',
                  dataIndex:  'order_date',
                  width:      100,
                  renderer:   Ext.util.Format.dateRenderer('Y-m-d'),
                  editor:     new Ext.form.DateField({
                      allowBlank: true,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/orderbatch/view/{order_batch_id}');
                window.location=t.apply({
                    order_batch_id: record.get('order_batch_id'),
                })
            },
        }
    );

    var receivedGrid = new MyViewGrid(
        {
            store:              category_store,
            columns: [
                { id:        'description',
                  header:    'Product Category',
                  dataIndex: 'description' },
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/festivalproduct/grid/{festival_id}/{product_category_id}');
                window.location=t.apply({
                        product_category_id: record.get('product_category_id'),
                        festival_id: festival_id,
                    })
            },
            objLabel: 'festival products in this category',
        }
    );

    var caskGrid = new MyViewGrid(
        {
            store:              category_store,
            columns: [
                { id:        'description',
                  header:    'Product Category',
                  dataIndex: 'description' },
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/cask/grid/{festival_id}/{product_category_id}');
                window.location=t.apply({
                        product_category_id: record.get('product_category_id'),
                        festival_id: festival_id,
                    })
            },
            objLabel: 'casks in this product category',
        }
    );

    var stillageGrid = new MyEditorGrid(
        {
            objLabel:           'Stillage Location',
            idField:            'stillage_location_id',
            autoExpandColumn:   'description',
            deleteUrl:          url_stillage_delete,
            submitUrl:          url_stillage_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.stillage_location_id = record.get( 'stillage_location_id' );
                fields.festival_id = festival_id;
                return(fields);
            },
            store:              stillage_store,
            contentCols: [
                { id:        'description',
                  header:    'Stillage Name',
                  dataIndex: 'description',
                  editor:     new Ext.form.TextField({
                      allowBlank: false,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/stillagelocation/grid/{stillage_location_id}');
                window.location=t.apply({
                    stillage_location_id: record.get('stillage_location_id'),
                })
            },
        }
    );

    // turn on validation errors beside form fields globally
    Ext.form.Field.prototype.msgTarget = 'side';

    var festivalForm = new Ext.form.FormPanel({
            labelWidth:  150,
            url:         url_object_submit,
            frame:       true,
            title:       'Festival details',
            bodyStyle:   'padding:5px',
            width:       500,
            defaults:    {width: 300}, // field box width
            defaultType: 'textfield',
            
            items: [
                { name:       'year',
                  fieldLabel: 'Year',
                  allowBlank: false, },
                { name:       'name',
                  fieldLabel: 'Festival Name',
                  allowBlank: false, },
                { name:       'fst_start_date',
                  fieldLabel: 'Start Date',
                  xtype:      'datefield',
                  format:     'Y-m-d',
                  allowBlank: true, },
                { name:       'fst_end_date',
                  fieldLabel: 'End Date',
                  xtype:      'datefield',
                  format:     'Y-m-d',
                  allowBlank: true, },
                { name:       'description',
                  fieldLabel: 'Description', },
                { name:       'festival_id',
                  value:      festival_id,
                  xtype:      'hidden', },
            ],
            layout: 'form',
            buttons: [{
                    text: 'Save Changes',
                },{
                    text: 'Discard Changes',
                }],
            
        });

    festivalForm.load(
              { url:     url_festival_load_form,
                waitMsg: 'Loading Festival details...',
                params:  { festival_id: festival_id }, });

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Festival Information',
              layout: 'anchor',
              items:  festivalForm, },
            { title: 'Products Received',
              layout: 'fit',
              items:  receivedGrid, },
            { title: 'All Casks Received',
              layout: 'fit',
              items:  caskGrid, },
            { title: 'Casks by Stillage',
              layout: 'fit',
              items:  stillageGrid, },
            { title: 'Product Order Batches',
              layout: 'fit',
              items:  orderBatchGrid, },
        ],
    });

    var panel = new Ext.Panel({
        title: festivalname,            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festivals', handler: function() { window.location = url_festival_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

