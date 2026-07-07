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
 *
 * $Id$
 */

function submitChanges( data, url, store ) {
    Ext.Ajax.request({
        url:        url,
        success:    function() {
            if ( store ) {
                store.reload();
            }
            else {
                Ext.Msg.alert('Success', 'Record saved to database');
            }
        },
        failure:    function(res, opts) {
            var stash = Ext.util.JSON.decode(res.responseText);
            Ext.Msg.alert('Error', stash.error);
        },
        params:     { changes: Ext.util.JSON.encode( data ) }
    });
}

function deleteProducts( data, url, store ) {
    var error = Ext.Ajax.request({
        url:        url,
        success:    function() { store.reload() },
        failure:    function(res, opts) {
            var stash = Ext.util.JSON.decode(res.responseText);
            Ext.Msg.alert('Error', stash.error);
        },
        params:     { changes: Ext.util.JSON.encode( data ) }
    });
}

/* Very simple object cloning function; only works one level deep! */
function simpleClone(obj) {
    if (null == obj || "object" != typeof obj) return obj;
    var copy = obj.constructor();
    for (var attr in obj) {
        if (obj.hasOwnProperty(attr)) copy[attr] = obj[attr];
    }
    return copy;
}

/* Quick lookup function used to create sortType attributes on
 * fields. Required for sorting grid comboboxes by display, rather
 * than key value */
function myMakeSortTypeFun(store, value) {
    return function(id) {
        var ix = store.findExact(store.idProperty, id);
        if ( ix >= 0 ) { // handle blank (optional) fields.
            return store.getAt(ix).get(value);
        }
        else {
            return ''; // assumes our desired sort field is always a string.
        }
    }
}

NewButton = Ext.extend(Ext.Button, {

    text:    'New Row',
    tooltip: 'Add a new row to the table',
    iconCls: 'icon-plus',

    initComponent: function() {
        Ext.apply(this,
                  {               
                      handler: function() {
                          var d = simpleClone(this.grid.store.defaultData);
                          var p = new this.grid.store.recordType(d);
                          this.grid.stopEditing();
                          this.grid.store.insert( 0, p );
                          this.grid.startEditing( 0, 1 );

                          /* This is important for adding records
                          where there are linked ComboBoxes, where we
                          are using the SelectionModel to detect which
                          row we're on. */
                          this.grid.getSelectionModel().selectFirstRow();
                      },
                      scope: this,
                  }
                 );
        
        NewButton.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        NewButton.superclass.onRender.apply(this, arguments);
    },
});

function saveGridRecords(btn, event) {
    btn.grid.stopEditing();
    var changes = new Array();
    var dirty = btn.grid.store.getModifiedRecords();
    for ( var i = 0 ; i < dirty.length ; i++ ) {
        changes.push( btn.recordChanges(dirty[i]) );
    }
    submitChanges( changes, btn.grid.submitUrl, btn.grid.store );
    btn.grid.store.commitChanges();

    // Some ComboBox fields don't properly reload because of the
    // lastQuery mechanism we're using to filter on the fly. We
    // currently pass them in as grid.reloadableStore, and reload them
    // manually here. This seems rather kludgey FIXME.
    var reloadable = btn.grid.reloadableStores;
    if ( reloadable ) {
        for ( var n=0; n < reloadable.length; n++) {
            reloadable[n].clearFilter();
            reloadable[n].reload();
        }
    }
}

SaveButton = Ext.extend(Ext.Button, {
    
    text:     'Save Changes',
    tooltip:  'Write changes to the database',
    iconCls:  'icon-save-table',

    // We use listeners rather than a handler because it seems to be
    // simpler to replace listeners after the fact.
    initComponent: function() {
        Ext.apply(this,
                  {
                      listeners: {
                          click: saveGridRecords,
                      },
                  }
                 );

        SaveButton.superclass.initComponent.apply(this, arguments);
    },

    onRender: function() {
        SaveButton.superclass.onRender.apply(this, arguments);
    },
});

