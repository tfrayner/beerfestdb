/*
 * This file is part of BeerFestDB, a beer festival product management
 * system.
 *
 * Copyright (C) 2010 Tim F. Rayner
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

'use strict';

/* ============================================================
 * HTTP / CSRF helpers
 * ============================================================ */

/**
 * POST form-encoded data to url, appending the CSRF token that the
 * Template Toolkit template injects as the global `csrf_token`.
 * Returns a Promise that resolves to the parsed JSON body, or rejects
 * with an Error whose message is taken from the server's error stash.
 */
async function bfdbPost(url, params) {
    const body = new URLSearchParams(params);
    body.set('csrf_token', typeof csrf_token !== 'undefined' ? csrf_token : '');
    const resp = await fetch(url, {
        method:  'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body:    body.toString(),
    });
    const text = await resp.text();
    let parsed;
    try { parsed = JSON.parse(text); } catch (e) { parsed = {}; }
    if (!resp.ok) {
        throw new Error(parsed.error || ('HTTP ' + resp.status));
    }
    return parsed;
}

/**
 * Submit an array of change objects to a Catalyst submit action.
 * onSuccess(stash) is called with the server's JSON response on success.
 */
function submitChanges(url, data, onSuccess) {
    bfdbPost(url, { changes: JSON.stringify(data) })
        .then(function (stash) { if (onSuccess) onSuccess(stash); })
        .catch(function (err)  { bfdbAlert('Error', err.message); });
}

/**
 * Send an array of ids (or id-objects) to a Catalyst delete action.
 * onSuccess() is called on success.
 */
function deleteRecords(url, ids, onSuccess) {
    bfdbPost(url, { changes: JSON.stringify(ids) })
        .then(function ()    { if (onSuccess) onSuccess(); })
        .catch(function (err) { bfdbAlert('Error', err.message); });
}

/* ============================================================
 * Bootstrap 5 modal helpers (replace Ext.Msg.alert / confirm)
 * ============================================================ */

function _ensureModal(id, extraFooter) {
    let modal = document.getElementById(id);
    if (!modal) {
        modal = document.createElement('div');
        modal.id        = id;
        modal.className = 'modal fade';
        modal.setAttribute('tabindex', '-1');
        modal.innerHTML =
            '<div class="modal-dialog">' +
              '<div class="modal-content">' +
                '<div class="modal-header">' +
                  '<h5 class="modal-title"></h5>' +
                  '<button type="button" class="btn-close" data-bs-dismiss="modal"></button>' +
                '</div>' +
                '<div class="modal-body"></div>' +
                '<div class="modal-footer">' +
                  (extraFooter || '') +
                  '<button type="button" class="btn btn-primary" data-bs-dismiss="modal">OK</button>' +
                '</div>' +
              '</div>' +
            '</div>';
        document.body.appendChild(modal);
    }
    return modal;
}

function bfdbAlert(title, msg) {
    const modal = _ensureModal('bfdb-alert-modal');
    modal.querySelector('.modal-title').textContent = title;
    modal.querySelector('.modal-body').textContent  = msg;
    bootstrap.Modal.getOrCreateInstance(modal).show();
}

function bfdbConfirm(title, msg, onYes) {
    const modal = _ensureModal(
        'bfdb-confirm-modal',
        '<button type="button" class="btn btn-danger" id="bfdb-confirm-yes">Yes</button>'
    );
    modal.querySelector('.modal-title').textContent = title;
    modal.querySelector('.modal-body').textContent  = msg;

    const yesBtn = modal.querySelector('#bfdb-confirm-yes');
    // Replace to clear any previous listener.
    const fresh  = yesBtn.cloneNode(true);
    yesBtn.replaceWith(fresh);
    const bsModal = bootstrap.Modal.getOrCreateInstance(modal);
    fresh.addEventListener('click', function () {
        bsModal.hide();
        if (onYes) onYes();
    });
    bsModal.show();
}

/* ============================================================
 * Utilities
 * ============================================================ */

/** Shallow object clone — equivalent to the old simpleClone(). */
function simpleClone(obj) {
    if (obj == null || typeof obj !== 'object') return obj;
    return Object.assign({}, obj);
}

