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
    
    var Company = Ext.data.Record.create([
        { name: 'company_id',        type: 'int' },
        { name: 'name',              type: 'string',   allowBlank: false },
        { name: 'loc_desc',          type: 'string' },
        { name: 'company_region_id', type: 'int'},
        { name: 'year_founded',      type: 'int' },
        { name: 'url',               type: 'string' },
        { name: 'comment',           type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     Company
    });

    /* Company region drop-down */
    var region_store = new Ext.data.JsonStore({
        url:        url_company_region_list,
        root:       'objects',
        fields:     [{ name: 'company_region_id', type: 'int'    },
                     { name: 'description',       type: 'string' }]
    });
    region_store.load();
    var region_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        store:          region_store,
        forceSelection: true,
        valueField:     'company_region_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    var content_cols = [
        { id:         'name',
          header:     'Name',
          dataIndex:  'name',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
        { id:         'loc_desc',
          header:     'Location',
          dataIndex:  'loc_desc',
          width:      150,
          editor:     new Ext.form.TextField({
//              allowBlank:     false,
          })},
        { id:         'company_region_id',
          header:     'Region',
          dataIndex:  'company_region_id',
          width:      70,
          renderer:   MyComboRenderer(region_combo),
          editor:     region_combo },
        { id:         'year_founded',
          header:     'Year founded',
          dataIndex:  'year_founded',
          width:      20,
          editor:     new Ext.form.TextField({
//              allowBlank:     false,
          })},
        { id:         'url',
          header:     'Web site',
          dataIndex:  'url',
          width:      70,
          editor:     new Ext.form.TextField({
//              allowBlank:     false,
          })},
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      70,
          editor:     new Ext.form.TextField({
//              allowBlank:     false,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/company/view/{company_id}');
        window.location=t.apply({company_id: record.get('company_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.company_id = record.get( 'company_id' );
        return(fields);
    }

    var panel = new Ext.Panel({
        title:  'Company listing',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Company',
                idField:            'company_id',
                autoExpandColumn:   'name',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_object_delete,
                submitUrl:          url_object_submit,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

