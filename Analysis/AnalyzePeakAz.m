function [angArrEph] = AnalyzePeakAz(angleCn0,bPlot)
% Input:
%         angleCn0: angle-cn0 pairs
%         bPlot: whether plot fitting result
% Output:
%         angArrEph: AoA and AoE information

N = length(angleCn0.MappedVec);
M = length(angleCn0.Svid);
AMP_THRESHOLD = 3;

%% Init angArrEph struct
angArrEph.Svid = angleCn0.Svid;
angArrEph.AoE = angleCn0.AoE;
angArrEph.AoA = zeros(1,M) + NaN;
angArrEph.absDiffRaw = zeros(1,M) + NaN;
angArrEph.absDiff = zeros(1,M);
angArrEph.relDiff = zeros(1,M);
angArrEph.Amp = zeros(1,M);

%% Plot data for each satellite
if bPlot
    figure('name','Find-Peak Az');
    colors = SetColors;
    ax1 = subplot(2,1,1);
    ax2 = subplot(2,1,2);
end

for i = 1:M
    vec = angleCn0.MappedVec(:,i);
    %smoothed_vec = smooth(angleCn0.MappedVec(:,i),16,'loess');
    smoothed_vec = KalmanFilter(vec,0.5,3);
    
    %% get AoA from the angle with max cn0
    [max_val, max_pos] = max(smoothed_vec);
    [min_val, ~] = min(smoothed_vec);

    % amplitude too small, regarded as invalid data
    angArrEph.Amp(i) = (max_val - min_val) * 0.5;
    if angArrEph.Amp(i) < AMP_THRESHOLD
        continue;
    end
    
    angArrEph.AoA(i) = max_pos * angleCn0.AngleSpan;

    %% Plot
    if bPlot
        % unsmoothed plot
        subplot(2,1,1);
        % draw curve
        plot(linspace(0,360,N), vec,...
            'Color', colors(i,:), 'LineWidth', 1.5);
        hold on;

        % draw svid tag
        text(360, smoothed_vec(end), num2str(angleCn0.Svid(i)),...
            'Color', colors(i,:));
        hold on;

        % smoothed plot
        subplot(2,1,2);

        % draw curve
        plot(linspace(0,360,N), smoothed_vec,...
        'Color', colors(i,:), 'LineWidth', 1.5);
        hold on;

        % points out max position
        plot(angArrEph.AoA(i), max_val,...
        '-o','MarkerEdgeColor',colors(i,:),...
        'LineWidth', 1.2,...
        'MarkerSize',6);
        hold on;

        % draw the AoE position
        plot([angArrEph.AoE(i),angArrEph.AoE(i)],[0,50],...
        '--','Color', colors(i,:), 'LineWidth', 1);
        hold on;

        % draw svid tag
        text(360, smoothed_vec(end), num2str(angleCn0.Svid(i)),...
            'Color', colors(i,:));
        hold on;

        %fprintf('AoA of satellite ID[%d]: %.2f degree\n',...
        %    angleCn0.Svid(i), angArrEph.AoA(i));
    end
end

if bPlot
    %% set title, label and axis range
    title(ax1,'unsmoothed Angle-Cn0 sequence');
    title(ax2,'smoothed Angle-Cn0 sequence');
    xlabel(ax1, 'Angle/degree');
    ylabel(ax1, 'Cn0/dBHz');
    xlabel(ax2, 'Angle/degree');
    ylabel(ax2, 'Cn0/dBHz');
    axis([ax1, ax2], [0 360 15 50]);
end

%% Calculate AoADiffNorm
% Get absolute DifDeg
angArrEph.absDiffRaw = CircleClamp(angArrEph.AoA - angArrEph.AoE);
% Calculate relative DifDeg and AoA
[~, iRef] = min(abs(angArrEph.absDiffRaw));
angArrEph.refId = angArrEph.Svid(iRef);
angArrEph.absDiff = CircleClamp(angArrEph.absDiffRaw - mean(angArrEph.absDiffRaw));
angArrEph.relDiff = CircleClamp(angArrEph.AoA - angArrEph.AoA(iRef));

end %End of function

