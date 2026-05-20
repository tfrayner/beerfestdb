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
        loadUrl:       url_country_list,
        submitUrl:     url_country_submit,
        deleteUrl:     url_country_delete,
        idField:       'country_id',
        objLabel:      'Country',
        firstEditCol:  'country_name',
        viewLinkUrl:   function (row) { return url_base + 'country/view/' + row.country_id; },
        recordChanges: function (row) { return { country_id: row.country_id, country_name: row.country_name, country_code_iso2: row.country_code_iso2, country_code_iso3: row.country_code_iso3, country_code_num3: row.country_code_num3 }; },
        columns: [
            { field: 'country_name', headerName: 'Country Name', flex: 1 },
            { field: 'country_code_iso2', headerName: 'ISO alpha-2', width: 120 },
            { field: 'country_code_iso3', headerName: 'ISO alpha-3', width: 120 },
            { field: 'country_code_num3', headerName: 'ISO numeric', width: 120 },
        ],
    });
});
