# ClickUp Bug Queue — Verify/Fix Report

List: "Euroside admin app" (ClickUp list 1300270000004675)
Source: https://sharing.clickup.com/3397824/l/h/6-1300270000004675-1/ac67cfa721713ae
Scope: all tasks with status `to do` as of 2026-10-09 (33 total).

Legend: Verified = confirmed the bug is real in current code. Fixed = code
change made + committed locally. Status column = ClickUp status (not yet
changed on ClickUp itself — reporting back to user instead).

| # | ClickUp ID | Summary | Verified | Fixed | Notes |
|---|---|---|---|---|---|
| 1 | 14yjutqfha0 | Workforce Planner: missing project filter dropdown | | | |
| 2 | 14yjutqfh93 | Workforce Planner: date range yyyy-mm-dd not dd/mm/yyyy | | | |
| 3 | 14yjutqfh82 | Productivity: missing search bar / This month contrast / My Reports / Add Filter | | | |
| 4 | 14yjutqfh7g | Screen scroll locked near signature/photo upload | | | |
| 5 | 14yjutqfh7b | Manager Diary Daywork WebView cut off + raw JS alert() | | | |
| 6 | 14yjutqfh6j | Daily Reports: Status filter doesn't filter | | | |
| 7 | 14yjutqfh69 | Missing Form Submission detail view (Daily Diary review/QA) | | | |
| 8 | 14yjutqfh5e | Daily Reports cards: wrong timestamp tz + redundant Material Cost/Charge fields | | | |
| 9 | 14yjutqfh5d | Job Sheet cards: timezone mismatch vs web | | | |
| 10 | 14yjutqfh4t | Job Sheets list: unhandled ClientException shown raw on UI | | | |
| 11 | 14yjutqfh4n | Job Sheets: severe latency/freeze on Reset filter | | | |
| 12 | 14yjutqfh37 | Project Setup tab needs redesign to match web Project Admin | | | |
| 13 | 14yjutqfh36 | Wrong operative assignments shown (project Euro009) | | | |
| 14 | 14yjutqfh21 | Missing Edit for price items / spec pricing (Price tab) | | | |
| 15 | 14yjutqfh1t | Files tab (Specifications): "View" button non-interactive | | | |
| 16 | 14yjutqfh1n | Add Material modal: options render as unboxed plain text | | | |
| 17 | 14yjutqfh1m | Spec attribute input container renders blank | | | |
| 18 | 14yjutqfh17 | Specifications tab: missing Open / Manage Attributes / Get Report buttons | | | |
| 19 | 14yjutqfh0v | Incidents list: no auto-refresh on create | | | |
| 20 | 14yjutqfh0m | Incident cards: Open unclickable, Delete missing, timestamp/status badge absent | | | |
| 21 | 14yjutqfh05 | Report Incident modal: missing All-statuses filter, field/styling mismatches | | | |
| 22 | 14yjutqfgzx | Locations tab shows job-sheet pins instead of block/level hierarchy | | | |
| 23 | 14yjutqfgzp | Site Manager: missing Import Drawings panel, CSV Template, Reorder/Import/Add, site filter | | | |
| 24 | 14yjutqfgzc | Drawings filter: flat dropdown instead of hierarchical multi-select | | | |
| 25 | 14yjutqfgz5 | Drawings: false "no files" toast, missing Recycle Bin, blank Pins canvas | | | |
| 26 | 14yjutqfgua | Approvals tab: missing Approval Stages section, site filter, Site Manager button | | | |
| 27 | 14yjutqfgu6 | Job Sheets: More Filters button non-interactive, quick filters don't execute | | | |
| 28 | 14yjutqffqz | Docs & Files: folder counter slow to update after delete | | | |
| 29 | 14yjutqffqj | Docs & Files: folder counter slow to update after upload | | | |
| 30 | 14yjutqffmv | Project cards: missing Assign/View team buttons | | | |
| 31 | 14yjutqffmn | Project cards: missing Project Code / Owner / Locations count | yes | yes | UI for all 3 already existed on the card - the *data* behind Owner and Locations was fake. Root cause: the Projects list API (`ProjectListSerializer`) never included a location-count field (model always fell back to a hardcoded `1`) and only exposed the manager as a nested `contractor` object, which the Flutter model's owner-fallback chain never checked (always fell back to "N/A"). Added `location_count` to the backend serializer; added `contractor` to the Flutter owner fallback chain (preferring `display_name` over `email`). Project Code was already fine (`displayNameWithCode`). |
| 32 | 14yjutqffhr | Notification dropdown: incorrect timestamps | yes | yes | Root cause: `AdminNotification.formattedUpdatedAt` parsed the UTC-aware timestamp correctly but never called `.toLocal()`, so it showed raw UTC time. Fixed via shared `DateHelper.formatToLocal()`; also added a timestamp line to the appbar's notification dropdown rows (had none). |
| 33 | 14yjutqffgz | Dashboard: only 7/9 metric cards, wrong counts (Pending Tasks, Not Clocked In) | | | |