/* ============================================================
 * AG Grid cell renderer factories
 * ============================================================ */

/**
 * Returns an AG Grid cellRenderer function that maps a foreign-key
 * value to a human-readable label.
 *
 * @param {Array<{value, label}>|Map} options
 */
function makeComboRenderer(options) {
    const map = options instanceof Map
        ? options
        : new Map((options || []).map(function (o) {
              return [String(o.value == null ? '' : o.value), o.label];
          }));
    return function (params) {
        if (params.value == null || params.value === '') return '';
        return map.get(String(params.value)) || String(params.value);
    };
}

/** Renders boolean DB values as 'yes'/'no'. */
function makeCheckboxRenderer() {
    return function (params) { return params.value ? 'yes' : 'no'; };
}

/** Renders numbers, converting undefined/null to empty string. */
function makeNumberRenderer() {
    return function (params) { return params.value != null ? params.value : ''; };
}

/**
 * Returns a cellRenderer that shows a link icon to navigate to a
 * detail page.  urlFn can be a plain string or a function(rowData).
 */
function makeViewLinkRenderer(urlFn) {
    return function (params) {
        if (!params.data) return '';
        const href = typeof urlFn === 'function' ? urlFn(params.data) : urlFn;
        return '<a href="' + href + '" class="bfdb-row-link" title="View details">' +
               '<span class="icon-open"></span></a>';
    };
}

/* ============================================================
 * AG Grid cell editors — flatpickr wrappers
 * ============================================================ */

/** AG Grid ICellEditor using flatpickr for date-only fields. */
class FlatpickrDateEditor {
    init(params) {
        this._value = params.value || '';
        this._input = document.createElement('input');
        this._input.value = this._value;
        this._input.className = 'form-control form-control-sm';
        this._fp = flatpickr(this._input, {
            dateFormat:  'Y-m-d',
            defaultDate: this._value || null,
            allowInput:  true,
            onReady:     () => { setTimeout(() => this._fp.open(), 50); },
            onClose:     () => { params.stopEditing(); },
        });
    }
    getGui()   { return this._input; }
    getValue() { return this._input.value; }
    destroy()  { if (this._fp) this._fp.destroy(); }
    isPopup()  { return false; }
}

/** AG Grid ICellEditor using flatpickr for datetime fields. */
class FlatpickrDateTimeEditor {
    init(params) {
        this._value = params.value || '';
        this._input = document.createElement('input');
        this._input.value = this._value;
        this._input.className = 'form-control form-control-sm';
        this._fp = flatpickr(this._input, {
            enableTime:  true,
            dateFormat:  'Y-m-d H:i:S',
            defaultDate: this._value || null,
            allowInput:  true,
            onReady:     () => { setTimeout(() => this._fp.open(), 50); },
            onClose:     () => { params.stopEditing(); },
        });
    }
    getGui()   { return this._input; }
    getValue() { return this._input.value; }
    destroy()  { if (this._fp) this._fp.destroy(); }
    isPopup()  { return false; }
}

/* ============================================================
 * Dirty-tracking registry  (for window.onbeforeunload)
 * ============================================================ */

const _dirtyGridApis = new Set();
const _dirtyForms    = new Set();

function registerDirtyGrid(api)    { _dirtyGridApis.add(api); }
function unregisterDirtyGrid(api)  { _dirtyGridApis.delete(api); }
function registerDirtyForm(form)   { _dirtyForms.add(form); }
function unregisterDirtyForm(form) { _dirtyForms.delete(form); }

window.onbeforeunload = function () {
    for (const api of _dirtyGridApis) {
        let hasDirty = false;
        api.forEachNode(function (n) { if (n.data && n.data.__dirty) hasDirty = true; });
        if (hasDirty) return 'You have unsaved changes. Are you sure you want to leave this page?';
    }
    for (const form of _dirtyForms) {
        if (form.isDirty && form.isDirty())
            return 'You have unsaved changes. Are you sure you want to leave this page?';
    }
};

