// role_view.js — Role detail view form
document.addEventListener('DOMContentLoaded', function () {
    createViewForm({
        container:  document.getElementById('datagrid'),
        loadUrl:    url_role_load_form,
        idParams:   { role_id: role_id },
        submitUrl:  url_role_submit,
        fields: [
            { name: 'rolename',   label: 'Role Name',   readOnly: true },
            { name: 'categories', label: 'Categories',
              type: 'multiselect', optionsUrl: url_product_category_list,
              valueField: 'product_category_id', displayField: 'description', allowBlank: true },
            { name: 'role_id',    label: '',            type: 'hidden' },
        ],
    });
});
