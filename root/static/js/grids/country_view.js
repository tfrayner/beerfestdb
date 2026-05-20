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
    createViewForm({
        container:  '#datagrid',
        loadUrl:    url_country_load_form,
        submitUrl:  url_country_submit,
        idParams:   { country_id: country_id },
        fields: [
            { name: 'country_name',        label: 'Country Name' },
            { name: 'country_code_iso2',   label: 'ISO alpha-2', maxLength: 2 },
            { name: 'country_code_iso3',   label: 'ISO alpha-3', maxLength: 3 },
            { name: 'country_code_num3',   label: 'ISO numeric', maxLength: 3 },
            { name: 'country_id', label: '', type: 'hidden' },
        ],
    });
});
