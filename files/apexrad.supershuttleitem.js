/* APEXRAD Super Shuttle Item - v24.2.0
 * https://github.com/Saeed-Hassanpour/APEXRAD-Super-ShuttleItem
 * Author: Saeed Hassanpour — Paya Shetaban Andisheh (APEXRAD)
 *
 * Architecture:
 *   - Collection APEXRAD_SUPERSHUTTLEITEM = source of truth for right panel
 *   - Left panel LOV: developer uses NOT EXISTS against the collection
 *   - MOVE: calls ADD_MEMBER  → collection updated → both panels refresh
 *   - REMOVE: calls REMOVE_MEMBER → collection updated → both panels refresh
 *   - REORDER: calls REORDER → collection reordered
 *   - SAVE: syncs collection → TARGET TABLE
 *
 * Public API:
 *   apexrad.superShuttleItem.reset('ITEM_NAME')
 *   apexrad.superShuttleItem.save('ITEM_NAME', callbackFn)
 */
var apexrad = apexrad || {};

(function ($, apex) {
    "use strict";

    apexrad.superShuttleItem = {

        /*
         * apexrad.superShuttleItem.reset('ITEM_NAME')
         * Full reset: reloads collection from TARGET TABLE, refreshes both panels.
         * Use when you want to discard unsaved changes and start fresh.
         */
        reset: function (pItemId) {
            var inst = apexrad.superShuttleItem._instances[pItemId];
            if (inst) { inst.resetPanels(); }
            else { apex.debug.warn('APEXRAD SSI: no instance for ' + pItemId); }
        },

        /*
         * apexrad.superShuttleItem.refreshLeft('ITEM_NAME')
         * Refreshes ONLY the left panel with current Parent Item(s) values.
         * Use in Dynamic Action on Parent Item(s) change (e.g. ITEM_NAME).
         * Existing right panel and collection are preserved.
         *
         * Example Dynamic Action on ITEM_NAME change:
         *   apexrad.superShuttleItem.refreshLeft('YOUR_ITEM_NAME');
         */
        refreshLeft: function (pItemId) {
            var inst = apexrad.superShuttleItem._instances[pItemId];
            if (inst) { inst.doRefreshLeft(); }
            else { apex.debug.warn('APEXRAD SSI refreshLeft: no instance for ' + pItemId); }
        },

        save: function (pItemId, callbackFn) {
            var inst = apexrad.superShuttleItem._instances[pItemId];
            if (inst) { inst.saveData(callbackFn); }
            else { apex.debug.warn('APEXRAD SSI save: no instance for ' + pItemId); }
        },

        _instances: {},

        init: function (pItemId, pOptions) {
            var defaults = {
                ajaxIdentifier  : null,
                showFilter      : true,
                placeholder     : 'Enter filter code/description',
                maxMove         : 1000,
                maxErrMsg       : 'Maximum allowed per move is #MAXIMUM-MOVE#. Please select fewer items.',
                labelsPos       : 'top',
                resetBtnId      : null,
                pageItems       : null,
                leftCountLabel  : 'Count',
                rightCntLabel   : 'Count',
                savedCountLabel : 'Saved Count',
                newCountLabel   : 'Selected Count',
                savedColorClass : 'apexrad-ssi-saved',
                countLabelClass : 'apexrad-ssi-count-label',
                allowAdd        : true,
                allowDel        : true
            };
            var opts = $.extend({}, defaults, pOptions);

            var pfx         = 'APEXRAD_SSI';
            var leftSelId   = pItemId + '_LEFT';
            var rightSelId  = pItemId + '_RIGHT';
            var containerId = pfx + '_CONTAINER';
            var filterInpId = pfx + '_FILTER_INPUT';
            var filterBtnId = pfx + '_FILTER_BTN';
            var filterClrId = pfx + '_FILTER_CLEAR';

            var apexItemNode = apex.item(pItemId) ? apex.item(pItemId).node : null;
            if (!apexItemNode) {
                apexItemNode = document.getElementById(pItemId);
            }
            if (!apexItemNode) {
                apex.debug.error('APEXRAD SSI: item node not found for:', pItemId);
                return;
            }

            var anchorEl  = apexItemNode.parentElement || apexItemNode;
            var inputName = apexItemNode.name || '';

            // ── Build shuttle HTML ────────────────────────────────────────
            var html = '';
            html += '<div class="apex-item-group apex-item-group--shuttle apexrad-ssi-shuttle" role="group"';
            html += ' id="' + containerId + '" data-labels-pos="' + opts.labelsPos + '"';
            html += ' aria-labelledby="' + pItemId + '_LABEL" tabindex="-1">';
            if (opts.showFilter) {
                html += '<div class="apexrad-ssi-filter-row" id="' + pfx + '_FILTER_ROW">';
                html += '<input type="text" id="' + filterInpId + '" placeholder="' + opts.placeholder + '"';
                html += ' class="text_field apex-item-text apexrad-ssi-filter-input" autocomplete="off"/>';
                html += '<a class="a-Button a-Button--popupLOV" id="' + filterBtnId + '"';
                html += ' aria-label="Filter" title="Filter" href="javascript:void(0);">';
                html += '<span class="fa fa-filter"></span></a>';
                html += '<a class="a-Button a-Button--popupLOV" id="' + filterClrId + '"';
                html += ' aria-label="Clear" title="Clear" href="javascript:void(0);">';
                html += '<span class="fa fa-times"></span></a>';
                html += '</div>';
            }
            html += '<table cellpadding="0" cellspacing="0" border="0" role="presentation" class="shuttle"><tbody><tr>';
            // Left panel
            html += '<td class="shuttleSelect1">';
            if (opts.labelsPos !== 'bottom') {
                html += '<span class="shuttleControl1-count">' + opts.leftCountLabel + ': <label class="' + opts.countLabelClass + '">0</label></span>';
            }
            html += '<select title="Move from" multiple id="' + leftSelId + '" size="10" class="shuttle_left apex-item-select"></select>';
            if (opts.labelsPos === 'bottom') {
                html += '<span class="shuttleControl1-count">' + opts.leftCountLabel + ': <label class="' + opts.countLabelClass + '">0</label></span>';
            }
            html += '</td>';
            // Control buttons
            html += '<td align="center" class="shuttleControl"><span class="shuttleControl-count">&nbsp;</span>';
            var buttons = [['RESET','Reset','reset']];
            if (opts.allowAdd) {
                buttons.push(['MOVE_ALL','Move All','move-all']);
                buttons.push(['MOVE','Move','move']);
            }
            if (opts.allowDel) {
                buttons.push(['REMOVE','Remove','remove']);
                buttons.push(['REMOVE_ALL','Remove All','remove-all']);
            }
            buttons.forEach(function(b){
                html += '<button id="' + pItemId + '_' + b[0] + '"';
                html += ' class="a-Button a-Button--noLabel a-Button--withIcon a-Button--small a-Button--noUI a-Button--shuttle"';
                html += ' type="button" title="' + b[1] + '" aria-label="' + b[1] + '">';
                html += '<span class="a-Icon icon-shuttle-' + b[2] + '" aria-hidden="true"></span></button>';
            });
            html += '</td>';
            // Right panel
            html += '<td class="shuttleSelect2">';
            if (opts.labelsPos !== 'bottom') {
                html += '<span class="shuttleControl2-count">' + opts.rightCntLabel + ': <label class="' + opts.countLabelClass + '">0</label></span>';
                html += '<span class="shuttleControl2-count" style="padding-left:.5em;">' + opts.newCountLabel + ': <label class="' + opts.countLabelClass + '">0</label></span>';
                html += '<span class="shuttleControl2-count" style="padding-left:.5em;">' + opts.savedCountLabel + ': <label class="' + opts.countLabelClass + '">0</label></span>';
            }
            html += '<select title="Move to" multiple id="' + rightSelId + '" name="' + (apexItemNode.name || inputName) + '" size="10" class="shuttle_right apex-item-select"></select>';
            if (opts.labelsPos === 'bottom') {
                html += '<span class="shuttleControl2-count">' + opts.rightCntLabel + ': <label class="' + opts.countLabelClass + '">0</label></span>';
                html += '<span class="shuttleControl2-count" style="padding-left:.5em;">' + opts.newCountLabel + ': <label class="' + opts.countLabelClass + '">0</label></span>';
                html += '<span class="shuttleControl2-count" style="padding-left:.5em;">' + opts.savedCountLabel + ': <label class="' + opts.countLabelClass + '">0</label></span>';
            }
            html += '</td>';
            // Sort buttons
            html += '<td align="center" class="shuttleSort2"><span class="shuttleControl-count">&nbsp;</span>';
            [['TOP','Top'],['UP','Up'],['DOWN','Down'],['BOTTOM','Bottom']].forEach(function(b){
                html += '<button id="' + pItemId + '_' + b[0] + '"';
                html += ' class="a-Button a-Button--noLabel a-Button--withIcon a-Button--small a-Button--noUI a-Button--shuttle"';
                html += ' type="button" title="' + b[1] + '" aria-label="' + b[1] + '">';
                html += '<span class="a-Icon icon-shuttle-' + b[1].toLowerCase() + '" aria-hidden="true"></span></button>';
            });
            html += '</td>';
            html += '</tr></tbody></table></div>';

            anchorEl.insertAdjacentHTML('afterend', html);

            var leftSel  = document.getElementById(leftSelId);
            var rightSel = document.getElementById(rightSelId);
            if (!leftSel || !rightSel) { return; }

            // ── State ────────────────────────────────────────────────────
            var _savedCount = 0;  // DB count from TARGET TABLE
            var _newCount   = 0;  // c003='NEW' items (moved, not saved)
            var _totalCnt   = 0;  // total collection size

            function _updateLabels(newCount, savedCount, totalCnt) {
                if (newCount   !== undefined && newCount   !== null) { _newCount   = Number(newCount)   || 0; }
                if (savedCount !== undefined && savedCount !== null) { _savedCount = Number(savedCount) || 0; }
                if (totalCnt   !== undefined && totalCnt   !== null) { _totalCnt   = Number(totalCnt)   || 0; }
                $('#' + containerId + ' .shuttleControl-count').remove();
                $('#' + containerId + ' .shuttleControl1-count').remove();
                $('#' + containerId + ' .shuttleControl2-count').remove();
                var lc = leftSel.length;
                $('#' + containerId + ' .shuttleControl').prepend('<span class="shuttleControl-count">&nbsp;</span>');
                $('#' + containerId + ' .shuttleSort2').prepend('<span class="shuttleControl-count">&nbsp;</span>');
                // Left panel label
                var lbl1 = '<span class="shuttleControl1-count">' + opts.leftCountLabel + ': <label class="' + opts.countLabelClass + '">' + lc + '</label></span>';
                if (opts.labelsPos === 'bottom') {
                    $('#' + containerId + ' .shuttleSelect1').append(lbl1);
                } else {
                    $('#' + containerId + ' .shuttleSelect1').prepend(lbl1);
                }
                // Right panel labels: Count | Selected Count | Saved Count
                var lbl_cnt  = '<span class="shuttleControl2-count">'                        + opts.rightCntLabel   + ': <label class="' + opts.countLabelClass + '">' + _totalCnt   + '</label></span>';
                var lbl_sel  = '<span class="shuttleControl2-count" style="padding-left:.5em;">' + opts.newCountLabel   + ': <label class="' + opts.countLabelClass + '">' + _newCount   + '</label></span>';
                var lbl_save = '<span class="shuttleControl2-count" style="padding-left:.5em;">' + opts.savedCountLabel + ': <label class="' + opts.countLabelClass + '">' + _savedCount + '</label></span>';
                if (opts.labelsPos === 'bottom') {
                    // append in order: Count, Selected Count, Saved Count
                    $('#' + containerId + ' .shuttleSelect2').append(lbl_cnt).append(lbl_sel).append(lbl_save);
                } else {
                    // prepend in reverse: Saved last prepended = bottom, Count first = top
                    $('#' + containerId + ' .shuttleSelect2').prepend(lbl_save).prepend(lbl_sel).prepend(lbl_cnt);
                }
            }

            function _x05() {
                if (!opts.pageItems) { return ''; }
                var items = opts.pageItems.split(',');
                var pairs = [];
                items.forEach(function(name) {
                    name = name.trim();
                    if (name) { pairs.push(name + '=' + apex.item(name).getValue()); }
                });
                return pairs.join('|');
            }

            function _call(x01, x02, x03, x04, x06, onSuccess) {
                var lSpinner$ = apex.util.showSpinner($('#' + containerId));
                apex.server.plugin(
                    opts.ajaxIdentifier,
                    { x01: x01, x02: x02, x03: x03, x04: x04, x05: _x05(), x06: x06 },
                    {
                        success: function(data) {
                            lSpinner$.remove();
                            onSuccess(data);
                        },
                        error: function(xhr, status, err) {
                            lSpinner$.remove();
                            apex.debug.error('APEXRAD SSI ' + x01 + ':', status, err);
                            var msg = 'An error occurred. Please try again.';
                            if (status === 'timeout') {
                                msg = 'Request timed out. Please try again.';
                            } else if (xhr && xhr.status === 401) {
                                msg = 'Session expired. Please refresh the page.';
                            }
                            apex.message.clearErrors();
                            apex.message.showErrors([{type:'error', location:'page', message: msg}]);
                        }
                    }
                );
            }

            // ── Populate right panel from server response ──────────────────
            function _applyRight(data) {
                if (!data || !data.right) { return; }
                rightSel.length = 0;
                var rows = data.right;
                for (var i = 0; i < rows.length; i++) {
                    var opt = new Option(rows[i].value, rows[i].id);
                    if (rows[i].flag === 'SAVED') {
                        $(opt).addClass(opts.savedColorClass);
                    } else {
                        $(opt).addClass('apexrad-ssi-new');
                    }
                    rightSel.options[rightSel.length] = opt;
                }
                // Counts from top-level JSON keys
                var newCnt = Number(data.newCount)   || 0;
                var totCnt = Number(data.totalCount) || 0;
                _updateLabels(newCnt, totCnt - newCnt, totCnt);
            }

            // ── LOAD_SAVED: init collection from TARGET TABLE → right panel ─
            function _loadSaved() {
                _call('LOAD_SAVED', pItemId, '', '', '', function(data) {
                    _applyRight(data);
                    _fillLeft('');
                });
            }

            // ── FILL_LEFT: run LOV SQL → left panel ────────────────────────
            function _fillLeft(filterText) {
                _call('FILL_LEFT', pItemId, filterText || '', '', '', function(data) {
                    if (!data || !data.item) { return; }
                    leftSel.length = 0;
                    var rows = data.item;
                    for (var i = 0; i < rows.length; i++) {
                        leftSel.options[i] = new Option(rows[i].value, rows[i].id);
                    }
                    _updateLabels();
                });
            }

            // ── ADD_MEMBER: move selected left→right via collection ─────────
            function _addMembers() {
                var selected = Array.from(leftSel.options).filter(function(o){ return o.selected; });
                if (selected.length === 0) { return; }
                // Enforce maxMove: limit items per single move operation
                if (selected.length > opts.maxMove) {
                    var msg = opts.maxErrMsg.replace('#MAXIMUM-MOVE#', opts.maxMove);
                    if (typeof parent !== 'undefined' && parent.apex) {
                        parent.apex.message.clearErrors();
                    }
                    apex.message.clearErrors();
                    apex.message.showErrors([{type:'error',location:'page',message:msg}]);
                    return;  // Move NOTHING
                }
                var pairs = selected.map(function(o){
                    return o.value + String.fromCharCode(1) + o.text;
                }).join('|');
                _call('ADD_MEMBER', pItemId, '', pairs, '', function(data) {
                    _applyRight(data);
                    _fillLeft($('#' + filterInpId).val() || '');
                });
            }

            function _addAllMembers() {
                var all = Array.from(leftSel.options);
                if (all.length === 0) { return; }
                // Enforce maxMove: limit items per single move-all operation
                if (all.length > opts.maxMove) {
                    var msg = opts.maxErrMsg.replace('#MAXIMUM-MOVE#', opts.maxMove);
                    if (typeof parent !== 'undefined' && parent.apex) {
                        parent.apex.message.clearErrors();
                    }
                    apex.message.clearErrors();
                    apex.message.showErrors([{type:'error',location:'page',message:msg}]);
                    return;  // Move NOTHING
                }
                var pairs = all.map(function(o){
                    return o.value + String.fromCharCode(1) + o.text;
                }).join('|');
                _call('ADD_MEMBER', pItemId, '', pairs, '', function(data) {
                    _applyRight(data);
                    _fillLeft($('#' + filterInpId).val() || '');
                });
            }

            // ── REMOVE_MEMBER: move selected right→left via collection ──────
            function _removeMembers() {
                var selected = Array.from(rightSel.options).filter(function(o){ return o.selected; });
                if (selected.length === 0) { return; }
                var vals = selected.map(function(o){ return o.value; }).join('|');
                _call('REMOVE_MEMBER', pItemId, '', vals, '', function(data) {
                    _applyRight(data);
                    _fillLeft($('#' + filterInpId).val() || '');
                });
            }

            function _removeAllMembers() {
                if (rightSel.length === 0) { return; }
                var vals = Array.from(rightSel.options).map(function(o){ return o.value; }).join('|');
                _call('REMOVE_MEMBER', pItemId, '', vals, '', function(data) {
                    _applyRight(data);
                    _fillLeft($('#' + filterInpId).val() || '');
                });
            }

            // ── REORDER: sync right panel order to collection ───────────────
            function _reorder() {
                var vals = Array.from(rightSel.options).map(function(o){ return o.value; }).join('|');
                _call('REORDER', pItemId, '', vals, '', function(data) {
                });
            }

            // ── Sort right panel (DOM only, then sync) ──────────────────────
            function _sortSel(dir) {
                var opts2 = Array.from(rightSel.options);
                if (dir === 'top') {
                    opts2.filter(function(o){return o.selected;}).reverse()
                        .forEach(function(o){ rightSel.insertBefore(o, rightSel.options[0]); });
                } else if (dir === 'bottom') {
                    opts2.filter(function(o){return o.selected;})
                        .forEach(function(o){ rightSel.appendChild(o); });
                } else if (dir === 'up') {
                    for (var i = 1; i < rightSel.options.length; i++) {
                        if (rightSel.options[i].selected && !rightSel.options[i-1].selected) {
                            rightSel.insertBefore(rightSel.options[i], rightSel.options[i-1]);
                        }
                    }
                } else if (dir === 'down') {
                    for (var i = rightSel.options.length-2; i >= 0; i--) {
                        if (rightSel.options[i].selected && !rightSel.options[i+1].selected) {
                            rightSel.insertBefore(rightSel.options[i+1], rightSel.options[i]);
                        }
                    }
                }
                _updateLabels();
            }

            // ── Wire buttons ──────────────────────────────────────────────
            $('#' + pItemId + '_MOVE').on('click',       function(){ _addMembers(); });
            $('#' + pItemId + '_MOVE_ALL').on('click',   function(){ _addAllMembers(); });
            $('#' + pItemId + '_REMOVE').on('click',     function(){ _removeMembers(); });
            $('#' + pItemId + '_REMOVE_ALL').on('click', function(){ _removeAllMembers(); });
            $('#' + pItemId + '_TOP').on('click',        function(){ _sortSel('top'); });
            $('#' + pItemId + '_UP').on('click',         function(){ _sortSel('up'); });
            $('#' + pItemId + '_DOWN').on('click',       function(){ _sortSel('down'); });
            $('#' + pItemId + '_BOTTOM').on('click',     function(){ _sortSel('bottom'); });
            $('#' + pItemId + '_RESET').on('click', function() {
                leftSel.length = 0; rightSel.length = 0;
                _newCount = 0; _updateLabels(0); _loadSaved();
            });
            $(leftSel).on('dblclick',  function(){ _addMembers(); });
            $(rightSel).on('dblclick', function(){ _removeMembers(); });

            // ── Filter bar ────────────────────────────────────────────────
            if (opts.showFilter) {
                $(document).on('click', '#' + filterBtnId, function(){ _fillLeft($('#'+filterInpId).val()); });
                $(document).on('keyup', '#' + filterInpId, function(e){ if(e.keyCode===13){_fillLeft($(this).val());} });
                $(document).on('click', '#' + filterClrId, function(){ $('#'+filterInpId).val(''); _fillLeft(''); });
            }

            // ── Instance registry ─────────────────────────────────────────
            apexrad.superShuttleItem._instances[pItemId] = {
                saveData: function(callbackFn) {
                    _call('SAVE', pItemId, '', '', String(rightSel.length), function(data) {
                        if (typeof callbackFn === 'function') { callbackFn(data); }
                        // After save: clear right panel immediately (no flicker)
                        // then reload from DB to reflect exact saved state
                        if (!data || !data.error) {
                            rightSel.length = 0;
                            _updateLabels(0, 0, 0);
                            _loadSaved();
                        }
                    });
                },
                /*
                 * Full reset: re-init collection from TARGET TABLE.
                 * Discards any unsaved (NEW) items.
                 */
                resetPanels: function() {
                    leftSel.length = 0;
                    rightSel.length = 0;
                    _newCount = 0;
                    _updateLabels(0);
                    _loadSaved();
                },
                /*
                 * Refresh left panel only. Right panel and collection unchanged.
                 * Picks up new Parent Item(s) values from current page state.
                 */
                doRefreshLeft: function() {
                    var filterText = opts.showFilter ? ($('#' + filterInpId).val() || '') : '';
                    _fillLeft(filterText);
                }
            };

            // ── Initial load ──────────────────────────────────────────────
            _loadSaved();

        } // init
    }; // apexrad.superShuttleItem

}(apex.jQuery, apex));
