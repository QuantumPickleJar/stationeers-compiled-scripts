# tuneables
CONST target    = 45
# hysteresis band
CONST thStep    = 10    # throttle step increment
CONST band      = 10       # fudge factor for stress
CONST limLow    = 20    # throttle limiter while accelerating
CONST limHigh   = 50   # limiter once stable
CONST launchRpm = 100 # switch from pulsing to closed loop here
CONST workRpm   = 450  # considered at-speed

ALIAS centrifuge db

VAR halfBand
VAR rStress
VAR rRPM
VAR rTh
VAR rLim
VAR rTmp
    
init: 
    # safe defaults
    centrifuge.On = true
    rTh  = 0
    rLim = limLow
    GOTO setKnobs
    
startup:
    # pulse 10% throttle 
    rRPM = centrifuge.RPM
    IF rRPM < launchRpm THEN 
        rTh = 10
        GOTO setKnobs
    ENDIF
    GOTO control
    

control:
    # read current telemetry
    rStress = centrifuge.Stress
    rRPM = centrifuge.RPM
    
    # choose limiter
    rLim = limHigh
    IF rRPM < workRpm THEN
        rLim = limLow
        #todo: verify if this belongs outside IF
    ENDIF
    

    halfBand = band / 2

#    rTmp = target - halfBand
#    IF rStress < rTmp THEN GOTO thUp
    IF rStress < (target - halfBand) THEN GOTO thUp
    ENDIF

    rTmp = target + halfBand
    IF rStress > (target + halfBand) THEN GOTO thDown
    ENDIF
    
    GOTO setKnobs
    
setKnobs:
    # round rTh to nearest 10, clamp 0..100, cap by limiter
    rTmp = rTh
    rTmp = (rTmp / 10) + 0.5
    rTmp = floor(rTmp) * 10
    
    IF rTmp < 0 THEN rTmp = 0 ENDIF
    IF rTmp > 100 THEN rTmp = 100 ENDIF
    IF rTmp > rLim THEN rTmp = rLim ENDIF
    centrifuge.Throttle = rTmp
    
    rTmp = rLim
    rTmp = (rTmp / 10) + 0.5
    rTmp = floor(rTmp) * 10
    
    IF rTmp < 0 THEN rTmp = 0 ENDIF
    IF rTmp > 100 THEN rTmp = 100 ENDIF
    
    centrifuge.Limiter = rTmp
    
    yield()
    GOTO startup
    
thUp:
    rTh = centrifuge.Throttle + thStep
    GOTO setKnobs
    
thDown:
    rTh = centrifuge.Throttle - thStep
    GOTO setKnobs