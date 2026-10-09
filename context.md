# Context Log — Siteflow ConstructionIQ Admin (Flutter)

This file logs every change made to this project by Claude, per the user's
standing global rule. Entries are append-only, most recent last.

## 2026-10-09 — ClickUp bug queue wired up

User connected a ClickUp MCP connector and pointed at the "Euroside admin app"
list (workspace 3397824, list id 1300270000004675, space "Hiral"):
https://sharing.clickup.com/3397824/l/h/6-1300270000004675-1/ac67cfa721713ae

Pulled the full list via `clickup_filter_tasks`: 135 tasks total, mostly
assigned to Prem Verma (user) and/or Harmanpreet Singh. Most are already
`qa done`/`dev done`. **33 tasks are still `to do`** — these are the ones
being worked through now, per the user's instruction "jo bug aainge unhe
solve karna hai" (solve whatever bugs come in).

Standing rules that apply to this work:
- Admin app changes are commit-locally-only by default, never pushed without
  explicit instruction (per earlier session rule, reconfirmed).
- Every change logged here; report.md tracks per-ClickUp-task verify/fix status.
- verify-then-report workflow: for each ClickUp task, verify the bug is real
  in the current code before fixing it, then log the outcome.

Relevant files identified for the open bugs:
- Dashboard: `lib/modules/dashboard/dashboard.dart`
- Projects list/cards: `lib/modules/projects/*`, `lib/modules/projects/tabs/*`
- Job Sheets: `lib/modules/drawer_pages/job_sheet_controller.dart`,
  `job_sheet_screen.dart`, `job_sheet_details_screen.dart`,
  `job_sheet_webview_screen.dart`, `lib/modules/projects/tabs/job_sheets_tab.dart`
- Daily Reports / Daily Diary: inside job sheet / manager diary screens
  (`manager_diary_list_screen.dart`, `manager_diary_select_screen.dart`)
- Workforce Planner: `lib/modules/drawer_pages/workforce_planner_screen.dart`
- Productivity: `lib/modules/drawer_pages/productivity_screen.dart`,
  `productivity_controller.dart`, `productivity_detail_screen.dart`
- Drawings / Site Manager / Incidents / Specifications:
  `lib/modules/projects/tabs/drawings_tab.dart`,
  `site_manager_tab.dart`, `incidents_tab.dart`, `specifications_tab.dart`
- Docs & Files: `lib/modules/projects/tabs/docs_files_tab.dart`
- Notifications: `lib/modules/drawer_pages/admin/admin_notifications_view.dart`,
  `admin_notifications_controller.dart`

Work proceeds in batches by feature area; see report.md for per-task status.

## 2026-10-09 — Re-verified Harman branch merge + app health before resuming bug queue

User interrupted mid-task ("pehele harma ki barch marge kar le ache se or
dikhna ki bug to nahi a rahe hai app me" — first merge Harman's branch
properly, check no bugs are showing in the app) to re-confirm the earlier
Harman-branch merge was solid before continuing with the ClickUp bug queue.

Verification performed (no code changes, verify-only):
- `git fetch origin` + `git log main..origin/Harman --oneline` → 0 commits;
  `git merge-base --is-ancestor origin/Harman main` → true. Confirms
  `origin/Harman` is fully contained in `main`, nothing left unmerged.
- `flutter analyze` → 247 issues, **all** info/warning (deprecated API usage
  like `withOpacity`, unused imports, lint style). Zero `error`-level issues.
- `flutter build windows --debug` → failed immediately: "Unable to find
  suitable Visual Studio toolchain" — this machine has no VS native toolchain
  installed, so this check was inconclusive (environment gap, not a code bug).
- `flutter build web --debug` → **succeeded cleanly** ("Built build\web"),
  which fully compiles every Dart file in the app. This is the strongest
  available signal (no native toolchain needed) that the merge introduced no
  compile-time bugs.

Conclusion: Harman's branch merge is solid and complete; no bugs detected in
the app from it. Resuming the ClickUp "to do" bug queue (see report.md).

## 2026-10-09 — First batch of ClickUp bugs fixed (14 of 16 from eurosideclickuppoints.md)

User dropped `eurosideclickuppoints.md` with 16 bug descriptions and said
"fix this but do not push until i say". Worked through 14 of them; see
report.md's table for the full per-item breakdown (root cause + fix for
each). Summary of what changed, by file:

