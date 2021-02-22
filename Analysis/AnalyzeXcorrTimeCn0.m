function [groupNorm] = AnalyzeXcorrTimeCn0(timeCn0, bPlot)
% Description: calculate CN0-Corr according to GNSS time-CN0 sequence
% Input:
%       timeCn0: Time-Cn0 data
%       bPlot: to plot correlation figure or not 
% Output:
%       groupNorm: the CN0-Corr value 
%
M = length(timeCn0.Svid);
N = length(timeCn0.TimeSpan);

%% make sure zero-mean
cn0DbHz = timeCn0.Cn0DbHz;
cn0DbHz = cn0DbHz - mean(cn0DbHz);

%% plot cross-correlation functions
if bPlot
    figure('name','Time-CN0 Xcorr');
    iRef = 1;
    n = -N+1:1:N-1;
    colors = SetColors;
    
    for i = 1:M
        vecRef = cn0DbHz(:,iRef);
        veci = cn0DbHz(:,i);

        R_ki = xcorr(vecRef, veci,'normalized');

        plot(n, R_ki,...
            'Color', colors(i,:), 'LineWidth', 1);
        hold on;

        tag = sprintf('%d-%d',timeCn0.Svid(iRef),timeCn0.Svid(i));
        text(0, R_ki(N), tag,...
            'Color', colors(i,:),...
            'FontWeight', 'bold');
        hold on;
    end
    
    plot([0,0],[-1,1],...
        'Color', [0.5,0.5,0.5], 'LineWidth', 1);
    axis([-60+1, 60-1, -1, 1])
    
    set(gca,'linewidth',1,'fontsize',24);
    xlabel('Lag (second)','fontsize',24)
    ylabel('Correlation coefficient', 'FontSize',24);
    set(gca,'XTick',[-50:25:50], 'YTick', [-1, 0, 1]);
end

%% Generate xcorr matrix
R_0 = zeros(M);

for i = 1:M
    for j = 1:M
        veci = cn0DbHz(:,i);
        vecj = cn0DbHz(:,j);
        % calculate correlation between satellite_i's and satellite_j's signals 
        R_0(i, j) = xcorr(veci, vecj, 0, 'normalized');
    end
end

if bPlot
    disp(round(R_0));
end

% zero out auto-correlations
for i = 1:M
    R_0(i,i) = 0;
end

% normalization
groupNorm = sum(sum(R_0)) ./ M;

end

