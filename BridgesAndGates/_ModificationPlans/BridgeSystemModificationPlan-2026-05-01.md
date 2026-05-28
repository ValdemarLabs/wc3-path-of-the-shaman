Now need to handle situation where BridgeUnit leaves the bridge area either from start/end entries (C or D rect) or from the brige rect overall (e.g., teleport away)

EASY FIX that wouldnt require any pathing blocker usage? >>>>>>>> When any unit enters bridge - force it to Move to other end

Each time when unit enters bridge (upperside C or D entrance) its added to periodic timer evaluation - checking that if unit is on bridge or left (teleport / etc)

Bridge entries might need more rects to check if leaving the bridge

Scenario prevention; ship about to enter under bridge and unit on bridge >> pause ship and force all bridge units to move to other side >> unpause ship when no units on bridge
>> same logic could be applied across all bridges > on bridge units have priority AND must exit bridge before beliw units are allowed to go under

Prevent bridge units accepting other commands during move to other side
Prevent bridge units accepting other commands during move to other side

Add check if unit is issued order upon bridge entries > the system forcefully issues new move order to bridge entry and then the bridge Move handles the usual bridge crossover move order