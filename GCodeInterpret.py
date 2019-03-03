#!/usr/bin/env python
# coding: utf-8

import os.path
# import matlab.engine

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
        

# def simulink():
#     eng = matlab.engine.start_matlab()
#     eng.sim("vdp")


