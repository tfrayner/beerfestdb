/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var FestivalProduct = Ext.data.Record.create([
        { name: 'product_id',         type: 'int' },
        { name: 'company_id',         type: 'int' },
        { name: 'sale_price',         type: 'float' },
        { name: 'sale_volume_id',     type: 'int' },
        { name: 'sale_currency_code', type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     FestivalProduct
    });

    var supplier_store = new Ext.data.JsonStore({
        url:        url_supplier_list,
        root:       'objects',
        fields:     [{ name: 'company_id', type: 'int' },
                     { name: 'name',       type: 'string'}]
    });

    /* Force the store to load from the database */
    supplier_store.load();

    var product_store = new Ext.data.JsonStore({
        url:        url_product_list,
        root:       'objects',
        fields:     [{ name: 'product_id', type: 'int' },
                     { name: 'name',       type: 'string'}]
    });

    /* Force the store to load from the database */
    product_store.load();

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
    
    var volume_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        transform:      'volumepopup',
        lazyRender:     true,
        listClass:      'x-combo-list-small',
    });
    
    var currency_combo = new Ext.form.ComboBox({
        typeAhead:      true,
        triggerAction:  'all',
        transform:      'currencypopup',
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
          width:      130,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
        { id:         'currency_code',
          header:     'Currency',
          dataIndex:  'currency_code',
          width:      70,
          renderer:   MyComboRenderer(currency_combo),
          editor:     currency_combo },
        { id:         'sale_volume_id',
          header:     'Sale volume',
          dataIndex:  'sale_volume_id',
          width:      70,
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

