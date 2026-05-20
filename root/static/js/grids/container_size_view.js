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
        loadUrl:    url_container_size_load_form,
        submitUrl:  url_cask_size_submit,
        idParams:   { container_size_id: container_size_id },
        fields: [
            { name: 'description',        label: 'Description' },
            { name: 'volume',             label: 'Volume', type: 'number' },
            { name: 'container_measure_id', label: 'Container Measure (ID)' },
            { name: 'dispense_method_id', label: 'Dispense Method (ID)' },
            { name: 'container_size_id', label: '', type: 'hidden' },
        ],
    });
});
