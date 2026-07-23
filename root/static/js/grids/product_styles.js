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
    // product_category_id comes from TT template var
    const _categoryId = typeof category_id !== 'undefined' ? category_id : null;
    createEditorGrid({
        container:     '#datagrid',
        loadUrl:       url_object_list,
        submitUrl:     url_productstyle_submit,
        deleteUrl:     url_productstyle_delete,
        idField:       'product_style_id',
        objLabel:      'Product Style',
        firstEditCol:  'description',
        viewLinkUrl:   function (row) { return url_base + 'productstyle/view/' + row.product_style_id; },
        recordChanges: function (row) { return { product_style_id: row.product_style_id, description: row.description, product_category_id: row.product_category_id }; },
        columns: [
        { field: 'description', headerName: 'Description', cellEditor: 'agTextCellEditor', flex: 1 },
        ],
    });
});
