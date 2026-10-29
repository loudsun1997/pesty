# Upstream fixes adopted by this fork

These changes build on the immediate-selection fix already in this fork.
The upstream PR branches were reviewed together because two proposals overlap.
The original authors and source commit IDs are retained by `git cherry-pick -x`.

## Adoption decisions

| Upstream proposal | Decision | Reason |
| --- | --- | --- |
| [#105: Switch sections with Command-Left/Right while search is focused](https://github.com/momenbasel/pesty/pull/105) | Adopted from `ba146112d510fbea6c76a600fbc9cb62aede36d5` | Handles the existing section shortcut before search-field passthrough. Shift-modified arrows retain native query selection; ordinary arrows retain caret editing. |
| [#106: Keep the bar open over Chrome password fields](https://github.com/momenbasel/pesty/pull/106) | Mechanism included through #107 | Both proposals add `.nonactivatingPanel`. Applying it again would duplicate the same style-mask change. #106's separate explicit-activation behavior is superseded by #107. |
| [#107: Full-screen visibility and side-Dock spacing](https://github.com/momenbasel/pesty/pull/107) | Adopted from `2cd4ebb818b69196b587ec223f033959dc890cbd` | Uses a nonactivating panel that can join other applications, removes explicit app activation on show, and spans the display horizontally while preserving visible vertical bounds. |

The #107 width calculation is extracted into `BarResizeGeometry.layoutFrame`
without changing its calculation. The controller uses the resulting bounds
for presentation and subsequent resizing. Five unit tests cover left/right
Docks, bottom-Dock/menu-bar exclusions, negative display origins, and resize
cancellation retaining the full display width.

`canJoinAllApplications` is available from macOS 13 in the installed AppKit
SDK, which is earlier than this app's macOS 14 minimum. The collection behavior
is intended for floating windows and overlays. The current combination does
not include the mutually exclusive `primary` or `auxiliary` behaviors.

## Reproduction

From a logged-in macOS GUI session:

```sh
swift test
bash scripts/check_panel_behavior.sh
bash scripts/check_bar_navigation.sh
bash scripts/check_card_interactions.sh
```

Run the GUI probes sequentially: they each need keyboard focus.

The panel probe compiles the production controller, panel, search field and
local key monitor into a disposable accessory-app bundle. It runs three fresh
launches with independent fixture history/preferences. There are no retries:
every launch must pass. It does not start the production app delegate,
clipboard polling or the global hotkey, and it never invokes paste.

The panel checks verify that:

- The panel stays visible and becomes key while the previous application
  remains frontmost.
- Command-Right/Left switch between history and a fixture pinboard while the
  actual native search field owns first responder.
- The search query survives section switching.
- Command-Shift-Left selects query text without switching sections.
- Ordinary Left moves the query caret without switching sections.
- Card clicks still select correctly and use the immediate-selection scroll
  policy inside the nonactivating panel.
- The panel hides cleanly after editing.

`NSApp.isActive` alone is not used as the frontmost-app test: in an unbundled
fixture it could report active while `NSWorkspace` still identified the
previous app as frontmost. The probe checks the actual frontmost process ID.

## Recorded validation and limits

Environment: Apple Silicon, macOS 15.7.5 (24G624), Swift 6.2.4.

- All 15 unit tests passed, including the five new display-layout regressions.
- The bundled panel probe passed all 15 checks on each of three fresh launches.
- All 10 strip integration checks passed, including actual scroll offsets,
  offscreen navigation, right-edge alignment, and context-menu dismissal.
- All 13 existing gesture scenarios passed. Updated selection callbacks took
  2.0–5.2 ms; the original-handler comparison took 356.1 ms in this run.
- The universal release app built successfully for arm64 and x86_64, and its
  local bundle signature verified. The local build is version 1.3.2 (11).

An earlier unbundled fixture launch lost focus and hid before keyboard checks;
other unbundled runs passed. That result was not reproduced in the three
bundled runs, but those runs do not rule out intermittent first-show issues.
#106's author also reports one early-hide run among otherwise passing checks.

The native checks run on the ordinary desktop. They do not reproduce another
application's native full-screen Space or a live Chrome password field holding
Secure Event Input. Those scenarios are supported by the PR authors' reported
manual testing, rather than independently reproduced here.

Side-Dock geometry is covered with synthetic screen rectangles; actual Dock
compositing/overlap, physical multi-monitor arrangements, macOS 14/26 runtime
behavior, and Intel runtime behavior still require manual validation. A
universal build establishes Intel compilation, not runtime interaction behavior.

No upstream PR is merged or changed by this adoption. The clipboard-selection
PR #108 keeps its focused branch; these additions are integrated into this
fork's main separately.
