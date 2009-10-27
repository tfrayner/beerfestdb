/*
 * $Id$
 */

Ext.onReady(function(){

        // Enable tooltips
        Ext.QuickTips.init();

        function submitChanges( data ) {
            Ext.Ajax.request({
                    url:        posturl,
                    success:    function() { store.reload() },
                    params:     { changes: Ext.util.JSON.encode( data ) }
                });
        }

        function deleteProducts( data ) {
            Ext.Ajax.request({
                    url:        deleteurl,
                    success:    function() { store.reload() },
                    params:     { changes: Ext.util.JSON.encode( data ) }
                });
        }

        var sm = new Ext.grid.CheckboxSelectionModel({
                listeners: {
                    // On selection change, set enabled state of the removeButton
                    // which was placed into the GridPanel using the ref config
                    selectionchange: function(sm) {
                        if (sm.getCount()) {
                            grid.removeButton.enable();
                        } else {
                            grid.removeButton.disable();
                        }
                    }
                }
            });

        action = new Ext.ux.grid.RowActions({
                header:'',
                keepSelection:true,
                actions:[{
                        iconCls:'icon-open',
                        tooltip:'Open',
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
          width:      100,
          editor:     new Ext.form.TextField({
                  allowBlank:     true,
              })},
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      100,
          editor:     new Ext.form.TextField({
                  allowBlank:     true,
              })},
        { id:         'product_style_id',
          header:     'Style',
          dataIndex:  'product_style_id',
          width:      70,
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
        { name: 'name',             type: 'string' },
        { name: 'description',      type: 'string' },
        { name: 'comment',          type: 'string' },
        { name: 'product_style_id', type: 'int' }
                                             ]);

        var store = new Ext.data.JsonStore({
                url:        gridurl,
                root:       'objects',
                fields:     Product
            });

        // FIXME make the width/height a proportion of the available view area.
        var grid = new Ext.grid.EditorGridPanel({
                store:              store,
                cm:                 col_model,
                sm:                 sm,
                title:              'Edit Products',
                width:              1000,
                height:             500,
                frame:              true,
                autoExpandColumn:   'name',
                plugins:            action,
                renderTo:           'datagrid',
                columnLines:        true,
                tbar:
                [
        {               
            text:           'New Product',
            handler:        function() {
                var p = new Product({
                        name:           'Unnamed New Product',
                        description:    'Unknown',
                    }); 
                grid.stopEditing();
                store.insert( 0, p );
                grid.startEditing( 0, 1 );
            },
            iconCls: 'icon-plus',
        },
        {
            text:           'Save Changes',
            handler:        function() {
                grid.stopEditing();
                var changes = new Array();
                var dirty = store.getModifiedRecords();
                for ( var i = 0 ; i < dirty.length ; i++ ) {
                    var id = dirty[i].get( 'product_id' );
                    var fields = dirty[i].getChanges();
                    fields.product_id = dirty[i].get( 'product_id' );
                    fields.product_category_id = category_id;
                    changes.push( fields );
                }
                submitChanges( changes );
                store.commitChanges();
            },
            iconCls: 'icon-save-table',
        },
        {
            text:           'Discard Changes',
            handler:        function() {
                grid.stopEditing();
                store.rejectChanges();
            },
            iconCls: 'icon-cancel',
        },
        {
            text:           'Remove Products',
            tooltip:        'Remove the selected item(s)',
            ref:            '../removeButton',
            disabled:       true,
            handler:        function() {
                grid.stopEditing();
                Ext.Msg.confirm('Name', 'Really delete the selected rows?',
                                function(btn, text){
                                    if (btn == 'yes'){
                                        var changes = new Array();
                                        var dirty = sm.getSelections();
                                        for ( var i = 0 ; i < dirty.length ; i++ ) {
                                            var id = dirty[i].get( 'product_id' );
                                            changes.push( id );
                                        }
                                        deleteProducts( changes );
                                    }
                                });
            },
            iconCls: 'icon-minus',
        }
                 ]

            });

        store.load();

    });

