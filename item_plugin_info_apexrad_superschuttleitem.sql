prompt --application/set_environment
set define off verify off feedback off

whenever sqlerror exit sql.sqlcode rollback
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.0'
,p_default_workspace_id=>0
,p_default_application_id=>0
,p_default_id_offset=>0
,p_default_owner=>null
);
end;
/

begin
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/

prompt --application/shared_components/plugins/item_type/info_apexrad_superschuttleitem
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(8800000001)
,p_plugin_type=>'ITEM TYPE'
,p_name=>'INFO.APEXRAD.SUPERSCHUTTLEITEM'
,p_display_name=>'APEXRAD Super Shuttle Item'
,p_supported_component_types=>'APEX_APPLICATION_PAGE_ITEMS'
,p_javascript_file_urls=>'#PLUGIN_FILES#js/apexrad.supershuttleitem.js?v=24.2.0'
,p_css_file_urls=>'#PLUGIN_FILES#css/apexrad.supershuttleitem.css?v=24.2.0'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'c_coll  constant varchar2(30) := ''APEXRAD_SUPERSHUTTLEITEM'';',
'',
'procedure render(',
'  p_item   in            apex_plugin.t_item,',
'  p_plugin in            apex_plugin.t_plugin,',
'  p_param  in            apex_plugin.t_item_render_param,',
'  p_result in out nocopy apex_plugin.t_item_render_result',
')',
'as',
'  l_show_filter     boolean        := nvl(p_item.attributes.get_varchar2(''attribute_01''),''Y'')=''Y'';',
'  l_placeholder     varchar2(255)  := nvl(p_item.attributes.get_varchar2(''attribute_02''),''Enter filter code/description'');',
'  l_max_move        number         := nvl(to_number(p_item.attributes.get_varchar2(''attribute_03'')),1000);',
'  l_max_err_msg     varchar2(4000) := nvl(p_item.attributes.get_varchar2(''attribute_04''),',
'                      ''Maximum allowed per move is #MAXIMUM-MOVE#. Please select fewer items.'');',
'  l_lbl_pos         varchar2(10)   := nvl(p_item.attributes.get_varchar2(''attribute_05''),''top'');',
'  l_left_label      varchar2(255)  := nvl(p_item.attributes.get_varchar2(''attribute_06''),''Count'');',
'  l_right_cnt_label varchar2(255)  := nvl(p_item.attributes.get_varchar2(''attribute_07''),''Count'');',
'  l_saved_label     varchar2(255)  := nvl(p_item.attributes.get_varchar2(''attribute_08''),''Saved Count'');',
'  l_right_label     varchar2(255)  := nvl(p_item.attributes.get_varchar2(''attribute_09''),''Selected Count'');',
'  l_page_items      varchar2(4000) := p_item.attributes.get_varchar2(''attribute_10'');',
'  l_src_table       varchar2(255)  := p_item.attributes.get_varchar2(''attribute_11'');',
'  l_src_pk          varchar2(255)  := p_item.attributes.get_varchar2(''attribute_12'');',
'  l_src_disp        varchar2(255)  := p_item.attributes.get_varchar2(''attribute_13'');',
'  l_src_where       varchar2(4000) := p_item.attributes.get_varchar2(''attribute_14'');',
'  l_table_name      varchar2(255)  := p_item.attributes.get_varchar2(''attribute_15'');',
'  l_shuttle_col     varchar2(255)  := p_item.attributes.get_varchar2(''attribute_19'');',
'  l_where_clause    varchar2(4000) := p_item.attributes.get_varchar2(''attribute_17'');',
'  l_use_merge       boolean        := nvl(p_item.attributes.get_varchar2(''attribute_18''),''Y'')=''Y'';',
'  l_allow_add       boolean        := p_item.attributes.get_varchar2(''attribute_20'')=''Y'';',
'  l_allow_del       boolean        := p_item.attributes.get_varchar2(''attribute_21'')=''Y'';',
'  l_item_id      varchar2(255)  := apex_escape.html_attribute(p_item.name);',
'  l_item_value   varchar2(32767):= p_param.value;',
'  l_disp         varchar2(4000);',
'  l_ret          varchar2(4000);',
'  l_selected     apex_t_varchar2;',
'  l_js_call      varchar2(32767);',
'  l_pfx          constant varchar2(20) := ''APEXRAD_SSI'';',
'',
'  function is_sel(p_v in varchar2) return boolean as',
'  begin',
'    if l_selected is null or l_selected.count = 0 then return false; end if;',
'    for i in 1..l_selected.count loop',
'      if l_selected(i) = p_v then return true; end if;',
'    end loop;',
'    return false;',
'  end is_sel;',
'',
'  procedure p(p_html in varchar2) as begin htp.p(p_html); end p;',
'',
'begin',
'  -- Render outputs only a lightweight anchor div + JS init call.',
'  -- ALL shuttle HTML (left/right panels, filter bar, buttons) is built',
'  -- dynamically by apexrad.superShuttleItem.init() in JavaScript.',
'  -- This avoids any HTML leaking into AJAX response buffers.',
'',
'  if p_param.is_readonly or p_param.is_printer_friendly then',
'    apex_plugin_util.print_hidden_if_readonly(',
'      p_item_name           => p_item.name,',
'      p_value               => l_item_value,',
'      p_is_readonly         => p_param.is_readonly,',
'      p_is_printer_friendly => p_param.is_printer_friendly',
'    );',
'    apex_util.prn(''<span id="'' || l_item_id || ''_DISPLAY" class="display_only">''',
'          || apex_escape.html(l_item_value) || ''</span>'');',
'    p_result.is_navigable := false;',
'    return;',
'  end if;',
'',
'  -- Output the shuttle mount point: a hidden input for session state',
'  -- plus an empty container div that JS will populate.',
'  -- Hidden input for APEX session state tracking.',
'  p(''<div style="display:none"><input type="hidden" id="''||p_item.name||''" name="''',
'    ||apex_plugin.get_input_name_for_page_item(false)',
'    ||''" value=""/></div>'');',
'',
'  l_js_call :=',
'    ''if(typeof apexrad!="undefined"&&apexrad.superShuttleItem){''',
'    || ''apexrad.superShuttleItem.init(''',
'    || apex_javascript.add_value(p_item.name)',
'    || ''{''',
'    || ''ajaxIdentifier:'' || apex_javascript.add_value(apex_plugin.get_ajax_identifier)',
'    || ''showFilter:''     || case when l_show_filter then ''true,'' else ''false,'' end',
'    || ''placeholder:''    || apex_javascript.add_value(l_placeholder)',
'    || ''maxMove:''        || to_char(l_max_move) || '',''',
'    || ''allowAdd:''      || case when l_allow_add then ''true'' else ''false'' end || '',''',
'    || ''allowDel:''      || case when l_allow_del then ''true'' else ''false'' end || '',''',
'    || ''resetBtnId:''     || apex_javascript.add_value(p_item.name || ''_RESET'')',
'    || ''labelsPos:''       || apex_javascript.add_value(l_lbl_pos)',
'    || ''leftCountLabel:''  || apex_javascript.add_value(l_left_label)',
'    || ''rightCntLabel:''   || apex_javascript.add_value(l_right_cnt_label)',
'    || ''savedCountLabel:'' || apex_javascript.add_value(l_saved_label)',
'    || ''newCountLabel:''   || apex_javascript.add_value(l_right_label)',
'    || ''maxErrMsg:''       || apex_javascript.add_value(l_max_err_msg)',
'    || ''pageItems:''      || case when l_page_items is not null',
'                               then rtrim(apex_javascript.add_value(l_page_items),'', '')',
'                               else ''null'' end',
'    || ''});''',
'    || ''}else{console.error("APEXRAD SSI: namespace not loaded");}''  ;',
'  apex_javascript.add_onload_code(p_code => l_js_call);',
'  p_result.is_navigable := true;',
'',
'exception when others then',
'  apex_debug.error(''APEXRAD Super Shuttle Item render: '' || sqlerrm);',
'  raise;',
'end render;',
'',
'',
'procedure ajax(',
'  p_item   in            apex_plugin.t_item,',
'  p_plugin in            apex_plugin.t_plugin,',
'  p_param  in            apex_plugin.t_item_ajax_param,',
'  p_result in out nocopy apex_plugin.t_item_ajax_result',
')',
'as',
'  l_action         varchar2(100)   := apex_application.g_x01;',
'  l_item_id        varchar2(255)   := apex_application.g_x02;',
'  l_filter_text    varchar2(4000)  := apex_application.g_x03;',
'  l_x04            varchar2(32767) := apex_application.g_x04;',
'  l_page_items_str varchar2(32767) := apex_application.g_x05;',
'  l_count          number          := 0;',
'  l_new_count      number          := 0;',
'  l_coll  constant varchar2(30)    := ''APEXRAD_SUPERSHUTTLEITEM'';',
'  -- Source attributes (for building LOV SQL dynamically)',
'  l_src_table    varchar2(255)   := p_item.attributes.get_varchar2(''attribute_11'');',
'  l_src_pk       varchar2(255)   := p_item.attributes.get_varchar2(''attribute_12'');',
'  l_src_disp     varchar2(255)   := p_item.attributes.get_varchar2(''attribute_13'');',
'  l_src_where    varchar2(4000)  := p_item.attributes.get_varchar2(''attribute_14'');',
'  -- Target attributes',
'  l_table_name   varchar2(255)   := p_item.attributes.get_varchar2(''attribute_15'');',
'  l_shuttle_col  varchar2(255)   := p_item.attributes.get_varchar2(''attribute_19'');',
'  l_where_clause varchar2(4000)  := p_item.attributes.get_varchar2(''attribute_17'');',
'  l_use_merge    varchar2(1)     := nvl(p_item.attributes.get_varchar2(''attribute_18''),''Y'');',
'  -- Generated LOV SQL (built from source attributes in render)',
'  l_lov_sql      varchar2(32767);',
'  l_ctx            apex_exec.t_context;',
'  l_disp           varchar2(4000);',
'  l_ret            varchar2(4000);',
'',
'  procedure set_page_items as',
'    l_pairs apex_t_varchar2;',
'    l_pair  apex_t_varchar2;',
'  begin',
'    if l_page_items_str is null then return; end if;',
'    l_pairs := apex_string.split(l_page_items_str, ''|'');',
'    for i in 1..l_pairs.count loop',
'      l_pair := apex_string.split(l_pairs(i), ''='');',
'      if l_pair.count >= 1 then',
'        apex_util.set_session_state(',
'          l_pair(1),',
'          case when l_pair.count >= 2 then l_pair(2) else null end);',
'      end if;',
'    end loop;',
'  end set_page_items;',
'',
'  -- Emit right panel JSON: all collection members.',
'  -- c003=SAVED (in target table) or NEW (moved, not yet saved).',
'  -- newCount and totalCount are emitted as top-level JSON keys.',
'  procedure emit_right as',
'  begin',
'    l_count       := 0;',
'    l_new_count   := 0;',
'    apex_json.open_object;',
'    apex_json.open_array(''right'');',
'    for rec in (',
'      select c001 ret_val, c002 disp_val, c003 flag',
'        from apex_collections',
'       where collection_name = l_coll',
'       order by case when c003 = ''NEW'' then 0 else 1 end, seq_id',
'    ) loop',
'      apex_json.open_object;',
'      apex_json.write(''id'',    rec.ret_val);',
'      apex_json.write(''value'', rec.disp_val);',
'      apex_json.write(''flag'',  rec.flag);',
'      apex_json.close_object;',
'      l_count := l_count + 1;',
'      if rec.flag = ''NEW'' then l_new_count := l_new_count + 1; end if;',
'    end loop;',
'    -- Emit counts as top-level JSON keys (no sentinel row needed)',
'    apex_json.close_array;',
'    apex_json.write(''newCount'',   l_new_count);',
'    apex_json.write(''totalCount'', l_count);',
'    apex_json.close_object;',
'    return;',
'  end emit_right;',
'',
'begin',
'  set_page_items;',
'  -- Build LOV SQL dynamically from source attributes.',
'  -- This replaces the old p_item.lov_definition approach.',
'  -- Build LOV SQL: SELECT display_col, pk_col FROM source',
'  -- Display formatting (substr+concat) is done in PL/SQL loop, not SQL.',
'  -- This avoids complex quote escaping inside wwv_flow_t_varchar2.',
'  -- Replace :ITEM_NAME bind variables with actual session state values',
'  -- so they work correctly inside execute immediate dynamic SQL.',
'  declare',
'    procedure subst_where(p_where in out varchar2) is',
'      l_name varchar2(255);',
'      l_val  varchar2(32767);',
'      l_pos  pls_integer;',
'      l_end  pls_integer;',
'    begin',
'      if p_where is null then return; end if;',
'      l_pos := 1;',
'      loop',
'        l_pos := regexp_instr(p_where, '':([A-Za-z][A-Za-z0-9_$#]*)'', l_pos, 1, 0);',
'        exit when l_pos = 0;',
'        l_end  := regexp_instr(p_where, '':([A-Za-z][A-Za-z0-9_$#]*)'', l_pos, 1, 1);',
'        l_name := regexp_substr(p_where, '':([A-Za-z][A-Za-z0-9_$#]*)'', l_pos, 1, null, 1);',
'        begin',
'          l_val := v(l_name);',
'        exception when others then l_val := null;',
'        end;',
'        p_where := substr(p_where,1,l_pos-1)',
'          ||chr(39)||replace(l_val,chr(39),chr(39)||chr(39))||chr(39)',
'          ||substr(p_where,l_end);',
'        l_pos := l_pos + length(chr(39)||replace(l_val,chr(39),chr(39)||chr(39))||chr(39));',
'      end loop;',
'    end subst_where;',
'  begin',
'    subst_where(l_src_where);',
'    subst_where(l_where_clause);',
'  end;',
'  if l_src_table is not null and l_src_pk is not null and l_src_disp is not null then',
'    l_lov_sql := ''select ''||dbms_assert.simple_sql_name(l_src_disp);',
'    l_lov_sql := l_lov_sql||'', ''||dbms_assert.simple_sql_name(l_src_pk);',
'    l_lov_sql := l_lov_sql||''  from ''||dbms_assert.sql_object_name(l_src_table);',
'    if l_src_where is not null then',
'      l_lov_sql := l_lov_sql||''  where (''||l_src_where||'')'';',
'    else',
'      l_lov_sql := l_lov_sql||''  where 1=1'';',
'    end if;',
'    l_lov_sql := l_lov_sql||''  and not exists (select 1 from apex_collections ac'';',
'    l_lov_sql := l_lov_sql||''  where ac.collection_name=''||chr(39)||''APEXRAD_SUPERSHUTTLEITEM''||chr(39);',
'    l_lov_sql := l_lov_sql||''  and ac.c001=''||dbms_assert.simple_sql_name(l_src_pk)||'') order by 1'';',
'  end if;',
'',
'  if l_action = ''LOAD_SAVED'' then',
'    -- Initialize collection from TARGET TABLE (c003=SAVED).',
'    -- BULK: method 6 - CREATE_COLLECTION_FROM_QUERYB2(name, query)',
'    -- No bind arrays: session state already set by set_page_items().',
'    -- BULK: CREATE_COLLECTION_FROM_QUERY (method 1, p_truncate_if_exists=YES)',
'    -- col1=c001(return), col2=c002(display), col3=c003(flag).',
'    if l_table_name is not null and l_shuttle_col is not null then',
'      declare',
'        l_bulk_q varchar2(32767);',
'      begin',
'        l_bulk_q := ''select t.''||l_shuttle_col;',
'        l_bulk_q := l_bulk_q||'', substr(s.''||l_src_disp||'',1,30)||chr(40)||t.''||l_shuttle_col||''||chr(41)'';',
'        l_bulk_q := l_bulk_q||chr(44)||chr(32)||chr(39)||''SAVED''||chr(39);',
'        l_bulk_q := l_bulk_q||''  from ''||l_table_name||'' t'';',
'        l_bulk_q := l_bulk_q||''  join ''||l_src_table||'' s'';',
'        l_bulk_q := l_bulk_q||''    on s.''||l_src_pk||'' = t.''||l_shuttle_col;',
'        if l_where_clause is not null then',
'          l_bulk_q := l_bulk_q||''  where (''||l_where_clause||'')'';',
'        end if;',
'        apex_collection.create_collection_from_query(',
'          p_collection_name    => l_coll,',
'          p_query              => l_bulk_q,',
'          p_generate_md5       => ''NO'',',
'          p_truncate_if_exists => ''YES'');',
'        -- Ensure collection exists even when query returns 0 rows',
'        if not apex_collection.collection_exists(l_coll) then',
'          apex_collection.create_collection(l_coll);',
'        end if;',
'      exception when others then',
'        apex_debug.warn(''APEXRAD SSI LOAD_SAVED: ''||sqlerrm);',
'      end;',
'    end if;',
'    emit_right;',
'',
'  elsif l_action = ''FILL_LEFT'' then',
'    apex_json.open_object;',
'    apex_json.open_array(''item'');',
'    begin',
'      l_ctx := apex_exec.open_query_context(',
'        p_location  => apex_exec.c_location_local_db,',
'        p_sql_query => l_lov_sql);',
'      while apex_exec.next_row(l_ctx) loop',
'        l_ret  := apex_exec.get_varchar2(l_ctx,2);',
'        l_disp := substr(apex_exec.get_varchar2(l_ctx,1),1,30)||chr(40)||l_ret||chr(41);',
'        if l_filter_text is null',
'           or instr(lower(l_disp),lower(l_filter_text))>0',
'           or instr(lower(l_ret), lower(l_filter_text))>0',
'        then',
'          apex_json.open_object;',
'          apex_json.write(''id'',    l_ret);',
'          apex_json.write(''value'', l_disp);',
'          apex_json.close_object;',
'          l_count := l_count + 1;',
'        end if;',
'      end loop;',
'      apex_exec.close(l_ctx);',
'    exception when others then',
'      apex_exec.close(l_ctx);',
'      apex_debug.warn(''APEXRAD SSI FILL_LEFT: ''||sqlerrm);',
'    end;',
'    apex_json.close_array;',
'    apex_json.close_object;',
'',
'  elsif l_action = ''ADD_MEMBER'' then',
'    -- Add selected items to collection with c003=NEW (not yet in TARGET TABLE).',
'    declare',
'      l_members apex_t_varchar2 := apex_string.split(l_x04, ''|'');',
'      l_parts   apex_t_varchar2;',
'      l_exists  number;',
'    begin',
'      for i in 1..l_members.count loop',
'        l_parts := apex_string.split(l_members(i), chr(1));',
'        if l_parts.count >= 2 then',
'          select count(1) into l_exists from apex_collections',
'           where collection_name = l_coll and c001 = l_parts(1);',
'          if l_exists = 0 then',
'            if not apex_collection.collection_exists(l_coll) then',
'              apex_collection.create_collection(l_coll);',
'            end if;',
'            -- c003=NEW: moved but not yet saved to TARGET TABLE',
'            apex_collection.add_member(l_coll, l_parts(1), l_parts(2), ''NEW'');',
'          end if;',
'        end if;',
'      end loop;',
'    end;',
'    emit_right;',
'',
'  elsif l_action = ''REMOVE_MEMBER'' then',
'    -- Remove items from collection only. TARGET TABLE is NOT touched.',
'    declare',
'      l_vals apex_t_varchar2 := apex_string.split(l_x04, ''|'');',
'    begin',
'      for i in 1..l_vals.count loop',
'        for rec in (select seq_id from apex_collections',
'                     where collection_name = l_coll',
'                       and c001 = l_vals(i)) loop',
'          apex_collection.delete_member(l_coll, rec.seq_id);',
'        end loop;',
'      end loop;',
'    end;',
'    emit_right;',
'',
'  elsif l_action = ''REORDER'' then',
'    declare',
'      l_vals apex_t_varchar2 := apex_string.split(l_x04, ''|'');',
'      l_c001 apex_t_varchar2;',
'      l_c002 apex_t_varchar2;',
'      l_c003 apex_t_varchar2;',
'    begin',
'      -- Bulk collect current collection members',
'      select c001, c002, c003',
'        bulk collect into l_c001, l_c002, l_c003',
'        from apex_collections',
'       where collection_name = l_coll;',
'      apex_collection.create_or_truncate_collection(l_coll);',
'      -- Re-add in the order specified by l_vals (from JS drag/sort)',
'      for i in 1..l_vals.count loop',
'        for j in 1..l_c001.count loop',
'          if l_c001(j) = l_vals(i) then',
'            apex_collection.add_member(l_coll, l_c001(j), l_c002(j), l_c003(j));',
'            exit;',
'          end if;',
'        end loop;',
'      end loop;',
'    end;',
'    apex_json.open_object; apex_json.write(''ok'',1); apex_json.close_object;',
'',
'  elsif l_action = ''SAVE'' then',
'    apex_json.open_object;',
'    if l_table_name is not null and l_shuttle_col is not null then',
'      declare',
'        l_safe_tbl varchar2(255) := dbms_assert.sql_object_name(l_table_name);',
'        l_safe_col varchar2(255) := dbms_assert.simple_sql_name(l_shuttle_col);',
'        -- Static SQL can read apex_collections directly (has APEX context)',
'        -- Collect IDs once into memory - used for both INSERT and DELETE',
'        l_ids      apex_t_varchar2;',
'        l_cnt      pls_integer := 0;',
'      begin',
'        select c001 bulk collect into l_ids',
'          from apex_collections',
'         where collection_name = l_coll;',
'        l_cnt := l_ids.count;',
'        if l_use_merge = ''Y'' then',
'          if l_cnt = 0 then',
'            -- Right panel is empty: delete all rows from target',
'            execute immediate ''delete from ''||l_safe_tbl',
'              ||case when l_where_clause is not null',
'                   then '' where (''||l_where_clause||'')'' else '''' end;',
'          else',
'            declare',
'              l_isql varchar2(4000);',
'              l_dsql varchar2(4000);',
'            begin',
'              -- INSERT new: c001 already varchar2, cast FK col to varchar2 for MINUS',
'              l_isql := ''insert into ''||l_safe_tbl||'' (''||l_safe_col||'')'';',
'              l_isql := l_isql||'' select c001 from apex_collections where collection_name=''||chr(39)||l_coll||chr(39);',
'              l_isql := l_isql||'' minus select to_char(''||l_safe_col||'') from ''||l_safe_tbl;',
'              execute immediate l_isql;',
'              -- DELETE deselected: cast FK col to varchar2 to match c001 type',
'              l_dsql := ''delete from ''||l_safe_tbl||'' t2 where to_char(t2.''||l_safe_col||'')'';',
'              l_dsql := l_dsql||'' not in (select c001 from apex_collections'';',
'              l_dsql := l_dsql||'' where collection_name=''||chr(39)||l_coll||chr(39)||'')'';',
'              execute immediate l_dsql;',
'            end;',
'          end if;',
'        else',
'          declare',
'              l_isql varchar2(4000);',
'          begin',
'            execute immediate ''delete from ''||l_safe_tbl',
'              ||case when l_where_clause is not null',
'                   then '' where (''||l_where_clause||'')'' else '''' end;',
'            l_isql := ''insert into ''||l_safe_tbl||'' (''||l_safe_col||'')'';',
'            l_isql := l_isql||'' select c001 from apex_collections'';',
'            l_isql := l_isql||'' where collection_name=''||chr(39)||l_coll||chr(39);',
'            execute immediate l_isql;',
'          end;',
'        end if;',
'        commit;',
'        apex_json.write(''saved'', l_cnt);',
'      exception when others then',
'        rollback;',
'        apex_debug.error(''APEXRAD SSI SAVE: ''||sqlerrm);',
'        apex_json.write(''error'', sqlerrm);',
'      end;',
'    else',
'      apex_json.write(''error'',''Target Table/FK Column required'');',
'    end if;',
'    apex_json.close_object;',
'',
'  else',
'    apex_json.open_object;',
'    apex_json.write(''error'',''Unknown action: ''||l_action);',
'    apex_json.close_object;',
'  end if;',
'',
'exception when others then',
'  apex_debug.error(''APEXRAD SSI ajax outer: ''||sqlerrm);',
'  begin apex_json.close_all; exception when others then null; end;',
'  apex_json.open_object;',
'  apex_json.write(''error'', sqlerrm);',
'  apex_json.close_object;',
'end ajax;'))
,p_api_version=>3
,p_files_version=>1
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'VISIBLE:LABEL:SESSION_STATE:SOURCE:READONLY:REQUIRED:ELEMENT'
,p_substitute_attributes=>true
,p_version_scn=>1
,p_subscribe_plugin_settings=>true
,p_help_text=>'<p>Super Shuttle Item for Oracle APEX 24.2+</p><p><strong>Copyright & Ownership</strong> © 2026 Saeed Hassanpour-Paya Shetaban Andisheh (APEXRAD). All rights reserved.<br/><ul><li>You may use this plugin freely in personal and commercial Oracle APEX projects.</li></ul>'
,p_version_identifier=>'24.2.0'
,p_about_url=>'https://github.com/Saeed-Hassanpour/APEXRAD-Super-ShuttleItem'
);
end;
/

