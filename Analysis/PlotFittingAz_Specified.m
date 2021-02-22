function [] = PlotFittingAz_Specified(angleCn0)

SV_SELECT = [1, 3, 17, 23];
SINGLE_SV_SELECT = 3;

FITTING_NORM_THRSHOLD = 1.16;

t = linspace(0,360,1024);

[~, i] = intersect(angleCn0.Svid, SV_SELECT);

colors = SetColors;
svid = angleCn0.Svid(i);
az = angleCn0.AzDeg;
mappedvec = angleCn0.MappedVec(:,i);
cn0 = angleCn0.Cn0DbHz(:,i);
aoe = angleCn0.AoE;

iS = (svid == SINGLE_SV_SELECT);

if any(~iS)
    fprintf('Invalid SV Selection!\n');
    return;
end

ftype = fittype('A*cos(2*pi*x/360-phi)+offset',...
                'independent',{'x'},'dependent',{'y'},...
                'coefficients',{'A','phi','offset'});
            
%% Single Sv plot
%subplot(1,2,1);
figure;

startPoint = estimateCoisineCoef(az(:,iS), cn0(:,iS));
fitting = fit(az(:,iS), cn0(:,iS), ftype, 'startpoint', startPoint);
coef = coeffvalues(fitting);

% scatter points
plot(az, cn0(:,iS), '.',...
    'Color', colors(iS,:), 'MarkerSize', 8);
hold on;

% fitting cosine curve
plot(t, coef(1)*cos(2*pi*t/360 - coef(2)) + coef(3),...
    'Color', colors(iS,:), 'LineWidth', 1.5);
hold on;

% draw AoE line
plot([aoe(iS), aoe(iS)], [0, 50], '--',...
    'Color', grayColor(colors(iS,:)), 'LineWidth', 1.0);
hold on;

text(aoe(iS) - 30, 51, 'AoE',...
    'FontSize', 16, 'Color', grayColor(colors(iS,:)));

axis([0 360 30 52]);
xticks(0:60:360);
yticks(30:2:50);

legend({'Measured Data','Fitting Curve','AoE'}, 'Location','southeast');

%title('Single Satellite');
xlabel('Azimuth (degree)');
ylabel('Cn0 (dBHz)');

%% Multiple Sv plot
%subplot(1,2,2);
figure;

tag = {};
p = zeros(length(svid),1);

for i = 1:length(svid) 
    % draw AoE line
    plot([aoe(i), aoe(i)], [0, 50], '--',...
        'Color', grayColor(colors(i,:)), 'LineWidth', 1.0);
    hold on;
    
    % plot scatter points
    plot(az, cn0(:,i), '.',...
        'Color', pointColor(colors(i,:)), 'MarkerSize', 8);
    hold on;
    
    tag{i} = ['sv-',num2str(svid(i))];
    
    % cosine curve fitting
    startPoint = estimateCoisineCoef(az(:,i), cn0(:,i));
    fitting = fit(az, cn0(:,i), ftype, 'startpoint', startPoint);
    coef = coeffvalues(fitting);
    
    % evaluate fitting performance
    err = calcFittingError(az, cn0(:,i), coef);
    fprintf('err for Svid[%d]: %.2f\n', svid(i), err);
    
     if err > FITTING_NORM_THRSHOLD
        smoothedVec = KalmanFilter(mappedvec(:,i),0.6,5);
        
        % smoothed curve
        ts = linspace(0,360,length(smoothedVec));
        p(i) = plot(ts, smoothedVec,...
            'Color', colors(i,:), 'LineWidth', 1.5);
        hold on;
        
        % mark peak
        [peakVal, peakPos] = max(smoothedVec);
        plot(ts(peakPos), peakVal,...
            '-o','MarkerEdgeColor',colors(i,:),...
            'LineWidth', 1.2,...
            'MarkerSize',8);
        hold on;
    else
        % fitting cosine curve
        y_f = coef(1)*cos(2*pi*t/360 - coef(2)) + coef(3);
        p(i) = plot(t, y_f,...
            'Color', colors(i,:), 'LineWidth', 1.5);
        hold on;

        % mark peak
        [peakVal, peakPos] = max(y_f);
        plot(t(peakPos), peakVal,...
            '-o','MarkerEdgeColor',colors(i,:),...
            'LineWidth', 1.2,...
            'MarkerSize',8);
        hold on;
     end
     
     % draw AoE tag
     text(aoe(i) - 30, 51, ['AoE-',num2str(svid(i))],...
    'FontSize', 10, 'Color', grayColor(colors(i,:)));
end

legend(p, tag, 'Location','southeast');

hold off;
axis([0 360 30 52]);
xticks(0:60:360);
yticks(30:2:50);

%title('Multiple Satellites');
xlabel('Azimuth (degree)');
ylabel('Cn0 (dBHz)');

end

function [startPoint] = estimateCoisineCoef(x, y)
    startPoint(1) = std(y) * sqrt(2);
    
    [~, iMax] = max(y);
    startPoint(2) = 2*pi*x(iMax)/360;
    
    startPoint(3) = mean(y);
end

function [err] =  calcFittingError(x, y, coef)
    y_f = coef(1)*cos(2*pi*x/360 - coef(2)) + coef(3);
    err = norm(y - y_f) / length(x);
end

function [pointcolor] = pointColor(color)
    alpha = 0.8;
    pointcolor = (1-alpha) + color*alpha;
end

function [linecolor] = grayColor(color)
    hsv = rgb2hsv(color);
    hsv(2) = hsv(2) * 0.6;
    linecolor = hsv2rgb(hsv);
end

