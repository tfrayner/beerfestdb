// gyle_view.js — Gyle detail view form
document.addEventListener('DOMContentLoaded', function () {
    createViewForm({
        container:  document.getElementById('datagrid'),
        loadUrl:    url_gyle_load_form,
        idParams:   { gyle_id: gyle_id },
        submitUrl:  url_gyle_submit,
        fields: [
            { name: 'festival_name',   label: 'Festival Name',       readOnly: true },
            { name: 'company_name',    label: 'Brewery',             readOnly: true },
            { name: 'abv',             label: 'Gyle ABV',            type: 'number' },
            { name: 'int_reference',   label: 'Internal Reference' },
            { name: 'ext_reference',   label: 'External Reference' },
            { name: 'comment',         label: 'Comment',             type: 'textarea' },
            { name: 'gyle_id',         label: '',                    type: 'hidden' },
        ],
    });
});