-- ============================================================
--  Plugin Attributes
-- ============================================================

-- 01: Show Filter
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000010)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'attribute_01'
,p_prompt=>'Show Filter'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_help_text=>'When Yes, a filter text box is rendered above the left panel.'
);
end;
/

-- 02: Filter Placeholder
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000011)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>15
,p_static_id=>'attribute_02'
,p_prompt=>'Filter Placeholder'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Enter filter code/description'
,p_is_translatable=>true
,p_depending_on_attribute_id=>wwv_flow_imp.id(8800000010)
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'Y'
,p_help_text=>'Placeholder text inside the filter input. Only shown when Show Filter = Yes.'
);
end;
/

-- 03: Maximum Move
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000012)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>17
,p_static_id=>'attribute_03'
,p_prompt=>'Maximum Move'
,p_attribute_type=>'INTEGER'
,p_is_required=>false
,p_default_value=>'1000'
,p_is_translatable=>false
,p_help_text=>'Maximum items movable in a single operation (1-1000). Default: 1000.'
);
end;
/

-- 04: Maximum Error Message
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000013)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>18
,p_static_id=>'attribute_04'
,p_prompt=>'Maximum Error Message'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Maximum allowed per move is #MAXIMUM-MOVE#. Please select fewer items.'
,p_is_translatable=>true
,p_help_text=>'Error shown when Maximum Move is exceeded. Use #MAXIMUM-MOVE# as placeholder for the limit value.'
);
end;
/

