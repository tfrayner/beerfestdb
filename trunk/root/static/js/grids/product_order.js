/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();

    var ProductOrder = Ext.data.Record.create([
        { name: 'product_order_id',       type: 'int' },
        { name: 'product_id',             type: 'int' },
        { name: 'distributor_id',         type: 'int' },
        { name: 'container_size_id',      type: 'int' },
        { name: 'currency_id',            type: 'int' },
        { name: 'price',                  type: 'int' },
        { name: 'is_final',               type: 'int' },
        { name: 'comment',                type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     ProductOrder
    });

    /* Product drop-down */
    var product_store = new Ext.data.JsonStore({
        url:        url_product_list,
        root:       'objects',
        fields:     [{ name: 'product_id', type: 'int'    },
                     { name: 'name',       type: 'string' }]

    });
    product_store.load();
    var product_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          product_store,
        valueField:     'product_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    /* Distributor drop-down */
    var distributor_store = new Ext.data.JsonStore({
        url:        url_distrib_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int'    },
                     { name: 'name',       type: 'string' }]

    });
    distributor_store.load();
    var distributor_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          distributor_store,
        valueField:     'company_id',
        displayField:   'name',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    /* Currency drop-down */
    var currency_store = new Ext.data.JsonStore({
        url:        url_currency_list,
        root:       'objects',
        fields:     [{ name: 'currency_id',   type: 'int'    },
                     { name: 'currency_code', type: 'string' }]

    });
    currency_store.load();
    var currency_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          currency_store,
        valueField:     'currency_id',
        displayField:   'currency_code',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    /* Cask size drop-down */
    var cask_size_store = new Ext.data.JsonStore({
        url:        url_cask_size_list,
        root:       'objects',
        fields:     [{ name: 'container_size_id', type: 'int'    },
                     { name: 'description',       type: 'string' }]

    });
    cask_size_store.load();
    var cask_size_combo = new Ext.form.ComboBox({
        forceSelection: true,
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          cask_size_store,
        valueField:     'container_size_id',
        displayField:   'description',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var content_cols = [
        { id:         'distributor_id',
          header:     'Distributor',
          dataIndex:  'distributor_id',
          width:      130,
          renderer:   MyComboRenderer(distributor_combo),
          editor:     distributor_combo, },
        /* FIXME we need some way to select brewer, then beer. */
            
        { id:         'product_id',
          header:     'Product',
          dataIndex:  'product_id',
          width:      130,
          renderer:   MyComboRenderer(product_combo),
          editor:     product_combo, },
        { id:         'container_size_id',
          header:     'Cask Size',
          dataIndex:  'container_size_id',
          width:      40,
          renderer:   MyComboRenderer(cask_size_combo),
          editor:     cask_size_combo, },
        { id:         'price',
          header:     'Price',
          dataIndex:  'price',
          width:      40,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'currency_id',
          header:     'Currency',
          dataIndex:  'currency_id',
          width:      40,
          renderer:   MyComboRenderer(currency_combo),
          editor:     currency_combo, },
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     true,
          })},
        { id:         'is_final',
          header:     'Finalised',
          dataIndex:  'is_final',
          width:      50,
          editor:     new Ext.form.Checkbox({
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/productorder/view/{product_order_id}');
        window.location=t.apply({product_order_id: record.get('product_order_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.product_order_id = record.get( 'product_order_id' );
        return(fields);
    }

    var panel = new Ext.Panel({
        title: festivalname + ' product listing: ' + categoryname,
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'ProductOrder',
                idField:            'product_order_id',
                autoExpandColumn:   'product_id',
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
//            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

