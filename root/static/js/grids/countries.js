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
    
    var Country = Ext.data.Record.create([
        { name: 'country_id',   type: 'int' },
        { name: 'country_name', type: 'string' },
        { name: 'country_code_iso2', type: 'string' },
        { name: 'country_code_iso3', type: 'string' },
        { name: 'country_code_num3', type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_country_list,
        root:       'objects',
        fields:     Country
    });
    
    var content_cols = [
        { id:         'country_name',
          header:     'Country Name',
          dataIndex:  'country_name',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
        { id:         'country_code_iso2',
          header:     'ISO 3166-1 alpha-2 code',
          dataIndex:  'country_code_iso2',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
              maxLength:      2,
          })},
        { id:         'country_code_iso3',
          header:     'ISO 3166-1 alpha-3 code',
          dataIndex:  'country_code_iso3',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
              maxLength:      3,
          })},
        { id:         'country_code_num3',
          header:     'ISO 3166-1 numeric code',
          dataIndex:  'country_code_num3',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
              maxLength:      3,
          })}, 
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'country/view/{country_id}');
        window.location=t.apply({country_id: record.get('country_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.country_id = record.get( 'country_id' );
        return(fields);
    }

    var panel = new MyMainPanel({
        title: 'All Countries',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Country',
                idField:            'country_id',
                autoExpandColumn:   'country_name',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_country_delete,
                submitUrl:          url_country_submit,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home',
              handler: function() { window.location = url_base; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

});