DiscardButton = Ext.extend(Ext.Button, {

    text:           'Discard Changes',
    tooltip:        'Restore the previously saved version',
    iconCls: 'icon-cancel',

    initComponent: function() {
        
        Ext.apply(this,
                  {
                      handler:        function() {
                          this.grid.stopEditing();
                          this.grid.store.rejectChanges();
                      },
                      scope: this,
                  }
                 );

        DiscardButton.superclass.initComponent.apply(this, arguments);
    },

    onRender: function() {
        DiscardButton.superclass.onRender.apply(this, arguments);
    },
});

RemoveButton = Ext.extend(Ext.Button, {

    text:           'Remove Rows',
    tooltip:        'Remove the selected item(s)',
    disabled:       true,
    iconCls:        'icon-minus',

    initComponent: function() {

        Ext.apply(
            this,
            {
                handler:        function() {
                    this.grid.stopEditing();
                    // Capture selections NOW, before the modal dialog causes
                    // the grid to lose focus and deselect rows (ExtJS 3 bug).
                    var dirty = this.sm.getSelections();
                    Ext.Msg.show({
                        title:    'Delete',
                        msg:      'Really delete the selected rows?',
                        buttons:  Ext.Msg.YESNO,
                        icon:     Ext.MessageBox.QUESTION,
                        fn:       function(btn, text){
                            if (btn == 'yes'){
                                var changes = new Array();
                                for ( var i = 0 ; i < dirty.length ; i++ ) {
                                    var id;
                                    if ( Ext.isArray(this.idField) ) {
                                        id = {};
                                        for ( var j = 0 ; j < this.idField.length ; j++ ) {
                                            id[ this.idField[j] ] = dirty[i].get( this.idField[j] );
                                        }
                                    } else {
                                        id = dirty[i].get( this.idField );
                                    }
                                    changes.push( id );
                                }
                                deleteProducts( changes,
                                                this.deleteUrl,
                                                this.grid.store );
                                this.grid.store.reload();
                            }
                        },
                        scope: this,
                    });
                },
                scope: this,
            }
        );
        
        RemoveButton.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        RemoveButton.superclass.onRender.apply(this, arguments);
    },
});


