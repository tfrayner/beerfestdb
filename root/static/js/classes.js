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
                    Ext.Msg.show({
                        title:    'Delete',
                        msg:      'Really delete the selected rows?',
                        buttons:  Ext.Msg.YESNO,
                        icon:     Ext.MessageBox.QUESTION,
                        fn:       function(btn, text){
                            if (btn == 'yes'){
                                var changes = new Array();
                                var dirty   = this.sm.getSelections();
                                for ( var i = 0 ; i < dirty.length ; i++ ) {
                                    var id = dirty[i].get( this.idField );
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

    columnLines:        true,
    stripeRows:         true,
    trackMouseOver:     true,
    loadMask:           true, // seems not to work in extjs 3.4
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
        
        Ext.apply(this, {
            cm:                 col_model,
            sm:                 sm,
            plugins:            action,
            tbar:
            [
                new NewButton({text:   'New ' + this.objLabel,
                               grid:   this}),
                new SaveButton({
                    grid:          this,
                    recordChanges: this.recordChanges,
                }),
                new DiscardButton({grid:this}),
                new RemoveButton({text:         'Remove ' + this.objLabel + 's',
                                  grid:         this,
                                  sm:           sm,
                                  ref:          '../removeButton',
                                  idField:      this.idField,
                                  deleteUrl:    this.deleteUrl}),
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
            
    initComponent: function() {

        // turn on validation errors beside form fields globally
        Ext.form.Field.prototype.msgTarget = 'side';

        Ext.apply(this, {
            buttons: [{
                text:    'Save Changes',
                tooltip: 'Write changes to the database',
                iconCls: 'icon-save-table',
                handler: function(b, e) {
                    var fields = this.getForm().getFieldValues({ dirtyOnly: true });
                    for ( var key in this.idParams ) {
                        fields[key] = this.idParams[key];
                    }
                    submitChanges( [ fields ], this.url );
                    this.getForm().setValues({ values: fields }); // doesn't currently work.
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

MyComboBox = Ext.extend(Ext.form.ComboBox, {
    noSelection:null,
	
    initComponent : function(){
		
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
    }
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
    targetUrl:   "/",  // A reasonable but not universally-applicable default.
    
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

