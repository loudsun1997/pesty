# Upstream PR readiness review

The experimental #105/#107 integration has been removed from main. Runtime
code is restored to the previously approved immediate-selection update at
`99df5fd885e1ffa51571ff642e27dc573c26c978`.

The experiment, authorship, layout tests and native probes remain available on
the fork's `codex/integrate-upstream-fixes` branch for review. That branch is
not an approved release.

## Current disposition

| Proposal | Disposition | Evidence and missing checks |
| --- | --- | --- |
| [#105: Command-arrow section navigation](https://github.com/momenbasel/pesty/pull/105) | Candidate for approval; not on main | Small routing change. Native fixture tests passed section switching with search focused, query retention, Command-Shift text selection and ordinary caret movement. Those tests ran with the combined panel experiment; isolate this fix and review its shortcut policy before adopting it separately. |
| [#106: Chrome password-field visibility](https://github.com/momenbasel/pesty/pull/106) | Hold | Author reports successful live Chrome tests and an unexplained early-hide run. Live Secure Event Input, the physical hotkey and paste into the originating app were not independently reproduced here. |
| [#107: Full-screen and side-Dock changes](https://github.com/momenbasel/pesty/pull/107) | Hold | Alters panel activation, Space membership and display width. Its author lists final side-Dock visual confirmation as pending. Our geometry tests establish rectangle calculations, not actual Dock overlap or full-screen Space behavior. |

All three PRs are open and non-draft. No submitted reviews or approvals were
returned by the review API, and no check runs or commit statuses were returned
by the checks API at review time. These are evidence gaps, not proof of a defect.

## Why passing local tests did not establish readiness

The combined experiment passed 15 unit tests, the existing gesture/strip
probes, and three bundled fresh-launch panel runs. However, an earlier
unbundled panel run lost focus and closed before the keyboard checks. Other
runs passed. Changing the fixture packaging and getting passing runs did not
explain that failure or establish that the full production flow is reliable.

The fixture does not start the app delegate, clipboard polling or global
hotkey, does not invoke paste, and does not recreate a foreign full-screen
Space or a live Chrome password field. These limitations affect the central
claims of #106/#107. Builds and synthetic tests were insufficient grounds for
promoting those changes to main.

## Work required before promotion

- Evaluate #105 independently on the approved panel behavior, including its
  intentional override of Command-Left/Right in the search field.
- Reproduce the Chrome password-field failure on the approved build, then
  verify visibility, Escape, hotkey toggling and paste targeting on the fix.
- Reproduce native full-screen Space behavior with another application and
  verify that showing, hiding and pasting preserve the intended Space/focus.
- Visually check real left/right/bottom Docks and resizing, including whether
  the expanded strip overlaps the Dock or obscures edge cards.
- Investigate intermittent first-show hiding instead of treating subsequent
  passing launches as an explanation.

The 1.3.2 experimental bundle is retained under `.build/review-artifacts/` as
unapproved. It was not installed. The installed app remains the previously
tested 1.3.1 click-delay fix.
