CONST T_LIQ     = 265.15 K
CONST T_FREEZE  = 218.15 K

CONST P_MIN     = 517 kPa      
CONST P_WORK    = 550 kPa       # chamber target
CONST P_FEED    = 900 kPa
CONST P_TOL     = 25 kPa        # PR Hysteresis
CONST T_TARGET  = 245.15 K
CONST T_BAND    = 3 K           # deadband
CONST HEAD_PSET = 620 kPa       # pressurant in tank
CONST TANK_CAP  = 6000 kPa

ALIAS GS    = d0
ALIAS PR_IN = d1
ALIAS DV_IN = d2
ALIAS AC    = d3
ALIAS PRESS_V = d4
ALIAS TANK  = d5

VAR P_IN        # pressure of incoming gas
VAR T_IN        # temperature of incoming gas
VAR P_TK        # pressure in tank
VAR freezeRisk  # whether or not we're failing to meet T_TARGET
VAR currMode
VAR canStore
VAR inWindow

#init:
PR_IN.Setting = P_FEED

# keep headspace at or above minimum, clamped at P_MIN

IF HEAD_PSET < P_MIN THEN 
    PRESS_V.Setting = P_MIN
ELSE
    PRESS_V.Setting = HEAD_PSET
ENDIF

# prep AC cooler
AC.On       = 1
AC.Mode     = 0

AC.Setting  = (T_TARGET - 273.15)

# close feed until condensation window achieved
DV_IN.On = 0

# main loop
#Start:
WHILE(TRUE) 
    P_IN = GS.Pressure
    T_IN = GS.Temperature
    P_TK = TANK.Pressure
    # 1 update control statement
    # if T_IN <= -55 C AND P_IN < 517 kPa then we risk freezing
    freezeRisk = 0
    IF T_IN <= T_FREEZE THEN 
        IF P_IN < P_MIN THEN
          freezeRisk = 1
        ENDIF
    ENDIF  
    
    # 2 react to control statement
    IF freezeRisk == 1 THEN 
        DV_IN.On   = 0
        AC.Mode    = 0
        # keep headspace greather than P_MIN
        IF HEAD_PSET < P_MIN THEN 
            PRESS_V.Setting = P_MIN
        ELSE
            PRESS_V.Setting = HEAD_PSET
        ENDIF
        wait(0.2)
        CONTINUE
    ENDIF
    
    # 3 Maintain feed pressure
    IF P_IN < (P_FEED - P_TOL) THEN 
        PR_IN.Setting = P_FEED
    ELSEIF P_IN > (P_FEED + P_TOL) THEN
        PR_IN.Setting = P_FEED
    ENDIF
    
    # 4 AirCon with symmetric deadband around T_TARGET
    # turn OFF if T_IN < T_TARGET - BAND
    # turn ON if T_IN > T_TARGET + BAND
    # else keep previous mode
    currMode = AC.Mode
    IF T_IN > (T_TARGET + T_BAND) THEN
        AC.Mode = 1
    ELSEIF T_IN < (T_TARGET - T_BAND) THEN
        AC.Mode = 0
    ELSE 
        AC.Mode = currMode
    ENDIF
    
    # 5
    inWindow = 0
    IF T_IN <= T_LIQ THEN 
       IF P_IN >= P_MIN THEN
            inWindow = 1
       ENDIF
    ENDIF
    
    canStore = 1
    IF P_TK >= TANK_CAP THEN 
        canStore = 0
    ENDIF
   
    IF inWindow && canStore THEN
        DV_IN.On = 1
    ELSE 
        DV_IN.On = 0
    ENDIF
    
    # Maintain tank headspace pressure 
    IF HEAD_PSET < P_MIN THEN
        PRESS_V.Setting = P_MIN
    ELSE 
        PRESS_V.Setting = HEAD_PSET
    ENDIF
    WAIT(0.2)
    
ENDWHILE