MyEditorGrid = Ext.extend(Ext.grid.EditorGridPanel, {

    changesOnly:        false,
    columnLines:        true,
    stripeRows:         true,
    trackMouseOver:     true,
    loadMask:           true, // seems not to work in extjs 3.4
    clicksToEdit:       1,    // single click activates cell editors (enables smooth tab navigation)
    comboStores:        [],
    viewConfig: new Ext.grid.GridView({
        autoFill: true,
        forceFit: true,
        getRowClass: function (record, index) {
            if (index === 0) { return 'half-grey' }
        },
    }),

    frame:true,
    initComponent: function() {

        var sm = new Ext.grid.CheckboxSelectionModel({
            listeners: {
                // On selection change, set enabled state of the removeButton
                // which was placed into the GridPanel using the ref config
                selectionchange: function(sm) {
                    if (this.changesOnly) { return; }
                    if (sm.getCount()) {
                        this.removeButton.enable();
                    } else {
                        this.removeButton.disable();
                    }
                },
                scope: this,
            }
        });
        
        var action = new Ext.ux.grid.RowActions({
            header:'',
            keepSelection:true,
            actions:[{
                iconCls:'icon-open',
                tooltip:'View ' + this.objLabel + ' details',
            }],
        });

        action.on({
            action: this.viewLink,
        });

        var col_model = new Ext.grid.ColumnModel({
            defaults: {
                sortable: true
            },
            columns: [].concat(sm, action, this.contentCols),
        });

        // Wrap renderers for required columns: dynamically add bfd-required-cell
        // to the <td> CSS class when the cell value is empty, so that unfilled
        // required cells are highlighted even in the non-editing display state.
        Ext.each(col_model.config, function(col) {
            if (!col.editor || col.editor.allowBlank !== false) { return; }
            var origRenderer = col.renderer;
            col.renderer = function(value, meta, record, rowIndex, colIndex, store) {
                var html = origRenderer
                    ? origRenderer.apply(this, arguments)
                    : (value !== null && value !== undefined ? String(value) : '');
                if (value === null || value === undefined || String(value) === '') {
                    meta.css = (meta.css ? meta.css + ' ' : '') + 'bfd-required-cell';
                }
                return html;
            };
        });

        Ext.apply(this, {
            cm:                 col_model,
            sm:                 sm,
            plugins:            action,
            tbar:
            [
                // Some grids don't support addition/deletion of rows, so we don't always
                // activate those buttons in the toolbar.
                new NewButton({text:     'New ' + this.objLabel,
                               grid:    this,
                               disabled: !!this.changesOnly,
                }),
                new SaveButton({
                    grid:          this,
                    recordChanges: this.recordChanges,
//                    disabled:      !!this.changesOnly,
                }),
                new DiscardButton({grid:     this,
//                                   disabled: !!this.changesOnly,
                }),
                new RemoveButton({text:         'Remove ' + this.objLabel + 's',
                                  grid:         this,
                                  sm:           sm,
                                  ref:          '../removeButton',
                                  idField:      this.idField,
                                  deleteUrl:    this.deleteUrl,
                                  disabled:     true,
                }),
            ],
            listeners: {
                beforerender: function(myGrid) {
                    myGrid.suspendEvents(true);
                    var myMask = new Ext.LoadMask(Ext.getBody());
                    myMask.show();
                    var allStores = myGrid.comboStores;
                    var numStores = allStores.length;
                    if ( numStores == 0 ) {
			myGrid.store.load({
                            callback: function (r, options, success) {
                                if (success === true) {
                                    myMask.hide();
                                    myGrid.resumeEvents();
                                }
                            }
                        });
                    }
                    else {
                        var loadedStores = 0;
                        Ext.each(allStores,
                                 function (storeCur, index, storearray) {
                            storeCur.load({
                                // defined in store config (unofficial).
                                params:    this.myLoadParams,
                                callback: function (r, options, success) {
                                    if (success === true) {
                                       loadedStores = loadedStores + 1;
                                        if (loadedStores == numStores) {
					    myGrid.store.load();
                                            myMask.hide();
                                            myGrid.resumeEvents();
                                        }
                                    }
                                }
                           });
                       });
                    }
                },
             }
        });

        MyEditorGrid.superclass.initComponent.apply(this, arguments);
    },

    // Intercept Tab at document capture phase so Firefox cannot move browser
    // focus away, then delegate to the selection model's onEditorKey — exactly
    // mirroring what the editor's 'specialkey' listener does internally.
    afterRender: function() {
        MyEditorGrid.superclass.afterRender.apply(this, arguments);
        var grid = this;
        document.addEventListener('keydown', function(e) {
            if (e.key !== 'Tab' && e.keyCode !== 9) { return; }
            if (!grid.activeEditor) { return; }
            // Prevent Firefox from moving browser focus away from the editor.
            e.preventDefault();
            // Stop propagation so the Tab keydown does not also reach the
            // editor field's own 'specialkey' listener, which would fire
            // onEditorKey a second time on the newly opened editor.
            e.stopPropagation();
            var extEvt = Ext.EventObject.setEvent(e);
            grid.getSelectionModel().onEditorKey(grid.activeEditor.field, extEvt);
        }, true /* useCapture */);
    },

    onRender: function() {
        MyEditorGrid.superclass.onRender.apply(this, arguments);
    },
});

