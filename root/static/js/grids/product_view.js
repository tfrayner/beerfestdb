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

    var festival_product_store = new Ext.data.JsonStore({
        url:        url_festival_product_list,
        root:       'objects',
        fields:     [{ name: 'festival_product_id', type: 'int'    },
                     { name: 'festival_name',       type: 'string' },
                     { name: 'product_id',          type: 'int' },
                     { name: 'festival_id',         type: 'int' },
                     { name: 'comment',             type: 'string' }],
        sortInfo:   {
            field:     'festival_name',
            direction: 'ASC',
        },
    });
    festival_product_store.load();

    /* Product form */
    var prodForm = new MyFormPanel({

        url:         url_product_submit,
        title:       'Product details',
            
        items: [

            { name:           'company_name',
              fieldLabel:     'Company',
              lazyRender:     true,
              xtype:          'textfield',
              readOnly:       true},
            
            { name:           'name',
              fieldLabel:     'Name',
              xtype:          'textfield',
              allowBlank:     false, },

            { name:           'category_name',
              fieldLabel:     'Category',
              lazyRender:     true,
              xtype:          'textfield',
              readOnly:       false, },

            { name:           'product_style_id',
              fieldLabel:     'Style',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          style_store,
              valueField:     'product_style_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },

            { name:           'nominal_abv',
              fieldLabel:     'Advertised ABV',
              xtype:          'numberfield',
              allowBlank:     true, },

            { name:           'description',
              fieldLabel:     'Short Description',
              xtype:          'textarea',
              allowBlank:     true, },

            { name:           'long_description',
              fieldLabel:     'Long Description',
              xtype:          'textarea',
              allowBlank:     true, },

            { name:           'comment',
              fieldLabel:     'Comment',
              xtype:          'textarea',
              allowBlank:     true, },
            
        ],

        loadUrl:     url_product_load_form,
        idParams:    { product_id: product_id },
        waitMsg:     'Loading Product details...',
    });

    /* Festival Product grid */
    var fpGrid = new MyEditorGrid(
        {
            objLabel:           'Festival Product',
            idField:            'festival_product_id',
            autoExpandColumn:   'festival_id',
            deleteUrl:          url_festivalproduct_delete,
            submitUrl:          url_festivalproduct_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.festival_product_id = record.get( 'festival_product_id' );
                fields.product_id          = product_id;
                return(fields);
            },
            store:              festival_product_store,
            contentCols: [
                { id:         'festival_name',
                  header:     'Festival',
                  dataIndex:  'festival_name',
                  editor:     new Ext.form.TextField({
                      readOnly: true,
                  })},
                { id:        'comment',
                  header:    'Comment',
                  dataIndex: 'comment',
                  width:      130,
                  editor:     new Ext.form.TextField({
                      allowBlank: true,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate(url_base + 'festivalproduct/view/{festival_product_id}');
                window.location=t.apply({
                    festival_product_id: record.get('festival_product_id'),
                })
            },
        }
    );

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Product Information',
              layout: 'anchor',
              items:  prodForm, },
            { title: 'Festivals',
              layout: 'fit',
              items:  fpGrid, },
//            { title: 'Characteristics',
//              layout: 'fit',
//              items:  charGrid, },
        ],
    });

    var panel = new MyMainPanel({
        title: productname,            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Companies', handler: function() { window.location = url_company_grid; } },
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