/* ============================================================
 * Editor grid factory
 * ============================================================
 *
 * createEditorGrid(config) → AG Grid API
 *
 * Required config keys:
 *   container   {Element|string}  parent element or CSS selector
 *   submitUrl   {string}
 *   deleteUrl   {string}
 *   idField     {string|string[]} primary-key field(s)
 *   columns     {Array}           AG Grid column definitions
 *   loadUrl     {string}          URL that returns JSON row array
 *
 * Optional:
 *   objLabel      {string}        label for toolbar button text
 *   defaultData   {object}        template for new rows
 *   firstEditCol  {string}        field to start editing on new rows
 *   viewLinkUrl   {function|string} if present, prepends a link column
 *   recordChanges {function(row)}  transform a dirty row before POST
 *   loadParams    {object}        extra query params for loadUrl
 *   comboUrls     {Array<{url, params, onLoad}>}  pre-load before rows
 *   onSave        {function()}    called after successful save
 *   onDiscard     {function()}    called after discard
 *   onAfterDelete {function()}    called after successful delete
 *   onReady       {function(api)} called once data is loaded
 */
function createEditorGrid(config) {
    const container = typeof config.container === 'string'
        ? document.querySelector(config.container)
        : config.container;

    /* ---- build column defs ---- */
    const colDefs = [];
    if (config.viewLinkUrl) {
        colDefs.push({
            headerName: '',
            field:      '__viewlink',
            width:      40,
            minWidth:   40,
            maxWidth:   40,
            pinned:     'left',
            sortable:   false,
            filter:     false,
            editable:   false,
            cellRenderer: makeViewLinkRenderer(config.viewLinkUrl),
        });
    }
    colDefs.push(...config.columns);

    /* ---- wrapper and grid div ---- */
    const wrapper = document.createElement('div');
    wrapper.className = 'bfdb-grid-wrapper d-flex flex-column h-100';

    const gridDiv = document.createElement('div');
    gridDiv.className = 'ag-theme-alpine flex-grow-1';

    /* ---- toolbar ---- */
    const toolbar = document.createElement('div');
    toolbar.className = 'd-flex gap-2 p-2 bg-light border-bottom bfdb-toolbar';

    const newBtn     = _mkBtn('btn-outline-secondary', '<span class="icon-plus"></span> New '     + (config.objLabel || 'Row'));
    const saveBtn    = _mkBtn('btn-outline-primary',   '<span class="icon-save-table"></span> Save Changes');
    const discardBtn = _mkBtn('btn-outline-secondary', '<span class="icon-cancel"></span> Discard Changes');
    const removeBtn  = _mkBtn('btn-outline-danger',    '<span class="icon-minus"></span> Remove ' + (config.objLabel || 'Row') + 's');
    removeBtn.disabled = true;

    toolbar.append(newBtn, saveBtn, discardBtn, removeBtn);
    wrapper.append(toolbar, gridDiv);
    container.appendChild(wrapper);

    /* ---- AG Grid ---- */
    const gridOptions = {
        columnDefs:   colDefs,
        defaultColDef: {
            sortable:   true,
            resizable:  true,
            filter:     true,
            editable:   true,
        },
        rowSelection:              'multiple',
        suppressRowClickSelection: true,   // require checkbox / programmatic select
        stopEditingWhenCellsLoseFocus: true,
        getRowClass: function (params) {
            return (params.data && params.data.__dirty) ? 'bfdb-dirty-row' : '';
        },
        onCellValueChanged: function (params) {
            params.data.__dirty = true;
            params.api.refreshCells({ rowNodes: [params.node], force: true });
        },
        onSelectionChanged: function (event) {
            removeBtn.disabled = event.api.getSelectedRows().length === 0;
        },
    };

    const api = agGrid.createGrid(gridDiv, gridOptions);
    registerDirtyGrid(api);

    /* ---- toolbar event listeners ---- */
    newBtn.addEventListener('click', function () {
        const row = simpleClone(config.defaultData || {});
        row.__dirty = true;
        row.__new   = true;
        api.applyTransaction({ add: [row], addIndex: 0 });
        const firstCol = config.firstEditCol || (config.columns[0] && config.columns[0].field);
        if (firstCol) {
            setTimeout(function () {
                api.startEditingCell({ rowIndex: 0, colKey: firstCol });
            }, 50);
        }
    });

    saveBtn.addEventListener('click', function () {
        api.stopEditing();
        const changes = [];
        api.forEachNode(function (node) {
            if (!node.data || !node.data.__dirty) return;
            const row = Object.assign({}, node.data);
            delete row.__dirty;
            delete row.__new;
            changes.push(config.recordChanges ? config.recordChanges(row) : row);
        });
        if (!changes.length) return;
        submitChanges(config.submitUrl, changes, function () {
            api.forEachNode(function (node) {
                if (node.data) { delete node.data.__dirty; delete node.data.__new; }
            });
            api.refreshCells();
            if (config.onSave) config.onSave();
        });
    });

    discardBtn.addEventListener('click', function () {
        api.stopEditing(true);
        if (config.onDiscard) config.onDiscard();
    });

    removeBtn.addEventListener('click', function () {
        const selected = api.getSelectedRows();
        if (!selected.length) return;
        bfdbConfirm('Delete', 'Really delete the selected rows?', function () {
            const ids = selected.map(function (row) {
                if (Array.isArray(config.idField)) {
                    const id = {};
                    config.idField.forEach(function (f) { id[f] = row[f]; });
                    return id;
                }
                return row[config.idField];
            });
            deleteRecords(config.deleteUrl, ids, function () {
                api.applyTransaction({ remove: selected });
                removeBtn.disabled = true;
                if (config.onAfterDelete) config.onAfterDelete();
            });
        });
    });

    /* ---- load data (optionally after pre-loading combo stores) ---- */
    function _load() {
        if (!config.loadUrl) return;
        const url = new URL(config.loadUrl, window.location.origin);
        if (config.loadParams) {
            Object.entries(config.loadParams).forEach(function ([k, v]) {
                url.searchParams.set(k, v);
            });
        }
        fetch(url.toString())
            .then(function (r) { return r.json(); })
            .then(function (data) {
                const rows = Array.isArray(data) ? data : (data.objects || data.data || []);
                api.setGridOption('rowData', rows);
                if (config.onReady) config.onReady(api);
            })
            .catch(function (err) { bfdbAlert('Load Error', err.message); });
    }

    const comboUrls = config.comboUrls || [];
    if (comboUrls.length === 0) {
        _load();
    } else {
        let loaded = 0;
        comboUrls.forEach(function (spec) {
            const url = new URL(spec.url, window.location.origin);
            if (spec.params) {
                Object.entries(spec.params).forEach(function ([k, v]) {
                    url.searchParams.set(k, v);
                });
            }
            fetch(url.toString())
                .then(function (r) { return r.json(); })
                .then(function (data) {
                    if (spec.onLoad) spec.onLoad(data);
                    loaded++;
                    if (loaded === comboUrls.length) _load();
                })
                .catch(function (err) { bfdbAlert('Load Error', err.message); });
        });
    }

    return api;
}