-- 05: Labels Position
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000014)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>19
,p_static_id=>'attribute_05'
,p_prompt=>'Labels Position'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'top'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'Position of count labels. Top: labels above panels. Bottom: labels below panels.'
);
end;
/
begin
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(8800000015)
,p_plugin_attribute_id=>wwv_flow_imp.id(8800000014)
,p_display_sequence=>10
,p_display_value=>'Top'
,p_return_value=>'top'
);
end;
/
begin
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(8800000016)
,p_plugin_attribute_id=>wwv_flow_imp.id(8800000014)
,p_display_sequence=>20
,p_display_value=>'Bottom'
,p_return_value=>'bottom'
);
end;
/

-- 06: Left Panel Count Label
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000060)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>40
,p_static_id=>'attribute_06'
,p_prompt=>'Left Panel Count Label'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Count'
,p_is_translatable=>true
,p_help_text=>'Label above the left panel showing available row count. Default: Count'
);
end;
/

-- 07: Right Panel Count Label
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000071)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>45
,p_static_id=>'attribute_07'
,p_prompt=>'Right Panel Count Label'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Count'
,p_is_translatable=>true
,p_help_text=>'Label showing total items in right panel. Default: Count'
);
end;
/

-- 08: Right Panel Saved Count Label
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000050)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>50
,p_static_id=>'attribute_08'
,p_prompt=>'Right Panel Saved Count Label'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Saved Count'
,p_is_translatable=>true
,p_help_text=>'Label showing count of rows saved in the target table. Updates on page load and after save only.'
);
end;
/

-- 09: Right Panel Selected Count Label
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000070)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>60
,p_static_id=>'attribute_09'
,p_prompt=>'Right Panel Selected Count Label'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Selected Count'
,p_is_translatable=>true
,p_help_text=>'Label showing count of newly moved items not yet saved. Starts at 0. Default: Selected Count'
);
end;
/

-- 10: Parent Item(s)
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000097)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>70
,p_static_id=>'attribute_10'
,p_prompt=>'Parent Item(s)'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'Comma-separated page items submitted with AJAX (e.g. P6_COUNTRY).'
);
end;
/

-- 11: Source Table Name
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000101)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>75
,p_static_id=>'attribute_11'
,p_prompt=>'Source Table Name'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Source table for the left shuttle panel (e.g. SHUTTLE_TEST).'
);
end;
/

-- 12: Source Return Column (PK)
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000102)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>76
,p_static_id=>'attribute_12'
,p_prompt=>'Source Return Column (PK)'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Primary key / return value column in the source table (e.g. ID).'
);
end;
/

-- 13: Source Display Column
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000103)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>13
,p_display_sequence=>77
,p_static_id=>'attribute_13'
,p_prompt=>'Source Display Column'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Display/label column in the source table (e.g. NAME). Shown in the shuttle left panel.'
);
end;
/

-- 14: Source Where Clause
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000104)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>14
,p_display_sequence=>78
,p_static_id=>'attribute_14'
,p_prompt=>'Source Where Clause'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'Optional WHERE clause for the source table query (e.g. COUNTRY = COALESCE(:P6_COUNTRY, COUNTRY)). Do NOT include the word WHERE. Supports :BIND variables from Parent Item(s).'
);
end;
/

-- 15: Target Table Name
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000080)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>15
,p_display_sequence=>80
,p_static_id=>'attribute_15'
,p_prompt=>'Target Table Name'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Target table storing saved selections (e.g. TARGET TABLE).'
);
end;
/

-- 16: Target Foreign Key Column
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000095)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>16
,p_display_sequence=>85
,p_static_id=>'attribute_19'
,p_prompt=>'Target Foreign Key Column'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Column in the target table that stores the source return value (e.g. CITY_ID). The PK column of the target table is auto-filled by sequence.'
);
end;
/

