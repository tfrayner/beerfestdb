/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    /* Category listing */
    var category_store = new Ext.data.JsonStore({
        url:        url_category_list,
        root:       'objects',
        fields:     [{ name: 'product_category_id',   type: 'int'    },
                     { name: 'description',           type: 'string' }]
    });
    category_store.load();

    /* Stillage listing */
    var stillage_store = new Ext.data.JsonStore({
        url:        url_stillage_list,
        root:       'objects',
        fields:     [{ name: 'stillage_location_id',  type: 'int'    },
                     { name: 'description',           type: 'string' }]
    });
    stillage_store.load();
    
    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/productorder/grid/{festival_id}/{product_category_id}');
        window.location=t.apply({
                product_category_id: record.get('product_category_id'),
                festival_id: festival_id,
            });
    };

    var orderGrid = new MyViewGrid(
        {
            store:              category_store,
            columns: [
                { id:        'description',
                  header:    'Product Category',
                  dataIndex: 'description' },
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/productorder/grid/{festival_id}/{product_category_id}');
                window.location=t.apply({
                        product_category_id: record.get('product_category_id'),
                        festival_id: festival_id,
                    })
            },
            objLabel: 'orders in this product category',
        }
    );

    var receivedGrid = new MyViewGrid(
        {
            store:              category_store,
            columns: [
                { id:        'description',
                  header:    'Product Category',
                  dataIndex: 'description' },
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/festivalproduct/grid/{festival_id}/{product_category_id}');
                window.location=t.apply({
                        product_category_id: record.get('product_category_id'),
                        festival_id: festival_id,
                    })
            },
            objLabel: 'festival products in this category',
        }
    );

    var caskGrid = new MyViewGrid(
        {
            store:              category_store,
            columns: [
                { id:        'description',
                  header:    'Product Category',
                  dataIndex: 'description' },
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/cask/grid/{festival_id}/{product_category_id}');
                window.location=t.apply({
                        product_category_id: record.get('product_category_id'),
                        festival_id: festival_id,
                    })
            },
            objLabel: 'casks in this product category',
        }
    );

    var stillageGrid = new MyEditorGrid(
        {
            objLabel:           'Stillage Location',
            idField:            'stillage_location_id',
            autoExpandColumn:   'description',
            deleteUrl:          url_stillage_delete,
            submitUrl:          url_stillage_submit,
            recordChanges:      function (record) {
                var fields = record.getChanges();
                fields.stillage_location_id = record.get( 'stillage_location_id' );
                fields.festival_id = festival_id;
                return(fields);
            },
            store:              stillage_store,
            contentCols: [
                { id:        'description',
                  header:    'Stillage Name',
                  dataIndex: 'description',
                  editor:     new Ext.form.TextField({
                      allowBlank: false,
                  })},
            ],
            viewLink: function (grid, record, action, row, col) {
                var t = new Ext.XTemplate('/stillagelocation/grid/{stillage_location_id}');
                window.location=t.apply({
                    stillage_location_id: record.get('stillage_location_id'),
                })
            },
        }
    );

    var tabpanel = new Ext.TabPanel({
        activeTab: 0,
        items: [
            { title: 'Products Ordered',
              layout: 'fit',
              items:  orderGrid, },
            { title: 'Products Received',
              layout: 'fit',
              items:  receivedGrid, },
            { title: 'All Casks Received',
              layout: 'fit',
              items:  caskGrid, },
            { title: 'Casks by Stillage',
              layout: 'fit',
              items:  stillageGrid, },
        ],
    });

    var panel = new Ext.Panel({
        title: festivalname,            
        layout: 'fit',
        items: tabpanel,
        tbar:
        [
            { text: 'Home', handler: function() { window.location = '/'; } },
            { text: 'Festivals', handler: function() { window.location = url_festival_grid; } },
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

