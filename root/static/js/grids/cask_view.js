// cask_view.js — Cask detail view with dip measurements sub-grid
document.addEventListener('DOMContentLoaded', function () {
    // Tab container
    var container = document.getElementById('datagrid');

    // Build Bootstrap tabs wrapper
    var tabNav  = document.createElement('ul');
    tabNav.className = 'nav nav-tabs mb-3';
    tabNav.id = 'cask-tabs';
    tabNav.setAttribute('role', 'tablist');

    var tabContent = document.createElement('div');
    tabContent.className = 'tab-content flex-grow-1';
    container.appendChild(tabNav);
    container.appendChild(tabContent);

    function makeTab(id, label, active) {
        var li   = document.createElement('li');  li.className = 'nav-item';
        var btn  = document.createElement('button');
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

    var formPane = makeTab('cask-form', 'Cask Information', true);
    var dipPane  = makeTab('cask-dips', 'Dips', false);

    // Cask detail form
    createViewForm({
        container: formPane,
        loadUrl:   url_cask_load_form,
        idParams:  { cask_id: cask_id },
        submitUrl: url_cask_submit,
        fields: [
            { name: 'company_name',          label: 'Company',          readOnly: true },
            { name: 'product_name',          label: 'Product',          readOnly: true },
            { name: 'ext_reference',         label: 'Brewery Cask ID' },
            { name: 'container_size_id',     label: 'Cask Size',
              type: 'select', optionsUrl: url_cask_size_list,
              valueField: 'container_size_id', displayField: 'description', allowBlank: false },
            { name: 'distributor_id',        label: 'Distributor',
              type: 'select', optionsUrl: url_company_list,
              valueField: 'company_id', displayField: 'name', allowBlank: true },
            { name: 'price',                 label: 'Cask Price' },
            { name: 'currency_id',           label: 'Currency',
              type: 'select', optionsUrl: url_currency_list,
              valueField: 'currency_id', displayField: 'currency_code', allowBlank: false },
            { name: 'festival_name',         label: 'Festival',         readOnly: true },
            { name: 'festival_ref',          label: 'Festival Cask ID', type: 'number' },
            { name: 'int_reference',         label: 'Cellar Cask No.',  type: 'number' },
            { name: 'is_sale_or_return',     label: 'Is SOR',           type: 'number' },
            { name: 'stillage_location_id',  label: 'Stillage',
              type: 'select', optionsUrl: url_stillage_list,
              valueField: 'stillage_location_id', displayField: 'description', allowBlank: true },
            { name: 'stillage_bay',          label: 'Bay No.',          type: 'number' },
            { name: 'bay_position_id',       label: 'Bay Position',
              type: 'select', optionsUrl: url_bay_position_list,
              valueField: 'bay_position_id', displayField: 'description', allowBlank: true },
            { name: 'cask_graveyard',        label: 'Cask Graveyard' },
            { name: 'comment',               label: 'Comment',          type: 'textarea' },
            { name: 'cask_management_id',    label: '',                 type: 'hidden' },
        ],
    });

    // Dip measurements sub-grid
    var dipBatchOptions = [];
    createEditorGrid({
        container:   dipPane,
        loadUrl:     url_cask_measurement_list,
        loadParams:  { cask_id: cask_id },
        submitUrl:   url_caskmeasurement_submit,
        deleteUrl:   url_caskmeasurement_delete,
        idField:     'cask_measurement_id',
        objLabel:    'Cask Measurement',
        viewLinkUrl: function (row) {
            return url_base + 'caskmeasurement/view/' + row.cask_measurement_id;
        },
        recordChanges: function (row, changes) {
            changes.cask_measurement_id = row.cask_measurement_id;
            changes.cask_id             = cask_id;
            return changes;
        },
        comboUrls: [
            {
                url: url_measurement_batch_list,
                onLoad: function (data) {
                    dipBatchOptions = (data.objects || data).map(function (o) {
                        return { value: o.measurement_batch_id, label: o.measurement_time };
                    });
                },
            },
        ],
        columns: [
            { field: 'measurement_batch_id', headerName: 'Dip Time',
              cellRenderer: function (p) {
                  var o = dipBatchOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: dipBatchOptions }; },
              editable: true, flex: 1 },
            { field: 'volume',  headerName: 'Volume',  editable: true },
            { field: 'comment', headerName: 'Comment', editable: true },
        ],
    });
});
