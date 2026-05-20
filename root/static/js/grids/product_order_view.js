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
