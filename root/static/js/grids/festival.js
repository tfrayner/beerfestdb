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
    createEditorGrid({
        container:     '#datagrid',
        loadUrl:       url_festival_list,
        submitUrl:     url_festival_submit,
        deleteUrl:     url_festival_delete,
        idField:       'festival_id',
        objLabel:      'Festival',
        firstEditCol:  'name',
        viewLinkUrl:   function (row) { return url_base + 'festival/view/' + row.festival_id; },
        recordChanges: function (row) {
            return {
                festival_id:    row.festival_id,
                name:           row.name,
                year:           row.year,
                description:    row.description,
                fst_start_date: row.fst_start_date,
                fst_end_date:   row.fst_end_date,
            };
        },
        columns: [
            { field: 'name',           headerName: 'Name',        cellEditor: 'agTextCellEditor',   flex: 1 },
            { field: 'year',           headerName: 'Year',        cellEditor: 'agNumberCellEditor', width: 80 },
            { field: 'description',    headerName: 'Description', cellEditor: 'agTextCellEditor',   flex: 1 },
            { field: 'fst_start_date', headerName: 'Start Date',  cellEditor: FlatpickrDateEditor, width: 120 },
            { field: 'fst_end_date',   headerName: 'End Date',    cellEditor: FlatpickrDateEditor, width: 120 },
        ],
    });
});
