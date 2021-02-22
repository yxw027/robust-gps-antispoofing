function [timeCn0] = SliceTimeCn0(gnssMeas,timeSpan,aer,bPlot)
% Extract Time-CN0 from gnssMeas and fill missing values
% Input: 
%   gnssMeas.FctSeconds    = Nx1 vector. Rx time tag of measurements.
%       .Svid           = 1xM vector of all svIds found in gpsRaw.
%       ...
%       .Cn0DbHz        = NxM
%
%   timeSpan = 1xN vector, the index of points needs to be processed,
%       usually set to [1:length(gnssMeas.Cn0DbHz)] or shorter
%
%   aer.AzDeg = the satellites' azimuth angles
%
%   bPlot = the plot flag, if set to true, it will plot the time-CN0
%   sequence
%   
%Output: 
%   timeCn0.TimeSpan = timeSpan vector
%          .Svid = 1xM vector containing satellite IDs
%          .Cn0DbHz = NxM vector, containing Cn0 sequence in time order
%          .AoE = 1xM vector. The satellite's groudtruth azimuth angles
%          .AzDeg: Nx1 vector. The receiver's azimuth angles in time order 

% plot figure or not 
if bPlot
    figure('name','Time-CN0');
    colors = SetColors;
end

% initialize
M = length(gnssMeas.Svid); % the number of satellites 
timeCn0.TimeSpan = timeSpan;
timeCn0.Svid = [];
timeCn0.Cn0DbHz = [];
timeCn0.AoE = [];
timeCn0.AzDeg = mean(gnssMeas.AngleZ(timeSpan,:), 2,'omitnan');

%% Slice C/N0
% process the signals in each satellite one by one 
for i=1:M
    % Original data
    siCn0DbHz = gnssMeas.Cn0DbHz(timeSpan,i);
    iF = find(isfinite(siCn0DbHz)); 
    % Too many missing data, considered invalid SV
    if length(iF) < length(timeSpan) / 2
        continue;
    end
    
    % fill the missing value with nearest non-missing value
    siCn0DbHz = fillmissing(siCn0DbHz, 'nearest');
    
    
    timeCn0.Svid(end+1) = gnssMeas.Svid(i);
    timeCn0.AoE(end+1) = mean(aer.AzDeg(:,i),'omitnan');
    timeCn0.Cn0DbHz(:,end+1) = siCn0DbHz;

    % Plot
    if bPlot
        p(i)=plot(timeSpan,siCn0DbHz,...
        'DisplayName',strcat('Satellite ID: ',int2str(gnssMeas.Svid(i))),...
        'LineWidth',2,...
        'Color',colors(i,:),...
        'DisplayName', strcat('Satellite ID: ',int2str(gnssMeas.Svid(i))));
        set(gca,'FontSize',15);
        hold on;

        ti = timeSpan(iF(end));
        ts = int2str(gnssMeas.Svid(i));
%         text(timeSpan(end),siCn0DbHz(iF(end)),ts,'Color',colors(i,:),'FontSize',28);
    end
end

if bPlot
    title('Time-Cn0 sequence','FontSize',30);
    xlabel('Time/s','FontSize',30);
    ylabel('C/No in dB.Hz','FontSize',30);
    set(gca,'FontSize',28);
    lgd= legend('show');
    lgd.FontSize=20;
    lgd.Location='southeast';
    axis([timeSpan(1), timeSpan(end), 0, 60]);
    grid on;
%     set(gcf,'PaperSize',[8,7])
%     print(gcf, 'HumAdvSpofT-C.pdf', '-dpdf', '-fillpage')
%     savefig('HumAdvSpofT-C.fig')
end

end %End of Function