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

// festival_product_view.js — Festival Product detail view form
document.addEventListener('DOMContentLoaded', function () {
    createViewForm({
        container:  document.getElementById('datagrid'),
        loadUrl:    url_fp_load_form,
        idParams:   { festival_product_id: festival_product_id },
        submitUrl:  url_festivalproduct_submit,
        fields: [
            { name: 'company_name',          label: 'Brewery',      readOnly: true },
            { name: 'product_name',          label: 'Product',      readOnly: true },
            { name: 'gyle_id',               label: 'Gyle',
              type: 'select', optionsUrl: url_gyle_list,
              valueField: 'gyle_id', displayField: 'int_reference', allowBlank: true },
            { name: 'sale_volume_id',        label: 'Sale Volume',
              type: 'select', optionsUrl: url_sale_volume_list,
              valueField: 'sale_volume_id', displayField: 'description', allowBlank: true },
            { name: 'sale_price',            label: 'Sale Price' },
            { name: 'sale_currency_id',      label: 'Currency',
              type: 'select', optionsUrl: url_currency_list,
              valueField: 'currency_id', displayField: 'currency_code', allowBlank: true },
            { name: 'comment',               label: 'Comment',      type: 'textarea' },
            { name: 'festival_product_id',   label: '',             type: 'hidden' },
        ],
    });
});
