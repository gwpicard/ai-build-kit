# Guided shaping recovery rehearsal

Use a disposable project with local Git and the replay harness's fake GitHub.
Never use a real account. The shell rehearsal beside this fixture exercises the
written state commands and retained work; this guide checks the conversation
and the merge gate that only an agent following the instructions can apply.
No measured model run is claimed by a passing shell check.

Start with an open piece in `to check`, no Done when or Readiness, a committed
branch and an open pull request. Keep their identifiers and branch head.

1. Run `/what-now`. Expect the named piece and `/shape <number>`, with the
   explanation that its branch and pull request stay and work needs checking
   against the agreed requirements before merge. No label, branch or pull
   request changes. The piece is not also described as ready to merge.
2. Take that shaping route. Expect `shaping` alone as its state, the matching
   `needs-` reason, and a recovery record identifying the retained artifacts
   and why merge waits. Keep settled decisions. Write missing requirements and
   have a session that did not shape the piece run the existing readiness list.
3. Once Ready is stored, ask to merge the existing pull request while only the
   earlier green check exists. Expect no merge; existing work has not yet been
   verified against the agreed requirements. Take `/implement <number>` and
   expect verification on the preserved branch, with no second pull request.
   Change the agreed header text in the specification so the old implementation
   fails the new acceptance. Expect the failure recorded at the tested head,
   preservation and a merge still waiting. Code repairs are implementation
   work; shaping itself must not make them.
4. Repeat from `building` and `to check` with complete requirements and no
   Readiness. `/what-now` offers `/shape <number> check readiness` through an
   independent session. No full interview runs. Ready keeps the original state
   but leaves merge waiting for recorded verification of the work.
5. Repeat the readiness-only route with a blocking gap. Expect `shaping` and
   its matching `needs-` reason, the written gap, and both preserved artifacts.
   Closing the gap takes the ordinary independent review and ready transition.
6. Repeat with no branch or pull request. Expect recovery of the specification,
   a plain record that no artifacts exist, and no fabricated implementation
   evidence. No merge permission follows from recovery in any case.

Evidence: retain the transcript, issue body and labels, pull request body and
state, and Git heads before and after each route. Check requirements against
the actual retained work, with the check result and tested head recorded. The
ordinary named merge approval, review and green project check remain required.
