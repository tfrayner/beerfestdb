// festivalproduct.js — Festival products editor grid (with cascading company→product combos)
document.addEventListener('DOMContentLoaded', function () {
    var brewerOptions   = [];
    var productOptions  = [];
    var allProducts     = []; // full unfiltered list for client-side cascade
    var volumeOptions   = [];
    var currencyOptions = [];

    createEditorGrid({
        container:   document.getElementById('datagrid'),
        loadUrl:     url_object_list,
        submitUrl:   url_festivalproduct_submit,
        deleteUrl:   url_festivalproduct_delete,
        idField:     'festival_product_id',
        objLabel:    'Festival Product',
        defaultData: { sale_currency_id: default_currency, sale_volume_id: default_sale_volume },
        viewLinkUrl: function (row) {
            return url_base + 'festivalproduct/view/' + row.festival_product_id;
        },
        recordChanges: function (row, changes) {
            changes.festival_product_id = row.festival_product_id;
            changes.sale_currency_id    = row.sale_currency_id;
            changes.sale_volume_id      = row.sale_volume_id;
            changes.festival_id         = festival_id;
            return changes;
        },
        comboUrls: [
            {
                url:    url_company_list,
                params: { brewer_festival_id: festival_id },
                onLoad: function (data) {
                    brewerOptions = (data.objects || data).map(function (o) {
                        return { value: o.company_id, label: o.name };
                    });
                },
            },
            {
                url:    url_product_list,
                onLoad: function (data) {
                    allProducts   = (data.objects || data);
                    productOptions = allProducts.map(function (o) {
                        return { value: o.product_id, label: o.name, company_id: o.company_id };
                    });
                },
            },
            {
                url:    url_sale_volume_list,
                onLoad: function (data) {
                    volumeOptions = (data.objects || data).map(function (o) {
                        return { value: o.sale_volume_id, label: o.description };
                    });
                },
            },
            {
                url:    url_currency_list,
                onLoad: function (data) {
                    currencyOptions = (data.objects || data).map(function (o) {
                        return { value: o.currency_id, label: o.currency_code };
                    });
                },
            },
        ],
        columns: [
            { field: 'company_id',      headerName: 'Brewer',
              cellRenderer: function (p) {
                  var o = brewerOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: brewerOptions }; },
              editable: true },
            { field: 'product_id',      headerName: 'Product',
              cellRenderer: function (p) {
                  var o = productOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function (params) {
                  // Filter products to those matching the current row's company_id
                  var companyId = params.data ? params.data.company_id : null;
                  var filtered = companyId
                      ? productOptions.filter(function (o) { return String(o.company_id) === String(companyId); })
                      : productOptions;
                  return { values: filtered };
              },
              editable: true, flex: 1 },
            { field: 'sale_price',      headerName: 'Sale Price',  editable: true },
            { field: 'sale_currency_id', headerName: 'Currency',
              cellRenderer: function (p) {
                  var o = currencyOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: currencyOptions }; },
              editable: true },
            { field: 'sale_volume_id',  headerName: 'Sale Volume',
              cellRenderer: function (p) {
                  var o = volumeOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: volumeOptions }; },
              editable: true },
            { field: 'comment',         headerName: 'Comment',     editable: true },
        ],
    });
});
