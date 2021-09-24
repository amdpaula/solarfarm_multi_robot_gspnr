clc
clear

%% Topological Map for Solar Farm Scenario
adjacency_matrix = [0  17  0  0   0;
                    17 0   11 25  0;
                    0  11  0  0   0;
                    0  25  0  0   29;
                    0  0   0  29  0];
 
topological_map = digraph(adjacency_matrix, {'panel1' 'panel2' 'panel3' 'center' 'panel4'}, 'omitselfloops');
plot(topological_map)

%% Importing Models from GreatSPN

PNPRO_path = 'cpr_solarfarm.PNPRO';
[nGSPN, GSPN_list] = ImportfromGreatSPN(PNPRO_path);

NavigationModelHalfBattery = GSPN_list.navigation_halffullbattery;
NavigationToCenter         = GSPN_list.navigation_halffullbattery_to_center;

UGVNavigationModel         = GSPN_list.navigation_UGV;

InspectionModelHalfBattery = GSPN_list.inspection_halffullbattery;
InspectionwithWait         = GSPN_list.inspection_halffullbattery_with_wait_state;

ChargingModel   = GSPN_list.new_charging;

%% Building GSPNR object

solarfarm = GSPNR();

battery_levels = 2;
battery_level_names = ["B0", "B1"];
%Inspection
nodes = string(table2array(topological_map.Nodes));
nNodes = size(nodes, 1);
for n_index = 1:nNodes
    node_name = nodes(n_index);
    if node_name == "center"
        continue
    elseif node_name == "panel4"
        for b_level = 1:battery_levels
            battery_level = battery_level_names(b_level);
            if battery_level == "B0"
                continue
            end
            if battery_level == "B1"
                inspectionfullbattery = copy(InspectionwithWait);
                inspectionfullbattery.format([node_name, "B1", "B0"]);
                solarfarm = MergeGSPNR(solarfarm, inspectionfullbattery);
            end
        end
    else
        for b_level = 1:battery_levels
            battery_level = battery_level_names(b_level);
            if battery_level == "B0"
                continue
            end
            if battery_level == "B1"
                inspectionfullbattery = copy(InspectionModelHalfBattery);
                inspectionfullbattery.format([node_name, "B1", "B0"]);
                solarfarm = MergeGSPNR(solarfarm, inspectionfullbattery);
            end
        end
    end
            
end
%Charging
for n_index = 1:nNodes
    node_name = nodes(n_index);
    if node_name == "center"
        continue
    else
        for b_level = 1:battery_levels
            battery_level = battery_level_names(b_level);
            if battery_level == "B0"
                charging = copy(ChargingModel);
                charging.format([node_name, battery_level, "B2"]);
                solarfarm = MergeGSPNR(solarfarm, charging);
            end
            if battery_level == "B1"
                continue;
            end
        end
    end
end
% Navigation
edges = string(topological_map.Edges.EndNodes);
weights = topological_map.Edges.Weight;
nEdges = size(edges, 1);
for e_index = 1:nEdges
    source = edges(e_index, 1);
    target = edges(e_index, 2);
    rate = 1/weights(e_index);
    if target == "center"
        for b_level = 1:battery_levels
            battery_level = battery_level_names(b_level);
            if battery_level == "B0"
                continue;
            end
            if battery_level == "B1"
                navigation_fullbattery = copy(NavigationToCenter);
                navigation_fullbattery.change_rate_of_transition("Arrived_<1>_<2>_<3>", rate);
                navigation_fullbattery.format([source, target, "B1", "B0"]);
                solarfarm = MergeGSPNR(solarfarm, navigation_fullbattery);
            end
        end
    else
        for b_level = 1:battery_levels
            battery_level = battery_level_names(b_level);
            if battery_level == "B0"
                continue;
            end
            if battery_level == "B1"
                navigation_fullbattery = copy(NavigationModelHalfBattery);
                navigation_fullbattery.change_rate_of_transition("Arrived_<1>_<2>_<3>", rate);
                navigation_fullbattery.format([source, target, "B1", "B0"]);
                solarfarm = MergeGSPNR(solarfarm, navigation_fullbattery);
            end
        end
    end
    ugv_navigation = copy(UGVNavigationModel);
    ugv_navigation.change_rate_of_transition("Arrived_<1>_<2>_UGV", rate);
    ugv_navigation.format([source, target]);
    solarfarm = MergeGSPNR(solarfarm, ugv_navigation);
end

global_arc_places = ["r.InspectionsGlobal","r.RequiredInspectionpanel1","r.RequiredInspectionpanel2","r.RequiredInspectionpanel3","r.RequiredInspectionpanel4"];  
global_arc_trans  = ["InspectedAll"       ,"InspectedAll"              ,"InspectedAll"              ,"InspectedAll"              ,"InspectedAll"              ];
global_arc_type   = ["in"                 ,"out"                       ,"out"                       ,"out"                       ,"out"                       ];
global_arc_weights= [4                    ,1                           ,1                           ,1                           ,1                           ];

solarfarm.add_arcs(global_arc_places,global_arc_trans,global_arc_type,global_arc_weights);

reward_elements = ["Inspect_panel1_B1",...
                   "Inspect_panel2_B1",...
                   "Inspect_panel3_B1",...
                   "Inspect_panel4_B1",...
                   "panel1_B0",...
                   "panel2_B0",...
                   "panel3_B0",...
                   "panel4_B0"];
reward_types = ["transition",...
                "transition",...
                "transition",...
                "transition",...
                "place",...
                "place",...
                "place",...
                "place"];
reward_values = [200,...
                 200,...
                 200,...
                 200,...
                -1,...
                -1,...
                -1,...
                -1];

solarfarm.set_reward_functions(reward_elements, reward_values, reward_types);

%Set robots initial locations
initial_marking = solarfarm.initial_marking;
UAV_center_index = solarfarm.find_place_index("center_B1");
UGV_center_index = solarfarm.find_place_index("center_UGV");

%Place Jackals
initial_marking(UAV_center_index) = 3;
%Place Warthog
initial_marking(UGV_center_index) = 1;


%Set initial counter, all panels need inspection
needs_inspection = solarfarm.places(find(startsWith(solarfarm.places, "r.RequiredInspection")));
for place_name_index = 1:size(needs_inspection, 2)
    place_name = needs_inspection(place_name_index);
    place_index = solarfarm.find_place_index(place_name);
    initial_marking(place_index) = 1;
end

solarfarm.set_initial_marking(initial_marking);

% load("last_workspace.mat")
% [mdp, markings, states, types] = solarfarm.continue_toMDP_without_wait(workspace);

[mdp, markings, states, types] = solarfarm.toMDP_without_wait();

description = "GSPNR - no discharging in any navigation to center; panel4 has wait state; inspection reward at 200";

save("second_iteration_model1.mat", "description", "solarfarm", "mdp", "markings", "states", "types");