/* ============================================================
 * View-only grid factory
 * ============================================================
 *
 * createViewGrid(config) → AG Grid API
 *
 * config: { container, columns, loadUrl, loadParams,
 *           viewLinkUrl, onReady }
 */
function createViewGrid(config) {
    const container = typeof config.container === 'string'
        ? document.querySelector(config.container)
        : config.container;

    const colDefs = [];
    if (config.viewLinkUrl) {
        colDefs.push({
            headerName: '',
            field:      '__viewlink',
            width:      40,
            minWidth:   40,
            maxWidth:   40,
            pinned:     'left',
            sortable:   false,
            filter:     false,
            editable:   false,
            cellRenderer: makeViewLinkRenderer(config.viewLinkUrl),
        });
    }
    colDefs.push(...config.columns);

    const gridDiv = document.createElement('div');
    gridDiv.className = 'ag-theme-alpine';
    gridDiv.style.cssText = 'height:100%;width:100%';
    container.appendChild(gridDiv);

    const api = agGrid.createGrid(gridDiv, {
        columnDefs:    colDefs,
        defaultColDef: { sortable: true, resizable: true, filter: true, editable: false },
    });

    if (config.loadUrl) {
        const url = new URL(config.loadUrl, window.location.origin);
        if (config.loadParams) {
            Object.entries(config.loadParams).forEach(function ([k, v]) {
                url.searchParams.set(k, v);
            });
        }
        fetch(url.toString())
            .then(function (r) { return r.json(); })
            .then(function (data) {
                api.setGridOption('rowData', Array.isArray(data) ? data : (data.objects || data.data || []));
                if (config.onReady) config.onReady(api);
            })
            .catch(function (err) { bfdbAlert('Load Error', err.message); });
    }

    return api;
}

