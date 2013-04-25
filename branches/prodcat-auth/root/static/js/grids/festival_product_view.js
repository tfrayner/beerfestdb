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

    /* Company drop-down */
    var company_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}],
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
    });
    company_store.load();
    var company_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          company_store,
        valueField:     'company_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Sale volume drop-down */
    var volume_store = new Ext.data.JsonStore({
        url:        url_sale_volume_list,
        root:       'objects',
        fields:     [{ name: 'sale_volume_id', type: 'int' },
                     { name: 'description',    type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    volume_store.load();

    /* Currency drop-down */
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
        fields:     [{ name: 'container_size_id',   type: 'int'    },
                     { name: 'description', type: 'string' }],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    casksize_store.load();
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

    /* Gyle drop-down */
    var gyle_store = new Ext.data.JsonStore({
        url:        url_gyle_list,
        root:       'objects',
        fields:     [{ name: 'gyle_id',       type: 'int'    },
                     { name: 'company_id',    type: 'int' },
                     { name: 'festival_product_id',    type: 'int' },
                     { name: 'abv',           type: 'float' },
                     { name: 'comment',       type: 'string' },
                     { name: 'ext_reference', type: 'string' },
                     { name: 'int_reference', type: 'string' }],
        sortInfo:   {
            field:     'int_reference',
            direction: 'ASC',
        },
    });
    gyle_store.load();
    var gyle_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          gyle_store,
        valueField:     'gyle_id',
        displayField:   'int_reference',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Cask drop-down */
    var cask_store = new Ext.data.JsonStore({
        url:        url_cask_list,
        root:       'objects',
        fields:     [{ name: 'cask_id',           type: 'int' },
                     { name: 'festival_id',       type: 'int' },
                     { name: 'gyle_id',           type: 'int' },
                     { name: 'distributor_id',    type: 'int' },
                     { name: 'order_batch_name',  type: 'string' },
                     { name: 'container_size_id', type: 'int' },
                     { name: 'currency_id',       type: 'int' },
                     { name: 'price',             type: 'int' },
                     { name: 'int_reference',     type: 'string' },
                     { name: 'ext_reference',     type: 'string' },
                     { name: 'festival_ref',      type: 'string' },
                     { name: 'is_sale_or_return', type: 'int' },
                     { name: 'comment',           type: 'string' }],
        sortInfo:   {
            field:     'int_reference',
            direction: 'ASC',
        },
    });
    cask_store.load();

    /* FestivalProduct form */
    var fpForm = new MyFormPanel({

        url:         url_festivalproduct_submit,
        title:       'Festival Product details',
            
        items: [

            { name:           'company_name',
              fieldLabel:     'Company',
              xtype:          'textfield',
              readOnly:       true, },
            
            { name:           'product_name',
              fieldLabel:     'Product',
              xtype:          'textfield',
              readOnly:       true, },
            
            { name:           'sale_price',
              fieldLabel:     'Sale Price',
              xtype:          'numberfield',
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
            
            { name:           'sale_volume_id',
              fieldLabel:     'Sale Volume',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          volume_store,
              forceSelection: true,
              valueField:     'sale_volume_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'combo',
              allowBlank:     false, },
            
            { name:           'comment',
              fieldLabel:     'Comment',
              xtype:          'textarea',
              allowBlank:     true, },

            { name:           'festival_product_id',
              value:          festival_product_id,
              xtype:          'hidden', },
            
            { name:           'festival_id',
              value:          festival_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_fp_load_form,
        idParams:    { festival_product_id: festival_product_id },
        waitMsg:     'Loading Festival Product details...',
    });

    /* Gyle grid */
    var gyleGrid = new MyEditorGrid(
        {
            objLabel:           'Gyle',
            idField:            'gyle_id',
            autoExpandColumn:   'int_reference',
            deleteUrl:          url_gyle_delete,
            submitUrl:          url_gyle_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.gyle_id             = record.get( 'gyle_id' );
                fields.festival_product_id = festival_product_id;
                return(fields);
            },
            store:              gyle_store,
            contentCols: [
                { id:        'int_reference',
                  header:    'Festival Gyle ID',
                  dataIndex: 'int_reference',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: false,
                  })},
                { id:        'ext_reference',
                  header:    'Brewery Gyle ID',
                  dataIndex: 'ext_reference',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:         'company_id',
                  header:     'Actual Brewer',
                  dataIndex:  'company_id',
                  width:      130,
                  renderer:   MyComboRenderer(company_combo),
                  editor:     company_combo, },
                { id:         'abv',
                  header:     'Gyle ABV',
                  dataIndex:  'abv',
                  width:      30,
                  editor:     new Ext.form.NumberField({
                      allowBlank: true,
                  })},
                { id:        'comment',
                  header:    'Comment',
                  dataIndex: 'comment',
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/gyle/view/{gyle_id}');
                window.location=t.apply({
                    gyle_id: record.get('gyle_id'),
                })
            },
        }
    );

    /* Cask grid */
    var caskGrid = new MyEditorGrid(
        {
            objLabel:           'Cask',
            idField:            'cask_id',
            autoExpandColumn:   'int_reference',
            deleteUrl:          url_cask_delete,
            submitUrl:          url_cask_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.cask_id = record.get( 'cask_id' );
                fields.festival_id = festival_id;
                fields.product_id  = product_id;
                return(fields);
            },
            store:              cask_store,
            contentCols: [
                { id:        'festival_ref',
                  header:    'Festival Cask ID',
                  dataIndex: 'festival_ref',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:        'int_reference',
                  header:    'Cellar Cask ID',
                  dataIndex: 'int_reference',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:        'ext_reference',
                  header:    'Brewery ID',
                  dataIndex: 'ext_reference',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:         'container_size_id',
                  header:     'Cask Size',
                  dataIndex:  'container_size_id',
                  width:      40,
                  renderer:   MyComboRenderer(casksize_combo),
                  editor:     casksize_combo, },
                { id:         'price',
                  header:     'Cask Price',
                  dataIndex:  'price',
                  width:      40,
                  editor:     new Ext.form.TextField({
                      allowBlank:     true,
                  })},
                { id:         'currency_id',
                  header:     'Currency',
                  dataIndex:  'currency_id',
                  width:      40,
                  renderer:   MyComboRenderer(currency_combo),
                  editor:     currency_combo, },
                { id:         'gyle_id',
                  header:     'Gyle (Festival ID)',
                  dataIndex:  'gyle_id',
                  width:      50,
                  renderer:   MyComboRenderer(gyle_combo),
                  editor:     gyle_combo, },
                { id:         'distributor_id',
                  header:     'Distributor',
                  dataIndex:  'distributor_id',
                  width:      130,
                  renderer:   MyComboRenderer(company_combo),
                  editor:     company_combo, },
                { id:         'is_sale_or_return',
		  header:     'SOR',
		  dataIndex:  'is_sale_or_return',
		  width:      40,
		  renderer:   MyCheckboxRenderer(),
		  editor:     new Ext.form.Checkbox()
		},
                { id:         'order_batch_name',
                  header:     'Order Batch',
                  dataIndex:  'order_batch_name',
                  width:      130,
                  editor:     new Ext.form.TextField({
                      readOnly: true,
                  })},
                { id:        'comment',
                  header:    'Comment',
                  dataIndex: 'comment',
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/cask/view/{cask_id}');
                window.location=t.apply({
                    cask_id: record.get('cask_id'),
                })
            },
        }
    );

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Festival Product Information',
              layout: 'anchor',
              items:  fpForm, },
            { title: 'Gyles',
              layout: 'fit',
              items:  gyleGrid, },
            { title: 'Casks',
              layout: 'fit',
              items:  caskGrid, },
        ],
    });

    var panel = new MyMainPanel({
        title: fpname,            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
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

