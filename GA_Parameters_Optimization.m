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

% Maximum number of generations. Rearranged as a vector for different
% values study
MaxGen_vals = 5:5:35;

% Population Size. Rearranged as a vector for different values study
PS_vals = 5:5:35;

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

MC = 120;
NPS = numel(PS_vals);
NMaxGen = numel(MaxGen_vals);

results = zeros(NPS, NMaxGen, MC);

% Threshold to decide when to parallelize
PS_threshold = 15; % PS >= 15 parallelize
MaxGen_threshold = 15; % MaxGen >= 15 parallelize

% Open parallel pool
if isempty(gcp('nocreate'))
    parpool;
end

% --- LÓGICA DEL TIMER Y PROGRESO ---
NCOMB = NPS * NMaxGen; % Número total de combinaciones (49)
n_finished = 0;        % Contador de combinaciones terminadas
% Iniciar el timer global para todo el proceso
tic;
    
for i = 1:NPS
    for j = 1:NMaxGen
        PS = PS_vals(i);
        MaxGen = MaxGen_vals(j);
        % GA options
        options1D = optimoptions('ga', ...
            'MaxGenerations', MaxGen, ...
            'PopulationSize', PS, ...
            'CrossoverFraction', CF, ...
            'EliteCount', EC, ...
            'PlotFcn', {@gaplotbestf, @gaplotgenealogy}, ...
            'Display', 'off');

        % --- Display de Progreso y Timer ---
        n_finished = n_finished + 1;
        
        % Calcular métricas de tiempo
        elapsed_time = toc; % Tiempo transcurrido en segundos
        avg_time_per_comb = elapsed_time / n_finished; % Tiempo promedio por combinación

        N_remaining = NCOMB - n_finished; % Combinaciones restantes
        estimated_time_remaining = N_remaining * avg_time_per_comb;

        % Convertir tiempos a formato legible (horas, minutos, segundos)
        % Nota: duration() es una función moderna y limpia de MATLAB
        d_elapsed = duration([0, 0, elapsed_time], 'Format', 'hh:mm:ss');
        d_remaining = duration([0, 0, estimated_time_remaining], 'Format', 'hh:mm:ss');

        % Debug: show current combination with timing info
        fprintf('=================================================================\n');
        fprintf('PROGRESO: %d/%d (%.1f%%) | PS=%d, MaxGen=%d\n', n_finished, NCOMB, (n_finished/NCOMB)*100, PS, MaxGen);
        fprintf('TIEMPO: Transcurrido %s | Estimado Restante %s\n', char(d_elapsed), char(d_remaining));

        % Big combinations of PS & MaxGen -> Parallelize 
        if PS >= PS_threshold || MaxGen >= MaxGen_threshold
            fprintf('MODE: PARALLEL\n');
            parfor k = 1:MC
                [phenotype_current, fval_current, ~, ~, ~, ~] = ga( ...
                objFun1D, NVAR, [], [], [], [], LB, UB, [], options1D );
                results(i, j, k) = fval_current; % Store the fitness value
            end
        else
            fprintf('MODE: SEQUENTIAL\n');
            % "Small" combinations -> squential
            for k = 1:MC
                [phenotype_current, fval_current, ~, ~, ~, ~] = ga( ...
                objFun1D, NVAR, [], [], [], [], LB, UB, [], options1D );
                results(i, j, k) = fval_current; % Store the fitness value
            end
        end
        fprintf('... Combination %d/%d finished.\n', n_finished, NCOMB);
    end
end

% Close parallel pool
delete(gcp('nocreate'));


% Compute statistics over MC iterations
mean_results = mean(results, 3); % Mean over MC iterations
std_results = std(results, 0, 3); % Standard deviaton over MC iterations
rsd_results = 100 * (std_results ./ mean_results); % Relative Standard Deviation (RSD)

max_results = max(results, [], 3);
min_results = min(results, [], 3);

%% Heatmaps
figure;
% 
% [X, y] = meshgrid(MaxGen_vals, PS_vals)

% Heatmap of the mean
subplot(2, 2, 1);
imagesc(MaxGen_vals, PS_vals, mean_results);
colorbar;
xticks(0:5:35);
yticks(0:5:35);
xlabel('MaxGen (Max generations)');
ylabel('PS (Population size)');
title('Mean fitness');
set(gca, 'YDir', 'normal');


% Heatmap of the RSD
subplot(2, 2, 2);
imagesc(MaxGen_vals, PS_vals, std_results);
colorbar;
xticks(0:5:35);
yticks(0:5:35);
xlabel('MaxGen (Max generations)');
ylabel('PS (Population size)');
title('STD');
set(gca, 'YDir', 'normal');


% Heatmap of the Max
subplot(2,2,3);
imagesc(MaxGen_vals, PS_vals, max_results);
colorbar;
xticks(0:5:35);
yticks(0:5:35);
xlabel('MaxGen (Max generations)');
ylabel('PS (Population size)');
title('Max fitness');
set(gca, 'YDir', 'normal');


% Heatmap of the Min
subplot(2,2,4);
imagesc(MaxGen_vals, PS_vals, min_results);
colorbar;
xticks(0:5:35);
yticks(0:5:35);
xlabel('MaxGen (Max generations)');
ylabel('PS (Population size)');
title('Min fitness');
set(gca, 'YDir', 'normal');


% Adjust layout
sgtitle('GA Statistics over MC iterations');