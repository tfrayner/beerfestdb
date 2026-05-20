// product_index.js — Product categories listing (navigate to products)
document.addEventListener('DOMContentLoaded', function () {
    createViewGrid({
        container: document.getElementById('datagrid'),
        loadUrl:   url_category_list,
        columns: [
            { field: 'description', headerName: 'Product Category', flex: 1 },
        ],
        viewLinkUrl: function (row) {
            return url_base + 'product/grid/' + row.product_category_id;
        },
    });
});
