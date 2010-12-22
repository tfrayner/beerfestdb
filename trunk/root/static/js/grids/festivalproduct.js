/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var FestivalProduct = Ext.data.Record.create([
        { name: 'festival_product_id', type: 'int' },
        { name: 'product_id',          type: 'int' },
        { name: 'company_id',          type: 'int' },
        { name: 'sale_price',          type: 'float' },
        { name: 'sale_volume_id',      type: 'int' },
        { name: 'sale_currency_id',    type: 'int' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     FestivalProduct
    });

    /* Supplier drop-down */
    var supplier_store = new Ext.data.JsonStore({
        url:        url_supplier_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}]
    });
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

    /* Product drop-down */
    var product_store = new Ext.data.JsonStore({
        url:        url_product_list,
        root:       'objects',
        fields:     [{ name: 'product_id', type: 'int' },
                     { name: 'name',       type: 'string'}]
    });
    product_store.load();
    /* FIXME needs work so that this reloads upon brewer selection */
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

    /* Sale volume drop-down */
    var volume_store = new Ext.data.JsonStore({
        url:        url_sale_volume_list,
        root:       'objects',
        fields:     [{ name: 'sale_volume_id', type: 'int' },
                     { name: 'description',    type: 'string'}]
    });
    volume_store.load();
    var volume_combo = new Ext.form.ComboBox({
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          volume_store,
        valueField:     'sale_volume_id',
        displayField:   'description',
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
        allowBlank:     false,
        typeAhead:      true,
        triggerAction:  'all',
        store:          currency_store,
        valueField:     'currency_id',
        displayField:   'currency_code',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var content_cols = [
        { id:         'company_id',
          header:     'Supplier',
          dataIndex:  'company_id',
          width:      130,
          renderer:   MyComboRenderer(brewer_combo),
          editor:     brewer_combo, },
        { id:         'product_id',
          header:     'Product',
          dataIndex:  'product_id',
          width:      130,
          renderer:   MyComboRenderer(product_combo),
          editor:     product_combo, },
        { id:         'sale_price',
          header:     'Sale price',
          dataIndex:  'sale_price',
          width:      40,
          editor:     new Ext.form.TextField({  // FIXME use currency format, reload on change.
              allowBlank:     true,
          })},
        { id:         'sale_currency_id',
          header:     'Currency',
          dataIndex:  'sale_currency_id',
          width:      40,
          renderer:   MyComboRenderer(currency_combo),
          editor:     currency_combo },
        { id:         'sale_volume_id',
          header:     'Sale volume',
          dataIndex:  'sale_volume_id',
          width:      40,
          renderer:   MyComboRenderer(volume_combo),
          editor:     volume_combo },
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/festivalproduct/view/{festival_product_id}');
        window.location=t.apply({festival_product_id: record.get('festival_product_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.festival_product_id = record.get( 'festival_product_id' );
        fields.festival_id = festival_id;
        return(fields);
    }

    var panel = new Ext.Panel({
        title: festivalname + ' product listing: ' + categoryname,
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'FestivalProduct',
                idField:            'festival_product_id',
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
            { text: 'Festival', handler: function() { window.location = url_festival_view; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

