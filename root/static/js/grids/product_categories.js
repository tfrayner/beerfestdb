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
        loadUrl:       url_category_list,
        submitUrl:     url_category_submit,
        deleteUrl:     url_category_delete,
        idField:       'product_category_id',
        objLabel:      'Product Category',
        firstEditCol:  'description',
        viewLinkUrl:   function (row) { return url_base + 'productcategory/view/' + row.product_category_id; },
        recordChanges: function (row) { return { product_category_id: row.product_category_id, description: row.description }; },
        columns: [
            { field: 'description', headerName: 'Category Name', flex: 1 },
        ],
    });
});
