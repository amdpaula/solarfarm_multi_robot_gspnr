clc
clear

load("last_workspace.mat", "workspace");

[mdp, markings, states, types] = continue_toMDP_without_wait(workspace);