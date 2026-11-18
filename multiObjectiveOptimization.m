%% SECTION 10a: MULTI-OBJECTIVE OPTIMIZATION 2D (weighted sums) (WP3)

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
addpath functions_student/

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
ah = plotAirspace(airspace);
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
MaxGen = 30;

% Population Size
PS = 35;

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
PF = 0.6; % [0-1]

%% SECTION 4: GENETIC ALGORITHM OPTIMISATION (MATLAB) - WITH WEIGHTED OBJ.FUNC
% SINGLE OBJECTIVE

% Info
fprintf('MULTI-OBJECTIVE GA 2D (MATLAB) - WEIGHTED SUM ----------------------------\n');
alpha = 0:0.025:1;
obj_aircraft = zeros(1, length(alpha));
obj_area = zeros(1, length(alpha));
phenotypes = zeros(NVAR, length(alpha));

% Open parallel pool
if isempty(gcp('nocreate'))
    parpool;
end

% GA options
options2D = optimoptions('ga', ...
    'MaxGenerations', MaxGen, ...
    'PopulationSize', PS, ...
    'CrossoverFraction', CF, ...
    'EliteCount', EC, ...
    'Display', 'off');

parfor i = 1:length(alpha)
    % Define objective function
    objFun_2D = @(x) objFun2D(x, alpha(i));
    
    % Solve with GA
    [ phenotype, fval, ~, ~, ~, ~ ] = ga ( ...
        objFun_2D, NVAR, [], [], [], [], LB, UB, [], options2D );
    phenotypes(:, i) = phenotype;
    [~, ~, obj_aircraft(i), ~, obj_area(i)] = objFun2D(phenotype, alpha(i));
end


% Close parallel pool
delete(gcp('nocreate'));

%% SECTION 5: PLOT PARETO FRONT AND RANKS
paretoPlots(obj_aircraft, obj_area)

%% Write complexity parametres

% Recover the voronoid structure from the phenotype
vorxy = phenotype2vor(phenotypes(:, 20));

% Add boundary voronoi (this avoids infinite sectors near FIR)
vorxyB = [vorxy; airspace.vorBounds]; 

% Obtain the complexity of the final (optimal) sectorization
comp = complexityFunction(vorxyB, airspace);

% Plot the voronoi sectors into the main Airspace plot "ah"
plotVoronoiSectors(ah, vorxy(:,1), vorxy(:,2), airspace);

% Display results
% fprintf("Best cost: %.2f\n", fval);
disp('Best individual:');
disp(vorxy);
disp('Complexity:');
disp(struct2table(comp));

%% SECTION 6: GENETIC ALGORITHM OPTIMISATION (MATLAB) - WITH VECTOR OBJ.FUNC
fprintf('MULTI-OBJECTIVE GA 2D --------------------------------------\n');
% GA options
% Options for multi-objective GA
options2D = optimoptions('gamultiobj',...
    'PopulationSize', PS, ...
    'CrossoverFraction', CF, ...
    'MaxGenerations', MaxGen, ...
    'ParetoFraction', PF, ...
    'PlotFcn', { ...
    @gaplotpareto, ...
    @gaplotgenealogy, ...
    @gaplotrankhist, ...
    @gaplotparetodistance});

% Define objective function
Multi_objFun = @MultiobjFun;
% Solve with GA
% Optimise
[paretoPheno2D, fval2D, exitflag2D, output2D, population2D, scores2D] = ...
    gamultiobj(Multi_objFun, NVAR, [], [], [], [], LB, UB, [], options2D);


%% SECTION 7: 2D MOO RESULTS

% Recover the voronoid structure from the phenotype
% We will take the first individual from the pareto!
vorxy = phenotype2vor(paretoPheno2D(6,:));

% Add boundary voronoi (this avoids infinite sectors near FIR)
vorxyB = [vorxy; airspace.vorBounds];

% Obtain the complexity of the final (optimal) sectorization
comp = complexityFunction(vorxyB, airspace);

% Plot the voronoi sectors into the main Airspace plot "ah"
plotVoronoiSectors(ah, vorxy(:,1), vorxy(:,2), airspace);

% Display results
disp('First individual in the pareto 2D:');
disp(vorxy);
fprintf("Cost of this individual: %.2f %.2f\n", fval2D(1,:));
disp('Complexity:');
disp(struct2table(comp));