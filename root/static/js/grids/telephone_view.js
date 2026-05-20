// telephone_view.js — Telephone detail view form
document.addEventListener('DOMContentLoaded', function () {
    createViewForm({
        container:  document.getElementById('datagrid'),
        loadUrl:    url_telephone_load_form,
        idParams:   { telephone_id: telephone_id },
        submitUrl:  url_telephone_submit,
        fields: [
            { name: 'company_name',       label: 'Brewery',           readOnly: true },
            { name: 'contact_type_desc',  label: 'Contact Type',      readOnly: true },
            { name: 'telephone_type_id',  label: 'Telephone Type',
              type: 'select', optionsUrl: url_telephone_type_list,
              valueField: 'telephone_type_id', displayField: 'description', allowBlank: true },
            { name: 'international_code', label: 'International Code' },
            { name: 'area_code',          label: 'Area Code' },
            { name: 'local_number',       label: 'Local Number' },
            { name: 'extension',          label: 'Extension' },
            { name: 'telephone_id',       label: '',                  type: 'hidden' },
        ],
    });
});
