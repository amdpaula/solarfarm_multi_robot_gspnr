clc
clear

load("fourth_iteration_model1.mat");

mdp.check_validity();
mdp.set_enabled_actions();
disp("MDP valid and set of enabled actions built")
disp("Starting value iteration")
timeout = 0;
discount_factor = 0.99;
[values, policy, error] = value_iteration(mdp, 1, discount_factor, 0.01, timeout);
disp("Finished value iteration");

save("fourth_iteration_policy.mat")