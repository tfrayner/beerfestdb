// contact_view.js — Contact detail view form
document.addEventListener('DOMContentLoaded', function () {
    createViewForm({
        container:  document.getElementById('datagrid'),
        loadUrl:    url_contact_load_form,
        idParams:   { contact_id: contact_id },
        submitUrl:  url_contact_submit,
        fields: [
            { name: 'contact_type_id', label: 'Contact Type',
              type: 'select', optionsUrl: url_contact_type_list,
              valueField: 'contact_type_id', displayField: 'description', allowBlank: true },
            { name: 'last_name',       label: 'Last Name' },
            { name: 'first_name',      label: 'First Name' },
            { name: 'street_address',  label: 'Street Address',  type: 'textarea' },
            { name: 'postcode',        label: 'Postcode' },
            { name: 'country_id',      label: 'Country',
              type: 'select', optionsUrl: url_country_list,
              valueField: 'country_id', displayField: 'country_name', allowBlank: true },
            { name: 'email',           label: 'Email' },
            { name: 'comment',         label: 'Comment',         type: 'textarea' },
            { name: 'contact_id',      label: '',                type: 'hidden' },
        ],
    });
});
