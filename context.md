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

## 2026-10-10 — Notification dropdown timestamp fix (#32 from the original 33-item ClickUp audit)

User reported (outside eurosideclickuppoints.md, from the original ClickUp
list): "Incorrect timestamps displayed in the notification dropdown on the
mobile app (event timestamps mismatch actual activity timing and device
time)."

Root cause found in `lib/models/admin_notification_model.dart`:
`formattedUpdatedAt` parsed the backend's UTC-aware ISO timestamp with
`DateTime.parse()` (correct), then read `.hour`/`.day`/etc directly off that
UTC-flagged `DateTime` without ever calling `.toLocal()` - so it displayed
the raw UTC clock time instead of converting to the device's own timezone.
Replaced the whole hand-rolled formatter with the shared
`DateHelper.formatToLocal()` (already correct, already used by the full
Notifications screen for the same data).

Also discovered the appbar's actual notification "dropdown"
(`PopupMenuButton` in `custom_appbar.dart`, `_NotificationRow`) displayed no
timestamp at all before this fix - added one (`sent_at`, falling back to
`created_at`), formatted correctly from the start.

Committed locally (`e792fdb`), not pushed, per the standing rule for this
repo.

## 2026-10-10 — Project cards: Owner/Locations count were silently fake (#31)

User reported (from the original 33-item ClickUp audit): "Project cards in
the mobile app omit essential project attributes present in the web admin
portal (such as inline Project Code, Owner, and Locations count)."

Verified first: all three UI elements already existed on the Projects
screen's card (`projects_screen.dart:_buildProjectCardItem`) - Code via
`Project.displayNameWithCode`, Owner, and Locations. So the bug wasn't a
missing UI element; it was the *data* behind two of the three being wrong:

- **Locations count** was always the model's hardcoded fallback `1`,
  because `ProjectListSerializer` (the API the mobile Projects list actually
  calls, `GET /api/projects/`) never included any location-count field at
  all - `locations_count`/`location_count`/`total_locations`/`locations`
  were all absent from that response.
- **Owner** was always "N/A", because that same serializer only exposes the
  project's manager as a nested `contractor: {...}` object, but
  `Project.fromJson`'s owner-resolution chain in the Flutter model checked
  only flat keys (`owner`, `owner_name`, `manager`, `created_by_name`,
  etc.) that don't exist on this response - it never looked at `contractor`
  at all.

Fix:
- Backend (`API/serializers.py`): added a `location_count` SerializerMethodField
  to `ProjectListSerializer` (`obj.drawing_locations.count()`).
