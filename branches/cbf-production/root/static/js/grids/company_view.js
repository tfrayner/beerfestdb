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

    /* Region drop-down */
    var region_store = new Ext.data.JsonStore({
        url:        url_company_region_list,
        root:       'objects',
        fields:     [{ name: 'company_region_id', type: 'int' },
                     { name: 'description',       type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    region_store.load();

    /* Contact type drop-down */
    var contact_type_store = new Ext.data.JsonStore({
        url:        url_contact_type_list,
        root:       'objects',
        fields:     [{ name: 'contact_type_id', type: 'int' },
                     { name: 'description',     type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    contact_type_store.load();
    var contact_type_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          contact_type_store,
        valueField:     'contact_type_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Country drop-down */
    var country_store = new Ext.data.JsonStore({
        url:        url_country_list,
        root:       'objects',
        fields:     [{ name: 'country_id',        type: 'int' },
                     { name: 'country_code_iso3', type: 'string'}],
        sortInfo:   {
            field:     'country_code_iso3',
            direction: 'ASC',
        },
    });
    country_store.load();
    var country_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          country_store,
        valueField:     'country_id',
        displayField:   'country_code_iso3',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Contact list */
    var contact_store = new Ext.data.JsonStore({
        url:        url_contact_list,
        root:       'objects',
        fields:     [{ name: 'contact_id',       type: 'int'    },
                     { name: 'contact_type_id',  type: 'int'    },
                     { name: 'company_id',       type: 'int'    },
                     { name: 'first_name',       type: 'string' },
                     { name: 'last_name',        type: 'string' },
                     { name: 'street_address',   type: 'string' },
                     { name: 'postcode',         type: 'string' },
                     { name: 'country_id',       type: 'int'    },
                     { name: 'email',            type: 'string' },
                     { name: 'comment',          type: 'string' }],
        sortInfo:   {
            field:     'last_name',
            direction: 'ASC',
        },
    });
    contact_store.load();

    var product_store = new Ext.data.JsonStore({
        url:        url_product_list,
        root:       'objects',
        fields:     [{ name: 'product_id',       type: 'int' },
                     { name: 'company_id',       type: 'int' },
                     { name: 'name',             type: 'string',   allowBlank: false },
                     { name: 'description',      type: 'string' },
                     { name: 'comment',          type: 'string' },
                     { name: 'nominal_abv',      type: 'float' },
                     { name: 'product_category_id', type: 'int' },
                     { name: 'product_style_id', type: 'int' }],
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
    });
    product_store.load();

    /* Product Style drop-down */
    var style_store = new Ext.data.JsonStore({
        url:        url_product_style_list,
        root:       'objects',
        fields:     [{ name: 'product_style_id', type: 'int'    },
                     { name: 'description',      type: 'string' }],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    style_store.load();
    var style_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        forceSelection: true,
        store:          style_store,
        valueField:     'product_style_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Product Category drop-down */
    var category_store = new Ext.data.JsonStore({
        url:        url_category_list,
        root:       'objects',
        fields:     [{ name: 'product_category_id', type: 'int'    },
                     { name: 'description',         type: 'string' }],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    category_store.load();
    var category_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        allowBlank:     false,
        forceSelection: true,
        store:          category_store,
        valueField:     'product_category_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Company form */
    var coForm = new MyFormPanel({

        url:         url_company_submit,
        title:       'Company details',
            
        items: [

            { name:           'name',
              fieldLabel:     'Name',
              xtype:          'textfield',
              allowBlank:     false, },
            
            { name:           'full_name',
              fieldLabel:     'Full Name',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'loc_desc',
              fieldLabel:     'Location',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'company_region_id',
              fieldLabel:     'Region',
              typeAhead:      true,
              triggerAction:  'all',
              store:          region_store,
              valueField:     'company_region_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'combo',
              allowBlank:     true, },
            
            { name:           'year_founded',
              fieldLabel:     'Year Founded',
              xtype:          'numberfield',
              allowBlank:     true, },
            
            { name:           'url',
              fieldLabel:     'Web site',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'comment',
              fieldLabel:     'Comment',
              xtype:          'textarea',
              allowBlank:     true, },

            { name:           'company_id',
              value:          company_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_company_load_form,
        idParams:    { company_id: company_id },
        waitMsg:     'Loading Company details...',
    });

    /* Contact grid */
    var contactGrid = new MyEditorGrid(
        {
            objLabel:           'Contact',
            idField:            'contact_id',
            autoExpandColumn:   'contact_type_id',
            deleteUrl:          url_contact_delete,
            submitUrl:          url_contact_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.contact_id = record.get( 'contact_id' );
                fields.company_id = company_id;
                return(fields);
            },
            store:              contact_store,
            contentCols: [
                { id:         'contact_type_id',
                  header:     'Contact Type',
                  dataIndex:  'contact_type_id',
                  width:      130,
                  renderer:   MyComboRenderer(contact_type_combo),
                  editor:     contact_type_combo, },
                { id:        'last_name',
                  header:    'Last Name',
                  dataIndex: 'last_name',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:        'first_name',
                  header:    'First Name',
                  dataIndex: 'first_name',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:        'street_address',
                  header:    'Street Address',
                  dataIndex: 'street_address',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                      readOnly:   true,  // hard to edit newlines accurately in the grid.
                  })},
                { id:         'postcode',
                  header:     'Postcode',
                  dataIndex:  'postcode',
                  width:      30,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:         'country_id',
                  header:     'Country',
                  dataIndex:  'country_id',
                  width:      130,
                  renderer:   MyComboRenderer(country_combo),
                  editor:     country_combo, },
                { id:         'email',
                  header:     'Email',
                  dataIndex:  'email',
                  width:      30,
                  editor:     new Ext.form.TextField({
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
                var t = new Ext.XTemplate('/contact/view/{contact_id}');
                window.location=t.apply({
                    contact_id: record.get('contact_id'),
                })
            },
        }
    );

    /* Product grid */
    var productGrid = new MyEditorGrid(
        {
            objLabel:           'Product',
            idField:            'product_id',
            autoExpandColumn:   'product_type_id',
            deleteUrl:          url_product_delete,
            submitUrl:          url_product_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.product_id          = record.get( 'product_id' );
                fields.product_category_id = record.get( 'product_category_id' );
                fields.name                = record.get( 'name' );
                fields.company_id          = company_id;
                return(fields);
            },
            store:              product_store,
            contentCols:
            [
                { id:         'name',
                  header:     'Name',
                  dataIndex:  'name',
                  width:      130,
                  editor:     new Ext.form.TextField({
                      allowBlank:     false,
                  })},
                { id:         'nominal_abv',
                  header:     'Advertised ABV',
                  dataIndex:  'nominal_abv',
                  width:      130,
                  renderer:   function(value) { return value ? value : '' },
                  editor:     new Ext.form.NumberField({
                      allowBlank:     true,
                  })},
                { id:         'description',
                  header:     'Description',
                  dataIndex:  'description',
                  width:      150,
                  editor:     new Ext.form.TextField({
                      allowBlank:     true,
                  })},
                { id:         'comment',
                  header:     'Comment',
                  dataIndex:  'comment',
                  width:      150,
                  editor:     new Ext.form.TextField({
                      allowBlank:     true,
                  })},
                { id:         'product_category_id',
                  header:     'Category',
                  dataIndex:  'product_category_id',
                  width:      70,
                  renderer:   MyComboRenderer(category_combo),
                  editor:     category_combo },
                { id:         'product_style_id',
                  header:     'Style',
                  dataIndex:  'product_style_id',
                  width:      70,
                  renderer:   MyComboRenderer(style_combo),
                  editor:     style_combo },
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/product/view/{product_id}');
                window.location=t.apply({
                    product_id: record.get('product_id'),
                })
            },
        }
    );

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Company Information',
              layout: 'anchor',
              items:  coForm, },
            { title: 'Contacts',
              layout: 'fit',
              items:  contactGrid, },
            { title: 'Products',
              layout: 'fit',
              items:  productGrid, },
        ],
    });

    var panel = new Ext.Panel({
        title: companyname,            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Companies', handler: function() { window.location = url_company_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

