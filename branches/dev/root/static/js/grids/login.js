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

Ext.onReady(function(){

    var login_form = new MyLoginPanel({
        url:         url_login_submit,
        targetUrl:   url_success_target,
        title:       'Login details',
        items: [
            { name:       'username',
              fieldLabel: 'Username',
              allowBlank: false, },
            { name:       'password',
              fieldLabel: 'Password',
              inputType:  'password',
              allowBlank: false, },
        ],
    });

    var panel = new Ext.Panel({
        title: 'BeerFestDB Login',
        items:  login_form,
    });
    
    var view = new Ext.Viewport({
        layout: 'fit',
        items:  panel,
    });
});

