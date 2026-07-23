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
        loadUrl:       url_company_region_list,
        submitUrl:     url_company_region_submit,
        deleteUrl:     url_company_region_delete,
        idField:       'company_region_id',
        objLabel:      'Company Region',
        firstEditCol:  'description',
        viewLinkUrl:   function (row) { return url_base + 'companyregion/view/' + row.company_region_id; },
        recordChanges: function (row) { return { company_region_id: row.company_region_id, description: row.description }; },
        columns: [
            { field: 'description', headerName: 'Description', flex: 1 },
        ],
    });
});