- Flutter (`lib/models/project_model.dart`): added `json['contractor']` as a
  fallback source in the owner-resolution chain, preferring `display_name`
  over `email` when reading a Map value (contractor has no `name` key, and
  showing someone's name reads better than their raw email address).

Backend: `manage.py test API.tests -k Project` (new test
`test_project_list_includes_owner_contractor_and_location_count` added).
Flutter: `flutter analyze` on `project_model.dart` clean.

## 2026-10-10 — Third bug batch from P:\Euroside_Project\bug.md (I1/I2/I9 done; I3 already correct)

User pointed to a new scratch file in the backend repo, `bug.md`, with 12
more bug descriptions (mostly Drawings/Site Manager/Incidents/Approvals/
Specifications-toolbar/Project-Setup-redesign - the cluster deferred from
the original 33-item audit). Tracked as I1-I12 in report.md. Also: per
explicit user feedback this session ("har bar purane test mat run kara kar
bas jitna update kiya hai utne kara kar" - don't run old tests every time,
just run what you've updated), switched to running only the single new/
touched test method per change, not the test class or suite.

- **I1/I2 (Docs & Files folder counter delay)**: root cause was that both
  upload and delete waited on a full `ProjectAllInOneDetailAPIView` refetch
  (the entire project - specs, drawings, job sheets, HSE, everything) before
  the folder's file counter updated at all. Fixed in
  `lib/modules/projects/tabs/docs_files_tab.dart`: both actions now
  optimistically insert/remove the file from local state immediately via
  `setState`, with the full refetch still happening afterward in the
  background (`unawaited(_fetchTabFiles())`) to reconcile. Backend
  (`API/views.py`, the `module == "files"` POST handler) enriched to return
  `folder_id`/`folder_type`/`is_private`/`created_at` on upload so the
  optimistic object the app inserts is complete, not just `{id, title,
  file_url}`.
- **I3 (Job Sheets "More Filters" non-interactive)**: investigated
  `lib/modules/projects/tabs/job_sheets_tab.dart` thoroughly - the button is
  wired to `_openMoreFiltersSheet`, quick filter dropdowns call `setState`,
  and `_filteredJobSheets` correctly reads every filter field client-side.
  Could not find a defect via code review. Left as "needs device
  verification" rather than guess at a fix with no evidence of what's
  actually broken.
- **I9 (Specifications tab toolbar/Open button)**: added an explicit "Open"
  button to each specification card (previously only tap-to-open via
  `InkWell`, no visible button); added "Manage Attributes" (bottom sheet
  listing/adding/deleting project-level attribute *definitions* - reuses the
  `ProjectSpecificationAttributeDefinitionsAPIView` built earlier this
  session, new methods added to `SpecificationController`) and "Get Report"
  (downloads/shares a CSV, new `?export=csv` query param added to
  `ProjectSpecificationsAPIView` in `API/views.py`, mirroring the web's
  existing `project_specifications_report` CSV export exactly - same
  column set: Name/Code/Price/Locations/Total Value).

Backend tests run narrowly per the user's instruction:
`test_project_list_includes_owner_contractor_and_location_count` (fixed an
off-by-one in an assertion someone else concurrently appended to that test
function - not something I originally wrote) and the new
`ProjectSpecificationAPITests.test_export_csv`, both passing individually.
Flutter: full `flutter analyze` clean (0 errors) after this batch.

Remaining from this batch: I4 (Approvals tab), I5 (Locations/Site Manager
mismatch), I6-I8 (Incidents trio), I10 (Project Setup redesign, large),
I11 (Manager Diary webview cut-off layout), I12 (signature/photo scroll
lock, previously investigated and unresolved).

## 2026-10-10 — Fourth bug batch from P:\Euroside_Project\bug.md (J1/J3-J9/J11 done; J2/J10 deferred)

12 more items added to the same scratch file (2 duplicate pairs deduped,
one already fixed as H1). Full detail/root-causes for each item are in
report.md's "Fourth batch" table; this is the narrative summary.

- **J3/J4 (Teams)**: Add Team modal was missing Nickname/Team Lead/
  Associated Projects fields; backend `AdminTeamsAPIView.post()` already
  accepted `nickname`/`lead_id` but never wired `project_ids` at all. Added
  the three fields + wired `project_ids` server-side (mirrors web's
  `team.selected_projects.set()` + `sync_project_team_assignments`). Found
  and fixed a real latent crash while testing: a JSON int `lead_id` (vs a
  web form's always-string) crashed `.strip()` with `AttributeError`. Also
  added a card-level three-dots menu (Team Details/Members/Shift Timezone/
  Delete Team) - the actions already existed inside `TeamDetailScreen`, just
  had no quick shortcut from the list like web has.
- **J5/J6 (Members/Guests)**: three-dots menus completed (View Profile/
  Update Member/Change Password/Convert to Guest/Delete Member; Convert to
  Member on the Guests side); new backend endpoints
  `members/<id>/change-password/`, `members/<id>/convert-to-guest/`,
  `guests/<id>/convert-to-member/` (all thin wrappers reusing existing web
  action helpers in `admin_app/views.py`). Found and fixed a real latent
  crash in the shared `convert_member_to_guest()` helper:
  `GuestInvite.first_name`/`last_name`/`phone` are NOT NULL but the source
  member's own fields can be `None` - fixed with `or ''` fallbacks
  (benefits the web action too, not just the new mobile API). Wired Export
  (backend already had it) + Role filter + Reset on both list screens.
  Add Qualification (Members) and Import Excel (both) deferred - no
  backend capability exists anywhere for either, genuinely new features.
- **J7 (Permissions matrix)**: three real bugs in
  `admin_permissions_controller.dart` - (1) fetch/save hit
  `.../roles/<id>/`, which only matches the pure-numeric-id route and
  404'd silently for every role (`role.id` is always prefixed,
  `system:admin`/`custom:5`), leaving every checkbox stuck at its all-
  false init state; (2) save used PATCH against an endpoint that only
  defines GET/POST; (3) payload was sent bare instead of wrapped under
  `{"permissions": {...}}`. Fixed all three.
- **J8/J9 (Activity Logs)**: export buttons used `launchUrl()` with no
  auth header against an endpoint with no query-string-JWT support - every
  tap silently 401'd; switched to authenticated fetch+share. Low-contrast
  export icons were a hardcoded dark navy color regardless of theme - made
  theme-aware. KPI cards always showed 0 because
  `AdminActivityLogsKPIAPIView` returned an entirely different field set
  than what the UI's 5 cards read - rewrote to match the web admin's
  manager-scoped stats exactly. List/export were also unscoped (should be
  manager-only, like web); and the list never read pagination at all, so
  it silently capped at the API's default first page of 20 (of 109) -
  added real `loadMoreLogs()` + a "Load More" control.
- **J11 (Dashboard)**: `dashboard.dart` rendered the Admin-only 9-card KPI
  set for every role including Manager, leaking staff-headcount metrics a
  Manager shouldn't see and not matching `contractor_dashboard.html`'s
  real 6-card set. Added a role branch (`user.effectiveRole`) - same
  backend response already has all needed data, this was purely a missing
  UI branch.
- **J1 (Material Details)**: backend (`AdminMaterialDetailAPIView.patch`)
  already fully accepted `input_type`/`material_group`/`tag_ids`/
  `certification_document` - the Details tab just displayed Group/Type as
  plain read-only text with no Tags UI at all. Added an editable Input
  Type dropdown (against `Material.INPUT_TYPE_CHOICES`), a Material Group
  dropdown (fetches `/admin/material-groups/`), and a Tags multi-select
  (fetches `/admin/material-tags/`, one `FilterChip` per tag). Cert
  Document upload already exists via the Attachments tab, left as-is.

Backend tests run narrowly per the user's "don't re-run old tests"
instruction, each run individually and passing: new
`AdminActivityLogsAPITests` (2 tests), the new
`test_create_team_with_nickname_lead_and_projects`, the new
`AdminMemberChangePasswordAndConvertToGuestAPITests` (4 tests), the new
`AdminGuestConvertToMemberAPITests` (3 tests). Flutter: full
`flutter analyze` clean (0 errors) after every item in this batch.

Deferred: J10 (Project Setup tab full redesign, same large/open-ended
item as I10, still deferred).

## 2026-10-10 — J2 (Forms library "locked") - backend gap, not a UI gap

User explicitly authorized working on this despite the earlier "don't
touch Forms builder" instruction, after I flagged the conflict via
AskUserQuestion - clarified as fixing the existing list screen, not
building a new form builder.

Investigated `library_screen.dart`'s `_buildFormsTab` first per the
verify-then-report workflow, expecting to need to build clickable
cards/pagination/filters/view/delete/created-date from scratch. All of
that UI already existed - built in an earlier session, commit
`48cdea1` ("full web admin parity for Forms tab"). So the user's
complaint had to be coming from somewhere else: traced it to two real
backend gaps that made the already-built UI non-functional:

- `LibraryFormsCatalogAPIView` (`API/views.py`) was documented and
  built as read-only (GET only). The app's "+ Add Form" button POSTs
  to the same URL - with no `post()` defined, DRF auto-returns 405,
  so every tap silently failed (the Flutter side at least has a
  friendly message for this case). "Delete" DELETEs
  `/library/forms/<id>/`, which had no URL route at all - plain 404
  from Django's resolver, HTML body, not JSON, so `jsonDecode` threw
  and the user saw a raw exception string.
- The GET endpoint never read `status`/`search` from the query
  string at all, even though the Flutter screen's Status dropdown and
  search box were already sending both - so the "Filters" the bug
  report called missing were actually present in the UI but silently
  no-ops server-side.

Fix, scoped to match the web exactly (not a new form builder):
added `POST` to `LibraryFormsCatalogAPIView` (bare `name`-only create
via `get_or_create`, mirrors `library_form_create_view`); added a new
`LibraryFormDetailAPIView.delete()` that archives rather than hard-
deletes (mirrors `library_form_archive_bulk_view` - checked and
confirmed there is no hard-delete for forms anywhere, even on the
web, since forms can be referenced by existing submissions); wired
`status`/`search` into the GET queryset. Renamed the Flutter card's
"Delete" action to "Archive" (icon, tooltip, confirm dialog, method
name `archiveForm`) to honestly describe what it now does, since
calling a soft-archive "Delete" would be misleading.

Backend: new `LibraryCatalogAPITests.test_create_form_then_archive_removes_it_from_active_list`,
run individually, passing; also reran the 3 pre-existing tests in
that class to confirm the new status/search filtering didn't break
the RBAC-gated list behavior. Flutter: full `flutter analyze` clean
(0 errors). Backend pushed to origin/main (`4657d36`); Flutter
committed locally only, per standing rule.

## 2026-10-10 — Merged origin/Harman into main; cross-checked against ClickUp

User asked to pull and merge Harman's branch, then for every
conflicting/incoming change to check which ClickUp ticket ("Euroside
admin app" list) it actually matched and resolve accordingly, rather
than just picking a side blindly.

`origin/Harman` had diverged at `34c5df8` with 17 commits across
add_attendance_dialog.dart, admin_members_view.dart/controller.dart,
job_sheet_controller.dart/screen.dart, productivity_controller.dart/
screen.dart, workforce_planner_screen.dart, admin_material_controller.dart,
material_detail_screen.dart, profile_controller.dart/screen.dart, plus
announcements/support files. `git merge --no-commit --no-ff` produced
7 real conflicts; the rest auto-merged.

For each conflict, looked up the matching ClickUp ticket before
resolving:
- Add Attendance modal (`add_attendance_dialog.dart`): ticket
  14yjutqfhbh (cascading dropdown dependencies broken, "Job 22
  (Mocked for API)" debug string exposed, missing task-sheet multi-
  select/default times/location helper text/double-asterisk). Read
  the ticket's full comment text and grepped Harman's 941-line
  rebuild for the exact phrases quoted in the ticket ("Select
  operative first", "Select one or more task sheets.", "Project
  location will be used if current location is not added.") - all
  present verbatim, confirming his rebuild is the real fix, not a
  parallel/older attempt. Took it wholesale over this repo's own
  older cascading-dropdown implementation.
- Workforce Planner, Productivity: same approach - ticket numbers
  14yjutqfha0/14yjutqfh93 and 86d3umczz/86d3um93w/86d3um8dh, all
  "dev done", sizes 2x+ the old files confirming full rebuilds. Took
  Harman's versions.
- `admin_members_view.dart` (6 conflicts, the one file this session
  had also touched for J5): ticket 14yjutqfhh5 (Active/Pending
  segmented tabs, dev done) was Harman's addition; this session's own
  work (role filter dropdown, Export, Reset, the 5-action member
  three-dots menu: View Profile/Update Member/Change Password/
  Convert to Guest/Delete Member) was not represented on his side at
  all - his equivalent card only had Edit Profile/Remove Member. Hand-
  merged: kept his tab structure, summary card, and pending-invite
  card wholesale, re-added this session's menu actions/dialogs/filter
  bar on top. Confirmed `admin_members_controller.dart` (auto-merged
  clean) already exposes both `statusFilter`/`setStatusFilter` (his)
  and `roleFilter`/`setRoleFilter`/`changePassword`/`convertToGuest`
  (this session's), so no controller changes were needed.
- `job_sheet_controller.dart`/`job_sheet_screen.dart`: small, genuine
  independent fixes on both sides (status-string formatting extracted
  to a helper; Daily Report material cost/charge detail fields) -
  took Harman's version where it was the cleaner superset in each
  case.

Found two pre-existing typos already present in `origin/Harman`
itself (verified via `git show origin/Harman:<file>`, so not
introduced by the merge): `cclass ApiEndpoints` in
`api_endpoints.dart` and `iimport 'dart:convert';` in both
`login_controller.dart` and `profile_controller.dart`. The single
`ApiEndpoints` typo alone cascaded into 753 `flutter analyze` errors
project-wide (every file referencing `ApiEndpoints.baseUrl` etc.
failed to resolve). Fixed all three; full `flutter analyze` clean (0
errors) after.

Immediately after the merge, user reported ticket 14yjutqfhqp
verbatim ("Change Password missing from Profile, organizational
fields wrong, View full audit log link should be removed"). The
Flutter side (Change Password button, full Profile Details grid:
Full Name/Email/Username/Mobile/Company Name/Role Type/Account
Status/Joining Date/Last Login, no audit log link) had just arrived
with the Harman merge and already matches the web's
`admin_profile.html` grid field-for-field - confirmed by reading that
template directly. Two fields still looked wrong: Company Name and
Last Login. Traced to a real backend gap: `UserSummarySerializer`
(`API/serializers.py`) never exposed `company_name` or `last_login`
in its `Meta.fields` tuple at all, even though
`user_model.dart`'s `User.fromJson` already prioritized exactly those
two JSON keys ahead of its hardcoded fallbacks - so the backend gap
was the entire bug, no Flutter change needed. Added
`get_company_name` (mirrors web's `OrganisationSettings.get_solo().name`)
and `get_last_login` (mirrors `profile_user.last_login`, Django's
built-in field, previously just never serialized). New test
`test_profile_api_returns_company_name_and_last_login` in
`UserProfileAndSetPasswordApiTests`, run individually plus the 4
sibling tests in that class, all passing. Backend pushed to
origin/main (`a4d94d0`).

Flutter merge commit is local-only so far (standing rule - never
pushed without explicit instruction), pending the user's confirmation
since merging another developer's branch into shared main is exactly
the kind of action worth a check before it goes out.

## 2026-10-10 — Closed the four remaining "not done" items (J5 Add
## Qualification, J5/J6 Import Excel, ClickUp member-count mismatch)

User asked which points from the whole session were still outstanding;
answered with a 7-item list, then asked to fix 4 of them (the other 3 -
J10 redesign, I3, I12 - stayed deferred, too open-ended/unverifiable to
just pick up).

- **Member count mismatch (ClickUp 14yjutqf9c4)**: investigated by
  diff-ing the mobile `AdminMemberListAPIView` query against the web's
  `member_list` view line by line. Role scoping was already identical
  (both use `member_role_values()`, confirmed). The real difference:
  web's final queryset chains `.filter(is_active=True).exclude(
  is_password_set=False, last_login__isnull=True)` - an account that's
  technically active but never completed setup is still a pending
  invite in web's eyes, not a counted member. Mobile's query stopped
  at the plain `is_active=True` filter, so it always counted a
  different (larger) set than web. Fixed both
  `AdminMemberListAPIView` and `AdminMemberExportAPIView` to apply the
  same exclude; while in there, deduplicated both to call the shared
  `member_role_values()` helper instead of each repeating
  `list(dict(EuroUser.MEMBER_ROLE_CHOICES).keys()) + [EuroUser.ROLE_CUSTOM]`
  inline - a second grep for the same literal turned up the export
  view too, which the first edit pass had missed despite already
  adding the (then-unused) import there.
- **Add Qualification**: before building anything, checked the web for
  what this even was - turned out `MemberQualification` is a real,
  already-existing model with full `add_qualification`/
  `delete_qualification` actions on `member_detail`, not a feature
  that needs inventing. Added `AdminMemberQualificationsAPIView`
  (POST) / `AdminMemberQualificationDetailAPIView` (DELETE) reusing
  that exact model and validation (title required, expiry can't
  predate issue date); `AdminMemberDetailAPIView.get()` now attaches
  a `qualifications` list via a small serializer helper (kept out of
  the list endpoint's serializer deliberately, to avoid N+1 queries
  across 20-100 members on every list fetch). Flutter: new
  `QualificationsDialog` (list/add/delete, with an optional file
  attachment via `FilePicker`), wired as a new "Add Qualification"
  item in the member three-dots menu; it fetches the member detail
  fresh on open since the list screen's own member objects never
  carry qualifications.
- **Import Excel (Members + Guests)**: same investigation first - the
  web already has complete `import_members_from_xlsx()` /
  `import_guests_from_xlsx()` helpers and
  `user_import_template_response(kind)` for the template download,
  all exercised by existing web actions. Added four thin mobile
  endpoints that call these helpers directly (not reimplementations):
  `AdminMembersImportTemplateAPIView`/`AdminMembersImportAPIView`,
  `AdminGuestsImportTemplateAPIView`/`AdminGuestsImportAPIView`.
  Members import blocks managers explicitly, matching web's own
  `is_manager_member_scope` guard on that specific action (web doesn't
  apply the same restriction to guest import, so mobile doesn't
  either). Flutter: both Members and Guests screens gained an upload-
  icon toolbar button opening an Import dialog (Download Template /
  Choose .xlsx File / Import), reusing the same
  `getTemporaryDirectory()` + `Share.shareXFiles()` pattern already
  used for every other download/export in this app.

Backend tests, each run individually and passing: `test_never_logged_in_member_excluded_from_active_count`,
3 new tests in `AdminMemberQualificationsAPITests`, 4 new tests across
`AdminMembersImportAPITests`/`AdminGuestsImportAPITests`; also reran
`LibraryCatalogAPITests` and `AdminMemberChangePasswordAndConvertToGuestAPITests`
(8 tests) as a sanity check since this touched the same view file
repeatedly. Flutter: full `flutter analyze` clean (0 errors) after
every change. Backend pushed to origin/main (`23a81ae`).

## 2026-10-10 — Job Sheet PDF download: missing images + needs horizontal scroll

User reported downloading a Job Sheet PDF on mobile has no images and
the sheet doesn't display in full, needing left-right scroll to read
it.

Traced the Flutter download flow (`job_sheet_screen.dart`'s
`_downloadJobSheetPdf()` and the project-level PDF download) - both
hit `GET /api/job-sheets/?ids=...&export=pdf`, check the response for
a real PDF (content-type + `%PDF` magic bytes), and if it's NOT a
real PDF, fall back to opening the job sheet's HTML form view in an
in-app `JobSheetWebviewScreen`. That fallback logic was already
correct - the actual bug was on the backend: `JobSheetListAPIView`
only ever handled `export` values of `csv`/`excel`/`true`; `pdf` fell
straight through to the normal JSON list response, so the Flutter
check always failed and always took the webview fallback. The webview
is the literal source of both symptoms: it loads the form's raw HTML
(unauthenticated image sub-resource requests silently fail) and isn't
styled responsively for a phone width (hence the horizontal scroll).

Fix: added an `export_format == "pdf"` branch to
`JobSheetListAPIView.get()` that calls the web's own
`render_job_sheets_list_combined_pdf(rows)` - the exact function the
web's `job_sheets_list` view already uses for its own `?report=pdf`,
operating on the same `rows` this mobile view already builds via
`build_job_sheets_list_rows`/`apply_job_sheets_list_filters`. Verified
by reading the ReportLab renderers themselves
(`render_single_job_sheet_pdf`/`render_form_submission_pdf`, depending
on whether the row is template- or form-based) that images are
embedded from local `MEDIA_ROOT` file paths (not fetched over HTTP),
and pages are fixed-width A4 - so this one fix resolves both symptoms
at once, and also covers the "Download Project PDF" button since it
hits the same endpoint with a different `ids` list.

No Flutter changes needed - its PDF-vs-fallback detection was already
correct, it just never got handed a real PDF to detect. New backend
test `test_export_single_job_sheet_as_pdf` (plus the 5 sibling tests
in that class, rerun as a sanity check). Pushed to origin/main
(`4e4ac53`).
