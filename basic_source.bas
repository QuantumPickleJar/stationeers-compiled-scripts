# tuneables
VAR target = 45
# hysteresis band
VAR th_step = 10    # throttle step increment
VAR band = 10       # fudge factor for stress
VAR lim_low = 20    # throttle limiter while accelerating
VAR lim_high = 50   # limiter once stable
VAR launch_rpm = 100 # switch from pulsing to closed loop here
VAR work_rpm = 450  # considered at-speed

ALIAS centrifuge db

VAR halfBand
VAR rStress
VAR rRPM
VAR rTh
VAR rLim
VAR rTmp

# clamp to 0..100 and snap to nearest 10
# expects rTmp input, returns in rTmp
snap10:
    # nearest multiple of 10 => round(x/10) * 10
    rTmp = (rTmp / 10) + 0.5
    rTmp = floor(rTmp) * 10
    rTmp = max(rTmp, 0) # check this line
    rTmp = min(rTmp, 100)
    return
    
    
init: 
    # safe defaults
    centrifuge.On = true
    rTh  = 0
    rLim = lim_low
    GOTO setKnobs
    
startup:
    # pulse 10% throttle 
    rRPM = centrifuge.RPM
    IF rRPM < launch_rpm THEN GOTO pulse ENDIF
    GOTO control
        
pulse: 
    rTh = th_step
    GOTO setKnobs

control:
    # read current telemetry
    rStress = centrifuge.Stress
    rRPM = centrifuge.RPM
    
    # choose limiter
    rLim = lim_high
    IF rRPM < work_rpm THEN
        rLim = lim_low
        #todo: verify if this belongs outside IF
    ENDIF
    
    # throttle up/down with hysteresis around target
    rTh = centrifuge.Throttle
    halfBand = band / 2

    rTmp = target - halfBand
    IF rStress < rTmp THEN GOTO th_up
    ENDIF

    rTmp = target + halfBand
    IF rStress > rTmp THEN GOTO th_down
    ENDIF
    
    GOTO setKnobs
    
setKnobs:
    rTmp = rTh
    GOSUB snap10
    centrifuge.Throttle = rTmp
    
    rTmp = rLim
    GOSUB snap10
    centrifuge.Limiter = rTmp
    
    yield()
    GOTO startup
    
th_up:
    rTmp = centrifuge.Throttle
    rTmp = rTmp + th_step
    GOSUB snap10
    GOTO setKnobs
    
th_down:
    rTmp = centrifuge.Throttle
    rTmp = rTmp - th_step
    GOSUB snap10
    GOTO setKnobs
