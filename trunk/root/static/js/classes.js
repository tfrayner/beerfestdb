/*
 * $Id$
 */

function submitChanges( data, url, store ) {
    Ext.Ajax.request({
        url:        url,
        success:    function() { store.reload() },
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

NewButton = Ext.extend(Ext.Button, {

    text:    'New Row',
    tooltip: 'Add a new row to the table',
    iconCls: 'icon-plus',

    initComponent: function() {
        Ext.apply(this,
                  {               
                      handler: function() {
                          var p = new this.grid.store.recordType();
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

SaveButton = Ext.extend(Ext.Button, {
    
    text:     'Save Changes',
    tooltip:  'Write changes to the database',
    iconCls:  'icon-save-table',

    initComponent: function() {
        Ext.apply(this,
                  {
                      handler:  function() {
                          this.grid.stopEditing();
                          var changes = new Array();
                          var dirty = this.grid.store.getModifiedRecords();
                          for ( var i = 0 ; i < dirty.length ; i++ ) {
                              changes.push( this.recordChanges(dirty[i]) );
                          }
                          submitChanges( changes, url_object_submit, this.grid.store );
                          this.grid.store.commitChanges();
                      },
                      scope: this,
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
    loadMask:           true,
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
            ]
            
        });
        MyEditorGrid.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        this.store.load();
        MyEditorGrid.superclass.onRender.apply(this, arguments);
    }
});

MyComboRenderer = function(combo){
    return function(value){
        var record = combo.findRecord(combo.valueField, value);
        return record ? record.get(combo.displayField) : combo.valueNotFoundText;
    }
}

MyCheckboxRenderer = function() {
    return function(value) { return value ? 'yes' : 'no' }
}