-- 17: Target Where Clause
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000096)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>17
,p_display_sequence=>90
,p_static_id=>'attribute_17'
,p_prompt=>'Target Where Clause'
,p_attribute_type=>'TEXTAREA'
,p_is_required=>false
,p_is_translatable=>false
,p_help_text=>'Optional WHERE clause scoping target table operations (e.g. FLAG=''N''). Do NOT include the word WHERE.'
);
end;
/
-- ============================================================
--  Static File: js/apexrad.supershuttleitem.js
-- ============================================================
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A20415045585241442053757065722053687574746C65204974656D202D207632342E322E300A202A2068747470733A2F2F6769746875622E636F6D2F53616565642D48617373616E706F75722F415045585241442D53757065722D53687574746C654974656D0A202A20417574686F723A2053616565642048617373616E706F757220E28094205061796120536865746162616E20416E646973686568202841504558524144290A202A0A202A204172636869746563747572653A0A202A2020202D20436F6C';
wwv_flow_imp.g_varchar2_table(2) := '6C656374696F6E20415045585241445F535550455253485554544C454954454D203D20736F75726365206F6620747275746820666F722072696768742070616E656C0A202A2020202D204C6566742070616E656C204C4F563A20646576656C6F7065722075736573204E4F542045584953545320616761696E73742074686520636F6C6C656374696F6E0A202A2020202D204D4F56453A2063616C6C73204144445F4D454D4245522020E2869220636F6C6C656374696F6E207570646174656420E2869220626F74';
wwv_flow_imp.g_varchar2_table(3) := '682070616E656C7320726566726573680A202A2020202D2052454D4F56453A2063616C6C732052454D4F56455F4D454D42455220E2869220636F6C6C656374696F6E207570646174656420E2869220626F74682070616E656C7320726566726573680A202A2020202D2052454F524445523A2063616C6C732052454F5244455220E2869220636F6C6C656374696F6E2072656F7264657265640A202A2020202D20534156453A2073796E637320636F6C6C656374696F6E20E2869220544152474554205441424C45';
wwv_flow_imp.g_varchar2_table(4) := '0A202A0A202A205075626C6963204150493A0A202A202020617065787261642E737570657253687574746C654974656D2E726573657428274954454D5F4E414D4527290A202A202020617065787261642E737570657253687574746C654974656D2E7361766528274954454D5F4E414D45272C2063616C6C6261636B466E290A202A2F0A7661722061706578726164203D2061706578726164207C7C207B7D3B0A0A2866756E6374696F6E2028242C206170657829207B0A20202020227573652073747269637422';
wwv_flow_imp.g_varchar2_table(5) := '3B0A0A20202020617065787261642E737570657253687574746C654974656D203D207B0A0A20202020202020202F2A0A2020202020202020202A20617065787261642E737570657253687574746C654974656D2E726573657428274954454D5F4E414D4527290A2020202020202020202A2046756C6C2072657365743A2072656C6F61647320636F6C6C656374696F6E2066726F6D20544152474554205441424C452C2072656672657368657320626F74682070616E656C732E0A2020202020202020202A205573';
wwv_flow_imp.g_varchar2_table(6) := '65207768656E20796F752077616E7420746F206469736361726420756E7361766564206368616E67657320616E642073746172742066726573682E0A2020202020202020202A2F0A202020202020202072657365743A2066756E6374696F6E2028704974656D496429207B0A20202020202020202020202076617220696E7374203D20617065787261642E737570657253687574746C654974656D2E5F696E7374616E6365735B704974656D49645D3B0A20202020202020202020202069662028696E737429207B';
wwv_flow_imp.g_varchar2_table(7) := '20696E73742E726573657450616E656C7328293B207D0A202020202020202020202020656C7365207B20617065782E64656275672E7761726E282741504558524144205353493A206E6F20696E7374616E636520666F722027202B20704974656D4964293B207D0A20202020202020207D2C0A0A20202020202020202F2A0A2020202020202020202A20617065787261642E737570657253687574746C654974656D2E726566726573684C65667428274954454D5F4E414D4527290A2020202020202020202A2052';
wwv_flow_imp.g_varchar2_table(8) := '6566726573686573204F4E4C5920746865206C6566742070616E656C20776974682063757272656E7420506172656E74204974656D2873292076616C7565732E0A2020202020202020202A2055736520696E2044796E616D696320416374696F6E206F6E20506172656E74204974656D287329206368616E67652028652E672E204954454D5F4E414D45292E0A2020202020202020202A204578697374696E672072696768742070616E656C20616E6420636F6C6C656374696F6E20617265207072657365727665';
wwv_flow_imp.g_varchar2_table(9) := '642E0A2020202020202020202A0A2020202020202020202A204578616D706C652044796E616D696320416374696F6E206F6E204954454D5F4E414D45206368616E67653A0A2020202020202020202A202020617065787261642E737570657253687574746C654974656D2E726566726573684C6566742827594F55525F4954454D5F4E414D4527293B0A2020202020202020202A2F0A2020202020202020726566726573684C6566743A2066756E6374696F6E2028704974656D496429207B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(10) := '2020202076617220696E7374203D20617065787261642E737570657253687574746C654974656D2E5F696E7374616E6365735B704974656D49645D3B0A20202020202020202020202069662028696E737429207B20696E73742E646F526566726573684C65667428293B207D0A202020202020202020202020656C7365207B20617065782E64656275672E7761726E2827415045585241442053534920726566726573684C6566743A206E6F20696E7374616E636520666F722027202B20704974656D4964293B20';
wwv_flow_imp.g_varchar2_table(11) := '7D0A20202020202020207D2C0A0A2020202020202020736176653A2066756E6374696F6E2028704974656D49642C2063616C6C6261636B466E29207B0A20202020202020202020202076617220696E7374203D20617065787261642E737570657253687574746C654974656D2E5F696E7374616E6365735B704974656D49645D3B0A20202020202020202020202069662028696E737429207B20696E73742E73617665446174612863616C6C6261636B466E293B207D0A202020202020202020202020656C736520';
wwv_flow_imp.g_varchar2_table(12) := '7B20617065782E64656275672E7761726E2827415045585241442053534920736176653A206E6F20696E7374616E636520666F722027202B20704974656D4964293B207D0A20202020202020207D2C0A0A20202020202020205F696E7374616E6365733A207B7D2C0A0A2020202020202020696E69743A2066756E6374696F6E2028704974656D49642C20704F7074696F6E7329207B0A2020202020202020202020207661722064656661756C7473203D207B0A20202020202020202020202020202020616A6178';
wwv_flow_imp.g_varchar2_table(13) := '4964656E74696669657220203A206E756C6C2C0A2020202020202020202020202020202073686F7746696C7465722020202020203A20747275652C0A20202020202020202020202020202020706C616365686F6C64657220202020203A2027456E7465722066696C74657220636F64652F6465736372697074696F6E272C0A202020202020202020202020202020206D61784D6F76652020202020202020203A20313030302C0A202020202020202020202020202020206D61784572724D7367202020202020203A';
wwv_flow_imp.g_varchar2_table(14) := '20274D6178696D756D20616C6C6F77656420706572206D6F766520697320234D4158494D554D2D4D4F5645232E20506C656173652073656C656374206665776572206974656D732E272C0A202020202020202020202020202020206C6162656C73506F73202020202020203A2027746F70272C0A20202020202020202020202020202020726573657442746E49642020202020203A206E756C6C2C0A20202020202020202020202020202020706167654974656D73202020202020203A206E756C6C2C0A20202020';
wwv_flow_imp.g_varchar2_table(15) := '2020202020202020202020206C656674436F756E744C6162656C20203A2027436F756E74272C0A202020202020202020202020202020207269676874436E744C6162656C2020203A2027436F756E74272C0A202020202020202020202020202020207361766564436F756E744C6162656C203A2027536176656420436F756E74272C0A202020202020202020202020202020206E6577436F756E744C6162656C2020203A202753656C656374656420436F756E74272C0A2020202020202020202020202020202073';
wwv_flow_imp.g_varchar2_table(16) := '61766564436F6C6F72436C617373203A2027617065787261642D7373692D7361766564272C0A20202020202020202020202020202020636F756E744C6162656C436C617373203A2027617065787261642D7373692D636F756E742D6C6162656C272C0A20202020202020202020202020202020616C6C6F7741646420202020202020203A20747275652C0A20202020202020202020202020202020616C6C6F7744656C20202020202020203A20747275650A2020202020202020202020207D3B0A20202020202020';
wwv_flow_imp.g_varchar2_table(17) := '2020202020766172206F707473203D20242E657874656E64287B7D2C2064656661756C74732C20704F7074696F6E73293B0A0A202020202020202020202020766172207066782020202020202020203D2027415045585241445F535349273B0A202020202020202020202020766172206C65667453656C49642020203D20704974656D4964202B20275F4C454654273B0A20202020202020202020202076617220726967687453656C496420203D20704974656D4964202B20275F5249474854273B0A2020202020';
wwv_flow_imp.g_varchar2_table(18) := '2020202020202076617220636F6E7461696E65724964203D20706678202B20275F434F4E5441494E4552273B0A2020202020202020202020207661722066696C746572496E704964203D20706678202B20275F46494C5445525F494E505554273B0A2020202020202020202020207661722066696C74657242746E4964203D20706678202B20275F46494C5445525F42544E273B0A2020202020202020202020207661722066696C746572436C724964203D20706678202B20275F46494C5445525F434C45415227';
wwv_flow_imp.g_varchar2_table(19) := '3B0A0A2020202020202020202020202F2F2046696E64207468652068696464656E2073656C6563742072656E64657265642062792074686520706C7567696E202841504558206974656D206E6F6465290A20202020202020202020202076617220617065784974656D4E6F6465203D20617065782E6974656D28704974656D496429203F20617065782E6974656D28704974656D4964292E6E6F6465203A206E756C6C3B0A2020202020202020202020206966202821617065784974656D4E6F646529207B0A2020';
wwv_flow_imp.g_varchar2_table(20) := '2020202020202020202020202020617065784974656D4E6F6465203D20646F63756D656E742E676574456C656D656E744279496428704974656D4964293B0A2020202020202020202020207D0A2020202020202020202020206966202821617065784974656D4E6F646529207B0A20202020202020202020202020202020617065782E64656275672E6572726F72282741504558524144205353493A206974656D206E6F6465206E6F7420666F756E6420666F723A272C20704974656D4964293B0A202020202020';
wwv_flow_imp.g_varchar2_table(21) := '2020202020202020202072657475726E3B0A2020202020202020202020207D0A0A2020202020202020202020202F2F20416E63686F7220666F7220696E73657274696E672073687574746C652048544D4C3A20706172656E74206F66207468652068696464656E2073656C6563740A20202020202020202020202076617220616E63686F72456C20203D20617065784974656D4E6F64652E706172656E74456C656D656E74207C7C20617065784974656D4E6F64653B0A2020202020202020202020207661722069';
wwv_flow_imp.g_varchar2_table(22) := '6E7075744E616D65203D20617065784974656D4E6F64652E6E616D65207C7C2027273B0A0A2020202020202020202020202F2F20E29480E29480204275696C642073687574746C652048544D4C20E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294800A20';
wwv_flow_imp.g_varchar2_table(23) := '20202020202020202020207661722068746D6C203D2027273B0A20202020202020202020202068746D6C202B3D20273C64697620636C6173733D22617065782D6974656D2D67726F757020617065782D6974656D2D67726F75702D2D73687574746C6520617065787261642D7373692D73687574746C652220726F6C653D2267726F757022273B0A20202020202020202020202068746D6C202B3D20272069643D2227202B20636F6E7461696E65724964202B20272220646174612D6C6162656C732D706F733D22';
wwv_flow_imp.g_varchar2_table(24) := '27202B206F7074732E6C6162656C73506F73202B202722273B0A20202020202020202020202068746D6C202B3D202720617269612D6C6162656C6C656462793D2227202B20704974656D4964202B20275F4C4142454C2220746162696E6465783D222D31223E273B0A202020202020202020202020696620286F7074732E73686F7746696C74657229207B0A2020202020202020202020202020202068746D6C202B3D20273C64697620636C6173733D22617065787261642D7373692D66696C7465722D726F7722';
wwv_flow_imp.g_varchar2_table(25) := '2069643D2227202B20706678202B20275F46494C5445525F524F57223E273B0A2020202020202020202020202020202068746D6C202B3D20273C696E70757420747970653D2274657874222069643D2227202B2066696C746572496E704964202B20272220706C616365686F6C6465723D2227202B206F7074732E706C616365686F6C646572202B202722273B0A2020202020202020202020202020202068746D6C202B3D202720636C6173733D22746578745F6669656C6420617065782D6974656D2D74657874';
wwv_flow_imp.g_varchar2_table(26) := '20617065787261642D7373692D66696C7465722D696E70757422206175746F636F6D706C6574653D226F6666222F3E273B0A2020202020202020202020202020202068746D6C202B3D20273C6120636C6173733D22612D427574746F6E20612D427574746F6E2D2D706F7075704C4F56222069643D2227202B2066696C74657242746E4964202B202722273B0A2020202020202020202020202020202068746D6C202B3D202720617269612D6C6162656C3D2246696C74657222207469746C653D2246696C746572';
wwv_flow_imp.g_varchar2_table(27) := '2220687265663D226A6176617363726970743A766F69642830293B223E273B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2266612066612D66696C746572223E3C2F7370616E3E3C2F613E273B0A2020202020202020202020202020202068746D6C202B3D20273C6120636C6173733D22612D427574746F6E20612D427574746F6E2D2D706F7075704C4F56222069643D2227202B2066696C746572436C724964202B202722273B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(28) := '202020202068746D6C202B3D202720617269612D6C6162656C3D22436C65617222207469746C653D22436C6561722220687265663D226A6176617363726970743A766F69642830293B223E273B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2266612066612D74696D6573223E3C2F7370616E3E3C2F613E273B0A2020202020202020202020202020202068746D6C202B3D20273C2F6469763E273B0A2020202020202020202020207D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(29) := '20202068746D6C202B3D20273C7461626C652063656C6C70616464696E673D2230222063656C6C73706163696E673D22302220626F726465723D22302220726F6C653D2270726573656E746174696F6E2220636C6173733D2273687574746C65223E3C74626F64793E3C74723E273B0A2020202020202020202020202F2F204C6566742070616E656C0A20202020202020202020202068746D6C202B3D20273C746420636C6173733D2273687574746C6553656C65637431223E273B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(30) := '20696620286F7074732E6C6162656C73506F7320213D3D2027626F74746F6D2729207B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C312D636F756E74223E27202B206F7074732E6C656674436F756E744C6162656C202B20273A203C6C6162656C20636C6173733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E303C2F6C6162656C3E3C2F7370616E3E273B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(31) := '207D0A20202020202020202020202068746D6C202B3D20273C73656C656374207469746C653D224D6F76652066726F6D22206D756C7469706C652069643D2227202B206C65667453656C4964202B2027222073697A653D2231302220636C6173733D2273687574746C655F6C65667420617065782D6974656D2D73656C656374223E3C2F73656C6563743E273B0A202020202020202020202020696620286F7074732E6C6162656C73506F73203D3D3D2027626F74746F6D2729207B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(32) := '202020202068746D6C202B3D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C312D636F756E74223E27202B206F7074732E6C656674436F756E744C6162656C202B20273A203C6C6162656C20636C6173733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E303C2F6C6162656C3E3C2F7370616E3E273B0A2020202020202020202020207D0A20202020202020202020202068746D6C202B3D20273C2F74643E273B0A2020202020202020202020202F2F20';
wwv_flow_imp.g_varchar2_table(33) := '436F6E74726F6C20627574746F6E730A20202020202020202020202068746D6C202B3D20273C746420616C69676E3D2263656E7465722220636C6173733D2273687574746C65436F6E74726F6C223E3C7370616E20636C6173733D2273687574746C65436F6E74726F6C2D636F756E74223E266E6273703B3C2F7370616E3E273B0A20202020202020202020202076617220627574746F6E73203D205B5B275245534554272C275265736574272C277265736574275D5D3B0A202020202020202020202020696620';
wwv_flow_imp.g_varchar2_table(34) := '286F7074732E616C6C6F7741646429207B0A20202020202020202020202020202020627574746F6E732E70757368285B274D4F56455F414C4C272C274D6F766520416C6C272C276D6F76652D616C6C275D293B0A20202020202020202020202020202020627574746F6E732E70757368285B274D4F5645272C274D6F7665272C276D6F7665275D293B0A2020202020202020202020207D0A202020202020202020202020696620286F7074732E616C6C6F7744656C29207B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(35) := '20627574746F6E732E70757368285B2752454D4F5645272C2752656D6F7665272C2772656D6F7665275D293B0A20202020202020202020202020202020627574746F6E732E70757368285B2752454D4F56455F414C4C272C2752656D6F766520416C6C272C2772656D6F76652D616C6C275D293B0A2020202020202020202020207D0A202020202020202020202020627574746F6E732E666F72456163682866756E6374696F6E2862297B0A2020202020202020202020202020202068746D6C202B3D20273C6275';
wwv_flow_imp.g_varchar2_table(36) := '74746F6E2069643D2227202B20704974656D4964202B20275F27202B20625B305D202B202722273B0A2020202020202020202020202020202068746D6C202B3D202720636C6173733D22612D427574746F6E20612D427574746F6E2D2D6E6F4C6162656C20612D427574746F6E2D2D7769746849636F6E20612D427574746F6E2D2D736D616C6C20612D427574746F6E2D2D6E6F554920612D427574746F6E2D2D73687574746C6522273B0A2020202020202020202020202020202068746D6C202B3D2027207479';
wwv_flow_imp.g_varchar2_table(37) := '70653D22627574746F6E22207469746C653D2227202B20625B315D202B20272220617269612D6C6162656C3D2227202B20625B315D202B2027223E273B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D22612D49636F6E2069636F6E2D73687574746C652D27202B20625B325D202B20272220617269612D68696464656E3D2274727565223E3C2F7370616E3E3C2F627574746F6E3E273B0A2020202020202020202020207D293B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(38) := '68746D6C202B3D20273C2F74643E273B0A2020202020202020202020202F2F2052696768742070616E656C0A20202020202020202020202068746D6C202B3D20273C746420636C6173733D2273687574746C6553656C65637432223E273B0A202020202020202020202020696620286F7074732E6C6162656C73506F7320213D3D2027626F74746F6D2729207B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E';
wwv_flow_imp.g_varchar2_table(39) := '74223E27202B206F7074732E7269676874436E744C6162656C202B20273A203C6C6162656C20636C6173733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E303C2F6C6162656C3E3C2F7370616E3E273B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E7422207374796C653D2270616464696E672D6C6566743A2E35656D3B223E27202B206F7074732E6E6577436F756E744C';
wwv_flow_imp.g_varchar2_table(40) := '6162656C202B20273A203C6C6162656C20636C6173733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E303C2F6C6162656C3E3C2F7370616E3E273B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E7422207374796C653D2270616464696E672D6C6566743A2E35656D3B223E27202B206F7074732E7361766564436F756E744C6162656C202B20273A203C6C6162656C20636C';
wwv_flow_imp.g_varchar2_table(41) := '6173733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E303C2F6C6162656C3E3C2F7370616E3E273B0A2020202020202020202020207D0A20202020202020202020202068746D6C202B3D20273C73656C656374207469746C653D224D6F766520746F22206D756C7469706C652069643D2227202B20726967687453656C4964202B202722206E616D653D2227202B2028617065784974656D4E6F64652E6E616D65207C7C20696E7075744E616D6529202B2027222073697A653D22';
wwv_flow_imp.g_varchar2_table(42) := '31302220636C6173733D2273687574746C655F726967687420617065782D6974656D2D73656C656374223E3C2F73656C6563743E273B0A202020202020202020202020696620286F7074732E6C6162656C73506F73203D3D3D2027626F74746F6D2729207B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E74223E27202B206F7074732E7269676874436E744C6162656C202B20273A203C6C6162656C20636C';
wwv_flow_imp.g_varchar2_table(43) := '6173733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E303C2F6C6162656C3E3C2F7370616E3E273B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E7422207374796C653D2270616464696E672D6C6566743A2E35656D3B223E27202B206F7074732E6E6577436F756E744C6162656C202B20273A203C6C6162656C20636C6173733D2227202B206F7074732E636F756E744C61';
wwv_flow_imp.g_varchar2_table(44) := '62656C436C617373202B2027223E303C2F6C6162656C3E3C2F7370616E3E273B0A2020202020202020202020202020202068746D6C202B3D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E7422207374796C653D2270616464696E672D6C6566743A2E35656D3B223E27202B206F7074732E7361766564436F756E744C6162656C202B20273A203C6C6162656C20636C6173733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E303C2F6C61';
wwv_flow_imp.g_varchar2_table(45) := '62656C3E3C2F7370616E3E273B0A2020202020202020202020207D0A20202020202020202020202068746D6C202B3D20273C2F74643E273B0A2020202020202020202020202F2F20536F727420627574746F6E730A20202020202020202020202068746D6C202B3D20273C746420616C69676E3D2263656E7465722220636C6173733D2273687574746C65536F727432223E3C7370616E20636C6173733D2273687574746C65436F6E74726F6C2D636F756E74223E266E6273703B3C2F7370616E3E273B0A202020';
wwv_flow_imp.g_varchar2_table(46) := '2020202020202020205B5B27544F50272C27546F70275D2C5B275550272C275570275D2C5B27444F574E272C27446F776E275D2C5B27424F54544F4D272C27426F74746F6D275D5D2E666F72456163682866756E6374696F6E2862297B0A2020202020202020202020202020202068746D6C202B3D20273C627574746F6E2069643D2227202B20704974656D4964202B20275F27202B20625B305D202B202722273B0A2020202020202020202020202020202068746D6C202B3D202720636C6173733D22612D4275';
wwv_flow_imp.g_varchar2_table(47) := '74746F6E20612D427574746F6E2D2D6E6F4C6162656C20612D427574746F6E2D2D7769746849636F6E20612D427574746F6E2D2D736D616C6C20612D427574746F6E2D2D6E6F554920612D427574746F6E2D2D73687574746C6522273B0A2020202020202020202020202020202068746D6C202B3D202720747970653D22627574746F6E22207469746C653D2227202B20625B315D202B20272220617269612D6C6162656C3D2227202B20625B315D202B2027223E273B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(48) := '68746D6C202B3D20273C7370616E20636C6173733D22612D49636F6E2069636F6E2D73687574746C652D27202B20625B315D2E746F4C6F776572436173652829202B20272220617269612D68696464656E3D2274727565223E3C2F7370616E3E3C2F627574746F6E3E273B0A2020202020202020202020207D293B0A20202020202020202020202068746D6C202B3D20273C2F74643E273B0A20202020202020202020202068746D6C202B3D20273C2F74723E3C2F74626F64793E3C2F7461626C653E3C2F646976';
wwv_flow_imp.g_varchar2_table(49) := '3E273B0A0A202020202020202020202020616E63686F72456C2E696E7365727441646A6163656E7448544D4C28276166746572656E64272C2068746D6C293B0A0A202020202020202020202020766172206C65667453656C20203D20646F63756D656E742E676574456C656D656E7442794964286C65667453656C4964293B0A20202020202020202020202076617220726967687453656C203D20646F63756D656E742E676574456C656D656E744279496428726967687453656C4964293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(50) := '2020202069662028216C65667453656C207C7C2021726967687453656C29207B2072657475726E3B207D0A0A2020202020202020202020202F2F20E29480E2948020537461746520E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294';
wwv_flow_imp.g_varchar2_table(51) := '80E29480E29480E29480E29480E29480E29480E29480E29480E294800A202020202020202020202020766172205F7361766564436F756E74203D20303B20202F2F20444220636F756E742066726F6D20544152474554205441424C450A202020202020202020202020766172205F6E6577436F756E742020203D20303B20202F2F20633030333D274E455727206974656D7320286D6F7665642C206E6F74207361766564290A202020202020202020202020766172205F746F74616C436E742020203D20303B2020';
wwv_flow_imp.g_varchar2_table(52) := '2F2F20746F74616C20636F6C6C656374696F6E2073697A650A0A20202020202020202020202066756E6374696F6E205F7570646174654C6162656C73286E6577436F756E742C207361766564436F756E742C20746F74616C436E7429207B0A20202020202020202020202020202020696620286E6577436F756E74202020213D3D20756E646566696E6564202626206E6577436F756E74202020213D3D206E756C6C29207B205F6E6577436F756E742020203D204E756D626572286E6577436F756E74292020207C';
wwv_flow_imp.g_varchar2_table(53) := '7C20303B207D0A20202020202020202020202020202020696620287361766564436F756E7420213D3D20756E646566696E6564202626207361766564436F756E7420213D3D206E756C6C29207B205F7361766564436F756E74203D204E756D626572287361766564436F756E7429207C7C20303B207D0A2020202020202020202020202020202069662028746F74616C436E74202020213D3D20756E646566696E656420262620746F74616C436E74202020213D3D206E756C6C29207B205F746F74616C436E7420';
wwv_flow_imp.g_varchar2_table(54) := '20203D204E756D62657228746F74616C436E74292020207C7C20303B207D0A202020202020202020202020202020202428272327202B20636F6E7461696E65724964202B2027202E73687574746C65436F6E74726F6C2D636F756E7427292E72656D6F766528293B0A202020202020202020202020202020202428272327202B20636F6E7461696E65724964202B2027202E73687574746C65436F6E74726F6C312D636F756E7427292E72656D6F766528293B0A2020202020202020202020202020202024282723';
wwv_flow_imp.g_varchar2_table(55) := '27202B20636F6E7461696E65724964202B2027202E73687574746C65436F6E74726F6C322D636F756E7427292E72656D6F766528293B0A20202020202020202020202020202020766172206C63203D206C65667453656C2E6C656E6774683B0A202020202020202020202020202020202428272327202B20636F6E7461696E65724964202B2027202E73687574746C65436F6E74726F6C27292E70726570656E6428273C7370616E20636C6173733D2273687574746C65436F6E74726F6C2D636F756E74223E266E';
wwv_flow_imp.g_varchar2_table(56) := '6273703B3C2F7370616E3E27293B0A202020202020202020202020202020202428272327202B20636F6E7461696E65724964202B2027202E73687574746C65536F72743227292E70726570656E6428273C7370616E20636C6173733D2273687574746C65436F6E74726F6C2D636F756E74223E266E6273703B3C2F7370616E3E27293B0A202020202020202020202020202020202F2F204C6566742070616E656C206C6162656C0A20202020202020202020202020202020766172206C626C31203D20273C737061';
wwv_flow_imp.g_varchar2_table(57) := '6E20636C6173733D2273687574746C65436F6E74726F6C312D636F756E74223E27202B206F7074732E6C656674436F756E744C6162656C202B20273A203C6C6162656C20636C6173733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E27202B206C63202B20273C2F6C6162656C3E3C2F7370616E3E273B0A20202020202020202020202020202020696620286F7074732E6C6162656C73506F73203D3D3D2027626F74746F6D2729207B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(58) := '202020202428272327202B20636F6E7461696E65724964202B2027202E73687574746C6553656C6563743127292E617070656E64286C626C31293B0A202020202020202020202020202020207D20656C7365207B0A20202020202020202020202020202020202020202428272327202B20636F6E7461696E65724964202B2027202E73687574746C6553656C6563743127292E70726570656E64286C626C31293B0A202020202020202020202020202020207D0A202020202020202020202020202020202F2F2052';
wwv_flow_imp.g_varchar2_table(59) := '696768742070616E656C206C6162656C733A20436F756E74207C2053656C656374656420436F756E74207C20536176656420436F756E740A20202020202020202020202020202020766172206C626C5F636E7420203D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E74223E272020202020202020202020202020202020202020202020202B206F7074732E7269676874436E744C6162656C2020202B20273A203C6C6162656C20636C6173733D2227202B206F7074732E';
wwv_flow_imp.g_varchar2_table(60) := '636F756E744C6162656C436C617373202B2027223E27202B205F746F74616C436E742020202B20273C2F6C6162656C3E3C2F7370616E3E273B0A20202020202020202020202020202020766172206C626C5F73656C20203D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E7422207374796C653D2270616464696E672D6C6566743A2E35656D3B223E27202B206F7074732E6E6577436F756E744C6162656C2020202B20273A203C6C6162656C20636C6173733D2227202B';
wwv_flow_imp.g_varchar2_table(61) := '206F7074732E636F756E744C6162656C436C617373202B2027223E27202B205F6E6577436F756E742020202B20273C2F6C6162656C3E3C2F7370616E3E273B0A20202020202020202020202020202020766172206C626C5F73617665203D20273C7370616E20636C6173733D2273687574746C65436F6E74726F6C322D636F756E7422207374796C653D2270616464696E672D6C6566743A2E35656D3B223E27202B206F7074732E7361766564436F756E744C6162656C202B20273A203C6C6162656C20636C6173';
wwv_flow_imp.g_varchar2_table(62) := '733D2227202B206F7074732E636F756E744C6162656C436C617373202B2027223E27202B205F7361766564436F756E74202B20273C2F6C6162656C3E3C2F7370616E3E273B0A20202020202020202020202020202020696620286F7074732E6C6162656C73506F73203D3D3D2027626F74746F6D2729207B0A20202020202020202020202020202020202020202F2F20617070656E6420696E206F726465723A20436F756E742C2053656C656374656420436F756E742C20536176656420436F756E740A20202020';
wwv_flow_imp.g_varchar2_table(63) := '202020202020202020202020202020202428272327202B20636F6E7461696E65724964202B2027202E73687574746C6553656C6563743227292E617070656E64286C626C5F636E74292E617070656E64286C626C5F73656C292E617070656E64286C626C5F73617665293B0A202020202020202020202020202020207D20656C7365207B0A20202020202020202020202020202020202020202F2F2070726570656E6420696E20726576657273653A205361766564206C6173742070726570656E646564203D2062';
wwv_flow_imp.g_varchar2_table(64) := '6F74746F6D2C20436F756E74206669727374203D20746F700A20202020202020202020202020202020202020202428272327202B20636F6E7461696E65724964202B2027202E73687574746C6553656C6563743227292E70726570656E64286C626C5F73617665292E70726570656E64286C626C5F73656C292E70726570656E64286C626C5F636E74293B0A202020202020202020202020202020207D0A2020202020202020202020207D0A0A0A20202020202020202020202066756E6374696F6E205F78303528';
wwv_flow_imp.g_varchar2_table(65) := '29207B0A2020202020202020202020202020202069662028216F7074732E706167654974656D7329207B2072657475726E2027273B207D0A20202020202020202020202020202020766172206974656D73203D206F7074732E706167654974656D732E73706C697428272C27293B0A20202020202020202020202020202020766172207061697273203D205B5D3B0A202020202020202020202020202020206974656D732E666F72456163682866756E6374696F6E286E616D6529207B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(66) := '202020202020202020206E616D65203D206E616D652E7472696D28293B0A2020202020202020202020202020202020202020696620286E616D6529207B2070616972732E70757368286E616D65202B20273D27202B20617065782E6974656D286E616D65292E67657456616C75652829293B207D0A202020202020202020202020202020207D293B0A2020202020202020202020202020202072657475726E2070616972732E6A6F696E28277C27293B0A2020202020202020202020207D0A0A2020202020202020';
wwv_flow_imp.g_varchar2_table(67) := '2020202066756E6374696F6E205F63616C6C287830312C207830322C207830332C207830342C207830362C206F6E5375636365737329207B0A20202020202020202020202020202020766172206C5370696E6E657224203D20617065782E7574696C2E73686F775370696E6E6572282428272327202B20636F6E7461696E6572496429293B0A20202020202020202020202020202020617065782E7365727665722E706C7567696E280A20202020202020202020202020202020202020206F7074732E616A617849';
wwv_flow_imp.g_varchar2_table(68) := '64656E7469666965722C0A20202020202020202020202020202020202020207B207830313A207830312C207830323A207830322C207830333A207830332C207830343A207830342C207830353A205F78303528292C207830363A20783036207D2C0A20202020202020202020202020202020202020207B0A202020202020202020202020202020202020202020202020706167654974656D733A206F7074732E706167654974656D73203F20272327202B206F7074732E706167654974656D732E7472696D28292E';
wwv_flow_imp.g_varchar2_table(69) := '7265706C616365282F2C5C732A2F672C20272C232729203A20756E646566696E65642C0A202020202020202020202020202020202020202020202020737563636573733A2066756E6374696F6E286461746129207B0A202020202020202020202020202020202020202020202020202020206C5370696E6E6572242E72656D6F766528293B0A202020202020202020202020202020202020202020202020202020206F6E537563636573732864617461293B0A202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(70) := '2020207D2C0A2020202020202020202020202020202020202020202020206572726F723A2066756E6374696F6E287868722C207374617475732C2065727229207B0A202020202020202020202020202020202020202020202020202020206C5370696E6E6572242E72656D6F766528293B0A20202020202020202020202020202020202020202020202020202020617065782E64656275672E6572726F72282741504558524144205353492027202B20783031202B20273A272C207374617475732C20657272293B';
wwv_flow_imp.g_varchar2_table(71) := '0A2020202020202020202020202020202020202020202020207D0A20202020202020202020202020202020202020207D0A20202020202020202020202020202020293B0A2020202020202020202020207D0A0A2020202020202020202020202F2F20E29480E2948020506F70756C6174652072696768742070616E656C2066726F6D2073657276657220726573706F6E736520E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294';
wwv_flow_imp.g_varchar2_table(72) := '800A20202020202020202020202066756E6374696F6E205F6170706C795269676874286461746129207B0A20202020202020202020202020202020696620282164617461207C7C2021646174612E726967687429207B2072657475726E3B207D0A20202020202020202020202020202020726967687453656C2E6C656E677468203D20303B0A2020202020202020202020202020202076617220726F7773203D20646174612E72696768743B0A20202020202020202020202020202020666F722028766172206920';
wwv_flow_imp.g_varchar2_table(73) := '3D20303B2069203C20726F77732E6C656E6774683B20692B2B29207B0A2020202020202020202020202020202020202020766172206F7074203D206E6577204F7074696F6E28726F77735B695D2E76616C75652C20726F77735B695D2E6964293B0A202020202020202020202020202020202020202069662028726F77735B695D2E666C6167203D3D3D202753415645442729207B0A20202020202020202020202020202020202020202020202024286F7074292E616464436C617373286F7074732E7361766564';
wwv_flow_imp.g_varchar2_table(74) := '436F6C6F72436C617373293B0A20202020202020202020202020202020202020207D20656C7365207B0A20202020202020202020202020202020202020202020202024286F7074292E616464436C6173732827617065787261642D7373692D6E657727293B0A20202020202020202020202020202020202020207D0A2020202020202020202020202020202020202020726967687453656C2E6F7074696F6E735B726967687453656C2E6C656E6774685D203D206F70743B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(75) := '207D0A202020202020202020202020202020202F2F20436F756E74732066726F6D20746F702D6C6576656C204A534F4E206B6579730A20202020202020202020202020202020766172206E6577436E74203D204E756D62657228646174612E6E6577436F756E74292020207C7C20303B0A2020202020202020202020202020202076617220746F74436E74203D204E756D62657228646174612E746F74616C436F756E7429207C7C20303B0A202020202020202020202020202020205F7570646174654C6162656C';
wwv_flow_imp.g_varchar2_table(76) := '73286E6577436E742C20746F74436E74202D206E6577436E742C20746F74436E74293B0A2020202020202020202020207D0A0A2020202020202020202020202F2F20E29480E29480204C4F41445F53415645443A20696E697420636F6C6C656374696F6E2066726F6D20544152474554205441424C4520E286922072696768742070616E656C20E294800A20202020202020202020202066756E6374696F6E205F6C6F616453617665642829207B0A202020202020202020202020202020205F63616C6C28274C4F';
wwv_flow_imp.g_varchar2_table(77) := '41445F5341564544272C20704974656D49642C2027272C2027272C2027272C2066756E6374696F6E286461746129207B0A20202020202020202020202020202020202020205F6170706C7952696768742864617461293B0A20202020202020202020202020202020202020205F66696C6C4C656674282727293B0A202020202020202020202020202020207D293B0A2020202020202020202020207D0A0A2020202020202020202020202F2F20E29480E294802046494C4C5F4C4546543A2072756E204C4F562053';
wwv_flow_imp.g_varchar2_table(78) := '514C20E28692206C6566742070616E656C20E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294800A20202020202020202020202066756E6374696F6E205F66696C6C4C6566742866696C7465725465787429207B0A202020202020202020202020202020205F63616C6C282746494C4C5F4C454654272C20704974656D49642C2066696C74657254657874207C7C2027272C202727';
wwv_flow_imp.g_varchar2_table(79) := '2C2027272C2066756E6374696F6E286461746129207B0A2020202020202020202020202020202020202020696620282164617461207C7C2021646174612E6974656D29207B2072657475726E3B207D0A20202020202020202020202020202020202020206C65667453656C2E6C656E677468203D20303B0A202020202020202020202020202020202020202076617220726F7773203D20646174612E6974656D3B0A2020202020202020202020202020202020202020666F7220287661722069203D20303B206920';
wwv_flow_imp.g_varchar2_table(80) := '3C20726F77732E6C656E6774683B20692B2B29207B0A2020202020202020202020202020202020202020202020206C65667453656C2E6F7074696F6E735B695D203D206E6577204F7074696F6E28726F77735B695D2E76616C75652C20726F77735B695D2E6964293B0A20202020202020202020202020202020202020207D0A20202020202020202020202020202020202020205F7570646174654C6162656C7328293B0A202020202020202020202020202020207D293B0A2020202020202020202020207D0A0A';
wwv_flow_imp.g_varchar2_table(81) := '2020202020202020202020202F2F20E29480E29480204144445F4D454D4245523A206D6F76652073656C6563746564206C656674E2869272696768742076696120636F6C6C656374696F6E20E29480E29480E29480E29480E29480E29480E29480E29480E294800A20202020202020202020202066756E6374696F6E205F6164644D656D626572732829207B0A202020202020202020202020202020207661722073656C6563746564203D2041727261792E66726F6D286C65667453656C2E6F7074696F6E73292E';
wwv_flow_imp.g_varchar2_table(82) := '66696C7465722866756E6374696F6E286F297B2072657475726E206F2E73656C65637465643B207D293B0A202020202020202020202020202020206966202873656C65637465642E6C656E677468203D3D3D203029207B2072657475726E3B207D0A202020202020202020202020202020202F2F20456E666F726365206D61784D6F76653A206C696D6974206974656D73207065722073696E676C65206D6F7665206F7065726174696F6E0A202020202020202020202020202020206966202873656C6563746564';
wwv_flow_imp.g_varchar2_table(83) := '2E6C656E677468203E206F7074732E6D61784D6F766529207B0A2020202020202020202020202020202020202020766172206D7367203D206F7074732E6D61784572724D73672E7265706C6163652827234D4158494D554D2D4D4F564523272C206F7074732E6D61784D6F7665293B0A202020202020202020202020202020202020202069662028747970656F6620706172656E7420213D3D2027756E646566696E65642720262620706172656E742E6170657829207B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(84) := '2020202020202020706172656E742E617065782E6D6573736167652E636C6561724572726F727328293B0A20202020202020202020202020202020202020207D0A2020202020202020202020202020202020202020617065782E6D6573736167652E636C6561724572726F727328293B0A2020202020202020202020202020202020202020617065782E6D6573736167652E73686F774572726F7273285B7B747970653A276572726F72272C6C6F636174696F6E3A2770616765272C6D6573736167653A6D73677D';
wwv_flow_imp.g_varchar2_table(85) := '5D293B0A202020202020202020202020202020202020202072657475726E3B20202F2F204D6F7665204E4F5448494E470A202020202020202020202020202020207D0A202020202020202020202020202020202F2F204275696C6420706970652D736570206368722831292D64656C696D69746564205245543A444953502070616972730A20202020202020202020202020202020766172207061697273203D2073656C65637465642E6D61702866756E6374696F6E286F297B0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(86) := '2020202020202072657475726E206F2E76616C7565202B20537472696E672E66726F6D43686172436F6465283129202B206F2E746578743B0A202020202020202020202020202020207D292E6A6F696E28277C27293B0A202020202020202020202020202020205F63616C6C28274144445F4D454D424552272C20704974656D49642C2027272C2070616972732C2027272C2066756E6374696F6E286461746129207B0A20202020202020202020202020202020202020205F6170706C7952696768742864617461';
wwv_flow_imp.g_varchar2_table(87) := '293B0A20202020202020202020202020202020202020205F66696C6C4C656674282428272327202B2066696C746572496E704964292E76616C2829207C7C202727293B0A202020202020202020202020202020207D293B0A2020202020202020202020207D0A0A20202020202020202020202066756E6374696F6E205F616464416C6C4D656D626572732829207B0A2020202020202020202020202020202076617220616C6C203D2041727261792E66726F6D286C65667453656C2E6F7074696F6E73293B0A2020';
wwv_flow_imp.g_varchar2_table(88) := '202020202020202020202020202069662028616C6C2E6C656E677468203D3D3D203029207B2072657475726E3B207D0A202020202020202020202020202020202F2F20456E666F726365206D61784D6F76653A206C696D6974206974656D73207065722073696E676C65206D6F76652D616C6C206F7065726174696F6E0A2020202020202020202020202020202069662028616C6C2E6C656E677468203E206F7074732E6D61784D6F766529207B0A2020202020202020202020202020202020202020766172206D';
wwv_flow_imp.g_varchar2_table(89) := '7367203D206F7074732E6D61784572724D73672E7265706C6163652827234D4158494D554D2D4D4F564523272C206F7074732E6D61784D6F7665293B0A202020202020202020202020202020202020202069662028747970656F6620706172656E7420213D3D2027756E646566696E65642720262620706172656E742E6170657829207B0A202020202020202020202020202020202020202020202020706172656E742E617065782E6D6573736167652E636C6561724572726F727328293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(90) := '2020202020202020202020207D0A2020202020202020202020202020202020202020617065782E6D6573736167652E636C6561724572726F727328293B0A2020202020202020202020202020202020202020617065782E6D6573736167652E73686F774572726F7273285B7B747970653A276572726F72272C6C6F636174696F6E3A2770616765272C6D6573736167653A6D73677D5D293B0A202020202020202020202020202020202020202072657475726E3B20202F2F204D6F7665204E4F5448494E470A2020';
wwv_flow_imp.g_varchar2_table(91) := '20202020202020202020202020207D0A20202020202020202020202020202020766172207061697273203D20616C6C2E6D61702866756E6374696F6E286F297B0A202020202020202020202020202020202020202072657475726E206F2E76616C7565202B20537472696E672E66726F6D43686172436F6465283129202B206F2E746578743B0A202020202020202020202020202020207D292E6A6F696E28277C27293B0A202020202020202020202020202020205F63616C6C28274144445F4D454D424552272C';
wwv_flow_imp.g_varchar2_table(92) := '20704974656D49642C2027272C2070616972732C2027272C2066756E6374696F6E286461746129207B0A20202020202020202020202020202020202020205F6170706C7952696768742864617461293B0A20202020202020202020202020202020202020205F66696C6C4C656674282428272327202B2066696C746572496E704964292E76616C2829207C7C202727293B0A202020202020202020202020202020207D293B0A2020202020202020202020207D0A0A2020202020202020202020202F2F20E29480E2';
wwv_flow_imp.g_varchar2_table(93) := '94802052454D4F56455F4D454D4245523A206D6F76652073656C6563746564207269676874E286926C6566742076696120636F6C6C656374696F6E20E29480E29480E29480E29480E29480E294800A20202020202020202020202066756E6374696F6E205F72656D6F76654D656D626572732829207B0A202020202020202020202020202020207661722073656C6563746564203D2041727261792E66726F6D28726967687453656C2E6F7074696F6E73292E66696C7465722866756E6374696F6E286F297B2072';
wwv_flow_imp.g_varchar2_table(94) := '657475726E206F2E73656C65637465643B207D293B0A202020202020202020202020202020206966202873656C65637465642E6C656E677468203D3D3D203029207B2072657475726E3B207D0A202020202020202020202020202020207661722076616C73203D2073656C65637465642E6D61702866756E6374696F6E286F297B2072657475726E206F2E76616C75653B207D292E6A6F696E28277C27293B0A202020202020202020202020202020205F63616C6C282752454D4F56455F4D454D424552272C2070';
wwv_flow_imp.g_varchar2_table(95) := '4974656D49642C2027272C2076616C732C2027272C2066756E6374696F6E286461746129207B0A20202020202020202020202020202020202020205F6170706C7952696768742864617461293B0A20202020202020202020202020202020202020205F66696C6C4C656674282428272327202B2066696C746572496E704964292E76616C2829207C7C202727293B0A202020202020202020202020202020207D293B0A2020202020202020202020207D0A0A20202020202020202020202066756E6374696F6E205F';
wwv_flow_imp.g_varchar2_table(96) := '72656D6F7665416C6C4D656D626572732829207B0A2020202020202020202020202020202069662028726967687453656C2E6C656E677468203D3D3D203029207B2072657475726E3B207D0A202020202020202020202020202020207661722076616C73203D2041727261792E66726F6D28726967687453656C2E6F7074696F6E73292E6D61702866756E6374696F6E286F297B2072657475726E206F2E76616C75653B207D292E6A6F696E28277C27293B0A202020202020202020202020202020205F63616C6C';
wwv_flow_imp.g_varchar2_table(97) := '282752454D4F56455F4D454D424552272C20704974656D49642C2027272C2076616C732C2027272C2066756E6374696F6E286461746129207B0A20202020202020202020202020202020202020205F6170706C7952696768742864617461293B0A20202020202020202020202020202020202020205F66696C6C4C656674282428272327202B2066696C746572496E704964292E76616C2829207C7C202727293B0A202020202020202020202020202020207D293B0A2020202020202020202020207D0A0A202020';
wwv_flow_imp.g_varchar2_table(98) := '2020202020202020202F2F20E29480E294802052454F524445523A2073796E632072696768742070616E656C206F7264657220746F20636F6C6C656374696F6E20E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294800A20202020202020202020202066756E6374696F6E205F72656F726465722829207B0A202020202020202020202020202020207661722076616C73203D2041727261792E66726F6D28726967687453656C2E6F7074696F6E7329';
wwv_flow_imp.g_varchar2_table(99) := '2E6D61702866756E6374696F6E286F297B2072657475726E206F2E76616C75653B207D292E6A6F696E28277C27293B0A202020202020202020202020202020205F63616C6C282752454F52444552272C20704974656D49642C2027272C2076616C732C2027272C2066756E6374696F6E286461746129207B0A20202020202020202020202020202020202020202F2F204E6F20554920757064617465206E6565646564202D206F7264657220616C72656164792073686F776E20696E20444F4D0A20202020202020';
wwv_flow_imp.g_varchar2_table(100) := '2020202020202020207D293B0A2020202020202020202020207D0A0A2020202020202020202020202F2F20E29480E2948020536F72742072696768742070616E656C2028444F4D206F6E6C792C207468656E2073796E632920E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294800A20202020202020202020202066756E6374696F6E205F736F727453656C2864697229207B0A20202020202020';
wwv_flow_imp.g_varchar2_table(101) := '202020202020202020766172206F70747332203D2041727261792E66726F6D28726967687453656C2E6F7074696F6E73293B0A2020202020202020202020202020202069662028646972203D3D3D2027746F702729207B0A20202020202020202020202020202020202020206F707473322E66696C7465722866756E6374696F6E286F297B72657475726E206F2E73656C65637465643B7D292E7265766572736528290A2020202020202020202020202020202020202020202020202E666F72456163682866756E';
wwv_flow_imp.g_varchar2_table(102) := '6374696F6E286F297B20726967687453656C2E696E736572744265666F7265286F2C20726967687453656C2E6F7074696F6E735B305D293B207D293B0A202020202020202020202020202020207D20656C73652069662028646972203D3D3D2027626F74746F6D2729207B0A20202020202020202020202020202020202020206F707473322E66696C7465722866756E6374696F6E286F297B72657475726E206F2E73656C65637465643B7D290A2020202020202020202020202020202020202020202020202E66';
wwv_flow_imp.g_varchar2_table(103) := '6F72456163682866756E6374696F6E286F297B20726967687453656C2E617070656E644368696C64286F293B207D293B0A202020202020202020202020202020207D20656C73652069662028646972203D3D3D202775702729207B0A2020202020202020202020202020202020202020666F7220287661722069203D20313B2069203C20726967687453656C2E6F7074696F6E732E6C656E6774683B20692B2B29207B0A20202020202020202020202020202020202020202020202069662028726967687453656C';
wwv_flow_imp.g_varchar2_table(104) := '2E6F7074696F6E735B695D2E73656C65637465642026262021726967687453656C2E6F7074696F6E735B692D315D2E73656C656374656429207B0A20202020202020202020202020202020202020202020202020202020726967687453656C2E696E736572744265666F726528726967687453656C2E6F7074696F6E735B695D2C20726967687453656C2E6F7074696F6E735B692D315D293B0A2020202020202020202020202020202020202020202020207D0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(105) := '7D0A202020202020202020202020202020207D20656C73652069662028646972203D3D3D2027646F776E2729207B0A2020202020202020202020202020202020202020666F7220287661722069203D20726967687453656C2E6F7074696F6E732E6C656E6774682D323B2069203E3D20303B20692D2D29207B0A20202020202020202020202020202020202020202020202069662028726967687453656C2E6F7074696F6E735B695D2E73656C65637465642026262021726967687453656C2E6F7074696F6E735B';
wwv_flow_imp.g_varchar2_table(106) := '692B315D2E73656C656374656429207B0A20202020202020202020202020202020202020202020202020202020726967687453656C2E696E736572744265666F726528726967687453656C2E6F7074696F6E735B692B315D2C20726967687453656C2E6F7074696F6E735B695D293B0A2020202020202020202020202020202020202020202020207D0A20202020202020202020202020202020202020207D0A202020202020202020202020202020207D0A202020202020202020202020202020205F7570646174';
wwv_flow_imp.g_varchar2_table(107) := '654C6162656C7328293B0A202020202020202020202020202020202F2F204E6F74653A205F72656F7264657228292064656C696265726174656C79204E4F542063616C6C656420686572652E0A202020202020202020202020202020202F2F20436F6C6C656374696F6E206F726465722069732073796E636564206F6E6C79206F6E20534156452E0A202020202020202020202020202020202F2F20546869732070726576656E747320756E6E656365737361727920414A4158206F6E20657665727920736F7274';
wwv_flow_imp.g_varchar2_table(108) := '20636C69636B2E0A2020202020202020202020207D0A0A2020202020202020202020202F2F20E29480E29480205769726520627574746F6E7320E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294800A202020';
wwv_flow_imp.g_varchar2_table(109) := '2020202020202020202428272327202B20704974656D4964202B20275F4D4F564527292E6F6E2827636C69636B272C2020202020202066756E6374696F6E28297B205F6164644D656D6265727328293B207D293B0A2020202020202020202020202428272327202B20704974656D4964202B20275F4D4F56455F414C4C27292E6F6E2827636C69636B272C20202066756E6374696F6E28297B205F616464416C6C4D656D6265727328293B207D293B0A2020202020202020202020202428272327202B2070497465';
wwv_flow_imp.g_varchar2_table(110) := '6D4964202B20275F52454D4F564527292E6F6E2827636C69636B272C202020202066756E6374696F6E28297B205F72656D6F76654D656D6265727328293B207D293B0A2020202020202020202020202428272327202B20704974656D4964202B20275F52454D4F56455F414C4C27292E6F6E2827636C69636B272C2066756E6374696F6E28297B205F72656D6F7665416C6C4D656D6265727328293B207D293B0A2020202020202020202020202428272327202B20704974656D4964202B20275F544F5027292E6F';
wwv_flow_imp.g_varchar2_table(111) := '6E2827636C69636B272C202020202020202066756E6374696F6E28297B205F736F727453656C2827746F7027293B207D293B0A2020202020202020202020202428272327202B20704974656D4964202B20275F555027292E6F6E2827636C69636B272C20202020202020202066756E6374696F6E28297B205F736F727453656C2827757027293B207D293B0A2020202020202020202020202428272327202B20704974656D4964202B20275F444F574E27292E6F6E2827636C69636B272C2020202020202066756E';
wwv_flow_imp.g_varchar2_table(112) := '6374696F6E28297B205F736F727453656C2827646F776E27293B207D293B0A2020202020202020202020202428272327202B20704974656D4964202B20275F424F54544F4D27292E6F6E2827636C69636B272C202020202066756E6374696F6E28297B205F736F727453656C2827626F74746F6D27293B207D293B0A2020202020202020202020202428272327202B20704974656D4964202B20275F524553455427292E6F6E2827636C69636B272C2066756E6374696F6E2829207B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(113) := '20202020206C65667453656C2E6C656E677468203D20303B20726967687453656C2E6C656E677468203D20303B0A202020202020202020202020202020205F6E6577436F756E74203D20303B205F7570646174654C6162656C732830293B205F6C6F6164536176656428293B0A2020202020202020202020207D293B0A20202020202020202020202024286C65667453656C292E6F6E282764626C636C69636B272C202066756E6374696F6E28297B205F6164644D656D6265727328293B207D293B0A2020202020';
wwv_flow_imp.g_varchar2_table(114) := '202020202020202428726967687453656C292E6F6E282764626C636C69636B272C2066756E6374696F6E28297B205F72656D6F76654D656D6265727328293B207D293B0A0A2020202020202020202020202F2F20E29480E294802046696C7465722062617220E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294';
wwv_flow_imp.g_varchar2_table(115) := '80E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294800A202020202020202020202020696620286F7074732E73686F7746696C74657229207B0A202020202020202020202020202020202428646F63756D656E74292E6F6E2827636C69636B272C20272327202B2066696C74657242746E49642C2066756E6374696F6E28297B205F66696C6C4C6566742824282723272B66696C746572496E704964292E76616C2829293B207D293B0A202020202020';
wwv_flow_imp.g_varchar2_table(116) := '202020202020202020202428646F63756D656E74292E6F6E28276B65797570272C20272327202B2066696C746572496E7049642C2066756E6374696F6E2865297B20696628652E6B6579436F64653D3D3D3133297B5F66696C6C4C65667428242874686973292E76616C2829293B7D207D293B0A202020202020202020202020202020202428646F63756D656E74292E6F6E2827636C69636B272C20272327202B2066696C746572436C7249642C2066756E6374696F6E28297B2024282723272B66696C74657249';
wwv_flow_imp.g_varchar2_table(117) := '6E704964292E76616C282727293B205F66696C6C4C656674282727293B207D293B0A2020202020202020202020207D0A0A2020202020202020202020202F2F20E29480E2948020496E7374616E636520726567697374727920E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480';
wwv_flow_imp.g_varchar2_table(118) := 'E29480E29480E29480E294800A202020202020202020202020617065787261642E737570657253687574746C654974656D2E5F696E7374616E6365735B704974656D49645D203D207B0A2020202020202020202020202020202073617665446174613A2066756E6374696F6E2863616C6C6261636B466E29207B0A20202020202020202020202020202020202020205F63616C6C282753415645272C20704974656D49642C2027272C2027272C2027272C2066756E6374696F6E286461746129207B0A2020202020';
wwv_flow_imp.g_varchar2_table(119) := '2020202020202020202020202020202020202069662028747970656F662063616C6C6261636B466E203D3D3D202766756E6374696F6E2729207B2063616C6C6261636B466E2864617461293B207D0A2020202020202020202020202020202020202020202020202F2F20416674657220736176653A20636C6561722072696768742070616E656C20696D6D6564696174656C7920286E6F20666C69636B6572290A2020202020202020202020202020202020202020202020202F2F207468656E2072656C6F616420';
wwv_flow_imp.g_varchar2_table(120) := '66726F6D20444220746F207265666C6563742065786163742073617665642073746174650A202020202020202020202020202020202020202020202020696620282164617461207C7C2021646174612E6572726F7229207B0A20202020202020202020202020202020202020202020202020202020726967687453656C2E6C656E677468203D20303B0A202020202020202020202020202020202020202020202020202020205F7570646174654C6162656C7328302C20302C2030293B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(121) := '2020202020202020202020202020202020205F6C6F6164536176656428293B0A2020202020202020202020202020202020202020202020207D0A20202020202020202020202020202020202020207D293B0A202020202020202020202020202020207D2C0A202020202020202020202020202020202F2A0A20202020202020202020202020202020202A2046756C6C2072657365743A2072652D696E697420636F6C6C656374696F6E2066726F6D20544152474554205441424C452E0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(122) := '2020202020202A20446973636172647320616E7920756E736176656420284E455729206974656D732E0A20202020202020202020202020202020202A2F0A20202020202020202020202020202020726573657450616E656C733A2066756E6374696F6E2829207B0A20202020202020202020202020202020202020206C65667453656C2E6C656E677468203D20303B0A2020202020202020202020202020202020202020726967687453656C2E6C656E677468203D20303B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(123) := '20202020205F6E6577436F756E74203D20303B0A20202020202020202020202020202020202020205F7570646174654C6162656C732830293B0A20202020202020202020202020202020202020205F6C6F6164536176656428293B0A202020202020202020202020202020207D2C0A202020202020202020202020202020202F2A0A20202020202020202020202020202020202A2052656672657368206C6566742070616E656C206F6E6C792E2052696768742070616E656C20616E6420636F6C6C656374696F6E';
wwv_flow_imp.g_varchar2_table(124) := '20756E6368616E6765642E0A20202020202020202020202020202020202A205069636B73207570206E657720506172656E74204974656D2873292076616C7565732066726F6D2063757272656E7420706167652073746174652E0A20202020202020202020202020202020202A2F0A20202020202020202020202020202020646F526566726573684C6566743A2066756E6374696F6E2829207B0A20202020202020202020202020202020202020207661722066696C74657254657874203D206F7074732E73686F';
wwv_flow_imp.g_varchar2_table(125) := '7746696C746572203F20282428272327202B2066696C746572496E704964292E76616C2829207C7C20272729203A2027273B0A20202020202020202020202020202020202020205F66696C6C4C6566742866696C74657254657874293B0A202020202020202020202020202020207D0A2020202020202020202020207D3B0A0A2020202020202020202020202F2F20E29480E2948020496E697469616C206C6F616420E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E2';
wwv_flow_imp.g_varchar2_table(126) := '9480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E29480E294800A2020202020202020202020205F6C6F6164536176656428293B0A0A20202020202020207D202F2F20696E69740A202020207D3B202F2F20617065787261642E737570657253687574746C654974656D0A0A7D28617065782E6A51756572792C206170';
wwv_flow_imp.g_varchar2_table(127) := '657829293B0A';
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(8800000100)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_file_name=>'js/apexrad.supershuttleitem.js'
,p_mime_type=>'application/javascript'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/

