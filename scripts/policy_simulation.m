clc
clear


load("fourth_iteration_model1.mat");
load("fourth_iteration_handcrafted_policy.mat");
% 
% policy_struct.gspn = solarfarm;
% policy_struct.state_index_to_markings = markings;
% policy_struct.states = states;
% policy_struct.mdp = MDP;
% policy_struct.mdp_policy = policy;


results = solarfarm.evaluate_policy(handcrafted_policy, 36000, 100, 1);