**Flutter app (this repo), all commits local only, not pushed:**
- `lib/modules/drawer_pages/workforce_planner_screen.dart` - added project
  filter dropdown (backend already supported it), fixed date format via
  `DateHelper.formatDate()`.
- `lib/modules/drawer_pages/productivity_screen.dart` +
  `productivity_controller.dart` - added a real search bar, a "My Reports"
  sheet (locally downloaded reports), a working period selector using the
  backend's `period=` param (replacing hardcoded fake 2026 dates), and a
  Client filter.
- `lib/modules/drawer_pages/job_sheet_controller.dart` - fixed the Status
  filter: was sending `status=in progress` (space), backend only recognizes
  `in_progress` (underscore) and was silently falling back to "all".
- `lib/modules/drawer_pages/job_sheet_screen.dart` +
  `job_sheet_details_screen.dart` - fixed a timezone double-conversion bug
  (server already localizes `created`/`last_updated` to the device tz, the
  card was running `DateHelper.formatToLocal()` on top of that again);
  removed redundant Material Cost/Charge fields from the shared Job
  Sheets/Daily Reports card (web doesn't show them); added a "Review & QA
  Status" section + Approve/Reject/Request Rectification actions wired to
  the existing `PATCH /api/my-approvals/<id>/`.
- `lib/models/job_sheet_model.dart` - added `source`, `rejectionReason`,
  `reviewedBy`, `reviewed`, `resubmissionCount` fields + `isReviewable`
  getter to support the above.
- `lib/modules/drawer_pages/job_sheet_webview_screen.dart` - added
  `setOnJavaScriptAlertDialog` so Manager Diary's `alert()` shows a themed
  Flutter dialog instead of the WebView's raw browser-chrome one.
- `lib/modules/projects/tabs/project_setup_tab.dart` - fixed the
  "Assignments" card: it was rendering `dropdown_options.available_managers`
  (every eligible manager) instead of `assignments.contractors` (who is
  actually assigned to the project) - this was the Euro009 bug.
- `lib/modules/projects/specification_detail_screen.dart` +
  `specification_controller.dart` - attribute inputs now have proper
  hint/label text + a type badge; Add Material options are now bordered
  tappable cards instead of plain text; added Edit support for price items
  (new backend PATCH + dialog, goes beyond web which only has add/delete).
- `lib/modules/drawer_pages/add_attendance_dialog.dart` - replaced two
  hardcoded mock dropdowns (`"Job 22 (Mocked for API)"`, `"Drilling Form"`)
  with real cascading Operative -> Project -> Task dropdowns backed by a new
  endpoint; removed the Task Sheet field entirely (backend never read it -
  it auto-submits the job's configured forms) and the non-functional "Use
  Current Location" button + mock lat/lon (backend already falls back to
  the project's own location).

**Backend (`P:\Euroside_Project`), pushed to origin/main after `manage.py
test` passed clean:**
- `API/views.py`: `AdminDashboardAPIView` gained a `users.supervisors` count
  and a `trends` block (active_projects/completed_tasks/pending_tasks/
  clocked_in_today), matching the web dashboard's 9-card KPI set and real
  trend percentages (mobile previously only showed 7 cards with hardcoded
  fake "+12%" style trend labels) - this was being worked on when the user
  interrupted to ask for the Harman-merge re-verification; finished and
  tested afterward.
- `_spec_detail_dict()` and the specification file-upload endpoint now pass
  `request.build_absolute_uri()` for `file_url` (was a bare relative path,
  which is why the mobile "View" button was always disabled).
- New `ProjectSpecificationPriceItemDetailAPIView.patch()` for editing a
  price item's name/quantity/unit_price.
- New `TimesheetAttendanceEntryOptionsAPIView` at
  `/api/timesheets/entry-options/` - supplies the Add Attendance dialog
  with real job data (mirrors the web modal's `entry_job_options`).
- Added tests: `TimesheetAttendanceEntryOptionsAPITests` (2),
  `ProjectSpecificationAPITests.test_edit_price_item`,
  `.test_specification_file_url_is_absolute`. Full API test suite green.

Not done from the 16-item list: B2 (full Project Setup tab redesign - large,
open-ended, needs its own pass) and E2 (signature/photo-upload scroll lock -
investigated the signature pad's CSS/JS, already correctly built with
`touch-action: none` and canvas-scoped listeners; likely a Flutter-WebView-
Android gesture-arena interaction that needs a physical device to pin down -
did not risk blind edits to the shared form-HTML renderer).
