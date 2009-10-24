/*
 * $Id$
 */

Ext.onReady(function(){

        function submitChanges( data ) {
            Ext.Ajax.request({
                    url:        posturl,
                    success:    function() { store.reload() },
                    params:     { changes: Ext.util.JSON.encode( data ) }
                });
        }

        var col_model = new Ext.grid.ColumnModel([
        {
            id:         'name',
            header:     'Name',
            dataIndex:  'name',
            width:      25,
            editor:     new Ext.form.TextField({
                    allowBlank:     false,
                })
        },
        {
            id:         'description',
            header:     'Description',
            dataIndex:  'description',
            width:      100,
            editor:     new Ext.form.TextField({
                    allowBlank:     true,
                })
        },
        {
            id:         'comment',
            header:     'Comment',
            dataIndex:  'comment',
            width:      100,
            editor:     new Ext.form.TextField({
                    allowBlank:     true,
                })
        }
                                                  ]); 
        
        col_model.defaultSortable = true;

        var Product = Ext.data.Record.create([
        { name: 'product_id',  type: 'int' },
        { name: 'name',        type: 'string' },
        { name: 'description', type: 'string' },
        { name: 'comment',     type: 'string' }
                                             ]);

        var store = new Ext.data.JsonStore({
                url:        gridurl,
                root:       'products',
                fields:     Product
            });

        var grid = new Ext.grid.EditorGridPanel({
                store:              store,
                cm:                 col_model,
                title:              'Edit Products',
                width:              800,
                height:             400,
                frame:              true,
                autoExpandColumn:   'name',
                renderTo:           'datagrid',
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
                    changes.push( fields );
                }
                //                console.log( changes );
                submitChanges( changes );
                store.commitChanges();
            },
        },
        {
            text:           'Discard Changes',
            handler:        function() {
                grid.stopEditing();
                store.rejectChanges();
            },
        }
                 ]
                
            });

        store.load();

    });

