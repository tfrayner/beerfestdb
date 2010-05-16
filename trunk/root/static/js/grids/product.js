/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var Product = Ext.data.Record.create([
        { name: 'product_id',       type: 'int' },
        { name: 'company_product_id', type: 'int' },
        { name: 'company_id',       type: 'int' },
        { name: 'name',             type: 'string',   allowBlank: false },
        { name: 'description',      type: 'string' },
        { name: 'comment',          type: 'string' },
        { name: 'product_style_id', type: 'int' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        gridurl,
        root:       'objects',
        fields:     Product
    });

    // N.B. this could be replaced by a two-field list in this case...
    var Company = Ext.data.Record.create([
        { name: 'company_id',       type: 'int' },
        { name: 'name',             type: 'string',  allowBlank: false },
        { name: 'loc_desc',         type: 'string' },
        { name: 'year_founded',     type: 'int' },
        { name: 'url',              type: 'string' },
        { name: 'comment',          type: 'string' },
    ]);

    var supplier_store = new Ext.data.JsonStore({
        url:        suppliergridurl,
        root:       'objects',
        fields:     Company
    });

    /* Force the store to load from the database */
    supplier_store.load();

    var brewer_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          supplier_store,
        valueField:     'company_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var style_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        transform:      'stylepopup',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var content_cols = [
        { id:         'company_id',
          header:     'Brewer',
          dataIndex:  'company_id',
          width:      130,
          renderer:   MyComboRenderer(brewer_combo),
          editor:     brewer_combo, },
        { id:         'name',
          header:     'Name',
          dataIndex:  'name',
          width:      130,
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
          width:      70,
          renderer:   MyComboRenderer(style_combo),
          editor:     style_combo },
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/product/view/{product_id}');
        window.location=t.apply({product_id: record.get('product_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.product_id = record.get( 'product_id' );
        fields.company_product_id = record.get( 'company_product_id' );
        fields.product_category_id = category_id;
        return(fields);
    }

    var panel = new Ext.Panel({
        title: festivalname + ' product listing: ' + categoryname,
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Product',
                idField:            'product_id',
                autoExpandColumn:   'name',
                store:              store,
                contentCols:        content_cols,
                viewLink:           viewLink,
                deleteUrl:          deleteurl,
                recordChanges:      recordChanges,
            }
        ),
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
//            { text: 'Festival', handler: function() { window.location = festivalurl; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

