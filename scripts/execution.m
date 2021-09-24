clc
clear

load("executable_approximated_rates.mat")

executable.set_marking(executable.initial_marking);

executable.set_catkin_ws("ros_ws")
executable.create_ros_interface_package(true)


disp("Build temp_interface package and launch ros packages")
pause()
disp("Press any key...")

results = executable.start_execution();