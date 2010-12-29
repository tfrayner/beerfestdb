/*
 * This file is part of BeerFestDB, a beer festival product management
 * system.
 * 
 * Copyright (C) 2010 Tim F. Rayner
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
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