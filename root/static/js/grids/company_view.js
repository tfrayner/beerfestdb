// company_view.js — Company detail view with contacts, products, and festivals sub-grids
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

    var pComp     = makeTab('co-info',     'Company Information', true);
    var pContacts = makeTab('co-contacts', 'Contacts',            false);
    var pProducts = makeTab('co-products', 'Products',            false);
    var pFests    = makeTab('co-festivals','Festivals',            false);

    // Company form
    createViewForm({
        container: pComp,
        loadUrl:   url_company_load_form,
        idParams:  { company_id: company_id },
        submitUrl: url_company_submit,
        fields: [
            { name: 'name',              label: 'Name' },
            { name: 'full_name',         label: 'Full Name' },
            { name: 'loc_desc',          label: 'Location' },
            { name: 'company_region_id', label: 'Region',
              type: 'select', optionsUrl: url_company_region_list,
              valueField: 'company_region_id', displayField: 'description', allowBlank: true },
            { name: 'year_founded',      label: 'Year Founded', type: 'number' },
            { name: 'url',               label: 'Web site' },
            { name: 'awrs_urn',          label: 'AWRS URN' },
            { name: 'comment',           label: 'Comment', type: 'textarea' },
            { name: 'company_id',        label: '', type: 'hidden' },
        ],
    });

    // Contacts editor grid
    var contactTypeOptions = [];
    var countryOptions     = [];
    createEditorGrid({
        container:   pContacts,
        loadUrl:     url_contact_list,
        loadParams:  { company_id: company_id },
        submitUrl:   url_contact_submit,
        deleteUrl:   url_contact_delete,
        idField:     'contact_id',
        objLabel:    'Contact',
        viewLinkUrl: function (row) {
            return url_base + 'contact/view/' + row.contact_id;
        },
        recordChanges: function (row, changes) {
            changes.contact_id = row.contact_id;
            changes.company_id = company_id;
            return changes;
        },
        comboUrls: [
            {
                url: url_contact_type_list,
                onLoad: function (data) {
                    contactTypeOptions = (data.objects || data).map(function (o) {
                        return { value: o.contact_type_id, label: o.description };
                    });
                },
            },
            {
                url: url_country_list,
                onLoad: function (data) {
                    countryOptions = (data.objects || data).map(function (o) {
                        return { value: o.country_id, label: o.country_code_iso3 };
                    });
                },
            },
        ],
        columns: [
            { field: 'contact_type_id', headerName: 'Contact Type',
              cellRenderer: function (p) {
                  var o = contactTypeOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: contactTypeOptions }; },
              editable: true, flex: 1 },
            { field: 'last_name',     headerName: 'Last Name',  editable: true },
            { field: 'first_name',    headerName: 'First Name', editable: true },
            { field: 'street_address', headerName: 'Street',    editable: false },
            { field: 'postcode',      headerName: 'Postcode',   editable: true },
            { field: 'country_id',    headerName: 'Country',
              cellRenderer: function (p) {
                  var o = countryOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: countryOptions }; },
              editable: true },
            { field: 'email',         headerName: 'Email',      editable: true },
            { field: 'comment',       headerName: 'Comment',    editable: true },
        ],
    });

    // Products editor grid
    var categoryOptions = [];
    var styleOptions    = [];
    createEditorGrid({
        container:   pProducts,
        loadUrl:     url_product_list,
        loadParams:  { company_id: company_id },
        submitUrl:   url_product_submit,
        deleteUrl:   url_product_delete,
        idField:     'product_id',
        objLabel:    'Product',
        defaultData: { product_category_id: default_product_category },
        viewLinkUrl: function (row) {
            return url_base + 'product/view/' + row.product_id;
        },
        recordChanges: function (row, changes) {
            changes.product_id          = row.product_id;
            changes.product_category_id = row.product_category_id;
            changes.name                = row.name;
            changes.company_id          = company_id;
            return changes;
        },
        comboUrls: [
            {
                url: url_category_list,
                onLoad: function (data) {
                    categoryOptions = (data.objects || data).map(function (o) {
                        return { value: o.product_category_id, label: o.description };
                    });
                },
            },
            {
                url: url_product_style_list,
                onLoad: function (data) {
                    styleOptions = (data.objects || data).map(function (o) {
                        return { value: o.product_style_id, label: o.description };
                    });
                },
            },
        ],
        columns: [
            { field: 'name',             headerName: 'Name',        editable: true },
            { field: 'nominal_abv',      headerName: 'ABV',
              cellRenderer: function (p) { return p.value ? p.value : ''; },
              editable: true },
            { field: 'description',      headerName: 'Description', editable: true, flex: 1 },
            { field: 'comment',          headerName: 'Comment',     editable: true },
            { field: 'product_category_id', headerName: 'Category',
              cellRenderer: function (p) {
                  var o = categoryOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: categoryOptions }; },
              editable: true },
            { field: 'product_style_id', headerName: 'Style',
              cellRenderer: function (p) {
                  var o = styleOptions.find(function (x) { return String(x.value) === String(p.value); });
                  return o ? o.label : (p.value || '');
              },
              cellEditor: TomSelectCellEditor,
              cellEditorParams: function () { return { values: styleOptions }; },
              editable: true },
        ],
    });

    // Festival Products view grid
    createViewGrid({
        container: pFests,
        loadUrl:   url_festival_product_list,
        loadParams:{ company_id: company_id },
        columns: [
            { field: 'festival_name', headerName: 'Festival Name', flex: 1 },
            { field: 'festival_year', headerName: 'Year' },
            { field: 'product_name',  headerName: 'Product' },
            { field: 'comment',       headerName: 'Comments' },
        ],
        viewLinkUrl: function (row) {
            return url_base + 'festivalproduct/view/' + row.festival_product_id;
        },
    });
});
