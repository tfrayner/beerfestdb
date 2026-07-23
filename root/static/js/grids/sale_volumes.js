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
 */

document.addEventListener('DOMContentLoaded', function () {
    let measureOptions = [];

    createEditorGrid({
        container:     '#datagrid',
        loadUrl:       url_sale_volume_list,
        submitUrl:     url_sale_volume_submit,
        deleteUrl:     url_sale_volume_delete,
        idField:       'sale_volume_id',
        objLabel:      'Sale Volume',
        firstEditCol:  'description',
        viewLinkUrl:   function (row) { return url_base + 'salevolume/view/' + row.sale_volume_id; },
        recordChanges: function (row) {
            return { sale_volume_id: row.sale_volume_id, description: row.description,
                      volume: row.volume, container_measure_id: row.container_measure_id };
        },
        comboUrls: [{
            url:    url_container_measure_list,
            onLoad: function (data) {
                measureOptions = (data.objects || data).map(function (r) {
                    return { value: r.container_measure_id, label: r.description };
                });
            },
        }],
        columns: [
            { field: 'description',        headerName: 'Description', cellEditor: 'agTextCellEditor',   flex: 1 },
            { field: 'volume',             headerName: 'Volume',      cellEditor: 'agNumberCellEditor', width: 80 },
            {
                field: 'container_measure_id', headerName: 'Measure', width: 150,
                cellRenderer: function (p) {
                    if (p.value == null) return '';
                    const o = measureOptions.find(function (x) { return String(x.value) === String(p.value); });
                    return o ? o.label : String(p.value);
                },
                cellEditor: TomSelectCellEditor,
                cellEditorParams: function () { return { values: measureOptions }; },
            },
        ],
    });
});
