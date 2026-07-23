// user_view.js — User detail view form
document.addEventListener('DOMContentLoaded', function () {
    createViewForm({
        container:  document.getElementById('datagrid'),
        loadUrl:    url_user_load_form,
        idParams:   { user_id: user_id },
        submitUrl:  url_user_submit,
        fields: [
            { name: 'username', label: 'Username', readOnly: true },
            { name: 'name',     label: 'Real name' },
            { name: 'email',    label: 'Email' },
            { name: 'roles',    label: 'Roles',
              type: 'multiselect', optionsUrl: url_role_list,
              valueField: 'role_id', displayField: 'rolename', allowBlank: true },
            { name: 'user_id',  label: '', type: 'hidden' },
        ],
    });
});
