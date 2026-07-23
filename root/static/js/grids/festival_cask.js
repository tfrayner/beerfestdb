// festival_cask.js — Festival casks editor grid (cask placement)
document.addEventListener('DOMContentLoaded', function () {
    var casksizeOptions  = [];
    var stillageOptions  = [];

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
            changes.cask_id            = row.cask_id;
            changes.cask_management_id = row.cask_management_id;
            changes.gyle_id            = row.gyle_id;
            return changes;
        },
        comboUrls: [
            {
                url:    url_cask_size_list,
                onLoad: function (data) {
                    casksizeOptions = (data.objects || data).map(function (o) {
                        return { value: o.container_size_id, label: o.description };
                    });
                },
            },
            {
                url:    url_stillage_list,
                onLoad: function (data) {
                    stillageOptions = (data.objects || data).map(function (o) {
                        return { value: o.stillage_location_id, label: o.description };
                    });
                },
            },
        ],
        columns: [
            { field: 'company_name',        headerName: 'Brewer',           editable: false },
            { field: 'product_name',        headerName: 'Product',          editable: false },
            { field: 'container_size_id',   headerName: 'Cask Size',
              cellRenderer: function (p) {
                  var o = casksizeOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: casksizeOptions }; },
              editable: true },
            { field: 'stillage_location_id', headerName: 'Stillage',
              cellRenderer: function (p) {
                  var o = stillageOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: stillageOptions }; },
              editable: true },
            { field: 'stillage_bay',    headerName: 'Bay',
              cellRenderer: function (p) { return p.value ? p.value : ''; },
              editable: true },
            { field: 'festival_ref',    headerName: 'Festival Cask ID', editable: true },
            { field: 'int_reference',   headerName: 'Cellar Cask No.', editable: true },
            { field: 'comment',         headerName: 'Comment',          editable: true, flex: 1 },
        ],
    });
});
