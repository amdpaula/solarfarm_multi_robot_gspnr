clc
clear

adjacency_matrix = [0 1  0 0 0;
                    1 0  1 1 0;
                    0 1  0 0 0;
                    0 1  0 0 1;
                    0 0  0 1 1];
 
top_map = digraph(adjacency_matrix, {'panel1' 'panel2' 'panel3' 'center' 'panel4'}, 'omitselfloops');

jackal_places = ["panel1_B1", "panel2_B1", "panel3_B1", "panel4_B1", "center_B1"];
discharged_places = ["panel1_B0", "panel2_B0", "panel3_B0", "panel4_B0"];
warthog_places = ["panel1_UGV", "panel2_UGV", "panel3_UGV", "panel4_UGV", "center_UGV"];
inspection_needed = ["r.RequiredInspectionpanel1", "r.RequiredInspectionpanel2", "r.RequiredInspectionpanel3", "r.RequiredInspectionpanel4"];

load("fourth_iteration_model1.mat")

nMarkings = size(markings, 1);

transitions = strings(nMarkings, 1);

for m_index = 1:nMarkings
    current_marking = markings(m_index, :);
    solarfarm.set_marking(current_marking);
    [imm, exp] = solarfarm.enabled_transitions();
    if isempty(imm)
        continue
    end
    %Check if can inspect at current location
    inspect = 0;
    for l_index = 1:4
        inspect_transition = "Inspect_panel"+string(l_index)+"_B1";
        if ismember(inspect_transition, imm)
            inspect = 1;
            transitions(m_index) = inspect_transition;
            break
        end
    end
    if inspect == 1
        continue
    end
    %Check if can charge at current location
    charge = 0;
    for l_index = 1:4
        charge_transition = "Charge_panel"+string(l_index)+"_B0";
        if ismember(charge_transition, imm)
            charge = 1;
            transitions(m_index) = charge_transition;
            break
        end
    end
    if charge == 1
        continue
    end
    
    marked_places = solarfarm.places(find(solarfarm.current_marking));
    nMarkedPlaces = size(marked_places, 2);
    for p_index = 1:nMarkedPlaces
        place = marked_places(p_index);
        if startsWith(place, "r.")
            continue
        end
        if ismember(place, jackal_places)
            %Jackal needs to take decision
            current_location = strsplit(place,"_");
            current_location = current_location(1);
            previous_distance = 1;
            path = [];
            inspection_is_required = false;
            for i_index = 1:4
                inspection_required = inspection_needed(i_index);
                if ismember(inspection_required, marked_places)
                    destination = extractAfter(inspection_required, 20);
                    [path, distance] = shortestpath(top_map, current_location, destination);
                    if distance < previous_distance
                        new_destination = destination;
                    end
                    inspection_is_required = true;
                end
            end
            if inspection_is_required
                next_navigation = path(2);
                transitions(m_index) = "Go_"+current_location+"_"+next_navigation+"_B1";
            end
        elseif ismember(place, warthog_places)
            current_location = strsplit(place,"_");
            current_location = current_location(1);
            previous_distance = 1;
            path = [];
            recharging_is_required = false;
            for i_index = 1:4
                recharging_required = discharged_places(i_index);
                if ismember(recharging_required, marked_places)
                    destination = strsplit(recharging_required, "_");
                    destination = destination(1);
                    [path, distance] = shortestpath(top_map, current_location, destination);
                    if distance < previous_distance
                        new_destination = destination;
                    end
                    recharging_is_required = true;
                end
            end
            if recharging_is_required
                next_navigation = path(2);
                transitions(m_index) = "Go_"+current_location+"_"+next_navigation+"_UGV";
            else
                if current_location ~="center"
                    transitions(m_index) = current_location+"_UGV_DWait";
                end
            end
        end
    end
    
    
end

