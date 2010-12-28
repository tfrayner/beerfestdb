/* 
 * $Id$
 */

// This function needs serious work FIXME.

Ext.onReady(function(){

    Ext.QuickTips.init();

    // turn on validation errors beside the field globally
    Ext.form.Field.prototype.msgTarget = 'side';

    var bd = Ext.getBody();

    /*
     * ================  Simple form  =======================
     */
    bd.createChild({tag: 'h2', html: 'Add a new stillage location'});

    var formObject;

    var saveHandler = function(button, event) {
        // FIXME handle failure as well. Note that while the form
        // currently submits and creates a new item in the DB, the
        // waitMsg and success params are being ignored.
        formObject.form.submit({
            success: function(form, action) {
                Ext.Msg.alert('Success', action.result.msg)
                window.location = url_festival_view
            },
            failure: function(res, opts) {
                var stash = Ext.util.JSON.decode(res.responseText);
                Ext.Msg.alert('Error', stash.error);
            },
        } );
    };

    formObject = new Ext.FormPanel({
        labelWidth: 100, // label settings here cascade unless overridden
        url:       url_object_submit,
        frame:     true,
        title:     'Stillage details',
        bodyStyle: 'padding:5px 5px 0',
        width:     350,
        defaults:  {width: 200},
        defaultType: 'textfield',

        items: [
            {
                fieldLabel: 'Stillage Name',
                name: 'description',
                allowBlank:false
            },{
                name:   'festival_id',
                value:  festival_id,
                hidden: true
            }
        ],

        buttons: [{
            text: 'Save',
            handler: saveHandler
        },{
            text: 'Cancel',
        }]
    });

    formObject.render(document.body);
});