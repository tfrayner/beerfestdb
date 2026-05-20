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
 */

document.addEventListener('DOMContentLoaded', function () {
    // Bootstrap tab panel
    const container = document.getElementById('datagrid');
    container.innerHTML =
        '<ul class="nav nav-tabs mb-0" id="user-tabs">' +
          '<li class="nav-item"><a class="nav-link active" href="#tab-users" data-bs-toggle="tab">Users</a></li>' +
          '<li class="nav-item"><a class="nav-link"        href="#tab-roles" data-bs-toggle="tab">Roles</a></li>' +
        '</ul>' +
        '<div class="tab-content flex-grow-1 d-flex flex-column">' +
          '<div class="tab-pane active flex-grow-1 d-flex flex-column" id="tab-users"  style="min-height:400px"></div>' +
          '<div class="tab-pane        flex-grow-1 d-flex flex-column" id="tab-roles"  style="min-height:400px"></div>' +
        '</div>';

    createEditorGrid({
        container:     '#tab-users',
        loadUrl:       url_object_list,
        submitUrl:     url_user_submit,
        deleteUrl:     url_user_delete,
        idField:       'user_id',
        objLabel:      'User',
        firstEditCol:  'username',
        viewLinkUrl:   function (row) { return url_base + 'user/view/' + row.user_id; },
        recordChanges: function (row) {
            return { user_id: row.user_id, username: row.username, name: row.name, email: row.email };
        },
        columns: [
            { field: 'username', headerName: 'Username',  cellEditor: 'agTextCellEditor', flex: 1 },
            { field: 'name',     headerName: 'Real Name', cellEditor: 'agTextCellEditor', flex: 1 },
            { field: 'email',    headerName: 'Email',     cellEditor: 'agTextCellEditor', flex: 1 },
        ],
    });

    createEditorGrid({
        container:     '#tab-roles',
        loadUrl:       url_role_list,
        submitUrl:     url_role_submit,
        deleteUrl:     url_role_delete,
        idField:       'role_id',
        objLabel:      'Role',
        firstEditCol:  'rolename',
        viewLinkUrl:   function (row) { return url_base + 'role/view/' + row.role_id; },
        recordChanges: function (row) { return { role_id: row.role_id, rolename: row.rolename }; },
        columns: [
            { field: 'rolename', headerName: 'Role Name', cellEditor: 'agTextCellEditor', flex: 1 },
        ],
    });
});
