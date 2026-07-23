/*
 * This file is part of BeerFestDB, a beer festival product management
 * system.
 * 
 * Copyright (C) 2026 Tim F. Rayner
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

// product_order_view.js — Product Order detail view form
document.addEventListener('DOMContentLoaded', function () {
    createViewForm({
        container:  document.getElementById('datagrid'),
        loadUrl:    url_productorder_load_form,
        idParams:   { product_order_id: product_order_id },
        submitUrl:  url_productorder_submit,
        fields: [
            { name: 'company_name',       label: 'Brewery',        readOnly: true },
            { name: 'product_name',       label: 'Product',        readOnly: true },
            { name: 'distributor_id',     label: 'Distributor',
              type: 'select', optionsUrl: url_company_list,
              valueField: 'company_id', displayField: 'name', allowBlank: false },
            { name: 'cask_count',         label: 'Cask Count',     type: 'number' },
            { name: 'container_size_id',  label: 'Cask Size',
              type: 'select', optionsUrl: url_cask_size_list,
              valueField: 'container_size_id', displayField: 'description', allowBlank: false },
            { name: 'price',              label: 'Total Price' },
            { name: 'currency_id',        label: 'Currency',
              type: 'select', optionsUrl: url_currency_list,
              valueField: 'currency_id', displayField: 'currency_code', allowBlank: false },
            { name: 'is_sale_or_return',  label: 'Sale or Return',  type: 'number' },
            { name: 'is_final',           label: 'Order Finalised', type: 'number' },
            { name: 'is_received',        label: 'Received',        type: 'number' },
            { name: 'comment',            label: 'Comment',         type: 'textarea' },
            { name: 'product_order_id',   label: '',                type: 'hidden' },
        ],
    });
});
