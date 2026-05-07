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

// Workaround for odd Ext.ux.form.LovCombo clear-on-blur bug when using ExtJS3.
Ext.override(Ext.ux.form.LovCombo, {
    beforeBlur: Ext.emptyFn
})

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();

    /* Product Category drop-down */
    var category_store = new Ext.data.JsonStore({
        url:        url_category_list,
        root:       'objects',
        fields:     [{ name: 'product_category_id', type: 'int'    },
                     { name: 'description',         type: 'string' }],
        idProperty: 'product_category_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    /* Product Style drop-down */
    var style_store = new Ext.data.JsonStore({
        url:        url_product_style_list,
        root:       'objects',
        fields:     [{ name: 'product_style_id', type: 'int'    },
                     { name: 'description',      type: 'string' }],
        idProperty: 'product_style_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    /* Allergen drop-down - two independent stores to avoid cross-talk between lovcombo fields */
    function makeAllergenStore() {
        return new Ext.data.JsonStore({
            url:        url_product_allergen_list,
            root:       'objects',
            fields:     [{ name: 'product_allergen_type_id', type: 'string' },  // Technically int, but we cast to string for lovcombo handling.
                         { name: 'description',              type: 'string' }],
            idProperty: 'product_allergen_type_id',
            sortInfo:   {
                field:     'description',
                direction: 'ASC',
            },
        });
    }
    var allergen_store_present = makeAllergenStore();
    var allergen_store_absent  = makeAllergenStore();

    /* Festival Product drop-down */
    var festival_product_store = new Ext.data.JsonStore({
        url:        url_festival_product_list,
        root:       'objects',
        fields:     [{ name: 'festival_product_id', type: 'int'    },
                     { name: 'festival_name',       type: 'string' },
                     { name: 'product_id',          type: 'int' },
                     { name: 'festival_id',         type: 'int' },
                     { name: 'comment',             type: 'string' }],
        idProperty: 'festival_product_id',
        sortInfo:   {
            field:     'festival_name',
            direction: 'ASC',
        },
    });

    /* Product Characteristic drop-down */
    var ProductCharacteristicType = Ext.data.Record.create([
        { name: 'product_characteristic_type_id', type: 'int' },
        { name: 'product_category_id',            type: 'int' },
        { name: 'description',                    type: 'string' },
    ]);

    var product_characteristic_type_store = new Ext.data.JsonStore({
        url:        url_product_characteristic_type_list,
        root:       'objects',
        fields:     ProductCharacteristicType,
        idProperty: 'product_characteristic_type_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });

    var product_characteristic_type_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          product_characteristic_type_store,
        valueField:     'product_characteristic_type_id',
        displayField:   'description',
        lazyRender:     true,
        noSelection:    emptySelect,
        forceSelection: true,
        xtype:          'mycombo',
    });

    var product_characteristic_store = new Ext.data.JsonStore({
        url:        url_product_characteristic_list,
        root:       'objects',
        fields:     [{ name: 'product_id',                type: 'int' },
                     { name: 'product_characteristic_type_id', type: 'int' },
                     { name: 'value',                     type: 'string' }],
        idProperty: 'product_characteristic_type_id',
        sortInfo:   {
            field:     'product_characteristic_type_id',
            direction: 'ASC',
        },
    });

    function updateStyleList(query) { // Listener function to update style dropdown.
        var currentRowId = prodForm.getForm().findField('product_category_id').getValue();
        this.store.reload( { params: { product_category_id: currentRowId }, add: true } );
        this.store.clearFilter();
        this.store.filter( { property:   'product_category_id',
                             value:      currentRowId,
                             exactMatch: true } );
        this.render()
    }

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

            { name:           'product_category_id',
              fieldLabel:     'Category',
              typeAhead:      true,
              triggerAction:  'all',
              mode:           'local',
              store:          category_store,
              valueField:     'product_category_id',
              displayField:   'description',
              lazyRender:     true,
              noSelection:    emptySelect,
              forceSelection: true,
              xtype:          'mycombo',
              allowBlank:     false,
              readOnly:       false,
              listeners: {
                  change: function(evt, t, o) {
                      /* t is the reference to the category_combo */
                      stylefield = prodForm.getForm().findField('product_style_id');
                      stylefield.setValue(null);
                      evt.render();
                  },
              }, },

            { name:           'product_style_id',
              fieldLabel:     'Style',
              typeAhead:      false,
              triggerAction:  'all',
              mode:           'local',
              store:          style_store,
              valueField:     'product_style_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true,
              listeners: {
                  focus:  updateStyleList, // both listeners appear to be needed.
                  expand: updateStyleList,
              }, },

            { name:           'nominal_abv',
              fieldLabel:     'Advertised ABV',
              xtype:          'numberfield',
              allowBlank:     true, },

            { name:           'is_vegan',
              fieldLabel:     'Is Vegan',
              lazyRender:     true,
              xtype:          'checkbox',
              allowBlank:     true },

            { name:           'allergens_present',
              fieldLabel:     'Allergens PRESENT',
              store:          allergen_store_present,
              triggerAction:  'all',
              mode:           'local',
              lazyRender:     true,
              valueField:     'product_allergen_type_id',
              displayField:   'description',
              emptyText:      'Select allergens...',
              hideOnSelect:   false,
              queryMode:      'local',
              multiSelect:    true,
              xtype:          'lovcombo',
              allowBlank:     true, },

            { name:           'allergens_absent',
              fieldLabel:     'Allergens ABSENT',
              store:          allergen_store_absent,
              triggerAction:  'all',
              mode:           'local',
              lazyRender:     true,
              valueField:     'product_allergen_type_id',
              displayField:   'description',
              emptyText:      'Select allergens...',
              hideOnSelect:   false,
              queryMode:      'local',
              multiSelect:    true,
              xtype:          'lovcombo',
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

        comboStores: [ category_store, style_store, allergen_store_present, allergen_store_absent ],
        loadUrl:     url_product_load_form,
        idParams:    { product_id: product_id },
        waitMsg:     'Loading Product details...',
    });

    /* Product Characteristic grid */
    var charGrid = new MyEditorGrid(
        {
            objLabel:           'Product Characteristic',
            idField:            ['product_id', 'product_characteristic_type_id'],
            autoExpandColumn:   'value',
            deleteUrl:          url_product_characteristic_delete,
            submitUrl:          url_product_characteristic_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.product_id = product_id;
                return(fields);
            },
            store:              product_characteristic_store,
            comboStores:         [ product_characteristic_type_store ],
            contentCols: [
                { id:         'product_characteristic_type_id',
                  header:     'Characteristic Type',
                  dataIndex:  'product_characteristic_type_id',
                  width:      130,
                  renderer:   MyComboRenderer(product_characteristic_type_combo),
                  editor:     product_characteristic_type_combo,
                  },
                { id:         'value',
                  header:     'Value',
                  dataIndex:  'value',
                  width:      150,
                  editor:     new Ext.form.TextField({
                      allowBlank:     true,
                  })},
            ],
            // Dead link - we have a no target view for product characteristics, and the link is not worth the effort of creating one.
            viewLink: function (grid, record, action, row, col) {},
        }
    );

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
            { title: 'Characteristics',
              layout: 'fit',
              items:  charGrid, },
            { title: 'Festivals',
              layout: 'fit',
              items:  fpGrid, },
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

});