-- ============================================================
--  Static File: css/apexrad.supershuttleitem.css
-- ============================================================
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A20415045585241442053757065722053687574746C65204974656D202D207632342E322E30202A2F0A0A2F2A20436F756E74206C6162656C73202A2F0A2E617065787261642D7373692D636F756E742D6C6162656C207B0A20202020636F6C6F723A20766172282D2D75742D70616C657474652D64616E6765722C2023666630303030293B0A20202020666F6E742D7765696768743A203630303B0A7D0A0A2F2A20536176656420726F777320696E2072696768742070616E656C202D20626C7565202A2F0A';
wwv_flow_imp.g_varchar2_table(2) := '2E617065787261642D7373692D7361766564207B0A20202020636F6C6F723A20766172282D2D75742D70616C657474652D7072696D6172792C2023343639366663293B0A7D0A0A2F2A204E65776C79206D6F76656420726F777320286E6F742079657420736176656429202D20726564206974616C6963202A2F0A2E617065787261642D7373692D6E6577207B0A20202020636F6C6F723A20236666323832383B0A20202020666F6E742D7374796C653A206974616C69633B0A7D0A0A2F2A2046696C7465722072';
wwv_flow_imp.g_varchar2_table(3) := '6F77202A2F0A2E617065787261642D7373692D66696C7465722D726F77207B0A20202020646973706C61793A20666C65783B0A20202020616C69676E2D6974656D733A2063656E7465723B0A202020206D617267696E2D626F74746F6D3A202E34656D3B0A7D0A0A2E617065787261642D7373692D66696C7465722D726F7720696E7075745B747970653D2274657874225D207B0A20202020666C65783A20312031206175746F3B0A202020206D696E2D77696474683A20303B0A7D0A0A2F2A20436F756E742073';
wwv_flow_imp.g_varchar2_table(4) := '70616E73202A2F0A2E73687574746C65436F6E74726F6C312D636F756E742C0A2E73687574746C65436F6E74726F6C322D636F756E74207B0A20202020666F6E742D73697A653A202E383735656D3B0A20202020636F6C6F723A20766172282D2D75742D636F6D706F6E656E742D746578742D6D757465642D636F6C6F722C2023353535293B0A2020202070616464696E672D626F74746F6D3A202E3235656D3B0A202020206C696E652D6865696768743A20312E343B0A7D0A0A2E73687574746C65436F6E7472';
wwv_flow_imp.g_varchar2_table(5) := '6F6C2D636F756E74207B0A20202020646973706C61793A20626C6F636B3B0A202020206865696768743A20312E34656D3B0A7D0A0A2F2A204C6F6164696E67206F7665726C6179202D2073696E676C65207370696E6E6572202A2F0A2E617065787261642D7373692D6C6F6164696E67207B0A20202020706F736974696F6E3A2072656C61746976653B0A20202020706F696E7465722D6576656E74733A206E6F6E653B0A202020206F7061636974793A20302E363B0A7D0A';
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(8800000101)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_file_name=>'css/apexrad.supershuttleitem.css'
,p_mime_type=>'text/css'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/

