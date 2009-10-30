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

    text: 'New Row',

    initComponent: function() {
        Ext.apply(this,
            {               
                tooltip: 'Add a new row to the table',
                handler: function() {
                    var p = new this.store.recordType();
                    this.grid.stopEditing();
                    this.store.insert( 0, p );
                    this.grid.startEditing( 0, 1 );
                },
                iconCls: 'icon-plus',
                scope: this,
            }
        );

        NewButton.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        NewButton.superclass.onRender.apply(this, arguments);
    },
});

ProductGrid = Ext.extend(Ext.grid.EditorGridPanel, {

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
                tooltip:'View product details',
            }],
        });

        action.on({
            action:function(grid, record, action, row, col) {
                var t = new Ext.XTemplate('/product/view/{product_id}');
                t.compile();
                window.location=t.apply({product_id: record.get('product_id')});
            },
        });

        var style_combo = new Ext.form.ComboBox({
            typeAhead:      true,
            triggerAction:  'all',
            transform:      'stylepopup',
            lazyRender:     true,
            listClass:      'x-combo-list-small'
        });
        
        var col_model = new Ext.grid.ColumnModel({
            defaults: {
                sortable: true
            },
            columns: [
                sm,
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
                action,
            ],
        }); 
        
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

        Ext.apply(this, {
            store:              store,
            cm:                 col_model,
            sm:                 sm,
            plugins:            action,
            tbar:
            [
                new NewButton({text:   'New Product',
                               grid:   this,
                               store:  store}),
                {
                    text:           'Save Changes',
                    tooltip:        'Write changes to the database',
                    handler:        function() {
                        this.stopEditing();
                        var changes = new Array();
                        var dirty = store.getModifiedRecords();
                        for ( var i = 0 ; i < dirty.length ; i++ ) {
                            var id = dirty[i].get( 'product_id' );
                            var fields = dirty[i].getChanges();
                            fields.product_id = dirty[i].get( 'product_id' );
                            fields.product_category_id = category_id;
                            changes.push( fields );
                        }
                        submitChanges( changes, posturl, store );
                        store.commitChanges();
                    },
                    iconCls: 'icon-save-table',
                    scope: this,
                },
                {
                    text:           'Discard Changes',
                    tooltip:        'Restore the previously saved version',
                    handler:        function() {
                        this.stopEditing();
                        store.rejectChanges();
                    },
                    iconCls: 'icon-cancel',
                    scope: this,
                },
                {
                    text:           'Remove Products',
                    tooltip:        'Remove the selected item(s)',
                    ref:            '../removeButton',
                    disabled:       true,
                    handler:        function() {
                        this.stopEditing();
                        Ext.Msg.confirm('Name', 'Really delete the selected rows?',
                                        function(btn, text){
                                            if (btn == 'yes'){
                                                var changes = new Array();
                                                var dirty = sm.getSelections();
                                                for ( var i = 0 ; i < dirty.length ; i++ ) {
                                                    var id = dirty[i].get( 'product_id' );
                                                    changes.push( id );
                                                }
                                                deleteProducts( changes, deleteurl, store );
                                                store.reload();
                                            }
                                        });
                    },
                    iconCls: 'icon-minus',
                    scope: this,
                }
            ]
            
        });
        ProductGrid.superclass.initComponent.apply(this, arguments);
    },
    
    onRender: function() {
        this.store.load();
        ProductGrid.superclass.onRender.apply(this, arguments);
    }
});

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var panel = new Ext.Panel({
        title: festivalname + ' product listing: ' + categoryname,
        layout: 'fit',
        items: new ProductGrid(),
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

