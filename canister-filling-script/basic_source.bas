# Automatic gas-canister filler.
# !!! Remember to set volume pump to no more !!!
# !!! than 10 L; I run 2 L for safety !!!

ALIAS CanisterStorage d0
ALIAS FillPump       d1
ALIAS EvacPump       d2
ALIAS Analyzer       d4

# Hashes for canister types (keep as integers you used)
CONST CANISTER       =  42280099
CONST SMARTCANISTER  = -668314371

Start:
    yield ()    # pause one tick

    # --- Check slot 0 for a canister and identify it
    VAR canPresent = CanisterStorage[0].Occupied
    VAR canHash    = CanisterStorage[0].OccupantHash

    # --- Decide safe fill pressure by canister type
    VAR fillPressure = 8 MPa     # default for regular cans
    IF canHash == SMARTCANISTER THEN
        fillPressure = 18 MPa
    ELSEIF canHash == CANISTER THEN
        fillPressure = 8 MPa
    ENDIF

    # --- Fill: only if a can is present and pressure is below target
    VAR storagePressure = CanisterStorage[0].Pressure
    VAR gasToMove       = (storagePressure < fillPressure)
    VAR pumpActive      = gasToMove && canPresent

    FillPump.On = pumpActive

    # If no can is present, evacuate the pipe
    IF canPresent == false THEN GOTO Evac
    ENDIF
    
    GOTO Start

Evac:
    # Evacuate analyzer line until it reads 0 kPa
    VAR pipePressure = Analyzer.Pressure
    VAR hasGas       = (pipePressure > 0)
    EvacPump.On = hasGas

    IF hasGas THEN GOTO Evac
    ENDIF
    GOTO Start
    