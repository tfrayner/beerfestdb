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
    
    /* Stillage listing */
    var stillage_store = new Ext.data.JsonStore({
        url:        url_stillage_list,
        root:       'objects',
        fields:     [{ name: 'stillage_location_id',  type: 'int'    },
                     { name: 'description',           type: 'string' }],
        sortInfo:   {
            field:     'description',
            direction: 'ASC',
        },
    });
    stillage_store.load();

    var myGrid = new MyViewGrid(
        {
            store:              stillage_store,
            columns: [
                { id:        'description',
                  header:    'Stillage Name',
                  dataIndex: 'description' },
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate(url_base + 'caskmeasurement/grid/{measurement_batch_id}/{stillage_location_id}');
                window.location=t.apply({
                        stillage_location_id: record.get('stillage_location_id'),
                        measurement_batch_id: measurement_batch_id,
                    })
            },
            objLabel: 'measurements from this stillage location',
        }
    );

    var panel = new MyMainPanel({
        title: festivalname + ': ' + batchtime,
        layout: 'fit',
        items: myGrid,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = url_base; } },
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

