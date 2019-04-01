#!/usr/bin/env python
# coding: utf-8

import os.path
import matlab.engine
import numpy as np
import math


#globals
drawHeight = 13     # height difference from pylon top to sand
moveHeight = 11
toolHeight = -1  # height difference from pylon top to tool
prevTool = "a"    # previous tool used (currently attached)
x1 = -1          # position of pylon 1 in coordinate plane
y1 = -1
x2 = -1          # position of pylon 2 in coordinate plane
y2 = -1
x3 = -1          # position of pylon 3 in coordinate plane
y3 = -1
prev_11 = -1     # length of cable from pylon to initial position of current move
prev_12 = -1
prev_13 = -1
totalRotation = 0   # sum of all angle rotations
# dict of tool coordinates
toolLoc = {
        "clear": (-1,-1),
        "blunt": (-1,-1),
        "point": (-1,-1),
        "rake": (-1,-1)
        }



# Reads in a GCode file and puts the commands into a list
def read_gCode():
    commandList = []
    
    fileName = input("File name (must be in current directory): ")
    file = open(os.path.join(os.getcwd(), fileName), 'r')
    text = file.readlines()
    file.close()

    for x in text:      
        xSplit = x.split(" ")
        if (("1" not in xSplit[0]) and ("2" not in xSplit[0])) or ((len(xSplit) > 5) or (len(xSplit) < 4)):
            continue
    
        command = ""
        tool = ""
        if "1" in xSplit[0]:   # Initialize move
            command = "move"
            if "1" in xSplit[1]:   # Initialize tool to Clearing
                tool = "clear"
            elif "2" in xSplit[1]:   # Initialize tool to Blunt
                tool = "blunt"
            elif "3" in xSplit[1]:   # Initialize tool to Fine Tipped
                tool = "point"
            elif "4" in xSplit[1]:   # Initialize tool to Rake
                tool = "rake"
            else:
                print("Error, tool does not exist!")
        else:   # Initialize draw   
            command = "draw"
            
        
        # Initilaize X Position
        xPos = float(xSplit[-3]) * 0.01
        # Initilaize Y Position
        yPos = float(xSplit[-2]) * 0.01
        # Initilaize Angle
        angle = int(xSplit[-1])
        
        if command == "move":
            commandList.append([command, tool, xPos, yPos, angle])
        else:
            commandList.append([command, xPos, yPos, angle])
            
    print(commandList)
    execute_command(commandList)
    
def execute_command(commandList):
    
    for command in commandList:
        if command[0] == "move":
            if command[1] != prevTool:
                set_step_params(toolLoc[command[1]][0], toolLoc[command[1]][1], command[4], toolHeight)         # could use previous angle here to do rotation on move after getting tool, may not matter
            set_step_params(command[2], command[3], command[4], moveHeight)
            prevTool = command[1]
        else:
            set_step_params(command[1], command[2], command[3], drawHeight)
            
        # get feedback from simulink and wait for move to finish
        totalRotation = totalRotation + a
        
        

def set_step_params(x, y, a, h):
    d1 = math.sqrt((x1-x)**2 + (y1 - y)**2)
    d2 = math.sqrt((x2-x)**2 + (y2 - y)**2)
    d3 = math.sqrt((x3-x)**2 + (y3 - y)**2)
    
    l1 = math.sqrt(d1**2 + h**2)
    l2 = math.sqrt(d2**2 + h**2)
    l3 = math.sqrt(d3**2 + h**2)   
    
    # set param of len_to_steps(l1 - prev_l1)
    # set param of len_to_steps(l2 - prev_l2)
    # set param of len_to_steps(l3 - prev_l3)
    # set param of angle_to_steps(a)
    
    #this will let us set all parameters simultaneously
    #eng.set_param('SchemeName', 'ParameterName', len_to_steps(l1 - prev_l1), 'NextParamName', len_to_steps(l2 - prev_l2), and so on)
    eng = matlab.engine.start_matlab()
    eng.udp_setup(angle_to_steps(a), 1, np.sign(a), len_to_steps(l1-prev_l1), 1, np.sign(l1-prev_l1), len_to_steps(l2-prev_l2), 1, np.sign(l2-prev_l2), len_to_steps(l3-prev_l3), 1, np.sign(l3-prev_l3), 0)
    
    prev_l1 = l1;
    prev_l3 = l2;
    prev_l2 = l3;
    
    
    #cm
def len_to_steps(l):
    steps = l * 2.1 / 100
    return steps
    
def angle_to_steps(a):
    #convert rotation angle to steps (may be easier to just convert difference in angle)
    steps = abs(a) * 3260 / 360
    return steps
    
           
# may want to do in main script/globally
# def simulink():
#     eng = matlab.engine.start_matlab()
#     eng.sim("vdp")


