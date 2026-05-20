// cask_measurement.js — Cask measurements editor grid
document.addEventListener('DOMContentLoaded', function () {
    var viewLinkUrl = function (row) {
        return url_base + 'cask/view/' + row.cask_id;
    };

    createEditorGrid({
        container:   document.getElementById('datagrid'),
        loadUrl:     url_object_list,
        submitUrl:   url_caskmeasurement_submit,
        deleteUrl:   url_caskmeasurement_delete,
        idField:     'cask_measurement_id',
        objLabel:    'Cask Measurement',
        viewLinkUrl: viewLinkUrl,
        recordChanges: function (row, changes) {
            changes.cask_measurement_id  = row.cask_measurement_id;
            changes.cask_id              = row.cask_id;
            changes.measurement_batch_id = batch_id;
            return changes;
        },
        columns: [
            { field: 'brewer',            headerName: 'Brewer',       editable: false },
            { field: 'product',           headerName: 'Beer',         editable: false },
            { field: 'is_vented',         headerName: 'Vented',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'is_tapped',         headerName: 'Tapped',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'is_ready',          headerName: 'Ready',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'internal_reference', headerName: 'Cellar No.',  editable: false },
            { field: 'cellar_reference',  headerName: 'Festival ID',  editable: false },
            { field: 'previous_volume',   headerName: 'Previous',
              cellRenderer: makeNumberRenderer(), editable: false },
            { field: 'volume',            headerName: 'Latest',
              cellRenderer: makeNumberRenderer(), editable: true },
            { field: 'container_measure', headerName: 'Units',        editable: false },
            { field: 'cask_comment',      headerName: 'Cask Comment', editable: true, flex: 1 },
            { field: 'is_condemned',      headerName: 'Condemned',
              cellRenderer: makeCheckboxRenderer(), editable: true },
        ],
    });
});
