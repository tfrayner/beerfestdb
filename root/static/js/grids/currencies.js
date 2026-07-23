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
        loadUrl:       url_currency_list,
        submitUrl:     url_currency_submit,
        deleteUrl:     url_currency_delete,
        idField:       'currency_id',
        objLabel:      'Currency',
        firstEditCol:  'currency_code',
        viewLinkUrl:   function (row) { return url_base + 'currency/view/' + row.currency_id; },
        recordChanges: function (row) { return { currency_id: row.currency_id, currency_code: row.currency_code, currency_number: row.currency_number, currency_format: row.currency_format, exponent: row.exponent, currency_symbol: row.currency_symbol }; },
        columns: [
        { field: 'currency_code', headerName: 'Code', cellEditor: 'agTextCellEditor', width: 80 },
        { field: 'currency_number', headerName: 'ISO Number', cellEditor: 'agTextCellEditor', width: 100 },
        { field: 'currency_format', headerName: 'Format', cellEditor: 'agTextCellEditor', flex: 1 },
        { field: 'exponent', headerName: 'Exponent', cellEditor: 'agNumberCellEditor', width: 80 },
        { field: 'currency_symbol', headerName: 'Symbol', cellEditor: 'agTextCellEditor', width: 80 },
        ],
    });
});
