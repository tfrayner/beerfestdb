// product.js — Products editor grid (within a category)
document.addEventListener('DOMContentLoaded', function () {
    var brewerOptions = [];
    var styleOptions  = [];

    createEditorGrid({
        container:   document.getElementById('datagrid'),
        loadUrl:     url_object_list,
        submitUrl:   url_product_submit,
        deleteUrl:   url_product_delete,
        idField:     'product_id',
        objLabel:    'Product',
        viewLinkUrl: function (row) {
            return url_base + 'product/view/' + row.product_id;
        },
        recordChanges: function (row, changes) {
            changes.product_id          = row.product_id;
            changes.product_category_id = category_id;
            changes.name                = row.name;
            changes.company_id          = row.company_id;
            return changes;
        },
        comboUrls: [
            {
                url:    url_company_list,
                onLoad: function (data) {
                    brewerOptions = (data.objects || data).map(function (o) {
                        return { value: o.company_id, label: o.name };
                    });
                },
            },
            {
                url:    url_product_style_list,
                onLoad: function (data) {
                    styleOptions = (data.objects || data).map(function (o) {
                        return { value: o.product_style_id, label: o.description };
                    });
                },
            },
        ],
        columns: [
            { field: 'company_id',       headerName: 'Brewer',
              cellRenderer: function (p) {
                  var o = brewerOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: brewerOptions }; },
              editable: true },
            { field: 'name',             headerName: 'Name',             editable: true },
            { field: 'nominal_abv',      headerName: 'Advertised ABV',
              cellRenderer: function (p) { return p.value ? p.value : ''; },
              editable: true },
            { field: 'description',      headerName: 'Description',      editable: true },
            { field: 'comment',          headerName: 'Comment',          editable: true },
            { field: 'product_style_id', headerName: 'Style',
              cellRenderer: function (p) {
                  var o = styleOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: styleOptions }; },
              editable: true, flex: 1 },
        ],
    });
});
