# Audio Scheduling Upgrade

## Timing Contract

The audio engine plays unchanged cached click samples at explicit sample times.
Swift tasks replenish the schedule; waking a task never defines a click's onset.
Already committed beats are immutable. The latest pending edit applies at the
next uncommitted beat, without moving that beat's existing deadline. Its interval
determines subsequent spacing. Pattern changes preserve beat position modulo the
new count unless an explicit restart requests beat zero. Silent beats remain
part of the timeline. Click tails overlap rather than being cut or time-stretched.

Stop must clear scheduled audio immediately. Starting again creates a fresh
timeline. A late refill must skip expired beats, report the scheduling underrun,
and resume at a future boundary without a catch-up burst. The UI must follow the
committed audible timeline, not assume a requested edit is already playing.

## First Checkpoint (Historical)

MetronomeBeatSchedule implements absolute sample deadlines and latest-pending
edit replacement. Offline AVAudioEngine tests inspect rendered click positions
and unchanged samples across a tempo edit. The current live player remains in
use; this candidate is not yet connected to playback.

## Validation Goals

Implement a bounded look-ahead window and reusable voice pool for overlapping
tails. Add underrun, cancellation, stop/restart, long-run drift, and pool-capacity
tests through the production scheduling path. Compare measured edit latency and
resilience under delayed refills before choosing the look-ahead duration. Expose
the applied beat/configuration to presentation, then test audible behaviour on
simulator and device. Retain the existing player until that evidence supports
replacement. This checkpoint makes no performance-improvement claim.

## Second Checkpoint: Bounded Refills and Overlapping Voices (Historical)

The candidate refill policy accepts windows no larger than 250 milliseconds;
this is a safety ceiling, not a measured live scheduling choice. It does not
duplicate committed events. Late refills count and skip expired beats using
arithmetic rather than an unbounded catch-up loop. The count is returned to the
future audio owner for underrun reporting.

A fixed-capacity voice reservation policy reuses a voice only after its previous
click ends. Exhaustion is an explicit error rather than permission to truncate
audio. The offline engine probe uses two reusable nodes and checks overlapping
tails at their original sample offsets. These policies are still candidates:
the live refill task, production voice capacity, stop/restart lifetime, and
audible-state publication have not been connected to the current player.

## Third Checkpoint: Live Integration for Developer Verification

The production player now uses the scheduler and voice reservations. Capacity
is derived from the longest click and minimum supported interval, capped at 64
voices. One actor-owned task refills a 100 ms window every 20 ms with 10 ms lead.
Stop clears scheduled nodes, reservations, and progress; generation checks
reject obsolete work after restart. Underruns and refill errors reach the UI.

Progress carries the committed beat index and monotonic event sequence.
Configuration controls still display requested values while committed audio
finishes; full applied-configuration presentation is not implemented here.

The old time-stretching path and loop-specific tests were replaced; Git retains
the baseline. The complete MetronomeTests target passed, including production
tempo/pattern edits and stop/restart checks. This is a live integration for manual
evaluation, not final performance acceptance. Device profiling, audible latency,
stress testing the margins, and sample-level capture of the full production path
remain outstanding.
