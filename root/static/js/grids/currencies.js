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
    
    var Currency = Ext.data.Record.create([
        { name: 'currency_id',            type: 'int' },
        { name: 'currency_code',          type: 'string' },
        { name: 'currency_number',        type: 'string' },
        { name: 'currency_format',        type: 'string' },
        { name: 'exponent',               type: 'int' },
        { name: 'currency_symbol',        type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_currency_list,
        root:       'objects',
        fields:     Currency
    });
    
    var content_cols = [
        { id:         'currency_code',
          header:     'Currency Code',
          dataIndex:  'currency_code',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
              maxLength:      3,
          })},
        { id:         'currency_number',
          header:     'Currency Number',
          dataIndex:  'currency_number',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
              maxLength:      3,
          })},
        { id:         'currency_format',
          header:     'Currency Format',
          dataIndex:  'currency_format',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
              maxLength:      20,
          })},
        { id:         'exponent',
          header:     'Exponent',
          dataIndex:  'exponent',
          width:      150,
          editor:     new Ext.form.NumberField({
              allowBlank:     false,
              allowDecimals:  false,
              allowNegative:  false,
              minValue:       0,
              maxValue:       10,
          })},
        { id:         'currency_symbol',
          header:     'Currency Symbol',
          dataIndex:  'currency_symbol',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
              maxLength:      10,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'currency/view/{currency_id}');
        window.location=t.apply({currency_id: record.get('currency_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.currency_id = record.get( 'currency_id' );
        return(fields);
    }

    var panel = new MyMainPanel({
        title: 'All Currencies',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Currency',
                idField:            'currency_id',
                autoExpandColumn:   'currency_code',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_currency_delete,
                submitUrl:          url_currency_submit,
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

