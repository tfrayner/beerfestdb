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
    
    /* Dispense method lookups */
    var dispense_store = new Ext.data.JsonStore({
        url:        url_dispense_method_list,
        root:       'objects',
        fields:     [{ name: 'dispense_method_id', type: 'int'    },
                     { name: 'description',        type: 'string' }],
        idProperty: 'dispense_method_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    dispense_store.load();

    /* Container measure lookups */
    var measure_store = new Ext.data.JsonStore({
        url:        url_container_measure_list,
        root:       'objects',
        fields:     [{ name: 'container_measure_id',  type: 'int'    },
                     { name: 'description', type: 'string' }],
        idProperty: 'container_measure_id',
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    measure_store.load();

    var ContainerSize = Ext.data.Record.create([
        { name: 'container_size_id',  type: 'int' },
        { name: 'description',        type: 'string' },
        { name: 'volume',             type: 'float' },
        { name: 'container_measure_id', type: 'int', sortType: myMakeSortTypeFun(measure_store,  'description') },
        { name: 'dispense_method_id',   type: 'int', sortType: myMakeSortTypeFun(dispense_store, 'description') },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_cask_size_list,
        root:       'objects',
        fields:     ContainerSize
    });

    /* Dispense method drop-down */
    var dispense_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          dispense_store,
        forceSelection: true,
        valueField:     'dispense_method_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    /* Container measure drop-down */
    var measure_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        mode:           'local',
        store:          measure_store,
        forceSelection: true,
        valueField:     'container_measure_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });

    var content_cols = [
        { id:         'description',
          header:     'Description',
          dataIndex:  'description',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'volume',
          header:     'Volume',
          dataIndex:  'volume',
          width:      40,
          editor:     new Ext.form.NumberField({
              allowBlank:     false,
          })},
        { id:         'container_measure_id',
          header:     'Measure',
          dataIndex:  'container_measure_id',
          width:      100,
          renderer:   MyComboRenderer(measure_combo),
          editor:     measure_combo },
        { id:         'dispense_method_id',
          header:     'Dispense Method',
          dataIndex:  'dispense_method_id',
          width:      100,
          renderer:   MyComboRenderer(dispense_combo),
          editor:     dispense_combo },
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate(url_base + 'containersize/view/{container_size_id}');
        window.location=t.apply({container_size_id: record.get('container_size_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.container_size_id = record.get( 'container_size_id' );
        return(fields);
    }

    var panel = new MyMainPanel({
        title: 'All Container Sizes',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Container Size',
                idField:            'container_size_id',
                autoExpandColumn:   'description',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_cask_size_delete,
                submitUrl:          url_cask_size_submit,
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

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

