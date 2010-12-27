/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var ProductStyle = Ext.data.Record.create([
        { name: 'product_style_id',    type: 'int' },
        { name: 'product_category_id', type: 'int' },
        { name: 'description',         type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     ProductStyle
    });
    
    var content_cols = [
        { id:         'description',
          header:     'Description',
          dataIndex:  'description',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/productstyle/view/{product_style_id}');
        window.location=t.apply({product_style_id: record.get('product_style_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.product_style_id = record.get( 'product_style_id' );
        fields.product_category_id = category_id;
        return(fields);
    }

    var panel = new Ext.Panel({
        title: 'Product Style listing: ' + categoryname,
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'ProductStyle',
                idField:            'product_style_id',
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
            { text: 'Home',
              handler: function() { window.location = '/'; } },
            { text: 'Product Categories',
              handler: function() { window.location = url_category_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

