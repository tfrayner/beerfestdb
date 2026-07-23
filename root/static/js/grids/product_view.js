// product_view.js — Product detail view with characteristics and festival products sub-grids
document.addEventListener('DOMContentLoaded', function () {
    var container = document.getElementById('datagrid');

    var tabNav = document.createElement('ul');
    tabNav.className = 'nav nav-tabs mb-3';
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

    var pInfo  = makeTab('prod-info',  'Product Information', true);
    var pChars = makeTab('prod-chars', 'Characteristics',     false);
    var pFests = makeTab('prod-fests', 'Festivals',           false);

    // Product form
    createViewForm({
        container: pInfo,
        loadUrl:   url_product_load_form,
        idParams:  { product_id: product_id },
        submitUrl: url_product_submit,
        fields: [
            { name: 'company_name',          label: 'Company',          readOnly: true },
            { name: 'name',                  label: 'Name' },
            { name: 'product_category_id',   label: 'Category',
              type: 'select', optionsUrl: url_category_list,
              valueField: 'product_category_id', displayField: 'description', allowBlank: false },
            { name: 'product_style_id',      label: 'Style',
              type: 'select', optionsUrl: url_product_style_list,
              valueField: 'product_style_id', displayField: 'description', allowBlank: true },
            { name: 'nominal_abv',           label: 'Advertised ABV',   type: 'number' },
            { name: 'is_vegan',              label: 'Is Vegan',         type: 'number' },
            { name: 'allergens_present',     label: 'Allergens PRESENT',
              type: 'multiselect', optionsUrl: url_product_allergen_list,
              valueField: 'product_allergen_type_id', displayField: 'description', allowBlank: true },
            { name: 'allergens_absent',      label: 'Allergens ABSENT',
              type: 'multiselect', optionsUrl: url_product_allergen_list,
              valueField: 'product_allergen_type_id', displayField: 'description', allowBlank: true },
            { name: 'description',           label: 'Short Description', type: 'textarea' },
            { name: 'long_description',      label: 'Long Description',  type: 'textarea' },
            { name: 'comment',               label: 'Comment',           type: 'textarea' },
        ],
    });

    // Characteristics editor grid
    var charTypeOptions = [];
    createEditorGrid({
        container:   pChars,
        loadUrl:     url_product_characteristic_list,
        loadParams:  { product_id: product_id },
        submitUrl:   url_product_characteristic_submit,
        deleteUrl:   url_product_characteristic_delete,
        idField:     ['product_id', 'product_characteristic_type_id'],
        objLabel:    'Product Characteristic',
        recordChanges: function (row, changes) {
            changes.product_id = product_id;
            return changes;
        },
        comboUrls: [
            {
                url: url_product_characteristic_type_list,
                onLoad: function (data) {
                    charTypeOptions = (data.objects || data).map(function (o) {
                        return { value: o.product_characteristic_type_id, label: o.description };
                    });
                },
            },
        ],
        columns: [
            { field: 'product_characteristic_type_id', headerName: 'Characteristic Type',
              cellRenderer: function (p) {
                  var o = charTypeOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: charTypeOptions }; },
              editable: true },
            { field: 'value', headerName: 'Value', editable: true, flex: 1 },
        ],
    });

    // Festival Products editor grid
    createEditorGrid({
        container:   pFests,
        loadUrl:     url_festival_product_list,
        loadParams:  { product_id: product_id },
        submitUrl:   url_festivalproduct_submit,
        deleteUrl:   url_festivalproduct_delete,
        idField:     'festival_product_id',
        objLabel:    'Festival Product',
        recordChanges: function (row, changes) {
            changes.festival_product_id = row.festival_product_id;
            changes.product_id          = product_id;
            return changes;
        },
        columns: [
            { field: 'festival_name', headerName: 'Festival',  editable: false },
            { field: 'comment',       headerName: 'Comment',   editable: true, flex: 1 },
        ],
        viewLinkUrl: function (row) {
            return url_base + 'festivalproduct/view/' + row.festival_product_id;
        },
    });
});