MyViewGrid = Ext.extend(Ext.grid.GridPanel, {

    columnLines:        true,
    stripeRows:         true,
    trackMouseOver:     true,
    loadMask:           true, // seems not to work in extjs 3.4
    viewConfig: new Ext.grid.GridView({
        autoFill: true,
        forceFit: true,
        getRowClass: function (record, index) {
            if (index === 0) { return 'half-grey' }
        },
    }),

    frame:true,
    initComponent: function() {

        var action = new Ext.ux.grid.RowActions({
            header:'',
            keepSelection:true,
            actions:[{
                iconCls:'icon-open',
                tooltip:'View ' + this.objLabel,
            }],
        });

        action.on({
            action: this.viewLink,
        });

        var col_model = new Ext.grid.ColumnModel({
            defaults: {
                sortable: true
            },
            columns: [].concat(action, this.columns),
        }); 
        
        Ext.apply(this, {
            cm:                 col_model,
            plugins:            action,
            listeners: {
                beforerender: function(myGrid) {
                    myGrid.suspendEvents(true);
                    var myMask = new Ext.LoadMask(Ext.getBody());
                    myMask.show();
                    myGrid.store.load({
                        // defined in store config (unofficial).
                        params:    myGrid.myLoadParams,
                        callback: function (r, options, success) {
                            if (success === true) {
                                myMask.hide();
                                myGrid.resumeEvents();
                            }
                        }
                    });
                },
            },
        });
        MyViewGrid.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        MyViewGrid.superclass.onRender.apply(this, arguments);
    }
});

MyComboRenderer = function(combo){
    return function(value){
        var record = combo.findRecord(combo.valueField, value);
        return record ? record.get(combo.displayField) : '';
    }
}

MyCheckboxRenderer = function() {
    return function(value) { return value ? 'yes' : 'no' }
}

MyNumberRenderer = function() {
    return function(value) { return undefined != value ? value : '' }
}

MyFormPanel = Ext.extend(Ext.form.FormPanel, {

    labelAlign:  'right',
    labelWidth:  150,
    frame:       true,
    bodyStyle:   'padding:5px',
    width:       500,
    defaults:    {width: 300}, // field box width
    defaultType: 'textfield',
    comboStores: [],
    afterSave: null,
            
    initComponent: function() {

        // turn on validation errors beside form fields globally
        Ext.form.Field.prototype.msgTarget = 'side';

        Ext.apply(this, {
            buttons: [{
                text:    'Save Changes',
                tooltip: 'Write changes to the database',
                iconCls: 'icon-save-table',
                handler: function(b, e) {
                    var panel = this;
                    var doSave = function() {
                        var fields = panel.getForm().getFieldValues({ dirtyOnly: true });
                        for ( var key in panel.idParams ) {
                            fields[key] = panel.idParams[key];
                        }
                        var afterSaveFn = panel.afterSave || function() {
                            Ext.Msg.alert('Success', 'Record saved to database', function() {
                                panel.getForm().load({
                                    url:     panel.loadUrl,
                                    params:  panel.idParams,
                                    waitMsg: panel.waitMsg,
                                });
                            });
                        };
                        Ext.Ajax.request({
                            url:     panel.url,
                            success: afterSaveFn,
                            failure: function(res, opts) {
                                var stash = Ext.util.JSON.decode(res.responseText);
                                Ext.Msg.alert('Error', stash.error);
                            },
                            params: { changes: Ext.util.JSON.encode( [ fields ] ) }
                        });
                    };
                    if (panel.beforeSave) {
                        panel.beforeSave(doSave);
                    } else {
                        doSave();
                    }
                },
                scope: this,
            },{
                text:    'Discard Changes',
                tooltip: 'Restore the previously saved version',
                iconCls: 'icon-cancel',
                handler: function(b, e) {
                    this.getForm().reset();
                },
                scope: this,
            }],
            initialConfig: {
                trackResetOnLoad: true,
            },
            listeners: {
                beforerender: function(myForm) {
                    myForm.suspendEvents(true);
                    var myMask = new Ext.LoadMask(Ext.getBody());
                    myMask.show();
                    var numStores = myForm.comboStores.length;
                    if ( numStores == 0 ) {
			myForm.load({
			    url:     myForm.loadUrl,
			    params:  myForm.idParams,
			    waitMsg: myForm.waitMsg,
			});
                        myMask.hide();
                        myForm.resumeEvents();
                    }
                    else {
                        var loadedStores = 0;
                        Ext.each(myForm.comboStores,
                                 function (storeCur, index, storearray) {
                            storeCur.load({
                                // defined in store config (unofficial).
                                params:    myForm.myLoadParams,
                                callback: function (r, options, success) {
                                    if (success === true) {
                                        loadedStores = loadedStores + 1;
                                        if (loadedStores == numStores) {
					    myForm.load({
						url:     myForm.loadUrl,
						params:  myForm.idParams,
						waitMsg: myForm.waitMsg,
					    });
                                            myMask.hide();
                                            myForm.resumeEvents();
                                        }
                                    }
                                }
                            });
                        });
                    }
                },
            },
        });
        MyFormPanel.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        MyFormPanel.superclass.onRender.apply(this, arguments);
    }
});

