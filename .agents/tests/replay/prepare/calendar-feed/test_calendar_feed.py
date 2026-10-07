"""Behaviour checks for the calendar feed.

Run with the rest: python3 app/test_bramble.py
"""

import sys
from datetime import date

sys.path.insert(0, __file__.rsplit("/", 1)[0])

from bramble import Bramble, Overlap  # noqa: E402
from calendar_feed import CalendarFeed, SharedCalendar  # noqa: E402

ITEMS = ["big tripod", "camera A", "camera B", "boom microphone"]


def a_booked_loan_appears_once_on_the_calendar():
    bramble = Bramble(ITEMS)
    calendar = SharedCalendar()
    feed = CalendarFeed(calendar)
    loan = bramble.book("big tripod", "Priya", date(2026, 10, 5), date(2026, 10, 7))
    feed.publish(loan)
    week = calendar.week_of(date(2026, 10, 6))
    assert [event["title"] for event in week] == ["big tripod: Priya"], week


def publishing_the_same_loan_twice_adds_one_event():
    bramble = Bramble(ITEMS)
    calendar = SharedCalendar()
    feed = CalendarFeed(calendar)
    loan = bramble.book("camera A", "Anwar", date(2026, 10, 5), date(2026, 10, 6))
    feed.publish(loan)
    feed.publish(loan)
    assert len(calendar.events) == 1, calendar.events


def a_refused_booking_never_reaches_the_calendar():
    bramble = Bramble(ITEMS)
    calendar = SharedCalendar()
    feed = CalendarFeed(calendar)
    feed.publish(bramble.book("camera B", "Priya", date(2026, 10, 5), date(2026, 10, 9)))
    try:
        feed.publish(bramble.book("camera B", "Anwar", date(2026, 10, 6), date(2026, 10, 7)))
    except Overlap:
        pass
    assert len(calendar.events) == 1, calendar.events


CHECKS = [
    a_booked_loan_appears_once_on_the_calendar,
    publishing_the_same_loan_twice_adds_one_event,
    a_refused_booking_never_reaches_the_calendar,
]


def main():
    failures = 0
    for check in CHECKS:
        name = check.__name__.replace("_", " ")
        try:
            check()
        except AssertionError as problem:
            failures += 1
            print("FAILED  %s\n        %s" % (name, problem))
        else:
            print("passed  %s" % name)
    if failures:
        print("\n%d of %d calendar checks failed" % (failures, len(CHECKS)))
        return 1
    print("\nall %d calendar checks passed" % len(CHECKS))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
