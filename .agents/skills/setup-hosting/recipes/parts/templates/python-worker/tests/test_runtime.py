import pytest

from src import runtime


@pytest.fixture(autouse=True)
def reset_poll_state() -> None:
    with runtime.poll_state_lock:
        runtime.poll_state["failures"] = 0


def test_repeated_poll_errors_make_health_unhealthy(
    monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    def unavailable() -> bool:
        raise OSError("queue unavailable")

    monkeypatch.setattr(runtime, "consume_one", unavailable)
    for _ in range(runtime.POLL_FAILURE_LIMIT):
        assert runtime.poll_once() is False

    assert runtime.health_status() == 503
    assert capsys.readouterr().err.splitlines() == [
        "document worker poll failed: OSError",
        "document worker poll failed: OSError",
        "document worker poll failed: OSError",
    ]


def test_successful_poll_clears_prior_failures(monkeypatch: pytest.MonkeyPatch) -> None:
    def readable() -> bool:
        return False

    monkeypatch.setattr(runtime, "consume_one", readable)
    with runtime.poll_state_lock:
        runtime.poll_state["failures"] = runtime.POLL_FAILURE_LIMIT

    assert runtime.poll_once() is False
    assert runtime.health_status() == 200