emptySelect = '-- Select --';

/* A note on Combo box classes: ExtJS's ComboBox is really designed for remote-mode, 
 * where the store is expected to contain only the one record matching the current value.
 * In local-mode, it is really designed for use as a free-form typeahead field, where
 * the user types in a value and the store filters down to matching records. In practice 
 * this can yield rendering errors in grids after save+reload, because the store's 
 * lastQuery is still set to the old value, so the store.data contains only the one record
 * matching that value, and the combo's default findRecord method only looks in store.data,
 * not store.snapshot (the full unfiltered dataset). MyComboBox addresses this limitation.
 * 
 * The MyComboBox subclass also adds an optional blank selection at
 * the top of the list, for use in form fields where a selected value is optional.
 * 
 * Some combo boxes are managing many-to-many relationships; for these we use the LovCombo class.
 * 
 * We currently try to avoid standard Ext.form.ComboBox, but it could be used if
 * allowBlank=false and typeAhead=false and there are no other special requirements.
 */

MyComboBox = Ext.extend(Ext.form.ComboBox, {
    noSelection:null,
	
    initComponent : function(){
		
        /* ComboBox override which adds an optional blank selection at the top of the 
         * list. To be used for form fields where a selected value is optional (i.e.
         * nullable in database). Not triggered if noSelection is null.
         */
        if(this.noSelection && this.store){
            var data = {};
            data[this.valueField] = null; 
            data[this.displayField] = this.noSelection;
	    
            this.store.on('load',function(){
                if(!this.getById(0)){
                    this.addSorted(new Ext.data.Record(data,0));
                }
            });
            this.store.sort(this.displayField,'asc');
	    }
        MyComboBox.superclass.initComponent.apply(this, arguments);
    },

    /* ExtJS's local-mode doQuery calls store.filter(displayField, query) whenever
     * the user types into a combo (typeAhead).  That filter is never automatically
     * cleared when the combo closes, so store.data ends up containing only the one
     * record the user last typed/selected.  The default findRecord only searches
     * store.data; it therefore misses every other value, causing MyComboRenderer
     * to return '' for all unchanged rows after a save+reload.
     *
     * This overrides findRecord to fall back to store.snapshot (the full
     * unfiltered dataset) when the value is not found in the filtered store.data.
     */
    findRecord: function(prop, value) {
        var record;
        this.store.data.each(function(r) {
            if (r.data[prop] == value) { record = r; return false; }
        });
        if (!record && this.store.snapshot) {
            this.store.snapshot.each(function(r) {
                if (r.data[prop] == value) { record = r; return false; }
            });
        }
        return record || false;
    },
});

Ext.reg('mycombo', MyComboBox);