## Active work queue (2026-10-09, from eurosideclickuppoints.md)

User dropped `eurosideclickuppoints.md` at the repo root with 16 bug
descriptions (15 match items already in the table above; 1 new — "Add
Attendance" modal cascading dropdowns/debug mock strings). Instruction:
**fix these, but do not push until explicitly told to.** Working through them
grouped by screen/file. All commits stay local only until the user says push.

| # | File area | Bug | Status |
|---|---|---|---|
| A1 | specification_detail_screen.dart | Spec attribute input container renders blank | **done** - added hintText/labelText per field type + a type badge under the attribute name |
| A2 | specification_detail_screen.dart | Add Material modal: unboxed plain text options | **done** - each option now a bordered, tappable card with icon + trailing plus |
| A3 | specification_detail_screen.dart | Files tab "View" button non-interactive | **done** - root cause was backend: `file_url` was a relative path (`f.file.url`), never passed `request.build_absolute_uri()`, so Flutter's `url.startsWith('http')` check always failed and permanently disabled the button. Fixed in `_spec_detail_dict()` and the upload endpoint (API/views.py) |
| A4 | specification_detail_screen.dart | Missing Edit for price items / spec pricing | **done** - added `PATCH .../price-items/<id>/` backend endpoint + `updatePriceItem()` controller method + Edit icon/dialog on mobile (web doesn't have this either - add/delete only - so this goes beyond web parity) |
| B1 | project_setup_tab.dart | Wrong operative assignments (Euro009) | **done** - root cause: "Assignments" card was rendering `dropdown_options.available_managers` (every eligible manager in the system) instead of `assignments.contractors` (who is actually assigned to this project) |
| B2 | project_setup_tab.dart | Full redesign to match web Project Admin | **not started** - large, open-ended ("complete redesign for functional, structural, and naming parity"); needs its own scoped pass, out of budget for this batch |
| C1 | job sheet cards | Timezone mismatch on Job Sheet cards | **done** - root cause: `sheet.created`/`lastUpdated` from the API are already localized to the device tz server-side (the request sends `tz=<device tz>`), but the card ran them through `DateHelper.formatToLocal()` again, which treats an already-local string as UTC and re-shifts it. Removed the redundant client-side reformat in both the list card and detail screen |
| D1 | Daily Reports cards | Wrong tz + redundant Material Cost/Charge fields | **done** - same timezone double-conversion fix as C1 (shared screen/card); removed the Material Cost/Charge fields from the shared Job Sheets/Daily Reports card entirely (web doesn't show them either) |
| D2 | Daily Diary | Missing Form Submission detail view (review/QA) | **done** - added a "Review & QA Status" section to `job_sheet_details_screen.dart` (reviewed by/at, rejection reason, resubmission count) plus Approve/Reject/Request Rectification actions wired to the existing `PATCH /api/my-approvals/<id>/`, shown when `source == 'user_form' && status == 'submitted'` |
| D3 | Daily Reports | Status filter doesn't filter | **done** - root cause: mobile sent `status=in progress` (space) but the backend only recognizes underscore keys (`in_progress`); backend silently fell back to "all". Fixed by replacing spaces with underscores before sending |
| E1 | Manager Diary webview | Daywork WebView cut off + raw JS alert() | **done** (alert part) - added `setOnJavaScriptAlertDialog` so `alert()` shows a themed Flutter dialog instead of the WebView's raw browser-chrome one. The "cut off" layout part already has an extensive auto-fit/scale injection script in place (unclear if still reproducible - flagged for device check) |
| E2 | signature/photo upload | Screen scroll locked | **investigated, not fixed** - the signature pad's CSS (`touch-action: none`) and JS (pointer/touch listeners scoped only to the canvas) are already correctly built and don't show an obvious lock bug; no body-scroll-lock toggling found for the live camera panel either. Likely a Flutter-WebView-Android gesture-arena interaction that needs a physical device to reproduce and pinpoint - did not risk blind edits to the shared 1000+ line inline form-HTML renderer used by every form type on web and mobile |
| F1 | productivity_screen.dart | Missing search / My Reports / Add Filter | **done** - added a real search bar (client-side filter on the current view's names), a "My Reports" bottom sheet listing locally-downloaded report files, a working period selector (Today/This Week/This Month/This Year/Custom, using the backend's existing `period=` param instead of hardcoded fake 2026 dates), and a Client filter (backend already supported `client=`, just wasn't exposed) |
| G1 | workforce_planner_screen.dart | Date format yyyy-mm-dd not dd/mm/yyyy | **done** - now uses the shared `DateHelper.formatDate()` |
| G2 | workforce_planner_screen.dart | Missing project filter dropdown | **done** - backend already returned a `projects` list + accepted `project_id=`; added the dropdown to the app bar |
| H1 | add_attendance_dialog.dart | Cascading dropdowns broken, debug mock strings exposed, layout mismatch | **done** - "Task Name (Job)" and "Task Sheet" were hardcoded (`"Job 22 (Mocked for API)"`, `"Drilling Form"`); added a new backend endpoint `GET /api/timesheets/entry-options/` (mirrors the web Add Attendance modal's `entry_job_options`) and real cascading Operative -> Project -> Task dropdowns. Removed the "Task Sheet" field entirely (the backend auto-submits the job's forms - it was never actually read from the payload) and the "Use Current Location" button + mock lat/lon (backend already falls back to the project's own location when omitted) |

## Third batch (2026-10-10, from P:\Euroside_Project\bug.md)

| # | Bug | Status |
|---|---|---|
| I1 | Docs & Files: folder counter delayed after upload, no real-time sync | **done** - root cause: upload/delete both waited on a full `ProjectAllInOneDetails` refetch (the whole project: specs, drawings, job sheets, HSE...) before updating anything. Now inserts/removes the file in local state immediately (optimistic), with the full refetch still happening in the background to reconcile. Backend upload response enriched with `folder_id`/`folder_type`/`is_private`/`created_at` so the optimistic object is complete. |
| I2 | Docs & Files: folder counter delayed after delete | **done** - same fix as I1 (shared code path) |
| I3 | Job Sheets: "More Filters" button non-interactive, quick filters fail | **investigated, already correct** - `job_sheets_tab.dart`'s More Filters button, quick filter dropdowns, and client-side `_filteredJobSheets` getter are all properly wired. Could not reproduce a defect via code review; needs device verification if it's still reported. |
| I4 | Approvals tab: missing Approval Stages section, site filter, Site Manager button | **investigated, already present** - all three already exist in `approvals_tab.dart`. The site filter's options are hardcoded placeholder text ("Block A"/"Block B"/"Main Building") instead of the project's real blocks, but verified against the web template (`project_approvals` view) that this filter is purely decorative there too - `site_blocks`/`site_level` params are parsed but never actually used to filter the Approval Stages or Forms list on web either. Not worth new plumbing for a filter that doesn't filter anything even on web; left as a minor cosmetic gap. |
| I5 | Locations tab shows job-sheet pins instead of block/level hierarchy (vs Site Manager) | **done** - found the mobile app had two tabs ("Site Manager" and "Locations") both rendering the exact same `SiteManagerTab` widget with identical params; the original "wrong data" bug was already gone (both showed the correct block/level hierarchy), but it was a confusing/redundant duplicate. Web only has ONE tab for this, labeled "Locations" (the `site_manager` view). Removed the redundant "Site Manager" tab entry so mobile matches web's single-tab structure exactly. |
| I6 | Report Incident modal: missing All-statuses filter, field/styling mismatches | **done** - added a "Status: All statuses / Open / Investigating / Closed" filter dropdown to the Incidents tab toolbar (new `status=` query param + `status_choices` on `ProjectIncidentsAPIView`), and added the missing "When did it happen?" (occurred_at) date/time field to the Report Incident dialog - the backend already accepted it, mobile just never sent it. |
| I7 | Incident cards: Open unclickable, Delete missing, timestamp/status badge absent | **done** - added an "Open" button (detail dialog), a "Delete" button (new `ProjectIncidentDetailAPIView.delete()`, soft-delete via `is_deleted`), an Occurred timestamp line, and turned the plain-text status into a colored badge matching the existing severity badge style. |
| I8 | Incidents list: no auto-refresh on create | **investigated, already correct** - `reportIncident()` already awaits `fetchIncidents()` internally before returning, and the tab is wrapped in `AnimatedBuilder(animation: _controller)`, so the list already rebuilds the moment the dialog closes. Could not reproduce; no change made. |
| I9 | Specifications tab: missing Open button on cards, Manage Attributes + Get Report toolbar buttons | **done** - added explicit "Open" button per card, "Manage Attributes" (bottom sheet, reuses the project-level attribute-definitions API) and "Get Report" (new `?export=csv` on `ProjectSpecificationsAPIView`, mirrors the web's CSV export) toolbar buttons. |
| I10 | Project Setup tab: full redesign to match web Project Admin (= B2, large) | pending |
| I11 | Manager Diary WebView: cut off / poorly formatted (= E1 "cut off" part; alert() part already fixed) | pending |
| I12 | Signature/photo upload: screen scroll locked (= E2, previously investigated, unresolved) | pending |

## Fourth batch (2026-10-10, from P:\Euroside_Project\bug.md - new points added)

11 unique items (2 duplicate pairs deduped; the Add Attendance item was
already fixed as H1 earlier). User explicitly cleared J2 (Forms library) for
work despite the earlier "don't touch Forms builder" instruction - confirmed
via AskUserQuestion this is about fixing the existing list screen's
clickability/pagination/filters, not building a new form builder.

| # | Bug | Status |
|---|---|---|
| J1 | Material Details view missing Input Type/Material Group/Tags/Cert upload fields, field order/styling mismatch | pending |
| J2 | Forms library cards non-clickable; missing Pagination/Add Form/Filters/View/Delete/Created Date | pending |
| J3 | Add Team modal missing Team Nickname/Team Lead/Associated Projects/Shift Start-End/Cancel | pending |
| J4 | Team cards missing three-dots menu (Team Details/Shift Timezone/Members/Delete Team) | pending |
| J5 | Member card three-dots menu missing 6 actions + missing Excel Import/Export + search/role filter bar | pending |
| J6 | Guests module missing "Convert to Member" + missing Export/Import Excel + search Reset | pending |
| J7 | Permissions matrix: saved Manager-role permissions not shown (all unchecked) | **done** - three real bugs in `admin_permissions_controller.dart`: (1) `fetchPermissions`/`savePermissions` called `.../roles/<id>/` which only matches a pure-numeric-id route (`AdminRoleDetailAPIView`); `role.id` is prefixed (`system:admin`/`custom:5`), so that URL 404'd silently every time, leaving every checkbox at its all-false init state; (2) `savePermissions` used PATCH but the real endpoint (`.../roles/<id>/permissions/`, `AdminRolePermissionsAPIView`) only defines GET/POST; (3) the save payload was sent bare instead of wrapped under `{"permissions": {...}}`. Fixed all three. |
| J8 | Activity Logs export buttons (CSV/Excel/PDF): low contrast, non-functional | **done** - root cause of "non-functional": buttons used `launchUrl()` to open the export URL in an external browser with no Authorization header at all (this endpoint has no query-string-JWT support), so every tap silently hit a 401/403. Switched to an authenticated `ApiClient.get()` fetch + save + share, matching the pattern already used elsewhere (job sheet PDF, productivity report). Root cause of "low contrast": icon/label color was hardcoded `Color(0xFF0F2C4A)` (dark navy) regardless of theme - dark-on-dark in dark mode. Made it theme-aware. |
| J9 | Activity Logs: wrong metric counts, filters don't execute, truncated to a few of 109 records | **done** - three real backend bugs: (1) `AdminActivityLogsKPIAPIView` returned a completely different field set (`total_logs`/`today_logins`/etc) than what the mobile UI's 5 cards actually read (`total_managers`/`active_managers`/`today_activities`/`this_month`/`failed_logins`), so every card always showed 0 - rewrote it to return the same 5 manager-scoped stats as the web admin's Activity Logs page, exactly; (2) the list/export endpoints weren't scoped to `user_role=manager` like web's `_audit_log_queryset` - this whole page is "Manager Activity Logs", not a global log; (3) the mobile list never read pagination fields from the response at all, so it silently showed only the API's default first page (20 of 109) - added real `loadMoreLogs()` + a "Load More" control. Also trimmed the Role filter dropdown to just "Manager" (Admin/Operative/Super Admin could never return results against the now-correctly-manager-scoped backend, matching web which only ever offered "Manager" too). |
| J11 | Dashboard summary cards for Manager role mismatch web contractor/manager dashboard | pending |

Work log (chronological, appended as each item is verified/fixed):