-- 18: Use MERGE Statement
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000200)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>18
,p_display_sequence=>95
,p_static_id=>'attribute_18'
,p_prompt=>'MERGE Mode'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_help_text=>'When Yes (default), SAVE inserts new rows then deletes rows no longer in the right panel. When No: deletes all rows matching Target Where Clause then re-inserts all selected rows.'
);
end;
/



-- 19: Allow Add Row
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000300)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>19
,p_display_sequence=>100
,p_static_id=>'attribute_20'
,p_prompt=>'Allow Add Row'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_help_text=>'When Yes (default), MOVE and MOVE ALL buttons are rendered. When No, these buttons are hidden and users cannot move items to the right panel.'
);
end;
/

-- 20: Allow Delete Row
begin
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(8800000310)
,p_plugin_id=>wwv_flow_imp.id(8800000001)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>20
,p_display_sequence=>105
,p_static_id=>'attribute_21'
,p_prompt=>'Allow Delete Row'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_help_text=>'When Yes (default), REMOVE and REMOVE ALL buttons are rendered. When No, these buttons are hidden and users cannot move items back to the left panel.'
);
end;
/
begin
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(8800000301)
,p_plugin_attribute_id=>wwv_flow_imp.id(8800000300)
,p_display_sequence=>10
,p_display_value=>'Add Row'
,p_return_value=>'ADD'
);
end;
/
begin
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(8800000302)
,p_plugin_attribute_id=>wwv_flow_imp.id(8800000300)
,p_display_sequence=>20
,p_display_value=>'Delete Row'
,p_return_value=>'DELETE'
);
end;
/

prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
