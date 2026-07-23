// festival_view.js — Festival detail view with sub-grids
document.addEventListener('DOMContentLoaded', function () {
    var container = document.getElementById('datagrid');

    var tabNav = document.createElement('ul');
    tabNav.className = 'nav nav-tabs mb-3';
    tabNav.id = 'festival-tabs';
    tabNav.setAttribute('role', 'tablist');
    var tabContent = document.createElement('div');
    tabContent.className = 'tab-content flex-grow-1';
    container.appendChild(tabNav);
    container.appendChild(tabContent);

    function makeTab(id, label, active) {
        var li  = document.createElement('li');  li.className = 'nav-item';
        var btn = document.createElement('button');
        btn.className = 'nav-link' + (active ? ' active' : '');
        btn.id = id + '-tab';
        btn.setAttribute('data-bs-toggle', 'tab');
        btn.setAttribute('data-bs-target', '#' + id);
        btn.setAttribute('role', 'tab');
        btn.textContent = label;
        li.appendChild(btn);
        tabNav.appendChild(li);
        var pane = document.createElement('div');
        pane.className = 'tab-pane fade h-100' + (active ? ' show active' : '');
        pane.id = id;
        pane.setAttribute('role', 'tabpanel');
        tabContent.appendChild(pane);
        return pane;
    }

    var pInfoPane     = makeTab('fst-info',      'Festival Information',   true);
    var pStatusPane   = makeTab('fst-status',    'Festival Status',        false);
    var pRecvPane     = makeTab('fst-products',  'Products Received',      false);
    var pCaskPane     = makeTab('fst-casks',     'All Casks Received',     false);
    var pStillPane    = makeTab('fst-stillage',  'Casks by Stillage',      false);
    var pOrderPane    = makeTab('fst-orders',    'Product Order Batches',  false);
    var pDipPane      = makeTab('fst-dips',      'Cask Dip Batches',       false);

    // Festival Information form
    createViewForm({
        container: pInfoPane,
        loadUrl:   url_festival_load_form,
        idParams:  { festival_id: festival_id },
        submitUrl: url_festival_submit,
        fields: [
            { name: 'year',           label: 'Year' },
            { name: 'name',           label: 'Festival Name' },
            { name: 'fst_start_date', label: 'Start Date', type: 'date' },
            { name: 'fst_end_date',   label: 'End Date',   type: 'date' },
            { name: 'description',    label: 'Description', type: 'textarea' },
            { name: 'festival_id',    label: '',           type: 'hidden' },
        ],
    });

    // Festival Status (read-only form)
    createViewForm({
        container: pStatusPane,
        loadUrl:   url_festival_status,
        idParams:  { festival_id: festival_id },
        submitUrl: url_festival_submit, // won't be used (read-only)
        fields: [
            { name: 'kils_ordered',         label: 'Total kils of beer ordered', readOnly: true },
            { name: 'kils_sale_or_return',  label: 'Total SOR kils',             readOnly: true },
            { name: 'kils_remaining',       label: 'Total kils of beer remaining', readOnly: true },
            { name: 'num_beers_available',  label: 'Beers available',            readOnly: true },
        ],
    });

    // Products Received - view grid of categories
    createViewGrid({
        container: pRecvPane,
        loadUrl:   url_category_list,
        columns: [
            { field: 'description', headerName: 'Product Category', flex: 1 },
        ],
        viewLinkUrl: function (row) {
            return url_base + 'festivalproduct/grid/' + festival_id + '/' + row.product_category_id;
        },
    });

    // All Casks Received - view grid of categories
    createViewGrid({
        container: pCaskPane,
        loadUrl:   url_category_list,
        columns: [
            { field: 'description', headerName: 'Product Category', flex: 1 },
        ],
        viewLinkUrl: function (row) {
            return url_base + 'cask/grid/' + festival_id + '/' + row.product_category_id;
        },
    });

    // Stillage editor grid
    createEditorGrid({
        container:   pStillPane,
        loadUrl:     url_stillage_list,
        loadParams:  { festival_id: festival_id },
        submitUrl:   url_stillageloc_submit,
        deleteUrl:   url_stillageloc_delete,
        idField:     'stillage_location_id',
        objLabel:    'Stillage Location',
        viewLinkUrl: function (row) {
            return url_base + 'stillagelocation/grid/' + row.stillage_location_id;
        },
        recordChanges: function (row, changes) {
            changes.stillage_location_id = row.stillage_location_id;
            changes.festival_id          = festival_id;
            return changes;
        },
        columns: [
            { field: 'description', headerName: 'Stillage Name', editable: true, flex: 1 },
        ],
    });

    // Order Batches editor grid
    createEditorGrid({
        container:   pOrderPane,
        loadUrl:     url_order_batch_list,
        loadParams:  { festival_id: festival_id },
        submitUrl:   url_order_batch_submit,
        deleteUrl:   url_order_batch_delete,
        idField:     'order_batch_id',
        objLabel:    'Order Batch',
        viewLinkUrl: function (row) {
            return url_base + 'orderbatch/view/' + row.order_batch_id;
        },
        recordChanges: function (row, changes) {
            changes.order_batch_id = row.order_batch_id;
            changes.festival_id    = festival_id;
            return changes;
        },
        columns: [
            { field: 'description', headerName: 'Order Batch Description', editable: true, flex: 1 },
            { field: 'order_date',  headerName: 'Order Date',
              cellEditor: FlatpickrDateEditor, editable: true },
        ],
    });

    // Cask Dip Batches editor grid
    createEditorGrid({
        container:   pDipPane,
        loadUrl:     url_measurement_batch_list,
        loadParams:  { festival_id: festival_id },
        submitUrl:   url_measurement_batch_submit,
        deleteUrl:   url_measurement_batch_delete,
        idField:     'measurement_batch_id',
        objLabel:    'Measurement Batch',
        viewLinkUrl: function (row) {
            return url_base + 'measurementbatch/view/' + row.measurement_batch_id;
        },
        recordChanges: function (row, changes) {
            changes.measurement_batch_id = row.measurement_batch_id;
            changes.festival_id          = festival_id;
            return changes;
        },
        columns: [
            { field: 'measurement_time', headerName: 'Measurement Batch Time',
              cellEditor: FlatpickrDateTimeEditor, editable: true, flex: 1 },
            { field: 'description',      headerName: 'Description (optional)',  editable: true },
        ],
    });
});
