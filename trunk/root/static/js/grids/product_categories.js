/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var ProductCategory = Ext.data.Record.create([
        { name: 'product_category_id',  type: 'int' },
        { name: 'description',          type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     ProductCategory
    });
    
    var content_cols = [
        { id:         'description',
          header:     'Category Name',
          dataIndex:  'description',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/productcategory/grid/{product_category_id}');
        window.location=t.apply({product_category_id: record.get('product_category_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.product_category_id = record.get( 'product_category_id' );
        return(fields);
    }

    var panel = new Ext.Panel({
        title: 'All Product Categories',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'ProductCategory',
                idField:            'product_category_id',
                autoExpandColumn:   'description',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          url_object_delete,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

