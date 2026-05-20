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

    const container = document.getElementById('datagrid');

    container.innerHTML =
        '<div class="row justify-content-center mt-5">' +
          '<div class="col-sm-8 col-md-5 col-lg-4">' +
            '<div class="card shadow-sm">' +
              '<div class="card-header bg-dark text-white">Please log in</div>' +
              '<div class="card-body">' +
                '<form id="login-form" novalidate>' +
                  '<div class="mb-3">' +
                    '<label for="login-username" class="form-label">Username</label>' +
                    '<input id="login-username" name="username" type="text"' +
                    '       class="form-control" autocomplete="username" required>' +
                  '</div>' +
                  '<div class="mb-3">' +
                    '<label for="login-password" class="form-label">Password</label>' +
                    '<input id="login-password" name="password" type="password"' +
                    '       class="form-control" autocomplete="current-password" required>' +
                  '</div>' +
                  '<div id="login-error" class="alert alert-danger d-none"></div>' +
                  '<button type="submit" class="btn btn-primary w-100">Log in</button>' +
                '</form>' +
              '</div>' +
            '</div>' +
          '</div>' +
        '</div>';

    document.getElementById('login-form').addEventListener('submit', function (e) {
        e.preventDefault();
        const form     = e.target;
        const errDiv   = document.getElementById('login-error');
        const username = form.username.value.trim();
        const password = form.password.value;

        if (!username || !password) {
            errDiv.textContent = 'Please enter both username and password.';
            errDiv.classList.remove('d-none');
            return;
        }
        errDiv.classList.add('d-none');

        bfdbPost(url_login_submit, { data: JSON.stringify({ username, password }) })
            .then(function () {
                window.location.href = (typeof url_success_target !== 'undefined' && url_success_target)
                    ? url_success_target
                    : url_base;
            })
            .catch(function (err) {
                errDiv.textContent = err.message || 'Login failed.';
                errDiv.classList.remove('d-none');
            });
    });
});

