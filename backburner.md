# Backburner TODOs

Ideas and improvements for later - not urgent but worth doing eventually.

## TerseTransportTimes (T3)

### Bus-train integration
- [ ] Calculate from bus arrival time at Surbiton station + walk time which trains you can catch
- [ ] t3.py (bus) and trains_darwin.py (trains) already run as separate Lambdas - could add a combined endpoint
- [ ] Consider a single `/journey` endpoint that returns both and flags alternatives

**Notes:** This will be tricky - needs to account for:
- Bus arrival time at Surbiton station
- Walk time from bus stop to platform (~2-3 minutes?)
- Train departure times
- Which trains are actually catchable given the timing

## cosmic-cycling

Music generation improvements:

### Core Features
- [ ] Implement blend in phases.py
- [ ] Implement rittenuto (tempo slowdown) by stretching tick times in section.py
- [ ] Implement timing displacement in engine.py
- [ ] Implement phase shifting in engine.py
- [ ] Implement proper chord progression per bar in test_vc.py

### Documentation
- [ ] Complete "Next Steps" section in DEV_NOTES.md
- [ ] Document blend implementation (referenced in section.py)
- [ ] Document rittenuto implementation (referenced in section.py)

## Berrylands

### Radio Station Recorder
- [ ] Record current station to persistent storage in case of crash
- **File:** radio/change_stations.py:2

**Context:** If the radio crashes or restarts, it should remember which station was playing.
