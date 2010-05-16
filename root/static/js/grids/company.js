/*
 * $Id$
 */

Ext.onReady(function(){

    // Enable tooltips
    Ext.QuickTips.init();
    
    var Company = Ext.data.Record.create([
        { name: 'company_id',       type: 'int' },
        { name: 'name',             type: 'string',        allowBlank: false },
        { name: 'loc_desc',         type: 'string' },
        { name: 'year_founded',     type: 'int' },
        { name: 'url',              type: 'string' },
        { name: 'comment',          type: 'string' },
    ]);

    var store = new Ext.data.JsonStore({
        url:        gridurl,
        root:       'objects',
        fields:     Company
    });

    var content_cols = [
        { id:         'name',
          header:     'Name',
          dataIndex:  'name',
          width:      150,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
        { id:         'loc_desc',
          header:     'Location',
          dataIndex:  'loc_desc',
          width:      150,
          editor:     new Ext.form.TextField({
//              allowBlank:     false,
          })},
        { id:         'year_founded',
          header:     'Year founded',
          dataIndex:  'year_founded',
          width:      5,
          editor:     new Ext.form.TextField({
//              allowBlank:     false,
          })},
        { id:         'url',
          header:     'Web site',
          dataIndex:  'url',
          width:      150,
          editor:     new Ext.form.TextField({
//              allowBlank:     false,
          })},
        { id:         'comment',
          header:     'Comment',
          dataIndex:  'comment',
          width:      300,
          editor:     new Ext.form.TextField({
              allowBlank:     false,
          })},
    ];

    function viewLink (grid, record, action, row, col) {
        var t = new Ext.XTemplate('/company/view/{company_id}');
        window.location=t.apply({company_id: record.get('company_id')});
    };

    function recordChanges (record) {
        var fields = record.getChanges();
        fields.company_id = record.get( 'company_id' );
        return(fields);
    }

    var panel = new Ext.Panel({
        title:  'Company listing',
        layout: 'fit',
        items: new MyEditorGrid(
            {
                objLabel:           'Company',
                idField:            'company_id',
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
        ],
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });

    //  FIXME we also need to warn the user if they're trying to
    //  navigate away from a dirty grid.
    
});

