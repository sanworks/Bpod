'''
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
'''
import struct
import math
class stateMachine(object):
    def __init__(self, bpodObject):
        self.nStates = 0
        self.eventNames = bpodObject.stateMachineInfo.eventNames;
        self.outputChannelNames = bpodObject.stateMachineInfo.outputChannelNames
        self.metaOutputNames = ('Valve', 'LED')
        self.stateNames = []
        self.stateTimers = [0]*bpodObject.stateMachineInfo.maxStates;
        self.stateTimerMatrix = [0]*bpodObject.stateMachineInfo.maxStates;
        self.inputMatrix = [[] for i in range(bpodObject.stateMachineInfo.maxStates)]
        self.outputMatrix = [[] for i in range(bpodObject.stateMachineInfo.maxStates)]
        self.globalTimers = Struct()
        self.globalTimers.matrix = [[] for i in range(bpodObject.stateMachineInfo.maxStates)]
        self.globalTimers.timers = [0]*bpodObject.HW.n.GlobalTimers
        self.globalCounters = Struct()
        self.globalCounters.attachedEvents = [254]*bpodObject.HW.n.GlobalCounters
        self.globalCounters.thresholds = [0]*bpodObject.HW.n.GlobalCounters
        self.globalCounters.matrix = [[] for i in range(bpodObject.stateMachineInfo.maxStates)]
        self.conditions = Struct()
        self.conditions.channels = [0]*bpodObject.HW.n.Conditions
        self.conditions.values = [0]*bpodObject.HW.n.Conditions
        self.conditions.matrix = [[] for i in range(bpodObject.stateMachineInfo.maxStates)]
        self.manifest = [] # List of states that have been added to the state machine
        self.undeclared = [] # List of states that have been referenced but not yet added
        self.stateMachineInfo = bpodObject.stateMachineInfo
    def addState(self, *args):
        nargs = len(args)
        for i in range(0,nargs,2):
            thisArg = args[i].lower()
            thisArgValue = args[i+1]
            if thisArg == 'name':
                if thisArgValue not in self.manifest:
                    self.stateNames.append(thisArgValue)
                    self.manifest.append(thisArgValue)
                    thisStateNumber = len(self.manifest)-1
                else:
                    thisStateNumber = self.manifest.index(thisArgValue)
                    self.stateNames[thisStateNumber] = thisArgValue
                self.stateTimerMatrix[thisStateNumber] = thisStateNumber
            elif thisArg == 'timer':
                self.stateTimers[thisStateNumber] = thisArgValue
            elif thisArg == 'statechangeconditions':
                conditionList = thisArgValue;
                nconditions = len(conditionList)
                for i in range(0,nconditions,2):
                    try:
                        thisEventCode = self.eventNames.index(conditionList[i])
                    except:
                        raise SMAError('Error creating state: ' + self.stateNames[-1] + '. ' + conditionList[i] + ' is an invalid event name.')
                    thisEventStateTransition = conditionList[i+1]
                    if thisEventStateTransition in self.manifest:
                        destinationStateNumber = self.manifest.index(thisEventStateTransition)
                    else:
                        if thisEventStateTransition == 'exit':
                            destinationStateNumber = float('NaN')
                        else: # Send to an undeclared state (replaced later with actual state in myBpod.sendStateMachine)
                            self.undeclared.append(thisEventStateTransition)
                            destinationStateNumber = (len(self.undeclared)-1)+10000
                    if thisEventCode == self.stateMachineInfo.Pos.Tup:
                        self.stateTimerMatrix[thisStateNumber] = destinationStateNumber
                    elif thisEventCode >= self.stateMachineInfo.Pos.condition:
                        self.conditions.matrix[thisStateNumber].append((thisEventCode,destinationStateNumber))
                    elif thisEventCode >= self.stateMachineInfo.Pos.globalCounter:
                        self.globalCounters.matrix[thisStateNumber].append((thisEventCode,destinationStateNumber))
                    elif thisEventCode >= self.stateMachineInfo.Pos.globalTimer:
                        self.globalTimers.matrix[thisStateNumber].append((thisEventCode,destinationStateNumber))
                    else:
                        self.inputMatrix[thisStateNumber].append((thisEventCode,destinationStateNumber))
            elif thisArg == 'outputactions':
                outputActionList = thisArgValue;
                nactions = len(outputActionList)
                for i in range(0,nactions,2):
                    thisAction = outputActionList[i]
                    if thisAction in self.metaOutputNames:
                        metaAction = self.metaOutputNames.index(thisAction)
                        value = outputActionList[i+1]
                        if metaAction == 0: # Valve
                            thisOutputCode = thisOutputCode = self.outputChannelNames.index('ValveState')
                            thisOutputValue = math.pow(2,value-1)
                        elif metaAction == 1: # LED
                            thisOutputCode = self.outputChannelNames.index('PWM' + str(value))
                            thisOutputValue = 255;
                        else:
                            raise SMAError('Error: a meta-action was unhandled.')
                    else:
                        try:
                            thisOutputCode = self.outputChannelNames.index(thisAction)
                        except:
                            raise SMAError('Error creating state: ' + self.stateNames[-1] + '. ' + thisAction + ' is an invalid output name.')
                        thisOutputValue = outputActionList[i+1]
                    self.outputMatrix[thisStateNumber].append((thisOutputCode,thisOutputValue))
            else:
                raise SMAError('Error: valid state machine arguments are: Name, Timer, StateChangeConditions, OutputActions.')
        self.nStates += 1
    def setGlobalTimer(self, timerNumber, timerDuration):
        self.globalTimers.timers[timerNumber-1] = timerDuration
    def setGlobalCounter(self, counterNumber, counterEvent, threshold):
        eventCode = self.eventNames.index(counterEvent)
        self.globalCounters.attachedEvents[counterNumber-1] = eventCode
        self.globalCounters.thresholds[counterNumber-1] = threshold
    def setCondition(self, conditionNumber, conditionChannel, channelValue):
        channelCode = self.stateMachineInfo.inputChannelNames.index(conditionChannel)
        self.conditions.channels[conditionNumber-1] = channelCode
        self.conditions.values[conditionNumber-1] = channelValue

class Struct:
    pass
class SMAError(Exception):
    pass