/* ============================================================
 * Tom Select helpers
 * ============================================================ */

/**
 * Initialise Tom Select on an element.
 * selector: CSS selector string or Element.
 * options:  Tom Select options object (merged with sensible defaults).
 */
function initCombo(selector, options) {
    const el = typeof selector === 'string' ? document.querySelector(selector) : selector;
    if (!el) return null;
    return new TomSelect(el, Object.assign({ create: false }, options || {}));
}

/**
 * AG Grid ICellEditor backed by Tom Select for labeled dropdowns.
 *
 * cellEditorParams: {
 *   values: [{value, label}, ...]  — current options array (may update between calls)
 * }
 *
 * The cellEditorParams function is called each time a cell enters edit mode,
 * so `values` is always fresh.
 */
class TomSelectCellEditor {
    init(params) {
        this._rawValue = params.value;
        this._container = document.createElement('div');
        this._container.style.cssText = 'width:100%;min-width:120px';

        const select = document.createElement('select');
        this._container.appendChild(select);

        const opts = (params.values || []);
        // Prepend a blank option for nullable fields
        const blank = document.createElement('option');
        blank.value = '';
        blank.textContent = '';
        select.appendChild(blank);

        opts.forEach(function (o) {
            const opt = document.createElement('option');
            opt.value  = o.value != null ? String(o.value) : '';
            opt.textContent = o.label;
            if (String(o.value) === String(params.value)) opt.selected = true;
            select.appendChild(opt);
        });

        this._ts = new TomSelect(select, {
            create:   false,
            maxItems: 1,
            onChange: (val) => {
                this._rawValue = val === '' ? null
                    : (val !== '' && !isNaN(val) ? Number(val) : val);
                params.stopEditing();
            },
        });
        // Open the dropdown shortly after mount
        setTimeout(() => { if (this._ts) this._ts.open(); }, 60);
    }

    getGui()   { return this._container; }
    getValue() { return this._rawValue; }
    isPopup()  { return true; }
    destroy()  { if (this._ts) this._ts.destroy(); }
}


/* ============================================================
 * flatpickr helpers
 * ============================================================ */

function initDatePicker(selector, options) {
    const el = typeof selector === 'string' ? document.querySelector(selector) : selector;
    if (!el) return null;
    return flatpickr(el, Object.assign({ dateFormat: 'Y-m-d' }, options || {}));
}

function initDateTimePicker(selector, options) {
    const el = typeof selector === 'string' ? document.querySelector(selector) : selector;
    if (!el) return null;
    return flatpickr(el, Object.assign({ enableTime: true, dateFormat: 'Y-m-d H:i:S' }, options || {}));
}

/* ============================================================
 * Private helpers
 * ============================================================ */

function _mkBtn(cls, html) {
    const btn = document.createElement('button');
    btn.type      = 'button';
    btn.className = 'btn btn-sm ' + cls;
    btn.innerHTML = html;
    return btn;
}

/* ============================================================
 * Detail-view form factory
 * ============================================================
 *
 * createViewForm(config) — renders a Bootstrap card form that loads
 * a single record for editing.
 *
 * Required config:
 *   container   {Element|string}
 *   loadUrl     {string}          GET — returns {object: {field: value, ...}}
 *   idParams    {object}          e.g. {country_id: 3}  appended as query params
 *   submitUrl   {string}          POST
 *   fields      {Array<{         field definitions:
 *                 name,           field name
 *                 label,          display label
 *                 type?,          'text'|'number'|'date'|'datetime'|'hidden' (default 'text')
 *                 maxLength?,     input maxlength
 *                 readOnly?,      if true, render as <input readonly>
 *               }>}
 *
 * Optional:
 *   afterSave   {function(stash)} called after successful save (default: reload)
 *   waitMsg     {string}          unused, kept for API compat
 */
