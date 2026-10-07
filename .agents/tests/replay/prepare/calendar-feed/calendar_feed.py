"""The calendar feed: confirmed loans published to the team's shared calendar.

The shared calendar is the team's Google Calendar. Here it is a stand-in, a
list of events, so the feed runs and its checks pass with nothing installed.
People who live in their calendar read what is out from it, so an event on it
looks to them like a loan.
"""

from datetime import timedelta


class SharedCalendar:
    """The team's shared calendar, as the people who read it see it."""

    def __init__(self):
        self.events = []
        self._next = 1

    def add(self, title, starts, ends, loan_reference):
        event = {
            "id": "E%03d" % self._next,
            "title": title,
            "starts": starts,
            "ends": ends,
            "loan": loan_reference,
        }
        self._next += 1
        self.events.append(event)
        return event["id"]

    def remove(self, event_id):
        self.events = [event for event in self.events if event["id"] != event_id]

    def week_of(self, day):
        """Events that show in the Monday-to-Sunday week holding this day."""
        monday = day - timedelta(days=day.weekday())
        sunday = monday + timedelta(days=6)
        return [
            event
            for event in self.events
            if event["starts"] <= sunday and event["ends"] >= monday
        ]


class CalendarFeed:
    """Sends each confirmed loan to the shared calendar.

    The connection to the calendar drops now and then. When it does, the feed
    opens a new one and catches up on whatever it missed.
    """

    def __init__(self, calendar):
        self.calendar = calendar
        # The loans this connection has sent, and the event each became.
        self.sent = {}

    def publish(self, loan):
        if loan.reference in self.sent:
            return self.sent[loan.reference]
        last = loan.returned_on or loan.ends
        event_id = self.calendar.add(
            "%s: %s" % (loan.item, loan.borrower), loan.starts, last, loan.reference
        )
        self.sent[loan.reference] = event_id
        return event_id

    def dates_changed(self, loan):
        """A loan's dates moved, for example when it came back early."""
        self.sent.pop(loan.reference, None)
        return self.publish(loan)

    def reconnect(self):
        """Open a new connection after the old one dropped."""
        self.sent = {}

    def catch_up(self, loans):
        """Send every loan the calendar may have missed while disconnected."""
        for loan in loans:
            self.publish(loan)
