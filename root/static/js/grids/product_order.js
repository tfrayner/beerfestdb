// product_order.js — Product orders editor grid (with cascading company→product combos)
document.addEventListener('DOMContentLoaded', function () {
    var brewerOptions      = [];
    var productOptions     = [];
    var distributorOptions = [];
    var caskSizeOptions    = [];
    var currencyOptions    = [];

    createEditorGrid({
        container:   document.getElementById('datagrid'),
        loadUrl:     url_object_list,
        submitUrl:   url_productorder_submit,
        deleteUrl:   url_productorder_delete,
        idField:     'product_order_id',
        objLabel:    'Product Order',
        defaultData: { currency_id: default_currency },
        viewLinkUrl: function (row) {
            return url_base + 'productorder/view/' + row.product_order_id;
        },
        recordChanges: function (row, changes) {
            changes.product_order_id = row.product_order_id;
            changes.currency_id      = row.currency_id;
            changes.order_batch_id   = order_batch_id;
            return changes;
        },
        comboUrls: [
            {
                url:    url_company_list,
                params: { brewer_order_batch_id: order_batch_id },
                onLoad: function (data) {
                    brewerOptions = (data.objects || data).map(function (o) {
                        return { value: o.company_id, label: o.name };
                    });
                },
            },
            {
                url:    url_product_list,
                onLoad: function (data) {
                    var all = (data.objects || data);
                    productOptions = all.map(function (o) {
                        return { value: o.product_id, label: o.name, company_id: o.company_id };
                    });
                },
            },
            {
                url:    url_company_list,
                params: { supplier_order_batch_id: order_batch_id },
                onLoad: function (data) {
                    distributorOptions = (data.objects || data).map(function (o) {
                        return { value: o.company_id, label: o.name };
                    });
                },
            },
            {
                url:    url_cask_size_list,
                onLoad: function (data) {
                    caskSizeOptions = (data.objects || data).map(function (o) {
                        return { value: o.container_size_id, label: o.description };
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
            { field: 'distributor_id',   headerName: 'Distributor',
              cellRenderer: function (p) {
                  var o = distributorOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: distributorOptions }; },
              editable: true },
            { field: 'company_id',       headerName: 'Brewer',
              cellRenderer: function (p) {
                  var o = brewerOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: brewerOptions }; },
              editable: true },
            { field: 'product_id',       headerName: 'Product',
              cellRenderer: function (p) {
                  var o = productOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function (params) {
                  var companyId = params.data ? params.data.company_id : null;
                  var filtered = companyId
                      ? productOptions.filter(function (o) { return String(o.company_id) === String(companyId); })
                      : productOptions;
                  return { values: filtered };
              },
              editable: true, flex: 1 },
            { field: 'container_size_id', headerName: 'Cask Size',
              cellRenderer: function (p) {
                  var o = caskSizeOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: caskSizeOptions }; },
              editable: true },
            { field: 'cask_count',       headerName: 'No. Casks',   editable: true },
            { field: 'price',            headerName: 'Total Price',  editable: true },
            { field: 'currency_id',      headerName: 'Currency',
              cellRenderer: function (p) {
                  var o = currencyOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: currencyOptions }; },
              editable: true },
            { field: 'comment',          headerName: 'Comment',      editable: true },
            { field: 'is_sale_or_return', headerName: 'SOR',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'is_final',         headerName: 'Ordered',
              cellRenderer: makeCheckboxRenderer(), editable: true },
            { field: 'is_received',      headerName: 'Arrived',
              cellRenderer: makeCheckboxRenderer(), editable: true },
        ],
        onReady: function (api) {
            // Warn before saving that received items will be locked for editing
            // (handled through normal save flow — no special override needed in AG Grid)
        },
    });
});
