clc
clear

load("executable_second_iteration.mat")

transitions = executable.transitions(find(startsWith(executable.transitions, "FinishedCharging")))
nTransitions = size(transitions, 2)

places_to_delete = executable.places(find(endsWith(executable.places, "B2")))

places_to_add = ["panel1_B1", "panel2_B1", "panel3_B1", "panel4_B1"]

executable.remove_arcs(places_to_delete, transitions, ["out", "out", "out", "out"])

executable.add_arcs(places_to_add, transitions, ["out", "out", "out", "out"], [1, 1, 1, 1])