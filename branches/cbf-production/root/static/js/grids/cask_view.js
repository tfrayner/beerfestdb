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

    /* Bay position drop-down */
    var bay_position_store = new Ext.data.JsonStore({
        url:        url_bay_position_list,
        root:       'objects',
        fields:     [{ name: 'bay_position_id', type: 'int' },
                     { name: 'description',     type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    bay_position_store.load();

    /* Cask size drop-down */
    var casksize_store = new Ext.data.JsonStore({
        url:        url_cask_size_list,
        root:       'objects',
        fields:     [{ name: 'container_size_id', type: 'int' },
                     { name: 'description',    type: 'string'}],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    casksize_store.load();

    /* Distributor drop-down */
    var dist_store = new Ext.data.JsonStore({
        url:        url_company_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}],
        sortInfo:   {
            field:     'name',
            direction: 'ASC',
        },
    });
    dist_store.load();

    var dip_store = new Ext.data.JsonStore({
        url:        url_cask_measurement_list,
        root:       'objects',
        fields:     [{ name: 'cask_measurement_id',  type: 'int'    },
                     { name: 'measurement_batch_id', type: 'int'    },
                     { name: 'comment',              type: 'string' },
                     { name: 'volume',               type: 'float'  }],
        sortInfo:   {
            field:     'measurement_batch_id',
            direction: 'ASC',
        },
    });
    dip_store.load();

    /* Dip batch drop-down */
    var dipbatch_store = new Ext.data.JsonStore({
        url:        url_measurement_batch_list,
        root:       'objects',
        fields:     [{ name: 'measurement_batch_id', type: 'int'    },
                     { name: 'measurement_time',     type: 'string' }],
        sortInfo:   {
            field:     'measurement_time',
            direction: 'ASC',
        },
    });
    dipbatch_store.load();
    var dipbatch_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        allowBlank:     false,
        forceSelection: true,
        store:          dipbatch_store,
        valueField:     'measurement_batch_id',
        displayField:   'measurement_time',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
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
            
            { name:           'container_size_id',
              fieldLabel:     'Cask Size',
              typeAhead:      true,
              triggerAction:  'all',
              store:          casksize_store,
              valueField:     'container_size_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'combo',
              allowBlank:     false, },
            
            { name:           'distributor_id',
              fieldLabel:     'Distributor',
              typeAhead:      true,
              triggerAction:  'all',
              store:          dist_store,
              valueField:     'company_id',
              displayField:   'name',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },
            
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
            
            { name:           'is_sale_or_return',
	      fieldLabel:     'Is SOR',
	      lazyRender:     true,
	      xtype:          'checkbox',
	      allowBlank:     true },

            { name:           'stillage_location_id',
              fieldLabel:     'Stillage',
              typeAhead:      true,
              triggerAction:  'all',
              store:          stillage_store,
              valueField:     'stillage_location_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
              allowBlank:     true, },

            { name:           'bay_position_id',
              fieldLabel:     'Bay position',
              typeAhead:      true,
              triggerAction:  'all',
              store:          bay_position_store,
              valueField:     'bay_position_id',
              displayField:   'description',
              lazyRender:     true,
              xtype:          'mycombo',
              noSelection:    emptySelect,
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

    /* Dip grid */
    var dipGrid = new MyEditorGrid(
        {
            objLabel:           'Cask Measurement',
            idField:            'cask_measurement_id',
            autoExpandColumn:   'cask_id',
            deleteUrl:          url_caskmeasurement_delete,
            submitUrl:          url_caskmeasurement_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.cask_measurement_id = record.get( 'cask_measurement_id' );
                fields.cask_id             = cask_id;
                return(fields);
            },
            store:              dip_store,
            contentCols: [
                { id:         'measurement_batch_id',
                  header:     'Dip Time',
                  dataIndex:  'measurement_batch_id',
                  renderer:   MyComboRenderer(dipbatch_combo),
                  editor:     dipbatch_combo, },
                { id:        'volume',
                  header:    'Volume',
                  dataIndex: 'volume',
                  width:      130,
                  editor:     new Ext.form.NumberField({
                      allowBlank: false,
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
                var t = new Ext.XTemplate('/caskmeasurement/view/{cask_measurement_id}');
                window.location=t.apply({
                    cask_measurement_id: record.get('cask_measurement_id'),
                })
            },
        }
    );

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Cask Information',
              layout: 'anchor',
              items:  caskForm, },
            { title: 'Dips',
              layout: 'fit',
              items:  dipGrid, },
        ],
    });

    var panel = new MyMainPanel({
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

