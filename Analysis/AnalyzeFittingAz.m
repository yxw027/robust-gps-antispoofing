function [angArrEph]  = AnalyzeFittingAz(angleCn0, bPlot,average)
% Input:
%         angleCn0: degree-cn0 sequence
%         bPlot: whether plot fitting result
%         average: if use average over rotation cycles or not
% Output:
%         angArrEph: AoA and AoE information
%           .Svid: 1xM, array of satellite IDs 
%           .AoE: groundtruth AoE of each satellite
%           .AoA: estimated AoAs from fittings
%           .absDiffRaw: AoA-Diff values of each satellites 
%           .Amp: estimated amplitudes from the fitting curves

M = length(angleCn0.Svid); % number of satellites 
SAMPLE_THRESHOLD = 4;
AMP_THRESHOLD = 1.5;

% plot fitting curves or not 
if bPlot
    figure('name','Cosine Fitting Az');
    colors = SetColors;
    t = linspace(0,360,1024);
end

%% Init angArrEph struct
angArrEph.Svid = angleCn0.Svid;
angArrEph.AoE = angleCn0.AoE;
angArrEph.AoA = zeros(1,M) + NaN;
angArrEph.absDiffRaw = zeros(1,M) + NaN;
angArrEph.Amp = zeros(1,M);

if average
    angleCn0.Cn0DbHz = angleCn0.MappedVec;
    angleCn0.AzDeg = angleCn0.MappedAzDeg;
end 

%% Prepare fitting struct
ftype = fittype('A*cos(2*pi*x/360-phi)+offset',...
                'independent',{'x'},'dependent',{'y'},...
                'coefficients',{'A','phi','offset'});

%% Processing
% process satellite signals one by one 
for i = 1:M
    [dataY, iMissing] = rmmissing(angleCn0.Cn0DbHz(:,i));
    dataX = angleCn0.AzDeg(~iMissing);
    
    % if length of valid points is less than SAMPLE_THRESHOLD, skip 
    if length(dataX) < SAMPLE_THRESHOLD
        continue;
    end
    
    % estimate coefficients {Amp, phi, offset} of cosine wave 
    startPoint = estimateCoisineCoef(dataX, dataY);
    
    % tinsufficient fluctuations, skip the sv
    %{x
    if startPoint(1) < AMP_THRESHOLD
        continue;
    end
    %}
    
    % fit the az angles and CN0 into the cosine wave 
    fitting = fit(dataX, dataY, ftype, 'startpoint', startPoint);
    coef = coeffvalues(fitting);
    
    % make sure amp is positive value
    if coef(1) < 0
        coef(1) = -coef(1);
        coef(2) = coef(2) + pi;
    end
    
    angArrEph.Amp(i) = coef(1);
    angArrEph.AoA(i) = mod(rad2deg(coef(2)), 360);
    
    %% Plot
    if bPlot
        % draw scatter points
        plot(dataX, dataY, '.',...
            'Color', grayColor(colors(i,:)), 'MarkerSize', 8);

        hold on;

        % draw AoE line
        aoe = angArrEph.AoE(i);
        plot([aoe, aoe], [0, 40], '--',...
            'Color', grayColor(colors(3+i,:)), 'LineWidth', 2);

        % fitting cosine curve
        p(i) = plot(t, coef(1)*cos(2*pi*t/360 - coef(2)) + coef(3),...
            'DisplayName',strcat('Satellite ID: ',int2str(angArrEph.Svid(i))),...
            'Color', colors(i,:), 'LineWidth', 2.0);
       
     
        hold on;

%         text(361, coef(1)*cos(2*pi*t(end)/360 - coef(2)) + coef(3), num2str(angArrEph.Svid(i)),...
%             'Color',colors(3+i,:),'FontSize',28);
    end
end

%% add labels on the plot 
if bPlot
    axis([0 360 0 60]);
    title('Degree-Cn0 sequence','FontSize',30);
    ylabel('C/No in dB.Hz','FontSize',30);
    xlabel('Angle (degrees)','Interpreter','none','FontSize',30);
    set(gca,'FontSize',28);
    grid on

end

%% Calculate AoADiffNorm
% Get absolute DifDeg
angArrEph.absDiffRaw = CircleClamp(angArrEph.AoA - angArrEph.AoE);

end%end of the function

function [startPoint] = estimateCoisineCoef(x, y)
% estimate coefficients of sine wave
% output:
%   startPoint(1): Amplitude
%   startPoint(2): phase
%   startPoint(3): offset 
    startPoint(1) = std(y) * sqrt(2);
    [~, iMax] = max(y);
    startPoint(2) = 2*pi*x(iMax)/360;
    startPoint(3) = mean(y);
end

function [linecolor] = grayColor(color)
    hsv = rgb2hsv(color);
    hsv(2) = hsv(2) * 0.75;
    linecolor = hsv2rgb(hsv);
end