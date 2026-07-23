// cask_measurement_view.js — Cask measurement detail view form
document.addEventListener('DOMContentLoaded', function () {
    createViewForm({
        container:  document.getElementById('datagrid'),
        loadUrl:    url_cask_measurement_load_form,
        idParams:   { cask_measurement_id: cask_measurement_id },
        submitUrl:  url_caskmeasurement_submit,
        fields: [
            { name: 'measurement_batch_name', label: 'Batch Name',        readOnly: true },
            { name: 'measurement_time',       label: 'Measurement Time',  readOnly: true },
            { name: 'volume',                 label: 'Volume',            type: 'number' },
            { name: 'comment',               label: 'Comment',           type: 'textarea' },
            { name: 'cask_id',               label: '',                  type: 'hidden' },
        ],
    });
});
