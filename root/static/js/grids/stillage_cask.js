// stillage_cask.js — Casks on a stillage editor grid
document.addEventListener('DOMContentLoaded', function () {
    var bayPositionOptions = [];

    createEditorGrid({
        container:   document.getElementById('datagrid'),
        loadUrl:     url_object_list,
        submitUrl:   url_cask_submit,
        deleteUrl:   url_cask_delete,
        idField:     'cask_id',
        objLabel:    'Cask',
        viewLinkUrl: function (row) {
            return url_base + 'cask/view/' + row.cask_id;
        },
        recordChanges: function (row, changes) {
            changes.cask_id              = row.cask_id;
            changes.cask_management_id   = row.cask_management_id;
            changes.stillage_location_id = row.stillage_location_id;
            return changes;
        },
        comboUrls: [
            {
                url:    url_bay_position_list,
                onLoad: function (data) {
                    bayPositionOptions = (data.objects || data).map(function (o) {
                        return { value: o.bay_position_id, label: o.description };
                    });
                },
            },
        ],
        columns: [
            { field: 'company_name',   headerName: 'Brewer',           editable: false },
            { field: 'product_name',   headerName: 'Product',          editable: false },
            { field: 'festival_ref',   headerName: 'Festival Cask ID', editable: true },
            { field: 'int_reference',  headerName: 'Cellar Cask No.',  editable: true },
            { field: 'stillage_bay',   headerName: 'Bay No.',
              cellRenderer: makeNumberRenderer(), editable: true },
            { field: 'bay_position_id', headerName: 'Bay Position',
              cellRenderer: function (p) {
                  var o = bayPositionOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: bayPositionOptions }; },
              editable: true },
            { field: 'is_vented',       headerName: 'Vented',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'is_tapped',       headerName: 'Tapped',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'is_ready',        headerName: 'Ready',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'is_condemned',    headerName: 'Condemned',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'is_sale_or_return', headerName: 'SOR',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'comment',         headerName: 'Comment', editable: true, flex: 1 },
        ],
    });
});
