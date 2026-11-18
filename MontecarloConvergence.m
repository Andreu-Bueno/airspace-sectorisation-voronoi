%% SECTION 1: CLEAR WORKSPACE
close all
clear
clc

% Info
disp(" _   _ ___________ _____ _   _ _____ _____ ");
disp("| | | |  _  | ___ |  _  | \ | |  _  |_   _|");
disp("| | | | | | | |_/ | | | |  \| | | | | | |  ");
disp("| | | | | | |    /| | | | . ` | | | | | |  ");
disp("\ \_/ \ \_/ | |\ \\ \_/ | |\  \ \_/ /_| |_ ");
disp(" \___/ \___/\_| \_|\___/\_| \_/\___/ \___/ ");
disp('>> AIRSPACE SECTORISATION WITH VORONOI <<');
disp('=============================================');

% Add functions subdir to the path
addpath functions/
addpath objectives_student/

%% SECTION 2: LOAD AIRSPACE DATA

% Define datafile paths
fNavWpts = 'data/NavWpts.dat'; % Airspace waypoints
fAirways = 'data/Airways.dat'; % Definition of airways
fFir = 'data/FIR.dat'; % Definition of FIR
fAC = 'data/LatLon-FIR-FL300up-filt-0755-0810.dat'; % Traffic data

% Load all airspace datafiles
airspace = loadAirspace(fNavWpts, fFir, fAirways, fAC);     % Carregar l'airspace una única vegada y calcular tots els WPs per evitar calcular durant una setmana

% Save airspace object
% To load it: airspace = load('data/airspace.mat');
save('data/airspace.mat', '-struct', 'airspace');

% Plot Airspace
% We save the plot axis "ah" so we can keep plotting stuff there
bh = plotAirspace(airspace);


%% SECTION 3: GENETIC ALGORITHM CONFIGURATION

% Number of sectors 
NSECT = 5; 

% Number of variables (coords {x,y} per sector)
NVAR = 10; 

% Boundaries of the Search Space
LB = repmat([-4, 35], [1, NSECT]); % Lower bounds
UB = repmat([6, 44], [1, NSECT]); % Upper bounds

% Maximum number of generations
MaxGen = 20;

% Population Size
PS = 20;

% Elite Count
% Individuals in the current generation with the best fitness values
% These individuals automatically survive to the next generation
% This parameter applies only to Single-objective GA
EC = 2; 

% Crossover Fraction
% Individuals created by combining the vectors of a pair of parents
CF = 0.4; % Percentage of the population [0-1]

% Mutation Fraction
% Individuals created by perturbing an individual by an offset
% This parameter applies only to AGA
MF = 0.3; % Percentage of the population [0-1]

% Newcomers Fraction
% Random new individuals introduced to the population
% This parameter applies only to AGA
NF = 0.1; % Percentage of the population [0-1]

% Pareto Fraction
% This parameter applies only to Multi-objective GA
PF = 0; % [0-1]


%% SECTION 6: GENETIC ALGORITHM OPTIMISATION (MATLAB)
% SINGLE OBJECTIVE

% Info
fprintf('SINGLE-OBJECTIVE GA 1D (MATLAB) ----------------------------\n');

% Define objective function
objFun1D = @objFun;

% GA options
options1D = optimoptions('ga', ...
    'MaxGenerations', MaxGen, ...
    'PopulationSize', PS, ...
    'CrossoverFraction', CF, ...
    'EliteCount', EC, ...
    'PlotFcn', {@gaplotbestf, @gaplotgenealogy});

n_runs = 250;
mean_vec = zeros(1, n_runs);
std_vec = zeros(1, n_runs);
vals_vec = zeros(1, n_runs);

% Create figure
figure;

% --- LEFT AXIS: MEAN ---
yyaxis left
h_mean = plot(NaN, NaN, 'b.-', 'LineWidth', 1.5);
ylabel('Mean Value');
hold on;
grid on;

% --- RIGHT AXIS: STD ---
yyaxis right
h_std = plot(NaN, NaN, 'r.--', 'LineWidth', 1.5);
ylabel('Std Deviation');


xlabel('Iterations');
title('Convergence of Mean and Std (Dual Axis)');
legend('Mean','Std');

for i = 1:n_runs
    [phenotype_current, fval_current, ~, ~, ~, ~] = ga( ...
    objFun1D, NVAR, [], [], [], [], LB, UB, [], options1D );

    vals_vec(1, i) = fval_current;
    mean_vec(1, i) = mean(vals_vec(1:i));
    std_vec(1, i) = std(mean_vec(1:i));

    % Update LEFT axis
    yyaxis left
    set(h_mean, 'XData', 1:i, 'YData', mean_vec(1:i));

    % Update RIGHT axis
    yyaxis right
    set(h_std,  'XData', 1:i, 'YData', std_vec(1:i));

    drawnow;
end