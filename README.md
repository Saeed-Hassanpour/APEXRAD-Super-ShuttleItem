# APEXRAD Super Shuttle Item

> Oracle APEX 24.2+ Item Plugin — A feature-rich shuttle component with collection-based selection, dynamic LOV generation, and real-time count labels.

**Version:** 24.2.0  
**Author:** Paya Shetaban Andisheh (APEXRAD)  
**License:** MIT  
**Repository:** https://github.com/Saeed-Hassanpour/APEXRAD-Super-ShuttleItem

---

## Features

- **Collection-based right panel** — uses `APEXRAD_SUPERSHUTTLEITEM` APEX collection as the temporary container for selected items
- **Dynamic LOV SQL** — generated automatically from Source Table, Return Column, Display Column, and Where Clause attributes — no manual SQL required
- **Color-coded items** — blue for items already saved in the target table, red italic for newly moved (unsaved) items
- **Real-time count labels** — Count, Selected Count, and Saved Count labels above (or below) each panel
- **Filter bar** — optional text filter above the left panel with configurable placeholder
- **Maximum Move** — configurable limit on items movable per operation with a customizable error message
- **Labels Position** — display labels above or below the shuttle panels
- **Parent Item(s)** — submit page item values (e.g. P6_COUNTRY) with every AJAX call so :BIND variables in Source Where Clause resolve correctly
- **RTL support** — layout works correctly in right-to-left pages

---

## Installation

1. Download `item_plugin_info_apexrad_superschuttleitem.sql`
2. In your APEX application: **Shared Components → Plug-ins → Import**
3. Import the SQL file
4. Add the item to any page, set **Type** to **APEXRAD Super Shuttle Item**

---

## Database Setup

### Source Table (left panel data)
```sql
create table SHUTTLE_TEST (
    ID      number primary key,
    NAME    varchar2(200),
    COUNTRY varchar2(100)
);
```

### Target Table (saved selections)
```sql
create table MYTABLE_TEST (
    ID      number generated always as identity primary key,
    CITY_ID number
);
```
> The target table PK is filled automatically by sequence/identity — no PK column attribute needed.

---

## Plugin Attributes

| # | Attribute | Type | Required | Default | Description |
|---|---|---|---|---|---|
| 01 | Show Filter | Checkbox | — | Yes | Show filter input above left panel |
| 02 | Filter Placeholder | Text | — | Enter filter code/description | Placeholder text in filter input |
| 03 | Maximum Move | Integer | — | 1000 | Max items per single move operation (1–1000) |
| 04 | Maximum Error Message | Text | — | Maximum allowed per move is #MAXIMUM-MOVE#... | Error shown when limit exceeded. Use `#MAXIMUM-MOVE#` as placeholder |
| 05 | Labels Position | Select | ✓ | top | `top` = labels above panels, `bottom` = labels below |
| 06 | Left Panel Count Label | Text | — | Count | Label for left panel row count |
| 07 | Right Panel Count Label | Text | — | Count | Label for total right panel item count |
| 08 | Right Panel Saved Count Label | Text | — | Saved Count | Label for rows saved in target table |
| 09 | Right Panel Selected Count Label | Text | — | Selected Count | Label for newly moved (unsaved) items |
| 10 | Parent Item(s) | Page Items | — | — | Page items submitted with AJAX (e.g. `P6_COUNTRY`) |
| 11 | Source Table Name | Text | ✓ | — | Source table for left panel (e.g. `SHUTTLE_TEST`) |
| 12 | Source Return Column (PK) | Text | ✓ | — | Primary key column in source table (e.g. `ID`) |
| 13 | Source Display Column | Text | ✓ | — | Display label column in source table (e.g. `NAME`) |
| 14 | Source Where Clause | Textarea | — | — | Optional WHERE clause for source table (no WHERE keyword). Supports :BIND variables |
| 15 | Target Table Name | Text | ✓ | — | Table storing saved selections (e.g. `MYTABLE_TEST`) |
| 16 | Target Foreign Key Column | Text | ✓ | — | FK column in target table (e.g. `CITY_ID`) |
| 17 | Target Where Clause | Textarea | — | — | Optional WHERE clause scoping target table operations |

---

## Generated LOV SQL

The plugin automatically generates the left panel SQL from Source attributes:

```sql
-- Example: Source Table=SHUTTLE_TEST, PK=ID, Display=NAME, Where=COUNTRY=COALESCE(:P6_COUNTRY,COUNTRY)
select substr(NAME,1,30)||(ID) as display,
       ID as return_val
  from SHUTTLE_TEST
 where COUNTRY = COALESCE(:P6_COUNTRY, COUNTRY)
   and not exists (
         select 1 from apex_collections ac
          where ac.collection_name = 'APEXRAD_SUPERSHUTTLEITEM'
            and ac.c001 = ID
       )
 order by 1
```

---

## Public JavaScript API

```javascript
// Full reset: reloads collection from target table, refreshes both panels
apexrad.superShuttleItem.reset('P6_MY_SHUTTLE');

// Refresh LEFT panel only (right panel and collection preserved)
// Use in Dynamic Action on Parent Item(s) change
apexrad.superShuttleItem.refreshLeft('P6_MY_SHUTTLE');

// Save collection to target table
apexrad.superShuttleItem.save('P6_MY_SHUTTLE', function(data) {
    if (data.error) { apex.message.alert(data.error); }
    else { apex.message.showPageSuccess('Saved ' + data.saved + ' rows'); }
});
```

---

## Dynamic Action Setup

### On Parent Item Change (e.g. P6_COUNTRY)
```
Event:  Change
Item:   P6_COUNTRY
Action: Execute JavaScript Code
Code:   apexrad.superShuttleItem.refreshLeft('P6_MY_SHUTTLE');
```

### Save Button
```
Event:  Click
Button: SAVE_BTN
Action: Execute JavaScript Code
Code:
apexrad.superShuttleItem.save('P6_MY_SHUTTLE', function(data) {
    if (data.error) { apex.message.alert(data.error); }
    else { apex.message.showPageSuccess('Saved ' + data.saved + ' rows'); }
});
```

---

## Collection Structure

| Column | Content |
|---|---|
| `c001` | Return value (source PK) |
| `c002` | Display value (`substr(NAME,1,30)||(ID)`) |
| `c003` | `SAVED` = exists in target table · `NEW` = moved, not yet saved |

---

## Right Panel Colors

| Color | Meaning |
|---|---|
| 🔵 Blue | Item already saved in target table (`c003 = 'SAVED'`) |
| 🔴 Red italic | Newly moved item, not yet saved (`c003 = 'NEW'`) |

---

## Changelog

### 24.2.0
- Initial release for Oracle APEX 24.2
- Dynamic LOV SQL generation from source table attributes
- Collection-based right panel management
- SAVED/NEW color coding
- Three right panel count labels (Count / Selected Count / Saved Count)
- Labels Position (top/bottom)
- Maximum Move limit with custom error message
- apex.util.showSpinner for single loading indicator
