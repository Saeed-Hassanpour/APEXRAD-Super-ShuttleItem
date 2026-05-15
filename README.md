# APEXRAD Super Shuttle Item Plugin v24.2.0
> A feature-rich shuttle component plugin for **Oracle APEX 24.2+** with collection-based selection, dynamic generation, and real-time count labels.
 
**Author:** Saeed Hassanpour — Paya Shetaban Andisheh (APEXRAD)  
**Version:** 24.2.0 
**License:** MIT  
**Repository:** https://github.com/Saeed-Hassanpour/APEXRAD-Super-ShuttleItem

---

![](https://raw.githubusercontent.com/Saeed-Hassanpour/APEXRAD-Super-ShuttleItem/main/images/SuperShuttelItemPlugin.gif)

![](https://github.com/Saeed-Hassanpour/APEXRAD-Super-ShuttleItem/blob/main/images/Super-ShuttleItem-setting.png)

## DEMO ##

[https://oracleapex.com/ords/r/saeedhassanpour/oac/](https://oracleapex.com/ords/r/saeedhassanpour/oac/super-shuttle-item-plugin?)

---

## Features

- **Color-coded items** — blue for items already saved in the target table, red italic for newly moved (unsaved) items
- **Real-time count labels** — Count, Selected Count, and Saved Count labels above (or below) each panel
- **Filter bar** — optional text filter above the left panel with configurable placeholder
- **Maximum Move** — configurable limit on items movable per operation with a customizable error message
- **Labels Position** — display labels above or below the shuttle panels
- **Parent Item(s)** — submit page item values (e.g. P6_COUNTRY) with every AJAX call so :BIND variables in Source Where Clause resolve correctly
- **RTL support** — layout works correctly in right-to-left pages
- **MERGE Mode** - SAVE inserts new rows then deletes rows no longer in the right panel. 

---

## Installation

1. Download `item_plugin_info_apexrad_superschuttleitem.sql`
2. In your APEX application: **Shared Components → Plug-ins → Import**
3. Import the SQL file
4. Add the item to any page, set **Type** to **APEXRAD Super Shuttle Item**

---

##Database Setup (Example)

### Source Table (left panel data)
```sql
CREATE TABLE "SHUTTLE_TEST" 
   (	"ID"      NUMBER NOT NULL ENABLE, --CITY ID
    	"NAME"    VARCHAR2(500 CHAR), 
	    "COUNTRY" VARCHAR2(100 CHAR)
   ) ;
  CREATE UNIQUE INDEX "SHUTTLE_TEST_PK" ON "SHUTTLE_TEST" ("ID");
ALTER TABLE "SHUTTLE_TEST" ADD CONSTRAINT "SHUTTLE_TEST_PK" PRIMARY KEY ("ID")
  USING INDEX "SHUTTLE_TEST_PK"  ENABLE;
```

### Target Table (saved selections)
```sql
create table MYTABLE_TEST (
    ID      number generated always as identity primary key,
    CITY_ID number
);
CREATE UNIQUE INDEX "MYTABLE_TEST_PK" ON "MYTABLE_TEST" ("ID");
ALTER TABLE "MYTABLE_TEST" ADD CONSTRAINT "MYTABLE_TEST_PK" PRIMARY KEY ("ID")
  USING INDEX "MYTABLE_TEST_PK"  ENABLE;

```
> The target table PK is filled automatically by sequence/identity — no PK column attribute needed.

### Import sql file `shuttle_sample_dateset.xlsx`
---

## Plugin Attributes

| # | Attribute | Description |
|---|---|---|
| 01 | Show Filter | Show filter input above left panel |
| 02 | Filter Placeholder | Placeholder text in filter input |
| 03 | Maximum Move | Max items per single move operation (1–1000) |
| 04 | Maximum Error Message | Error shown when limit exceeded. Use `#MAXIMUM-MOVE#` as placeholder |
| 05 | Labels Position | `top` = labels above panels, `bottom` = labels below |
| 06 | Left Panel Count Label | Label for left panel row count |
| 07 | Right Panel Count Label | Label for total right panel item count |
| 08 | Right Panel Saved Count Label | Label for rows saved in target table |
| 09 | Right Panel Selected Count Label | Label for newly moved (unsaved) items |
| 10 | Parent Item(s) | Page items submitted with AJAX (e.g. `P6_COUNTRY`) |
| 11 | Source Table Name | Source table for left panel (e.g. `SHUTTLE_TEST`) |
| 12 | Source Return Column (PK) | Primary key column in source table (e.g. `ID`) |
| 13 | Source Display Column | Display label column in source table (e.g. `NAME`) |
| 14 | Source Where Clause | Optional WHERE clause for source table (no WHERE keyword). Supports :BIND variables |
| 15 | Target Table Name | Table storing saved selections (e.g. `MYTABLE_TEST`) |
| 16 | Target Foreign Key Column | FK column in target table (e.g. `CITY_ID`) |
| 17 | Target Where Clause | Optional WHERE clause scoping target table operations |
| 18 | MERGE Mode | When Yes (default), SAVE inserts new rows then deletes rows no longer in the right panel. When No: deletes all rows matching Target Where Clause then re-inserts all selected rows. |
| 19 | Allow Add Row | MOVE and MOVE ALL buttons are rendered. When No, these buttons are hidden and users cannot move items to the right panel. |
| 20 | Allow Delete Row | REMOVE and REMOVE ALL buttons are rendered. When No, these buttons are hidden and users cannot move items back to the left panel. |

---

## Public JavaScript API

```javascript
// Full reset: reloads collection from target table, refreshes both panels
apexrad.superShuttleItem.reset('MY_SHUTTLE');

// Refresh LEFT panel only (right panel and collection preserved)
// Use in Dynamic Action on Parent Item(s) change
apexrad.superShuttleItem.refreshLeft('MY_SHUTTLE');

// Save collection to target table
apexrad.superShuttleItem.save('MY_SHUTTLE', function(data) {
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

## Right Panel Colors

| Color | Meaning |
|---|---|
| 🔵 Blue | Item already saved in target table |
| 🔴 Red italic | Newly moved item, not yet saved |

---

## Changelog

### 24.2.0
- Initial release for Oracle APEX 24.2
- Dynamic SQL generation from source table attributes
- Collection-based right panel management
- SAVED/NEW color coding
- Three right panel count labels (Count / Selected Count / Saved Count)
- Labels Position (top/bottom)
- Maximum Move limit with custom error message
- MERGE Mode
- Allow Add Row
- Allow Delete Row
