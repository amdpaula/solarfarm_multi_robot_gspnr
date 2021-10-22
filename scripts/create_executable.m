clc
clear

%% Loading files
%load("robocup_corrected_models.mat");
%load("robocup_corrected_policy", "policy");
% load("robocup_model_accurate_rates.mat");
% load("robocup_policy_accurate_rates.mat", "policy");

load("fourth_iteration_model1.mat")
%load("fourth_iteration_policy.mat")
load("fourth_iteration_handcrafted_policy")
%% Setting up policy
% policy_struct.gspn = solarfarm;
% policy_struct.state_index_to_markings = markings;
% policy_struct.states = states;
% policy_struct.mdp = mdp;
% policy_struct.mdp_policy = policy;

%% Changing immediate transitions to exponential transitions - for 'Bat_Levels...'
solarfarm_imm = copy(solarfarm);

check_bat_trans_indices = find(startsWith(solarfarm.transitions, "Discharged"));
check_bat_trans_indices = cat(2, check_bat_trans_indices, find(startsWith(solarfarm.transitions, "FinishedCharging")));

for ti_index = 1:size(check_bat_trans_indices, 2)
    trans_index = check_bat_trans_indices(ti_index);
    trans_name = solarfarm_imm.transitions(trans_index);
    solarfarm_imm.change_type_of_transition(trans_name, "exp");
end

%% Setting up map between action places and ROS action servers

action_map = struct();

[exp_trans, exp_trans_indices] = solarfarm_imm.get_exponential_transitions();

nEXPTrans = size(exp_trans, 2);

action_places = [];

for t_index = 1:nEXPTrans
    exp_trans_index = exp_trans_indices(t_index);
    input_places = solarfarm_imm.input_arcs(:,exp_trans_index);
    input_place_indices = find(input_places);
    action_places = cat(2, action_places, input_place_indices');
end
action_places = unique(action_places);

%Package name where ROS action servers are
UAV_package_name = "multi_jackal_tutorials";
UGV_package_name = "multi_warthog";
battery_package = "battery_mockup"

nActionPlaces = size(action_places, 2);

for p_index = 1:nActionPlaces
    place_index = action_places(p_index);
    place_name = solarfarm_imm.places(place_index);
    if startsWith(place_name, "Navigating")
        action_map.(place_name).server_name = "NavigateWaypointActionServer";
        action_map.(place_name).package_name = UAV_package_name;
        action_map.(place_name).action_name = "NavigateWaypointAction";
        components = strsplit(place_name, "_");
        origin_string = components(2);
        origin_string = "'"+origin_string+"'";
        destination_string = components(3);
        destination_string = "'"+destination_string+"'";
        action_map.(place_name).message = struct("origin", origin_string, "destination", destination_string);
        action_map.(place_name).with_result = false;
    end
    if startsWith(place_name, "Discharging")
        action_map.(place_name).server_name = "CheckBatteryActionServer";
        action_map.(place_name).package_name = battery_package;
        action_map.(place_name).action_name = "CheckBatteryAction";
        action_map.(place_name).message = struct("check", 0);
        
        components = strsplit(place_name, "_");
        if size(components,2) == 5
            action_map.(place_name).with_result = true;
            %Discharge after inspection
            current_battery_level = components(5);
            if current_battery_level == "B1"
                lower_battery_level = "B0";
                transition_to_same_level = "Discharged_after_inspecting_"+components(4)+"_"+components(5)+"_"+components(5);
                transition_to_level_below = "Discharged_after_inspecting_"+components(4)+"_"+components(5)+"_"+lower_battery_level;
                action_map.(place_name).result_trans = struct("medium", transition_to_same_level, "low", transition_to_level_below);
            end
        elseif size(components,2) == 6
            %Discharge after navigation
            current_battery_level = components(6);
            if current_battery_level == "B1"
                action_map.(place_name).with_result = true;
                lower_battery_level = "B0";
                transition_to_same_level = "Discharged_after_navigating_"+components(4)+"_"+components(5)+"_"+components(6)+"_"+components(6);
                transition_to_level_below = "Discharged_after_navigating_"+components(4)+"_"+components(5)+"_"+components(6)+"_"+lower_battery_level;
                action_map.(place_name).result_trans = struct("medium", transition_to_same_level, "low", transition_to_level_below);
            end
        end
        
    end
    
    if endsWith(place_name, "UGV_Wait")
        action_map.(place_name).server_name = "WaitActionServer";
        action_map.(place_name).package_name = UAV_package_name;
        action_map.(place_name).action_name = "WaitAction";
        action_map.(place_name).message = struct("time", uint32(1));
        action_map.(place_name).with_result = true;
        components = strsplit(place_name, "_");
        transition = components(1)+"_"+components(2)+"_Finished_Waiting";
        action_map.(place_name).result_trans = struct("success", transition);
    end
    if startsWith(place_name, "Inspecting")
        action_map.(place_name).server_name = "InspectWaypointActionServer";
        action_map.(place_name).package_name = UAV_package_name;
        action_map.(place_name).action_name = "InspectWaypointAction";
        components = strsplit(place_name, "_");
        waypoint_string = components(2);
        waypoint_string = "'"+waypoint_string+"'";
        action_map.(place_name).message = struct("waypoint", waypoint_string);
        action_map.(place_name).with_result = false;
    end
    if startsWith(place_name, "Charging")
        action_map.(place_name).server_name = "ChargeJackalActionServer";
        action_map.(place_name).package_name = UAV_package_name;
        action_map.(place_name).action_name = "ChargeWarthogAction";
        action_map.(place_name).message = struct("location", "'location'");
        action_map.(place_name).with_result = false;
    end
    if startsWith(place_name, "UGV_Charging")
        action_map.(place_name).server_name = "ChargeWarthogActionServer";
        action_map.(place_name).package_name = UAV_package_name;
        action_map.(place_name).action_name = "ChargeWarthogAction";
        action_map.(place_name).message = struct("location", "'location'");
        action_map.(place_name).with_result = false;
    end
end

%% Creating executable

executable = ExecutableGSPNR();

executable.initialize(solarfarm_imm, [], action_map);

tic
%executable.set_empty_policy();
executable.set_manual_policy(handcrafted_policy.markings, handcrafted_policy.transitions);
toc

%% Setting up robot type mapping

executable.add_robots(["jackal0", "jackal1", "warthog"], ["center_B1", "center_B1", "center_UGV"]);

places = [string.empty];
types = [string.empty];
nPlaces = size(executable.places, 2);
for p_index = 1:nPlaces
    place_name = executable.places(p_index);
    if ~isempty(find(executable.robot_places == place_name))
        if contains(place_name, "UGV")
            places = cat(2, places, place_name);
            types = cat(2, types, "UGV");
        else
            places = cat(2, places, place_name);
            types = cat(2, types, "UAV");
        end
    end
end

executable.set_types(["UAV", "UGV"], places, types); 

%% Saving workspace

save("executable_fourth_iteration_handcrafted_policy.mat", "executable");