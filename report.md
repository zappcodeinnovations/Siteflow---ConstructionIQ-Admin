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
| J1 | Material Details view missing Input Type/Material Group/Tags/Cert upload fields, field order/styling mismatch | **done** - backend (`AdminMaterialDetailAPIView.patch`) already fully accepted `input_type`/`material_group`/`tag_ids`/`certification_document`, the Flutter Details tab just displayed Group/Type as plain read-only text and had no Tags UI at all. Added editable Input Type dropdown (hardcoded against `Material.INPUT_TYPE_CHOICES`, a stable structural enum), Material Group dropdown (fetches `/admin/material-groups/`), and a Tags multi-select (fetches `/admin/material-tags/`, `FilterChip` per tag). Certification Document upload already exists via the Attachments tab - left as-is rather than duplicating the upload UX. |
| J2 | Forms library cards non-clickable; missing Pagination/Add Form/Filters/View/Delete/Created Date | **done** - the UI side (clickable cards, pagination, Add Form, Status/search filters, View, Delete, Created Date) was already fully built in an earlier session (commit `48cdea1`), but two real backend gaps made it look locked: (1) `LibraryFormsCatalogAPIView` was read-only (GET only) - the app's "Add Form" POST always 405'd and "Delete" DELETE'd a URL with no route at all (404, not even a clean error), so those two buttons silently failed every time; (2) the GET endpoint ignored `status`/`search` query params entirely, so the Status filter dropdown and search box never actually filtered anything server-side. Added `POST` to the catalog view (bare create, mirrors web's `library_form_create_view`) and a new `LibraryFormDetailAPIView.delete()` that archives (mirrors `library_form_archive_bulk_view` - there is no hard-delete for forms anywhere, including on the web, since forms may be referenced by existing submissions); wired `status`/`search` into the GET queryset. Renamed the Flutter "Delete" action to "Archive" (icon + dialog text) to match what it actually does now. |
| J3 | Add Team modal missing Team Nickname/Team Lead/Associated Projects/Shift Start-End/Cancel | **done** - Shift Start/End and Cancel already existed. Added Team Nickname field, Team Lead dropdown (fetches `/admin/members/`), and Associated Project(s) checklist (fetches `/api/projects/`); backend `AdminTeamsAPIView.post()` already accepted `nickname`/`lead_id` but had never wired `project_ids` at all (mirrors web's `create_team` action: `team.selected_projects.set(...)` + `sync_project_team_assignments`). Also found and fixed a real latent crash while testing: `lead_id` sent as a JSON int (not string) crashed with `AttributeError` on `.strip()`. |
| J4 | Team cards missing three-dots menu (Team Details/Shift Timezone/Members/Delete Team) | **done** - all 4 actions already existed inside `TeamDetailScreen` (reachable by tapping the card), so nothing was actually unreachable, but there was no quick three-dots shortcut on the card itself like web has. Added a `PopupMenuButton` with "Team Details / Members / Shift Timezone" (navigates) and "Delete Team" (quick delete, no navigation). |
| J5 | Member card three-dots menu missing 6 actions + missing Excel Import/Export + search/role filter bar | **done** - search already existed. Menu now has all 6: View Profile/Update Member/Change Password/Add Qualification/Convert to Guest/Delete Member. New backend endpoints `change-password/` and `convert-to-guest/` (found + fixed a real latent crash in the shared `convert_member_to_guest()` helper: `GuestInvite.first_name`/`last_name`/`phone` are NOT NULL but the member's own fields can be `None`). Added Export (backend already had it, just unwired) + Role filter + Reset. **Add Qualification**: the web already has a full `MemberQualification` model + `add_qualification`/`delete_qualification` actions on `member_detail` - added mobile `AdminMemberQualificationsAPIView`/`AdminMemberQualificationDetailAPIView` reusing the same model/validation, plus a new `QualificationsDialog` (list/add/delete, with file attachment support). **Import Excel**: the web already has `import_members_from_xlsx()` + `user_import_template_response('member')` - added mobile `AdminMembersImportTemplateAPIView`/`AdminMembersImportAPIView` reusing them directly, plus an Import dialog (download template / pick .xlsx / import) wired to the toolbar's new upload icon. |
| J6 | Guests module missing "Convert to Member" + missing Export/Import Excel + search Reset | **done** - new `convert-to-member/` endpoint (reuses existing `convert_guest_to_member()` web helper) + menu item; wired Export (backend already had it) + Reset. **Import Excel**: same pattern as J5, reusing the web's existing `import_guests_from_xlsx()` + `user_import_template_response('guest')` via new `AdminGuestsImportTemplateAPIView`/`AdminGuestsImportAPIView`. |

**ClickUp 14yjutqf9c4** (Members Directory count "20" vs web's "21 assigned") - **done**. Root cause: `AdminMemberListAPIView`'s and `AdminMemberExportAPIView`'s active-member queries never excluded accounts that are technically `is_active=True` but never completed setup (no password set, never logged in) - the web's `member_list` view does exclude these (`.exclude(is_password_set=False, last_login__isnull=True)`), so mobile was counting rows the web's Pending tab already accounts for, under a different definition. Fixed both mobile endpoints to match web exactly; also deduplicated both to use the shared `member_role_values()` helper instead of a repeated inline role list.
| J7 | Permissions matrix: saved Manager-role permissions not shown (all unchecked) | **done** - three real bugs in `admin_permissions_controller.dart`: (1) `fetchPermissions`/`savePermissions` called `.../roles/<id>/` which only matches a pure-numeric-id route (`AdminRoleDetailAPIView`); `role.id` is prefixed (`system:admin`/`custom:5`), so that URL 404'd silently every time, leaving every checkbox at its all-false init state; (2) `savePermissions` used PATCH but the real endpoint (`.../roles/<id>/permissions/`, `AdminRolePermissionsAPIView`) only defines GET/POST; (3) the save payload was sent bare instead of wrapped under `{"permissions": {...}}`. Fixed all three. |
| J8 | Activity Logs export buttons (CSV/Excel/PDF): low contrast, non-functional | **done** - root cause of "non-functional": buttons used `launchUrl()` to open the export URL in an external browser with no Authorization header at all (this endpoint has no query-string-JWT support), so every tap silently hit a 401/403. Switched to an authenticated `ApiClient.get()` fetch + save + share, matching the pattern already used elsewhere (job sheet PDF, productivity report). Root cause of "low contrast": icon/label color was hardcoded `Color(0xFF0F2C4A)` (dark navy) regardless of theme - dark-on-dark in dark mode. Made it theme-aware. |
| J9 | Activity Logs: wrong metric counts, filters don't execute, truncated to a few of 109 records | **done** - three real backend bugs: (1) `AdminActivityLogsKPIAPIView` returned a completely different field set (`total_logs`/`today_logins`/etc) than what the mobile UI's 5 cards actually read (`total_managers`/`active_managers`/`today_activities`/`this_month`/`failed_logins`), so every card always showed 0 - rewrote it to return the same 5 manager-scoped stats as the web admin's Activity Logs page, exactly; (2) the list/export endpoints weren't scoped to `user_role=manager` like web's `_audit_log_queryset` - this whole page is "Manager Activity Logs", not a global log; (3) the mobile list never read pagination fields from the response at all, so it silently showed only the API's default first page (20 of 109) - added real `loadMoreLogs()` + a "Load More" control. Also trimmed the Role filter dropdown to just "Manager" (Admin/Operative/Super Admin could never return results against the now-correctly-manager-scoped backend, matching web which only ever offered "Manager" too). |
| J11 | Dashboard summary cards for Manager role mismatch web contractor/manager dashboard | **done** - `dashboard.dart` always rendered the Admin-only 9-card set (Active Projects/Completed Tasks/Pending Tasks/Total Operatives/Total Managers/Total Supervisors/Clocked In/Clocked Out Pending/Not Clocked In) for every logged-in role, including Manager - which leaks staff-headcount metrics a Manager isn't meant to see and doesn't match `contractor_dashboard.html`'s actual 6-card set at all (Total/Active/Completed Projects, Clocked In/Not Clocked In/Not Clocked Out). Added a role check (`user.effectiveRole`) and a second 6-card branch mirroring the web manager dashboard exactly - same backend API response already has all the needed data (`kpis.projects`/`kpis.attendance`), this was purely a missing UI branch. |

## Merge from Harman's branch + ClickUp cross-check (2026-10-10)

Merged `origin/Harman` into `main` (17 commits, diverged since
`34c5df8`). Per explicit instruction, cross-checked each conflicted/
incoming file against the ClickUp "Euroside admin app" list before
resolving, so each resolution matches a real ticket rather than a
guess:

| ClickUp ticket | Status | Resolution |
|---|---|---|
| 14yjutqfhbh - Add Attendance cascading dropdowns/mock data/layout | in progress | Took Harman's full rebuild - verified it implements every line of the ticket spec verbatim (disabled-state cascading, live tasks replacing "Job 22 (Mocked for API)", task-sheet multi-select, default clock times, location helper text, double-asterisk Operative). |
| 14yjutqfha0 + 14yjutqfh93 - Workforce Planner project filter + date format | dev done | Took Harman's rebuild. |
| 86d3umczz / 86d3um93w / 86d3um8dh - Productivity API failure/filter/date-preset bugs | dev done | Took Harman's rebuild (search bar, date presets, multi-criteria filters, My Reports tab). |
| 14yjutqfhh5 - Members Active/Pending tabs | dev done | Took Harman's tab structure; re-merged this session's role filter/export/reset/5-action member menu on top so neither side's work was lost. |

Also found and fixed two pre-existing typos baked into Harman's own
branch (not introduced by the merge - confirmed present in
`origin/Harman` beforehand): `cclass ApiEndpoints` in
`api_endpoints.dart` and `iimport 'dart:convert';` in both
`login_controller.dart` and `profile_controller.dart`. These broke
the whole project's compile (753 `flutter analyze` errors cascading
from the single `ApiEndpoints` typo) - full analyze is clean (0
errors) after fixing both.

**14yjutqfhqp - Change Password missing from Profile, organizational
fields wrong, "View full audit log" link should be removed**: the
Flutter UI side (Change Password button, full Profile Details grid,
no audit log link) came in with the same Harman merge and already
matches the web admin's `admin_profile.html` grid field-for-field.
Investigated the two fields that still looked wrong after the merge -
Company Name and Last Login - and found a real backend gap:
`UserSummarySerializer` (`API/serializers.py`) never exposed
`company_name`/`last_login` at all, even though the Flutter model
(`user_model.dart`) already prioritized exactly those JSON keys over
its fallbacks. Added both: `company_name` mirrors the web's
`organisation_settings.name` (`OrganisationSettings.get_solo()`),
`last_login` mirrors `profile_user.last_login` shown on the web's own
page. No Flutter change needed - the model was already correct,
only the backend was missing the data. New test
`test_profile_api_returns_company_name_and_last_login`, run
individually and passing. Backend pushed to `origin/main` (`a4d94d0`).

Flutter merge commit (`62ae3f5`) is local-only per standing rule;
not yet pushed pending explicit confirmation.

**User-reported (2026-10-10): Job Sheet PDF download has no images and needs left-right scroll** - **done**, backend only. `JobSheetListAPIView`'s `export=pdf` query param was never actually handled server-side - it silently fell through to the normal JSON response. The Flutter app's `_downloadJobSheetPdf()`/project-PDF download already correctly detected "not a real PDF" and fell back to opening the job sheet's HTML form in an in-app webview - which is exactly what the user was seeing: no images (webview sub-resource requests have no auth header) and not mobile-responsive (needs horizontal scroll). Fixed by wiring `export=pdf` to the web's existing `render_job_sheets_list_combined_pdf()` (same rows the view already builds, same ReportLab renderer used by the web's own `?report=pdf`) - produces a real, correctly-paginated A4 PDF with images embedded from disk. No Flutter change needed; its PDF-detection logic was already correct, it just never received a real PDF before. New test `test_export_single_job_sheet_as_pdf`. Pushed to origin/main (`4e4ac53`).

**User-reported (2026-10-11): Daily Diary view and PDF download still missing images/signatures** - **done**, backend only. Two separate gaps: (1) `_render_submission_html` (used by the "View Form in Browser" action, what Daily Diary's "View" opens) never rendered any file-type field's value - browsers can't set a file input's value to a server file, and structured forms like Daily Diary have no HTML template at all, so nothing visual showed up. Fixed by appending the same "Images & Files" gallery (Live Signature/Client Signature/Live Photos/other, grouped by `_split_submission_file_entries`) the existing print template already builds for its own PDF path. (2) Weekly Diary's PDF download goes through a *different* endpoint (`WeeklyDiaryAPIView`, not `JobSheetListAPIView`) which never handled `export=pdf` at all - it returned the normal JSON response with status 200, so the app's "not a real PDF" fallback check never triggered and it always opened the webview instead. Wired it to the web's own `render_weekly_diary_pdf()` (operative_id/project_id/week-scoped, already embeds images correctly from disk). No Flutter change needed in either case - the detection logic was already correct, it just never got real content/a real PDF to detect. New tests: `test_user_form_html_preview_includes_submitted_images`, `test_weekly_diary_pdf_export_returns_real_pdf` (+2 guard tests). Pushed to origin/main (`d27fbc9`).

**User-reported (2026-10-12): Daily Diary "Work Started At"/"Work Finished At" show raw ISO timestamps** - **done**, backend only. Two functions filled datetime values in verbatim with zero formatting: `_fill_submission_html_controls` (the "View Form in Browser" HTML filler) and `_build_friendly_submission_fields` (feeds the mobile job sheet API's `raw_fields`/`friendly_fields` and the PDF's field table) - neither ever attempted to parse/reformat an ISO string, unlike the web's own submission-detail page, which has had a correct, tested formatter (`_format_submission_display_value`, `'%d %b %Y %I:%M %p'`) for months, just never reused here. Swapped both to call it (native date/time HTML inputs are explicitly excluded, since reformatting would break their required value format - only plain text controls get the human-readable string). Also swapped the raw-payload label source to `_submission_business_label_for_raw_key` so the labels now read "Work Started"/"Work Finished" exactly like the web, instead of the generic prettified "Work Started At"/"Work Finished At". New tests: `SubmissionHtmlDateFormattingTests` (4 cases). Pushed to origin/main (`004ccc5`).

**User-reported (2026-10-12): missing delete button for photo attachments in Create Support Ticket modal** - investigated, **already fixed**. This exact feature (preview card with thumbnail, filename, formatted file size, and a dedicated delete/trash `IconButton` calling `_removeAttachment()`) was added in commit `eba406e` ("feat(support): add attachment preview card...") as part of Harman's branch, merged into `main` on 2026-10-10 (`62ae3f5`). No code change needed - confirmed present and correctly wired in the current `create_ticket_dialog.dart`.

## Batch (2026-10-12, 12 user-reported items)

| # | Bug | Status |
|---|---|---|
| 1 | Members: "Assigned"/"Invited"/"Seats" mismatch (mobile 58/0/58 vs web 23/1/23) | **done** - `AdminMemberListAPIView` never returned `assigned`/`invited` counters at all, so the summary card fell back to showing the active-member total for Assigned and 0 for Invited. Added both, computed the same way as web's `assigned_seat_total`/`pending_invite_total` (org-wide, independent of which status tab is open). |
| 2 | Members Pending tab: "Invited 0" instead of 1 | **done**, same root cause as #1, plus a real bonus find: `AdminMemberInviteSerializer` declared `role_display` but never listed it in `Meta.fields` - DRF raised an `AssertionError` (500) the moment the serializer rendered any row, so the Pending tab crashed outright whenever at least one pending invite existed. Fixed both. |
| 3 | Members Pending tab: "Manager" role label unreadable (dark text on dark card) | **done** - the pending card showed the role as plain text with a fixed `black87` color directly on the dark surface, unlike the Active tab's cards which wrap it in a colored badge. Wrapped it the same way. |
| 4 | Tasks total count mismatch (mobile 125 vs web 120) | **done** - `AdminTasksListAPIView` built its own `project__in=accessible_projects()` filter by hand instead of reusing `accessible_jobs()` (the same helper the web's `/jobs/` page uses, which adds `.distinct()`). Now reuses it directly. |
| 5 | Dashboard dark mode: "Portfolio completion statistics" card stays solid white | **done** - `ProjectProgressChart` hardcoded a white container regardless of theme, unlike its `AttendanceTrendChart` sibling right below it. Gave it the same `isDark`-aware card color/border/title color. |
| 6 | Notification cards: wrong date format + redundant "Edit" button | **mostly already correct / done**. Investigated the date format via `DateHelper.formatToLocal` - it already uses an explicit `dd/MM/yyyy hh:mm a` pattern (locale-independent), so no format-order bug found in code; the body-text "BST" example in the report is literal free text the notification's author typed, not a formatting bug. The Edit button *was* a real bug - the web's own notifications list template only ever renders Delete, never Edit - removed it (and the now-dead `_canEdit` permission check/edit dialog import). |
| 7 | Ticket Details Conversation: wrong date format + unlabeled timezone | **mostly already correct / done**. Same date-format finding as #6 (code already correct). The real, fixable issue: every timestamp in this app is shown in the UK operational timezone with no label, so a time like "3:48 PM" reads as ambiguous. Added an explicit BST/GMT suffix via a new `DateHelper.ukTimezoneAbbreviation()` (extracted from the existing BST date-math already used by `toUkDateTime`). |
| 8 | Daily Diary "Work Started At"/"Work Finished At" show raw ISO timestamps | **done** - see entry above (2026-10-12), fixed the same day as this batch. |
| 9 | Create Support Ticket: missing attachment delete button | **already fixed** - see entry above, from the Harman merge. |
| 10 | Invite Member: First Name doesn't auto-populate Email | **done** - typing First/Last Name now auto-suggests `<first>.<last>@euroside.co.uk` into Email, mirroring the web's `buildSuggestedEmail`/`syncSuggestedEmail` JS exactly (including not clobbering a manually-edited address). |
| 11 | Invite Member: Role dropdown missing System/Custom Roles grouping | **done** - dropdown now groups System Roles vs Custom Roles (fetched from the existing `/admin/members/filter-options/` endpoint) with disabled section headers; submits `role=custom` + `custom_role_id` for a custom selection, mirroring the web's `<optgroup>`/hidden-input pattern. |
| 12 | Invite Member / Create Ticket: missing duplicate Employee Code validation | **done** - `AdminMemberInviteAPIView` was missing the web's own duplicate `employee_id` check entirely (no unique DB constraint either, so a duplicate silently succeeded). Added the same check, plus a new live-check endpoint (`AdminMemberEmployeeIdExistsAPIView`, mirrors the web's `member_employee_id_exists`) that the mobile field now debounce-calls to show an inline warning + icon before submitting. |
| 13 | Assigned Operators selector (Tasks) shows full org directory before project selection, doesn't filter after | **done** - `OperativeProjectJobCreateAPIView` never returned any operative list at all; the app's dropdown always pulled the full org-wide `/admin/members/?role=operative` directory with zero project scoping. Added an `operatives` field reusing `available_job_operatives()` directly (same helper the web's "Create Online Job" modal uses) - empty until a project is picked, scoped to that project's active `ProjectAssignment` workers after. |

New backend tests: `test_assigned_and_invited_counters_match_web_definitions`, `test_pending_tab_does_not_crash_when_an_invite_exists`, `test_manager_with_overlapping_access_paths_does_not_double_count`, `AdminMemberInviteDuplicateEmployeeIdAPITests` (4 cases), 2 new cases in `OperativeProjectJobCreateApiTests`. Backend pushed to origin/main across commits `c1f0f91`, `42dec36`. Flutter committed locally across `ee58917`, `cfb78cb`.

Work log (chronological, appended as each item is verified/fixed):

## 2026-10-23 — Phase 2 "Safety & Compliance" plan audit (admin-app slice, read-only)

**Point (as given):** User pasted a "Phase 2 - Safety & Compliance - Replace OneTrace" plan (RAMS, Toolbox Talks, Permit-to-Work, Compliance Dashboard, Enhanced Audit Logs, New Suggestions/Attendance) and asked which points are done vs pending. Full cross-repo writeup lives in `Euroside_Project/report.md` (2026-10-23 entry) — this is just this app's slice.

**Verification (this app only):** No new Compliance/RAMS/ToolboxTalk/Permit folder exists under `lib/modules/drawer_pages/admin/` — still just Members/Guests/Announcements/Notifications/Permissions/Activity Logs/Organisation/Support. The real surface is `lib/modules/projects/tabs/hse_tab.dart` (+ `project_hse_controller.dart`, `hse_document_model.dart`) — one generic document uploader with 8 category tags (rams/toolbox_talk/site_induction/permit_to_work/certificate/training/other), sign-required checkbox, "X/Y signed" progress, revision/"Recycle Bin" history. No Compliance Dashboard screen anywhere (only 2 hits for "compliance" in the whole codebase, both marketing copy). Enhanced Audit Logs export **already exists and works**: `admin_activity_logs_view.dart` has CSV/Excel/PDF export buttons wired to `DownloadManager`. Manager's own clock in/out (`manager_attendance_screen.dart`) is GPS-only via `geolocator` — no QR scan/generate-for-clock-in flow; the app's only QR feature is a per-project identification QR in `projects_screen.dart`, unrelated to attendance, and no QR-scanning package exists in `pubspec.yaml`. `add_attendance_dialog.dart` (manual attendance entry) is single-operator/single-signature only — no multi-labourer co-sign support.

**Work:** None — diagnosis/report only.

**Status:** Reported back to user.

## 2026-10-24 — ClickUp bug sweep: yesterday's (2026-10-23) 13 "to do" tickets

**Point (as given):** "sab se pehele kal ke solve karna" (solve yesterday's first), referring to
the 13 tickets in this ClickUp list created 2026-10-23 - confirmed via each task's
`date_created` that these are a distinct, newer batch than the Oct-16/Oct-13 tickets still
sitting in "to do". Also asked to check each task's comments for extra context before fixing.

**Verification:** Read every ticket's description and comments, then traced each into the
actual Flutter (and, for one, Django backend) code before touching anything, per the user's
"verify first whether it's a real bug" instruction. 12 of 13 were confirmed real; 1
(the Manager Notifications header icon order) was a deliberate, consistent app-wide design
choice, not a bug - see `context.md`'s 2026-10-24 entry for the full per-ticket breakdown of
root causes and fixes.

**Work:** 12 fixes across `client_screen.dart`, `dashboard_controller.dart`/`dashboard.dart`,
`admin_activity_logs_view.dart`, `auth_service.dart`, `profile_screen.dart`,
`admin_notifications_view.dart`/`add_notification_dialog.dart`, `task_screen.dart`,
`manager_attendance_screen.dart`, plus the Project Team modal's backend fix in
`Euroside_Project/API/views.py`+`serializers.py` (2 new passing tests there).

**Tests:** `flutter analyze` clean across every changed file. Backend: `manage.py check` clean,
2 new passing tests for the Project Team modal fix.

**Status:** All 13 ClickUp tasks updated - 12 moved to `dev done`, 1 to `not a bug`, each with a
comment explaining the finding. Code fixed and verified locally; not committed/pushed yet.

## 2026-10-24 — RAMS Builder screen + Compliance Dashboard permission

**Point (as given):** "admin aap me /compliance-dashboard/ or build rams or Construction
Reports bhi add kar dena manager or superviser ko permission hogi to dikhega barna nhi."

**Verification:** Construction Reports already fully built and working as asked - no gap.
Compliance Dashboard: this app's screen/route/drawer item already existed, but the backend
permission it depends on (`AuthService.can('compliance_dashboard')`) was ungrantable - a backend
fix, not a Flutter one (see `Euroside_Project` repo logs). RAMS Builder: genuinely missing - no
mobile screen or API existed. Asked the user to pick a scope (full builder / simplified form /
web-view shortcut) since the three options differ enormously in effort and UX; user chose "Full
builder."

**Work:** New `rams_builder_screen.dart` + `project_rams_controller.dart`, plus entry points in
`hse_tab.dart` ("Build RAMS" button, "Open RAMS builder" on existing RAMS document cards) and
`hazardCount`/`highestRiskScore` fields added to `hse_document_model.dart`. Hazard matrix editor
reuses `material_detail_screen.dart`'s rate-tier-editor pattern rather than inventing a new one.
Backend: new `ProjectRamsBuilderAPIView` (token-auth mobile API, reuses the web builder's exact
save logic via a newly extracted shared function) and the Compliance Dashboard permission
re-enable - both in `Euroside_Project`, full details in that repo's own report.md.

**Tests:** `flutter analyze` clean, 0 new issues. Backend: 6 new passing API tests + all 14
existing web RAMS tests still pass, `manage.py check` clean.

**Status:** Built and verified locally across both repos. Not committed/pushed yet.

## 2026-10-24 — ClickUp bug sweep: remaining older (2026-10-13/16) "to do" tickets

**Point (as given):** "ab jo bug bache hai pehele assign kiye wale, unhe verify kar ke solve
karna hai" - solve the remaining 16 already-assigned bugs, verify first. Mid-task: "kuch bug
old hai jo ki abhi solve karne ka koi matlbe nhi hai bo bhi dekhna sabhi solve karne ka mat
sochna" - also flag old/stale ones not worth forcing a fix on, don't assume everything must be
fixed.

**Verification:** Went through all 16 individually against current code. Traced 3 separately-
worded tickets (blank Total Worked, Contractor Dashboard future timestamps, shift-duration
confusion) to one shared root cause in the operative app's clock-in/out timestamp submission.
Confirmed 3 others were already correctly implemented by prior work (shift-duration restore
logic, Daywork form scrolling, Guests Directory live refresh) with no code change needed. Found
1 genuinely not a bug (QA buttons - backend authorizes by role, no granular permission exists to
gate on; tried a client-side fix, reverted it once that became clear). Could not locate a
current-code defect for 2 (clock-out location N/A, Daily Diary PDF date format) despite thorough
checking across all three repos, and left 1 alone (Create Notification "enhanced options" - a
vague feature-parity ask, not a specific defect).

**Work:** 7 concrete fixes - see `context.md`'s matching entry for the full file-by-file
breakdown (timezone fix in the operative app's `api_client.dart`; downloads screen friendly
errors; task-creation project dropdown; employee code confirmation; N/A→hyphen in Attendance
Logs; Activity Logs pull-to-refresh; HS&E upload date-picker default).

**Tests:** New backend regression test for the timezone fix, passing. `flutter analyze` clean
(0 errors) on both Flutter apps. `manage.py check` clean.

**Status:** All 16 ClickUp tasks updated with a status + comment explaining the finding - 7
`dev done` (new fixes), 3 `dev done` (already-correct, verified not changed), 1 `not a bug`, 2
`under discussion` (asked for more detail/a fresh repro), 1 left as `to do` with a comment
explaining why it's out of scope for this pass. Code changes not committed/pushed yet.

## 2026-10-26 — Construction Reports crash + dark mode, Manager/Supervisor operative scope

**Point (as given):** Two screenshots - Construction Reports page not dark-mode styled, and a
red Flutter crash ("No Material widget found") on the Logs screen reached from it. Separately:
"manager or supervisor ko all oprative aane ka option ana chahiye jese admin ko dikhta hai admin
aap me bhi fix karna hai" - Manager/Supervisor should see the full operative list like Admin
does when assigning to a project, fix it in the Admin app too.

**Verification:** Confirmed both screenshot issues directly in code - `_ReportCard` hardcoded
white/fixed colors (no `isDark` branching at all despite the variable being computed), and the
Activity Logs card pushed a Scaffold-less body widget directly, which is why the Material
widget error only appeared from this one entry point. For the operative-scoping ask, traced the
Admin app's "Project Assignments" panel to `ProjectAllInOneDetailAPIView` (not the
`ProjectOptionsAPIView` endpoint used by Create Task) and found the same team-lead-only scoping
pattern repeated in 4 separate backend locations (2 web, 2 API) - all intentional at the time
they were written, now explicitly reversed on request.

**Work:** Construction Reports dark-mode colors + routing fix (this repo). Operative-directory
widening across all 4 backend locations (`Euroside_Project`'s own report.md has the full
breakdown). Also folded in a pre-existing uncommitted fix to `projects_screen.dart`'s Assign
Operatives dialog (confirmed with the user as this session's own earlier work) - it hardcoded
`teamIds: const []` on save, dropping a project's existing team assignments.

**Tests:** `flutter analyze` clean (0 errors). Backend: 6 tests across 3 test classes (2 new,
1 updated to reflect the intentionally-reversed restriction) all pass.

**Point (as given):** "web em construction report asi hai or mobile aap me difrent hai to ese
bhi fix karna hai" (+ screenshot of the web Construction Reports page) - make the Admin app's
Construction Reports hub match the web page's layout.

**Verification:** Read the full web template (`templates/dashboard/construction_reports.html`,
1049 lines) to get the exact structure: two sections (org-wide, no project needed; project-scoped,
greyed out until a project is picked) and 7 report cards total, including a Specifications report
that didn't exist anywhere in the Flutter app. Ran a read-only survey agent against the Admin app
to confirm: a `SpecificationsTab` already exists (buried as a Project Details tab, not reachable
from the hub, but its CSV export already matches the web one exactly); none of Job Sheets/
Timesheet/Productivity screens take a project-id constructor argument, but their controllers
already support filtering to one id-based (`JobSheetController.fetchJobSheets(projectId:)`,
`TimesheetController.setAdvancedFilters(project:)` - confirmed `selectedProject` there is already
numeric, not a name); `ProductivityDetailScreen(id, title, isMember: false)` is already the exact
per-project drill-down the web's "Project Productivity" card maps to.

**Work:** Rebuilt `construction_reports_screen.dart` as a `StatefulWidget` with its own project
list + picker (same fetch pattern as `create_task_controller.dart`), split into the two sections,
added an `enabled` flag to the card widgets for the greyed/locked look. Added `initialProjectId`
to `JobSheetScreen` and `TimesheetScreen` (two one-line wiring changes into already-id-aware
controller methods). Project Productivity and Specifications needed no new screens at all - wired
directly to `ProductivityDetailScreen` and `SpecificationsTab` respectively (the latter wrapped in
a plain `Scaffold`+`AppBar` since it's a bare body widget).

**Tests:** `flutter analyze` clean (no new errors/warnings).

**Status:** Committed (`89e24a4`) and pushed to `origin/main`.

---

## 2026-10-26 — Construction Reports format badges don't export like web; custom range needs two calendars

**Point (as given):** "button work nhi kar rahi hai abhi bhi aap side me construction reports me jese web me click karne pr filter pop up ata hai phir me use select kar ke report direct downlode kar leta hu" (+ screenshots of the web's CSV/EXCEL/PDF buttons and its period-picker dialog). Followed by: "DATE RANGE KE LIYE DO ALAG ALAG COLANDER CHAHIYE" once the dialog existed.

**Verification:** The redesigned hub's format badges were static, no tap handler. Checked each report's export endpoint for `from`/`to`/`project` support: Activity Logs and Timesheets already had it; Productivity had it too but `project` text-matches the name, not an id; Job Sheets had no date-range support at all on the mobile API (web's own view has had it all along) - fixed in `Euroside_Project/API/views.py` (own context.md entry there).

**Work:** `_ReportLink.onFormatTap` makes each format badge independently tappable, opening a new `_ReportExportDialog` (period: Month/Year/Custom/All) that downloads directly via `DownloadManager` - mirrors the web's `#reportExportDialog` click-to-download flow exactly, no navigation. Specifications downloads immediately with no dialog (matches web). Project Productivity's URL uses the project's name, not id. Custom period originally used one combined range-picker dialog; changed to two independent `showDatePicker` calendars side by side ("From date" / "To date") per the follow-up ask.

**Tests:** `flutter analyze` clean (0 issues).

**Status:** Committed (`c160a6c`) and pushed to `origin/main`.

---

## 2026-10-26 — "Admin Control" never reachable in the app drawer for Manager/Supervisor

**Point (as given):** "problem ye hai ki mujhe bo penaal hi nhi mil rahe hai access karne ke liye koi option nhi hai kisi bhi side bar me nhi hai" (+ screenshots: web sidebar with no Admin section at all, and the Admin app's full drawer scrolled top to bottom - no Announcements/Notifications/Admin entry anywhere, just "Operative Logs" under SYSTEM & CONFIG).

**Verification:** `custom_drawer.dart`'s "Operative Logs" / "Admin Control" items were an `if / else if` pair. `_isOperativeLogViewer` is true for every manager and supervisor unconditionally, so it always wins the `else if` and "Admin Control" (`_allowedMenus.any((key) => key.startsWith('admin_'))`) could never render for that role, no matter which admin_* permissions were granted - the two conditions aren't actually mutually exclusive.

**Work:** Split into two independent `if` blocks so Operative Logs and Admin Control can both show. `admin_screen.dart` (the `/admin` destination)'s own per-tab permission filter was already correct - this was purely a missing entry point.

**Note:** the matching web-side bug (`sidebar_items_for_user()`, same root shape - the parent "Admin" nav entry requiring its own ungranted permission key) was already found and fixed earlier today, committed locally in `Euroside_Project` but not yet pushed/deployed - that's why the web screenshot in this same report still shows no Admin section.

**Tests:** `flutter analyze` clean (0 issues).

**Status:** Committed (`75db5db`) and pushed to `origin/main`.

---

## 2026-10-26 — Announcements API 403 + "Admin Control" renamed for Manager/Supervisor

**Point (as given):** screenshot of the now-reachable Announcements tab showing "You do not have permission to manage announcements from mobile API."; plus "admin control ke place pr advance access kar manager or superviser ke liye".

**Verification:** backend-side bug (own repo's report.md has the full breakdown) - the Announcements mobile API endpoint was hardcoded to Admin/Superuser only, never checking the RBAC `admin_announcements` permission, unlike its Notifications sibling.

**Work:** `custom_drawer.dart`'s drawer item label changed from a fixed "Admin Control" to `_isOperativeLogViewer ? "Advance Access" : "Admin Control"` - Manager/Supervisor see "Advance Access", everyone else still sees "Admin Control".

**Tests:** `flutter analyze` clean (0 issues).

**Status:** Committed (`67bf0e0`) and pushed to `origin/main`.

---

## 2026-10-26 — ClickUp "to do" bug sweep (2 app-side points)

**Point (as given):** "click up pr admin aap ke todo me bug hai fix ir" - 5 tickets total in the list; 3 were backend-only (own repo's report.md), these 2 touch this app.

**Verification:** `errorStyle` on the login screen's password field had no color set (9px, no weight) - confirmed low-contrast default. The Task No field's ternary only checked whether `setup.jobNoDisplay` was non-empty, never whether a project had been picked at all, so "Auto-generated" showed from the moment the modal opened.

**Work:** `login_screen.dart` - explicit error text color/weight/size. `create_task_dialog.dart` - Task No stays blank until `selectedProjectId != null`.

**Tests:** `flutter analyze` clean (0 issues).

**Status:** Committed (`b1d4e4d`) and pushed to `origin/main`.

---

## 2026-10-26 — App pointed at the test server

**Point (as given):** "app ko test server ki ip pr trasfer kar de".

**Verification:** test server only serves plain HTTP (confirmed via `curl` on the box), and neither platform had any cleartext exception configured - the app has only ever pointed at HTTPS production, so switching `baseUrl` alone would've been silently blocked by the OS before any request left the device.

**Work:** `ApiEndpoints.baseUrl` → `http://64.227.164.177/api`. Added a cleartext exception scoped to that one IP on both platforms (Android `network_security_config.xml`, iOS `NSAppTransportSecurity`) rather than a blanket "allow all HTTP" toggle.

**Tests:** `flutter analyze` clean (0 issues).

**Status:** Committed (`15ee1d9`) and pushed to `origin/main`.

---

## 2026-10-26 — Hide Operative Logs from the Manager/Supervisor drawer

**Point (as given):** "side bar se logs bala optin hide kar manager or superviser ke liye" - clarified via a question: Operative Logs specifically, not reversing the earlier data-fix.

**Verification:** Confirmed "Operative Logs" has no web equivalent (grepped templates, nothing) - purely an Admin app drawer entry.

**Work:** Removed the drawer link for Manager/Supervisor. Underlying permission/route untouched - this is a visibility change only.

**Tests:** `flutter analyze` clean (0 issues).

**Status:** Verified locally. Not committed/pushed yet.

---

## 2026-10-27 — Add "Manage Templates" to the RAMS Builder

**Point (as given):** "...admin aap me bhi manage teplate missimg hai RAMS Builde me", reconfirmed "abhi bhi app me build RAMS me Manage Templates missing hai" / "ye task complite kar".

**Verification:** RAMS Builder screen already existed with the template dropdown; confirmed via grep no mobile API/screen existed to manage the templates themselves.

**Work:** New `method_statement_templates_controller.dart` + `method_statement_templates_screen.dart` (Active/Archived list, add/edit `AlertDialog`, archive/restore per row). Added "Manage Templates" button next to the dropdown in `rams_builder_screen.dart`, re-fetching builder data on return so new templates appear immediately. New endpoints added to `api_endpoints.dart`.

**Tests:** `flutter analyze` clean (0 issues) on all 4 changed/new files.

**Status:** Verified locally. Not committed/pushed yet.

---

## 2026-10-27 — Fix UI overflow on HS&E / RAMS Builder

**Point (as given):** "JO UI ISSUE HAI UNE BHI FIX KA" + screenshots showing yellow/black "OVERFLOWED BY X PIXELS" banners on the HS&E tab's toolbar and the RAMS Builder's template dropdown row.

**Verification:** Both were real `RenderFlex`-style overflows, not cosmetic. The dropdown lacked `isExpanded: true` (classic Flutter gotcha - item text renders at natural width instead of shrinking); the HS&E toolbar's `Wrap` was a non-flex child of an outer `Row`, so it never actually got to wrap.

**Work:** Added `isExpanded: true` to the template dropdown and moved "Manage Templates" to its own line below it instead of squeezing both into one row. Flattened the HS&E toolbar's nested `Wrap`-inside-`Row` into one flat `Wrap` holding all 3 buttons.

**Tests:** `flutter analyze` clean (0 issues).

**Status:** Verified locally. Not committed/pushed yet.
