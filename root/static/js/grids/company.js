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
    let regionOptions = [];

    createEditorGrid({
        container:     '#datagrid',
        loadUrl:       url_company_list,
        submitUrl:     url_company_submit,
        deleteUrl:     url_company_delete,
        idField:       'company_id',
        objLabel:      'Company',
        firstEditCol:  'name',
        viewLinkUrl:   function (row) { return url_base + 'company/view/' + row.company_id; },
        recordChanges: function (row) {
            return { company_id: row.company_id, name: row.name, full_name: row.full_name,
                      loc_desc: row.loc_desc, company_region_id: row.company_region_id,
                      year_founded: row.year_founded, url: row.url,
                      awrs_urn: row.awrs_urn, comment: row.comment };
        },
        comboUrls: [{
            url:    url_company_region_list,
            onLoad: function (data) {
                regionOptions = (data.objects || data).map(function (r) {
                    return { value: r.company_region_id, label: r.description };
                });
            },
        }],
        columns: [
            { field: 'name',              headerName: 'Name',         cellEditor: 'agTextCellEditor', flex: 1 },
            { field: 'full_name',         headerName: 'Full Name',    cellEditor: 'agTextCellEditor', flex: 1 },
            { field: 'loc_desc',          headerName: 'Location',     cellEditor: 'agTextCellEditor', width: 150 },
            {
                field: 'company_region_id', headerName: 'Region', width: 130,
                cellRenderer: function (p) {
                    if (p.value == null) return '';
                    const o = regionOptions.find(function (x) { return String(x.value) === String(p.value); });
                    return o ? o.label : String(p.value);
                },
                cellEditor: TomSelectCellEditor,
                cellEditorParams: function () { return { values: regionOptions }; },
            },
            { field: 'year_founded', headerName: 'Founded', cellEditor: 'agNumberCellEditor', width: 80 },
            { field: 'url',          headerName: 'Web Site', cellEditor: 'agTextCellEditor', width: 150 },
            { field: 'awrs_urn',     headerName: 'AWRS URN', cellEditor: 'agTextCellEditor', width: 120 },
            { field: 'comment',      headerName: 'Comment',  cellEditor: 'agTextCellEditor', flex: 1 },
        ],
    });
});
