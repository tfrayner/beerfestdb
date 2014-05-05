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

    /* Country drop-down */
    var country_store = new Ext.data.JsonStore({
        url:        url_country_list,
        root:       'objects',
        fields:     [{ name: 'country_id',        type: 'int' },
                     { name: 'country_name',      type: 'string'}],
        sortInfo:   {
            field:     'country_name',
            direction: 'ASC',
        },
    });
    country_store.load();

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
    phone_type_store.load();
    var phone_type_combo = new MyComboBox({
        forceSelection: true,
        allowBlank:     true,
        noSelection:    emptySelect,
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          phone_type_store,
        valueField:     'telephone_type_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Telephone list */
    var phone_store = new Ext.data.JsonStore({
        url:        url_telephone_list,
        root:       'objects',
        fields:     [{ name: 'telephone_id',       type: 'int'    },
                     { name: 'contact_id',         type: 'int'    },
                     { name: 'telephone_type_id',  type: 'int'    },
                     { name: 'international_code', type: 'string' },
                     { name: 'area_code',          type: 'string' },
                     { name: 'local_number',       type: 'string' },
                     { name: 'extension',          type: 'string' }],
        sortInfo:   {
            field:     'local_number',
            direction: 'ASC',
        },
    });
    phone_store.load();

    /* Contact form */
    var contactForm = new MyFormPanel({

        url:         url_contact_submit,
        title:       'Contact details',
            
        items: [
            
            { name:           'contact_type_id',
              fieldLabel:     'Contact Type',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          contact_type_store,
              valueField:     'contact_type_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },

            { name:           'last_name',
              fieldLabel:     'Last Name',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'first_name',
              fieldLabel:     'First Name',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'street_address',
              fieldLabel:     'Street Address',
              xtype:          'textarea',
              allowBlank:     true, },
            
            { name:           'postcode',
              fieldLabel:     'Postcode',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'country_id',
              fieldLabel:     'Country',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          country_store,
              valueField:     'country_id',
              displayField:   'country_name',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },
            
            { name:           'email',
              fieldLabel:     'Email',
              xtype:          'textfield',
              allowBlank:     true, },
            
            { name:           'comment',
              fieldLabel:     'Comment',
              xtype:          'textarea',
              allowBlank:     true, },

            { name:           'contact_id',
              value:          contact_id,
              xtype:          'hidden', },
            
        ],

        loadUrl:     url_contact_load_form,
        idParams:    { contact_id: contact_id },
        waitMsg:     'Loading Contact details...',
    });

    /* Telephone grid */
    var phoneGrid = new MyEditorGrid(
        {
            objLabel:           'Telephone',
            idField:            'telephone_id',
            autoExpandColumn:   'local_number',
            deleteUrl:          url_telephone_delete,
            submitUrl:          url_telephone_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.telephone_id = record.get( 'telephone_id' );
                fields.contact_id   = contact_id;
                return(fields);
            },
            store:              phone_store,
            contentCols: [
                { id:         'telephone_type_id',
                  header:     'Telephone Type',
                  dataIndex:  'telephone_type_id',
                  width:      130,
                  renderer:   MyComboRenderer(phone_type_combo),
                  editor:     phone_type_combo, },
                { id:        'international_code',
                  header:    'International Code',
                  dataIndex: 'international_code',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:        'area_code',
                  header:    'Area Code',
                  dataIndex: 'area_code',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
                { id:        'local_number',
                  header:    'Local Number',
                  dataIndex: 'local_number',
                  width:      50,
                  editor:     new Ext.form.TextField({
                      allowBlank: false,
                  })},
                { id:         'extension',
                  header:     'Extension',
                  dataIndex:  'extension',
                  width:      30,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate(url_base + 'telephone/view/{telephone_id}');
                window.location=t.apply({
                    telephone_id: record.get('telephone_id'),
                })
            },
        }
    );

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Contact Information',
              layout: 'anchor',
              items:  contactForm, },
            { title: 'Telephone Numbers',
              layout: 'fit',
              items:  phoneGrid, },
        ],
    });

    var panel = new MyMainPanel({
        title:  'Contact Details',            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Company', handler: function() { window.location = url_company_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

