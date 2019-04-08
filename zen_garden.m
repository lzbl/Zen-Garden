%globals
drawHeight = 10;     % height difference from pylon top to sand
moveHeight = 8.125;
toolHeight = 10.5;  % height difference from pylon top to tool 
prevTool = "a";    % previous tool used (currently attached)
x1 = -15.48020;     % position of pylon 1 in coordinate plane
y1 = -8.9375;
x2 = 15.1013;          % position of pylon 2 in coordinate plane
y2 = -8.71875;
x3 = 0;          % position of pylon 3 in coordinate plane
y3 = 17.625;
o1 = sqrt(17.875^2 + moveHeight^2);
o2 = sqrt(17.4375^2 + moveHeight^2);
o3 = sqrt(17.625^2 + moveHeight^2);
prev_l1 = sqrt(17.875^2 + moveHeight^2);    % length of cable from pylon to initial position of current move
prev_l2 = sqrt(17.4375^2 + moveHeight^2);
prev_l3 = sqrt(17.625^2 + moveHeight^2);
totalRotation = 0;   % sum of all angle rotations
% dict of tool coordinates
keySet = {'clear','blunt','point','rake'};
valueSet = [{[6,6]}, {[-6,6]}, {[-6,-6]}, {[6,-6]}];
toolLoc = containers.Map(keySet,valueSet);
%change_height("move", 1, drawHeight, moveHeight, toolHeight);
read_gCode(prevTool, drawHeight, moveHeight, toolHeight,x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, o1, o2, o3)

function [] = read_gCode(prevTool, drawHeight, moveHeight, toolHeight,x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, o1, o2, o3)
    commandList = {};

    fid=fopen('GCodeTestFileRakeLines.txt');
    tline = fgetl(fid);
    tlines = cell(0,1);
    while ischar(tline)
        if ~isempty(tline) && tline(1) ~= '#'
            tlines{end+1,1} = tline;
        end
        tline = fgetl(fid);
    end
    fclose(fid);
    for x = 1 : length(tlines)      
        xSplit = string(tlines{x}).split();
        if (("1" ~= xSplit(1)) && ("2" ~= xSplit(1))) || ((length(xSplit) > 5) || (length(xSplit) < 4))
            continue;
        end
        
        command = "";
        tool = "";
        if "1" == xSplit(1)   % Initialize move
            command = "move";
            if "1" == xSplit(2)   % Initialize tool to Clearing
                tool = "clear";
            elseif "2" == xSplit(2)   % Initialize tool to Blunt
                tool = "blunt";
            elseif "3" == xSplit(2)   % Initialize tool to Fine Tipped
                tool = "point";
            elseif "4" == xSplit(2)   % Initialize tool to Rake
                tool = "rake";
            else
                %print("Error, tool does not exist!")
            end
        else   % Initialize draw   
            command = "draw";
        end 
        
        % Initilaize X Position
        xPos = double(xSplit(length(xSplit)-2)) * 0.01;
        % Initilaize Y Position
        yPos = double(xSplit(length(xSplit)-1)) * 0.01;
        % Initilaize Angle
        angle = double(xSplit(length(xSplit)));
        
        
        if command == "move"
            commandList{end+1} = [command, tool, xPos, yPos, angle];
        else
            commandList{end+1} = [command, xPos, yPos, angle];
        end
    end
    
    %celldisp(commandList)

    % Start following directions in GCode
    [prev_l1, prev_l2, prev_l3] = execute_command(commandList, prevTool, drawHeight, moveHeight, toolHeight,x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc );
    
    % add command to put tool back
    udp_setup(0, 0, 0, len_to_steps(o1-prev_l1), 1, sign(prev_l1-o1), len_to_steps(o2-prev_l2), 1, sign(prev_l2-o2), len_to_steps(o3-prev_l3), 1, sign(o3-prev_l3), 1);
end

