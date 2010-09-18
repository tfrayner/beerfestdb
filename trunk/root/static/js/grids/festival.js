/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var Festival = Ext.data.Record.create([
        { name: 'festival_id', type: 'int',    allowBlank: false },
        { name: 'year',        type: 'int' ,   allowBlank: false },
        { name: 'name',        type: 'string', allowBlank: false },
        { name: 'description', type: 'string' },
        { name: 'fst_start_date',  type: 'date', dateFormat: 'Y-m-d H:i:s' },
        { name: 'fst_end_date',    type: 'date', dateFormat: 'Y-m-d H:i:s' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        url_object_list,
        root:       'objects',
        fields:     Festival
    });

    var content_cols = [
        { id:         'year',
          header:     'Year',
          dataIndex:  'year',
          width:      30,
          // FIXME make this a drop-down or something.
          editor:     new Ext.form.NumberField({
              allowBlank:     false,
              allowDecimals:  false,
              maxLength:      4,
              minLength:      4,
          })},
        { id:         'name',
          header:     'Name',
          dataIndex:  'name',
          width:      150,
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
        { id:         'fst_start_date',
          header:     'Start date',
          dataIndex:  'fst_start_date',
          width:      100,
          // FIXME we probably want a custom renderer here and for end_date.
          editor:     new Ext.form.DateField({
              allowBlank:     true,
          })},
        { id:         'fst_end_date',
          header:     'End date',
          dataIndex:  'fst_end_date',
          width:      100,
          editor:     new Ext.form.DateField({
              allowBlank:     true,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/festival/view/{festival_id}');
        window.location=t.apply({festival_id: record.get('festival_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.festival_id = record.get( 'festival_id' );
        return(fields);
    }

    var panel = new Ext.Panel({
        title: 'Festival listing',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Festival',
                idField:            'festival_id',
                autoExpandColumn:   'name',
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