function createViewForm(config) {
    const container = typeof config.container === 'string'
        ? document.querySelector(config.container)
        : config.container;

    /* ---- build form HTML ---- */
    const card = document.createElement('div');
    card.className = 'card shadow-sm mx-auto mt-4';
    card.style.maxWidth = '600px';

    const cardBody = document.createElement('div');
    cardBody.className = 'card-body';

    const form = document.createElement('form');
    form.id        = 'bfdb-view-form';
    form.noValidate = true;

    // Render fields
    config.fields.forEach(function (fld) {
        const type = fld.type || 'text';
        if (type === 'hidden') {
            const inp = document.createElement('input');
            inp.type  = 'hidden';
            inp.name  = fld.name;
            inp.id    = 'bfdb-field-' + fld.name;
            form.appendChild(inp);
            return;
        }
        const group = document.createElement('div');
        group.className = 'mb-3';

        const lbl = document.createElement('label');
        lbl.htmlFor   = 'bfdb-field-' + fld.name;
        lbl.className = 'form-label';
        lbl.textContent = fld.label;
        group.appendChild(lbl);

        let inp;
        if (type === 'date') {
            inp = document.createElement('input');
            inp.type = 'text';
            inp.className = 'form-control';
        } else if (type === 'datetime') {
            inp = document.createElement('input');
            inp.type = 'text';
            inp.className = 'form-control';
        } else if (type === 'textarea') {
            inp = document.createElement('textarea');
            inp.rows = 4;
            inp.className = 'form-control';
        } else if (type === 'select' || type === 'multiselect') {
            inp = document.createElement('select');
            if (type === 'multiselect') inp.multiple = true;
            inp.className = 'form-control';
        } else {
            inp = document.createElement('input');
            inp.type = (type === 'number') ? 'number' : 'text';
            inp.className = 'form-control';
        }
        inp.id   = 'bfdb-field-' + fld.name;
        inp.name = fld.name;
        if (fld.maxLength) inp.maxLength = fld.maxLength;
        if (fld.readOnly)  inp.readOnly  = true;
        group.appendChild(inp);
        form.appendChild(group);
    });

    /* error banner */
    const errDiv = document.createElement('div');
    errDiv.id        = 'bfdb-form-error';
    errDiv.className = 'alert alert-danger d-none';
    form.appendChild(errDiv);

    /* buttons */
    const btnRow = document.createElement('div');
    btnRow.className = 'd-flex gap-2';
    const saveBtn    = document.createElement('button');
    saveBtn.type     = 'submit';
    saveBtn.className = 'btn btn-primary';
    saveBtn.textContent = 'Save Changes';
    const discardBtn = document.createElement('button');
    discardBtn.type      = 'button';
    discardBtn.className = 'btn btn-secondary';
    discardBtn.textContent = 'Discard Changes';
    btnRow.append(saveBtn, discardBtn);
    form.appendChild(btnRow);

    cardBody.appendChild(form);
    card.appendChild(cardBody);
    container.appendChild(card);

    /* ---- initialise date pickers ---- */
    config.fields.forEach(function (fld) {
        const type = fld.type || 'text';
        const el = document.getElementById('bfdb-field-' + fld.name);
        if (!el) return;
        if (type === 'date')     initDatePicker(el);
        if (type === 'datetime') initDateTimePicker(el);
    });

    /* ---- load select/multiselect options (async) ---- */
    const _selectInstances = {};
    const _selectPromises = (config.fields || [])
        .filter(function (fld) { return fld.type === 'select' || fld.type === 'multiselect'; })
        .map(function (fld) {
            const el = document.getElementById('bfdb-field-' + fld.name);
            return fetch(fld.optionsUrl)
                .then(function (r) { return r.json(); })
                .then(function (data) {
                    const opts = Array.isArray(data) ? data : (data.objects || data.data || []);
                    if (fld.allowBlank !== false) {
                        const blank = document.createElement('option');
                        blank.value = '';
                        blank.textContent = '';
                        el.appendChild(blank);
                    }
                    opts.forEach(function (opt) {
                        const o = document.createElement('option');
                        o.value = String(opt[fld.valueField]);
                        o.textContent = opt[fld.displayField];
                        el.appendChild(o);
                    });
                    const tsOpts = { allowEmptyOption: fld.allowBlank !== false };
                    if (fld.type === 'multiselect') {
                        tsOpts.plugins = { remove_button: {} };
                    }
                    _selectInstances[fld.name] = initCombo(el, tsOpts);
                });
        });

    /* ---- load form data ---- */
    let _originalValues = {};

    function _loadForm() {
        const url = new URL(config.loadUrl, window.location.origin);
        if (config.idParams) {
            Object.entries(config.idParams).forEach(function ([k, v]) {
                url.searchParams.set(k, v);
            });
        }
        fetch(url.toString())
            .then(function (r) { return r.json(); })
            .then(function (data) {
                const obj = data.object || data;
                _originalValues = Object.assign({}, obj);
                config.fields.forEach(function (fld) {
                    const type = fld.type || 'text';
                    const el = document.getElementById('bfdb-field-' + fld.name);
                    const val = obj[fld.name];
                    if ((type === 'select' || type === 'multiselect') && _selectInstances[fld.name]) {
                        const ts = _selectInstances[fld.name];
                        if (type === 'multiselect') {
                            const vals = val ? String(val).split(',').filter(Boolean) : [];
                            ts.setValue(vals, true);
                        } else {
                            ts.setValue(val != null ? String(val) : '', true);
                        }
                    } else if (el) {
                        el.value = val != null ? val : '';
                        if (el._flatpickr) el._flatpickr.setDate(val || null, false);
                    }
                });
            })
            .catch(function (err) {
                errDiv.textContent = 'Load error: ' + err.message;
                errDiv.classList.remove('d-none');
            });
    }
    Promise.all(_selectPromises).then(function () { _loadForm(); });

    /* ---- dirty tracking ---- */
    registerDirtyForm({
        isDirty: function () {
            return config.fields.some(function (fld) {
                const el = document.getElementById('bfdb-field-' + fld.name);
                if (!el) return false;
                return el.value !== String(_originalValues[fld.name] != null ? _originalValues[fld.name] : '');
            });
        }
    });

    /* ---- save ---- */
    form.addEventListener('submit', function (e) {
        e.preventDefault();
        errDiv.classList.add('d-none');
        const payload = {};
        config.fields.forEach(function (fld) {
            const type = fld.type || 'text';
            if ((type === 'select' || type === 'multiselect') && _selectInstances[fld.name]) {
                const ts = _selectInstances[fld.name];
                if (type === 'multiselect') {
                    payload[fld.name] = ts.getValue().join(',');
                } else {
                    payload[fld.name] = ts.getValue();
                }
            } else {
                const el = document.getElementById('bfdb-field-' + fld.name);
                if (el) payload[fld.name] = el.value;
            }
        });
        // Merge fixed id params
        if (config.idParams) Object.assign(payload, config.idParams);
        submitChanges(config.submitUrl, [payload], function (stash) {
            if (config.afterSave) {
                config.afterSave(stash);
            } else {
                _loadForm();
                bfdbAlert('Saved', 'Record saved to database.');
            }
        });
    });

    /* ---- discard ---- */
    discardBtn.addEventListener('click', function () {
        config.fields.forEach(function (fld) {
            const type = fld.type || 'text';
            const val = _originalValues[fld.name];
            if ((type === 'select' || type === 'multiselect') && _selectInstances[fld.name]) {
                const ts = _selectInstances[fld.name];
                if (type === 'multiselect') {
                    const vals = val ? String(val).split(',').filter(Boolean) : [];
                    ts.setValue(vals, true);
                } else {
                    ts.setValue(val != null ? String(val) : '', true);
                }
            } else {
                const el = document.getElementById('bfdb-field-' + fld.name);
                if (!el) return;
                el.value = val != null ? val : '';
                if (el._flatpickr) el._flatpickr.setDate(val || null, false);
            }
        });
        errDiv.classList.add('d-none');
    });
}