function[prev_l1, prev_l2, prev_l3] =  execute_command(commandList, prevTool, drawHeight, moveHeight, toolHeight,x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc)

    for i=1:length(commandList)
        
        command = commandList{i};
        if (command(1) == "move")
            if (command(2) ~= prevTool)
                if prevTool == "a"
                    [prev_l1, prev_l2, prev_l3] = switch_tool(command(2), 1, prevTool, drawHeight, moveHeight, toolHeight,x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc);
                else
                    [prev_l1, prev_l2, prev_l3] = switch_tool(command(2), 0, prevTool, drawHeight, moveHeight, toolHeight,x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc);
                end
            end
            
            [prev_l1, prev_l2, prev_l3] = set_step_params(double(command(3)), double(command(4)), double(command(5)), moveHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc,1 );
            %[prev_l1, prev_l2, prev_l3] = set_step_params(double(command(3)), double(command(4)), double(command(5)), drawHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc,1 );
            
            a = command(5);
            prevTool = command(2);
        else
            [prev_l1, prev_l2, prev_l3] = change_height(command(1), 1, drawHeight, moveHeight, toolHeight, prev_l1, prev_l2, prev_l3);
            
            [prev_l1, prev_l2, prev_l3] = set_step_params(double(command(2)), double(command(3)), double(command(4)), drawHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, 1);
            
            [prev_l1, prev_l2, prev_l3] = change_height(command(1), 0, drawHeight, moveHeight, toolHeight, prev_l1, prev_l2, prev_l3);
            a = command(4);
        end

    end
end

% Change height of electromagnet in Zen Garden
function[prev_l1, prev_l2, prev_l3] = change_height(command, returnToolORStartDraw, drawHeight, moveHeight, toolHeight, prev_l1, prev_l2, prev_l3)
    % Move command that is returning tool to respective tool holder
    if(command == "move" && returnToolORStartDraw == 1)
        udp_setup(0, 1, 0, len_to_steps(moveHeight-toolHeight), 1, sign(moveHeight-toolHeight), len_to_steps(moveHeight-toolHeight), 1, sign(moveHeight-toolHeight), len_to_steps(moveHeight-toolHeight), 1, sign(-(moveHeight-toolHeight)), 1);
        udp_setup(0, 1, 0, len_to_steps(toolHeight-moveHeight), 1, sign(toolHeight-moveHeight), len_to_steps(toolHeight-moveHeight), 1, sign(toolHeight-moveHeight), len_to_steps(toolHeight-moveHeight), 1, sign(-(toolHeight-moveHeight)), 0);
    % Move command that is picking up tool at respective tool holder
    elseif(command == "move" && returnToolORStartDraw == 0)
        udp_setup(0, 1, 0, len_to_steps(moveHeight-toolHeight), 1, sign(moveHeight-toolHeight), len_to_steps(moveHeight-toolHeight), 1, sign(moveHeight-toolHeight), len_to_steps(moveHeight-toolHeight), 1, sign(-(moveHeight-toolHeight)), 0);
        udp_setup(0, 1, 0, len_to_steps(toolHeight-moveHeight), 1, sign(toolHeight-moveHeight), len_to_steps(toolHeight-moveHeight), 1, sign(toolHeight-moveHeight), len_to_steps(toolHeight-moveHeight), 1, sign(-(toolHeight-moveHeight)), 1);
    % Draw command that lowers tool to start drawing in sand
    elseif(command == "draw" && returnToolORStartDraw == 1)
        udp_setup(0, 1, 0, len_to_steps(moveHeight-drawHeight), 1, sign(moveHeight-drawHeight), len_to_steps(moveHeight-drawHeight), 1, sign(moveHeight-drawHeight), len_to_steps(moveHeight-drawHeight), 1, sign(-(moveHeight-drawHeight)), 1);
        prev_l1 = prev_l1 + abs(moveHeight-drawHeight);
        prev_l2 = prev_l2 + abs(moveHeight-drawHeight);
        prev_l3 = prev_l3 + abs(moveHeight-drawHeight);
    % Draw command that raises tool to stop drawing in sand
    else
        udp_setup(0, 1, 0, len_to_steps(drawHeight-moveHeight), 1, sign(drawHeight-moveHeight), len_to_steps(drawHeight-moveHeight), 1, sign(drawHeight-moveHeight), len_to_steps(drawHeight-moveHeight), 1, sign(-(drawHeight-moveHeight)), 1);
        prev_l1 = prev_l1 - abs(moveHeight-drawHeight);
        prev_l2 = prev_l2 - abs(moveHeight-drawHeight);
        prev_l3 = prev_l3 - abs(moveHeight-drawHeight);
    end 
end

