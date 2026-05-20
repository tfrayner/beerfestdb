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
