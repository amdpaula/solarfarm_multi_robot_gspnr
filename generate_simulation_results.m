clc
clear

nRuns = 10;

load("fourth_iteration_model1.mat");
% load("fourth_iteration_handcrafted_policy.mat");
% 
% for r_index = 1:nRuns
%     results = solarfarm.evaluate_policy(handcrafted_policy, 3600, 100000, 1);
%     file_name = "simulated_handcrafted_run"+string(r_index)+".mat";
%     save(file_name, "results");
%     msg = "Finished run - "+string(r_index)+" for handcrafted policy";
% end
% 
% clear
% load("fourth_iteration_model1.mat");

% for r_index = 1:nRuns
%     results = solarfarm.evaluate_policy([], 3600, 100000, 0);
%     file_name = "simulated_random_run"+string(r_index)+".mat";
%     save(file_name, "results");
%     msg = "Finished run - "+string(r_index)+" for random policy"
% end
% 
% clear
% nRuns = 10;
% load("fourth_iteration_model1.mat");
load("fourth_iteration_policy.mat");
policy_struct.gspn = solarfarm;
policy_struct.state_index_to_markings = markings;
policy_struct.states = states;
policy_struct.mdp = mdp;
policy_struct.mdp_policy = policy;

for r_index = 1:nRuns
    results = solarfarm.evaluate_policy(policy_struct, 3600, 100000, 0);
    file_name = "simulated_optimal_run"+string(r_index)+".mat";
    save(file_name, "results");
    msg = "Finished run - "+string(r_index)+" for optimal policy"
end




