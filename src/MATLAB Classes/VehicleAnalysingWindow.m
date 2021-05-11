classdef VehicleAnalysingWindow < handle
    %VEHICLEANALYSINGWINDOW Analysing window for vehicles
    %   Detailed explanation goes here TODO: write a detailed explanation
    
    properties
        egoVehicleId    % vehicle the camera should focus on
        vehicles        % all vehicles that should be shown in the analysis
        gui             % contains all parts of the gui
            % fig                   figure of the analysis window
            % grid                  grid to align all components of the gui
            % vehicleSelectionDd    drop-down selection menu for the actual vehicle
            % axes                  used as a container for a plot
            % bep                   birds eye plot
            % outlinePlotter        plots the outlines of the cars
            % lanePlotter           plots the outlines of the roads
        scenario        % contains cars and roads that should be plotted
    end 
    
    methods
        function obj = VehicleAnalysingWindow(vehicles, egoVehicleId)
            %VEHICLEANALYSINGWINDOW Construct an instance of this class
            %   Detailed explanation goes here
            
            % get ego vehicle id
            obj.egoVehicleId = egoVehicleId;
            % get all vehicles
            obj.vehicles = vehicles;

            % generate window 
            obj.gui = generateGui(obj);
            
            % get scenario with road network
            obj.getRoadScenario();
            
            % add vehicles to the driving scenario
            obj.addVehiclesToScenario(obj.vehicles);
            
            % initialize birds eye view
            obj.updatePlot();
        end
        
        function gui = generateGui(~)
            %GENERATEGUI Generate the vehicle analysing window
            %   using uifigure
           
            % find old analysing window and close it
            close(findall(groot,'Type','figure','Tag','vehicleAnalysingWindow_tag')); % close last window
            % generate ui figure              
            gui.fig = uifigure('Name','Vehicle Analysing Window');
            % tune ui figure properties
            gui.fig.Visible = 'on';
            gui.fig.Tag = 'vehicleAnalysingWindow_tag';
            
            % generate grid layout
            gui.grid = uigridlayout(gui.fig);
            gui.grid.RowHeight = {22,22,'1x'};
            gui.grid.ColumnWidth = {150,'1x'};
            % generate drop-downs
            gui.vehicleSelectionDd = uidropdown(gui.grid,'Items',{'Vehicle 1','Vehicle 2'});
            % TODO: one dropdown item per vehicle
            % TODO: get nextWaypointBlocked! visible on screen
            %dd1.Items = {'1','2'};
            %generate tabs
            %tabgp = uitabgroup(obj.fig,'Position',[.05 .05 .3 .8]);
            %tab1 = uitab(tabgp,'Title','Vehicle 1');
            %tab2 = uitab(tabgp,'Title','Vehicle 2');
            %tab1 = uitab('Title','Vehicle 1');
            % generate vehicle plot container by using axes
            gui.axes = uiaxes(gui.grid);
            gui.axes.Layout.Row = 3;
            gui.axes.Layout.Column = 2;
            % set the unit length to the same length
            daspect(gui.axes,[1 1 1]); % TODO: still neccesary?
            % birds eye plot in axes container
            gui.bep = birdsEyePlot('Parent', gui.axes, 'XLim',[-50 100], 'YLim',[-20 20]);
            % plotters
            gui.outlinePlotter = outlinePlotter(gui.bep);
            gui.lanePlotter = laneBoundaryPlotter(gui.bep,'DisplayName','Road');
        end
                    
        
        function getRoadScenario(obj)
            % get a scenario with the road network
            
            obj.scenario = scenario_map_v1();
        end
        
        
        function addVehiclesToScenario(obj, vehicles)
            % add vehicles for plotting with properties of the
            % simulated vehicles to the scenario
            
            for i = 1 : length(vehicles)
                vehicle(obj.scenario, ...
                    'ClassID', 1, ... % group 1 means cars
                    'Name', vehicles(i).id, ...
                    'Length', vehicles(i).physics.size(3), ...
                    'Width', vehicles(i).physics.size(2), ...
                    'Height', vehicles(i).physics.size(1), ...
                    'RearOverhang', vehicles(i).physics.size(3)/2); % This moves the origin to the middle of the car
            end
        end
        
        
        function updatePlot(obj)
            % update all plotted objects
            
            % get vehicles poses
            i = 1:length(obj.vehicles);
            positions = cat(1,cat(2,obj.vehicles(i).dynamics).position);
            orientations = cat(1,cat(2,obj.vehicles(i).dynamics).orientation);
            % coordinate transformation for plot
            x = -positions(:,3); % x = negative y-Position of vehicle
            y = -positions(:,1); % y = negative x-Position of vehicle
            yaw = orientations(:,4) + pi; % rotate by 180 degrees
            % update vehicle position and orientation
            obj.updateVehiclePose(x, y, yaw);
            
            % redraw vehicles
            [position,yaw,Length,width,originOffset,color] = targetOutlines(obj.scenario.Actors(obj.egoVehicleId));
            plotOutline(obj.gui.outlinePlotter, position, yaw, Length, width, ...
                'OriginOffset',originOffset, 'Color',color);
            
            % redraw vehicles from ego vehicle pose
            rb = roadBoundaries(obj.scenario.Actors(obj.egoVehicleId));
            plotLaneBoundary(obj.gui.lanePlotter,rb);
        end
        
        
        function updateVehiclePose(obj, x, y, yaw)
            % update positions from all vehicles
            % yaw is in rad
            
            for i = 1 : length(obj.vehicles)
                % set position of actor
                obj.scenario.Actors(i).Position = [x(i) y(i) 0];
                % set rotation of actor
                obj.scenario.Actors(i).Yaw = yaw(i)/pi*180;
            end
        end
 
    end
end