MyLoginPanel = Ext.extend(Ext.form.FormPanel, {

    labelAlign:  'right',
    labelWidth:  150,
    frame:       true,
    bodyStyle:   'padding:5px',
    width:       500,
    defaults:    {width: 300}, // field box width
    defaultType: 'textfield',
    targetUrl:   url_success_target || url_base, // default to server root if not set by controller.
    
    initComponent: function() {

        // turn on validation errors beside form fields globally
        Ext.form.Field.prototype.msgTarget = 'side';

        Ext.apply(this, {
            buttons: [{
                text:    'Log in',
                iconCls: 'icon-login',
                handler: function(b, e) {
                    var fields = this.getForm().getFieldValues();
                    Ext.Ajax.request({
                        url:        this.url,
                        success:    function() {
                            Ext.Msg.show({
                                title:'Success',
                                msg: 'Successfully logged in',
                                buttons: { ok: 'Okay' },
                                scope: this,
                                fn: function() {
                                    window.location.href = this.targetUrl;
                                }});
                        },
                        failure:    function(res, opts) {
                            var stash = Ext.util.JSON.decode(res.responseText);
                            Ext.Msg.alert('Error', stash.message);
                        },
                        params:     { data: Ext.util.JSON.encode( fields ) },
                        scope: this,
                    });
                },
                scope: this,
            }],
        });
        MyLoginPanel.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        MyLoginPanel.superclass.onRender.apply(this, arguments);
    }
});

MyMainPanel = Ext.extend(Ext.Panel, {

    logoutUrl:   url_base + "logout",
    rootUrl:     url_base,
    
    initComponent: function() {

        Ext.apply(this, {
            tools: [{
                id: 'logout',
                qtip: 'Log out from the database',
                handler: function(event, elem, panel, conf) {
                    Ext.Ajax.request({
                        url:        url_base + "/logout",
                        success:    function() {
                            Ext.Msg.show({
                                title:'Success',
                                msg: 'Successfully logged out.',
                                buttons: { ok: 'Okay' },
                                scope: this,
                                fn: function() {
                                    window.location.href = url_base;
                                }});
                        },
                        failure:    function(res, opts) {
                            var stash = Ext.util.JSON.decode(res.responseText);
                            Ext.Msg.alert('Error', stash.error);
                        },
                        scope: this,
                    });
                },
            }],
        });
        MyMainPanel.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        MyMainPanel.superclass.onRender.apply(this, arguments);
    }
});

// Attach the CSRF token to every Ext.Ajax request automatically.
// csrf_token is rendered into the page by the site/html template.
Ext.onReady(function() {
    Ext.Ajax.extraParams = { csrf_token: csrf_token };
});

// Required-field highlighting.
// Fields with allowBlank: false show a pale yellow background when empty and
// revert to the normal background once a value has been entered.  Covers both
// MyFormPanel form fields and MyEditorGrid cell editors (editing state).
// The non-editing display state is handled by the renderer wrapper in
// MyEditorGrid.initComponent above.
(function() {
    function updateRequired(field) {
        if (!field.el) { return; }
        var v = field.getValue();
        var isEmpty = (v === null || v === undefined || String(v) === '');
        field.el[isEmpty ? 'addClass' : 'removeClass']('bfd-required');
    }

    /* Override Ext.form.Field.prototype.afterRender once, here, to stamp
     * a CSS class on any field with allowBlank === false. This covers every form
     * field and grid cell editor in one place.
     */
    var origAfterRender = Ext.form.Field.prototype.afterRender;
    Ext.form.Field.prototype.afterRender = function() {
        origAfterRender.apply(this, arguments);
        if (this.allowBlank !== false) { return; }
        var field = this;
        updateRequired(field);
        // Update on user-driven change (blur for text fields, select for combos).
        field.on('change', function() { updateRequired(field); });
        // Patch setValue on this instance so that programmatic loads
        // (e.g. form.load()) also trigger a re-check.  Deferred 10 ms to allow
        // ComboBox to finish updating its internal this.value before getValue()
        // is called.
        var origSetValue = field.setValue;
        field.setValue = function(v) {
            origSetValue.apply(this, arguments);
            Ext.defer(function() { updateRequired(field); }, 10);
            return this;
        };
    };
}());

window.onbeforeunload = function() {
    var dirty = false;
    Ext.ComponentMgr.all.each(function(cmp) {
        if (cmp instanceof MyFormPanel && cmp.getForm().isDirty()) {
            dirty = true;
        } else if (cmp instanceof MyEditorGrid && cmp.store &&
                   cmp.store.getModifiedRecords().length > 0) {
            dirty = true;
        }
    });
    if (dirty) {
        return 'You have unsaved changes. Are you sure you want to leave this page?';
    }
};
