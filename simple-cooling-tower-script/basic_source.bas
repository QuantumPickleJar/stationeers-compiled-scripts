
# Automatically evacuates cooling-tower when temp
# is below 40C
# needs a volume pump and a gas analyzer

ALIAS Sensor d0
ALIAS Pump   d1

CONST maxTemp = 40 C  
# compiler converts C → K

# Set the volume pump to its max capacity
Pump.Setting = Pump.Maximum

Start:
    yield ()               # one tick
    VAR pipeTemp  = Sensor.Temperature
    VAR pipePress = Sensor.Pressure

    VAR tempGo  = (pipeTemp  < maxTemp)
    VAR pressGo = (pipePress > 0)

    Pump.On = (tempGo && pressGo)
GOTO Start
