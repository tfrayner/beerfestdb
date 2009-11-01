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
                              changes.push( this.getFields(dirty[i]) );
                          }
                          submitChanges( changes, posturl, this.grid.store );
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
                                    var id = dirty[i].get( this.idfield );
                                    changes.push( id );
                                }
                                deleteProducts( changes,
                                                this.deleteurl,
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

    autoExpandColumn:   'name',
    renderTo:           'datagrid',
    columnLines:        true,

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
                tooltip:'View details',
            }],
        });

        action.on({
            action: this.viewLink,
        });

        var col_model = new Ext.grid.ColumnModel({
            defaults: {
                sortable: true
            },
            columns: [].concat(sm, this.content_cols, action),
        }); 
        
        Ext.apply(this, {
            cm:                 col_model,
            sm:                 sm,
            plugins:            action,
            tbar:
            [
                new NewButton({text:   'New Product',
                               grid:   this}),
                new SaveButton({
                    grid:      this,
                    getFields: function(record) {
                        var fields = record.getChanges();
                        fields.product_id = record.get( 'product_id' );
                        fields.product_category_id = category_id;
                        return(fields);
                    },
                }),
                new DiscardButton({grid:this}),
                new RemoveButton({text:         'Remove Products',
                                  grid:         this,
                                  sm:           sm,
                                  ref:          '../removeButton',
                                  idfield:      'product_id',
                                  deleteurl:    deleteurl}),
            ]
            
        });
        MyEditorGrid.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        this.store.load();
        MyEditorGrid.superclass.onRender.apply(this, arguments);
    }
});

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var Product = Ext.data.Record.create([
        { name: 'product_id',       type: 'int' },
        { name: 'name',             type: 'string',   allowBlank: false },
        { name: 'description',      type: 'string' },
        { name: 'comment',          type: 'string' },
        { name: 'product_style_id', type: 'int' }
    ]);

    var store = new Ext.data.JsonStore({
        url:        gridurl,
        root:       'objects',
        fields:     Product
    });

    var style_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        transform:      'stylepopup',
        lazyRender:     true,
        listClass:      'x-combo-list-small'
    });
    
    var content_cols = [
        { id:         'name',
          header:     'Name',
          dataIndex:  'name',
          width:      25,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
        { id:         'description',
          header:     'Description',
          dataIndex:  'description',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'product_style_id',
          header:     'Style',
          dataIndex:  'product_style_id',
          width:      100,
          renderer:   function(value) {  // render the option text, not the value.
              var r = style_combo.store.getById(value); 
              return r ? r.get('text') : '<unknown>';
          },
          editor:     style_combo },
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/product/view/{product_id}');
        window.location=t.apply({product_id: record.get('product_id')});
    };

    var panel = new Ext.Panel({
        title: festivalname + ' product listing: ' + categoryname,
        layout: 'fit',
        items: new MyEditorGrid({store:        store,
                                 content_cols: content_cols,
                                 viewLink:     viewLink,}),
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festival', handler: function() { window.location = festivalurl; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });
    
    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

