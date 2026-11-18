function paretoPlots(solObjective1, solObjective2)
%DRAWPARETOPLOTS Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    solObjective1
    solObjective2
end

%% Plot scatter of solutions with X: solObjective1 and Y:solObjective2
figure;
scatter(solObjective1, solObjective2, 80, '+', 'MarkerEdgeColor','r', 'LineWidth', 2);
xmax = max(solObjective1) + 2;
ymax = max(solObjective2) + 2;
xlim([0, xmax])
ylim([0, ymax])
xlabel('Objective 1 (Aircrafts)');
ylabel('Objective 2 (Areas)');
title('Pareto Front (Weighted Sum)');
grid on;
hold on;

%% Search Pareto Front
isPareto = true(size(solObjective1));
for i = 1:length(solObjective1)
    for j = 1:length(solObjective2)
        if all([solObjective1(j) <= solObjective1(i), solObjective2(j) <= solObjective2(i)]) && ...
           any([solObjective1(j) < solObjective1(i),  solObjective2(j) < solObjective2(i)])
            isPareto(i) = false;
            break;
        end
    end
end

% Extract points of the front
pf_x = solObjective1(isPareto);
pf_y = solObjective2(isPareto);

% Sort for any of the objectives (objective 1 increasingly)
[pf_x, idx] = sort(pf_x);
pf_y = pf_y(idx);

scatter(pf_x, pf_y, 120, '+', ...
        'MarkerEdgeColor', 'y', ...
        'LineWidth', 3);

% Plot Pareto front
plot(pf_x, pf_y, 'LineWidth', 2, 'Color', 'b');

legend('All solutions','Pareto solutions','Pareto front','Location','best');


fprintf('Pareto plots displayed\n');

%% Analyze ranks
ranks = assignRanks(solObjective1, solObjective2);

% Plot histogram
figure;
histogram(ranks, 'BinMethod','integers', ...
                  'FaceColor',[0.2 0.4 0.8], ...
                  'EdgeColor','black');

xlabel('Ranks of dominance');
ylabel('Number of Individuals');
title('Rank Histogram');
grid on;
set(gca,'FontSize',12)


end


function ranks = assignRanks(solObjective1, solObjective2)

n = length(solObjective1);
ranks = zeros(n,1);

remaining = true(n,1);
currentRank = 1;

while any(remaining)
    idx = find(remaining);
    isFront = true(length(idx),1);

    for i = 1:length(idx)
        for j = 1:length(idx)
            if i ~= j
                if all([solObjective1(idx(j)) <= solObjective1(idx(i)), ...
                        solObjective2(idx(j)) <= solObjective2(idx(i))]) && ...
                   any([solObjective1(idx(j)) < solObjective1(idx(i)), ...
                        solObjective2(idx(j)) < solObjective2(idx(i))])
                    isFront(i) = false;
                    break
                end
            end
        end
    end

    % Assign current rank
    ranks(idx(isFront)) = currentRank;
    remaining(idx(isFront)) = false;

    currentRank = currentRank + 1;
end
end