function[prev_l1, prev_l2, prev_l3] = set_step_params(x, y, a, h, x1, y1, x2, y2, x3, y3, prev_l1, prev_l2, prev_l3, toolLoc, emag)
    %global prev_l1, prev_l2, prev_l3, x1, x2, x3, y1, y2, y3, eng

    d1 = sqrt((x1-x)^2 + (y1 - y)^2);
    d2 = sqrt((x2-x)^2 + (y2 - y)^2);
    d3 = sqrt((x3-x)^2 + (y3 - y)^2);
    
    l1 = sqrt(d1^2 + h^2);
    l2 = sqrt(d2^2 + h^2);
    l3 = sqrt(d3^2 + h^2);
    
    %print (angle_to_steps(a), 1, sign(a), len_to_steps(l1-prev_l1), 1, sign(prev_l1-l1), len_to_steps(l2-prev_l2), 1, sign(prev_l2-l2), len_to_steps(l3-prev_l3), 1, sign(l3-prev_l3), 0)
    udp_setup(angle_to_steps(a), 1, sign(a), len_to_steps(l1-prev_l1), 1, sign(prev_l1-l1), len_to_steps(l2-prev_l2), 1, sign(prev_l2-l2), len_to_steps(l3-prev_l3), 1, sign(l3-prev_l3), emag);

    prev_l1 = l1;
    prev_l2 = l2;
    prev_l3 = l3;
    
end

% save of function "set_set_params"
% function[prev_l1, prev_l2, prev_l3] = set_step_params(x, y, a, h, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, emag)
%     %global prev_l1, prev_l2, prev_l3, x1, x2, x3, y1, y2, y3, eng
% 
%     d1 = sqrt((x1-x)^2 + (y1 - y)^2);
%     d2 = sqrt((x2-x)^2 + (y2 - y)^2);
%     d3 = sqrt((x3-x)^2 + (y3 - y)^2);
%     
%     l1 = sqrt(d1^2 + h^2);
%     l2 = sqrt(d2^2 + h^2);
%     l3 = sqrt(d3^2 + h^2);
% 
%     
%     %print (angle_to_steps(a), 1, sign(a), len_to_steps(l1-prev_l1), 1, sign(prev_l1-l1), len_to_steps(l2-prev_l2), 1, sign(prev_l2-l2), len_to_steps(l3-prev_l3), 1, sign(l3-prev_l3), 0)
%     udp_setup(angle_to_steps(a), 1, sign(a), len_to_steps(l1-prev_l1), 1, sign(prev_l1-l1), len_to_steps(l2-prev_l2), 1, sign(prev_l2-l2), len_to_steps(l3-prev_l3), 1, sign(l3-prev_l3), emag);
% 
%     prev_l1 = l1;
%     prev_l2 = l2;
%     prev_l3 = l3;
%     
% end

function[o] = len_to_steps(l)
    %.826772
    o = round(abs(l) / .787 * 100);
end

function[o] =  angle_to_steps(a)
    o = abs(a) * 3260 / 360;
end

function[prev_l1, prev_l2, prev_l3] =  switch_tool(tool, first, prevTool, drawHeight, moveHeight, toolHeight,x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc)
    if (~first)
        temp = toolLoc(char(prevTool));
        
        [prev_l1, prev_l2, prev_l3] = set_step_params(temp(1), temp(2), 0, moveHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, 1);
        
        %[prev_l1, prev_l2, prev_l3] = set_step_params(temp(1), temp(2), 0, toolHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, 1);
        [prev_l1, prev_l2, prev_l3] = change_height("move", 1, drawHeight, moveHeight, toolHeight, prev_l1, prev_l2, prev_l3);
        %[prev_l1, prev_l2, prev_l3] = set_step_params(temp(1), temp(2), 0, moveHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, 0);
        
        % toggle emag
    end
    
    temp = toolLoc(char(tool));
    
    [prev_l1, prev_l2, prev_l3] =  set_step_params(temp(1), temp(2), 0, moveHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, 0)    ;
    
    %[prev_l1, prev_l2, prev_l3] = set_step_params(temp(1), temp(2), 0, toolHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, 1)    ;
    [prev_l1, prev_l2, prev_l3] = change_height("move", 0, drawHeight, moveHeight, toolHeight, prev_l1, prev_l2, prev_l3);
    %[prev_l1, prev_l2, prev_l3] =  set_step_params(temp(1), temp(2), 0, moveHeight, x1, y1, x2, y2, x3, y3,prev_l1, prev_l2, prev_l3, toolLoc, 1)    ;
    
    %toggle emag
end

function[o] =  sign(val)
    if val > 0
        o = 1;
    else
        o = 0;
    end
end