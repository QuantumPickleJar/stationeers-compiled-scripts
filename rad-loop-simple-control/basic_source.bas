ALIAS tempCheck d0
ALIAS evacPump  d1
# check cooled side to avoid bursting
ALIAS radsCheck d2 
ALIAS coolantValve d3

CONST MIN_PRESSURE = 3 mPA
CONST MAX_PRESSURE = 55 mPA

CONST DESIRED_TEMP = 20 C


# condensation prevention
# CONST DANGER_TEMP 
# CONST DANGER_PRESSURE 

# if tempCheck.Temperature


Start: 
    yield()
    
    VAR inputPressure = tempCheck.Pressure
    VAR inputTemp = tempCheck.Temperature
    
    # content-based temperature safety
    
    
    # if there is gas in the radiator pipe, evacPump should come on
    IF (inputPressure > 40 MPa) || (inputTemp < DESIRED_TEMP) THEN 
        coolantValve.Setting = 0
        # evacPump.Setting = 1
    ELSEIF (inputTemp >= DESIRED_TEMP) THEN
        coolantValve.Setting = 1
        # evacPump.Setting =
    ENDIF

    GOTO Start
    