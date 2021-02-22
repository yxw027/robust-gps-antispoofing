function [timeCn0] = timeMap(timeCn0,bplot)
% This Function implements time mapping for Cn0, convert a non-uniform
% rotation to a uniform rotation. The basic idea of converting is
% described as follows: firstly assuming the sampling rate of GPS chip is
% 1Hz, then the timestamp of each point is 1s, 2s ... Ns. Now if we assume
% that the receiver is rotating at a constant speed (w), then the desired
% time stamp of a point i should be az_i/w, where az_i is the az angle the
% receiver has rotated from the beginning, and az_i/w is likely not an
% integer in this case. In the next step, we draw the (az_i/w,CNO_i) pairs in
% a time-CN0 plot, then we estimate the value of CN0 at i second (i is an
% integer and belongs to [1,N]) using interpolation, these new estimated CN0s 
% form a new array which is mapped array result. 
%
% input:
%   timeCn0: struct containing time-CN0 sequence
%   bplot: if plot the mapping process or not 
% output:
%   timeCn0: the newtimeCn0 after converting, only timeCn0.Cn0DbHz changed
%   rotFre: the synthesitic rotFre we used for mapping
%% Note: this funtion do not support the situation that rotation direction changes while rotating!

maxTimeInterval = max(timeCn0.TimeSpan);

% if rotation is counterclockwise, then reverse the timeCn0.AzDeg and timeCn0.Cn0DbHz
if ifflip(timeCn0.AzDeg)
    timeCn0 = dataflip(timeCn0);
end

% unwrap the angle vector 
AzDegUnwrap = degUnwrap(timeCn0.AzDeg);
% set a rotation Speed deg/sec
rotSpeed = round(max(AzDegUnwrap-AzDegUnwrap(1))/maxTimeInterval);

% the desired timestamp if assuming the receiver rotated at constant speed rotSpeed
timeDeg = AzDegUnwrap./rotSpeed; 
timeDeg = timeDeg-timeDeg(1)+1;

%fitting
M = length(timeCn0.Svid);% number of sv
N = length(timeCn0.TimeSpan); % number of data points 
newCn0DbHz = zeros(size(timeCn0.Cn0DbHz));
for i=1:M
    
    % estimate the CN0 of j-th point of sv_i using Linear Interpolation 
    for j = 1:N
        newCn0DbHz(j,i) =  Linearsmooth(timeCn0.Cn0DbHz,timeDeg,i,j);
    end 

    % curve smoothing for signals in each sv
%     newCn0DbHz(:,i) = CurveFit(timeDeg, timeCn0.Cn0DbHz(:,i), [1:N], bplot);
    
end 

if bplot
    plotMap(timeCn0.TimeSpan,AzDegUnwrap,timeDeg,newCn0DbHz,timeCn0.Cn0DbHz)
end 

timeCn0.Cn0DbHz = newCn0DbHz; 
rotFre = rotSpeed/360; 
timeCn0.rotFre = rotFre;




end

function fitVal = Linearsmooth(Cn0DbHz,timeDeg,i,j)
% estimate the CN0 of j-th point of sv_i using Linear Interpolation 
    if j==1
        fitVal = Cn0DbHz(j,i);
    else
        % find the left timeindex of j
        leftNeiborIdx = max(find(timeDeg<=j));
        while(isnan(Cn0DbHz(leftNeiborIdx,i)) && leftNeiborIdx>=1)
            leftNeiborIdx  = leftNeiborIdx-1;
        end 
        
        % find the right timeindex of j
        rightNeiborIdx = min(find(timeDeg>j));
        if isempty(rightNeiborIdx) % for the situation of last point 
            rightNeiborIdx = leftNeiborIdx;
            leftNeiborIdx = leftNeiborIdx-1;
        else
            while(isnan(Cn0DbHz(rightNeiborIdx,i)) && rightNeiborIdx<=length(timeDeg))
                rightNeiborIdx  = rightNeiborIdx+1;
            end
         
        end
        % linear mapping
        scope = (Cn0DbHz(rightNeiborIdx,i)-Cn0DbHz(leftNeiborIdx,i))...
            /(timeDeg(rightNeiborIdx)-timeDeg(leftNeiborIdx));
        fitVal = Cn0DbHz(leftNeiborIdx,i)+(j-timeDeg(leftNeiborIdx))*scope;
        
    end 
    
    
end 
 
function mappedDeg = degUnwrap(degVec)
% unwrap the degree vector from a cyclic vector into a monotonically increasing
% vector

% check if rotation direction is clockwise
degRotFre = diff(degVec);
numDegIncrease = nnz(degRotFre>0);
if numDegIncrease<length(degRotFre)/8
    error("counter clockwise rotation");
end 


mappedDeg = zeros(size(degVec)); 
numPeriod = 0;

for i=1:length(degVec)
    if i==1
        mappedDeg(i)= degVec(i);
    else
        if degRotFre(i-1)>0 || abs(degRotFre(i-1))<100
            mappedDeg(i) = degVec(i)+numPeriod*360;
        else
            numPeriod=numPeriod+1;
            mappedDeg(i) = degVec(i)+numPeriod*360;
        end 
    end 
end 

 
end 

function plotMap(TimeSpan,AzDegUnwrap,timeDeg,newCn0DbHz,Cn0DbHz)

[M,N] = size(Cn0DbHz);% N: number of svid, M: number of timeSpan

figure('name','TimeMapping');
colors = SetColors;

for i=1:N
    subplot(4,1,1);
    plot(TimeSpan,Cn0DbHz(:,i),...
    'LineWidth',1.2,...
    'Color',colors(i,:));
    hold on;
%     ti = timeSpan(iF(end));
%     ts = int2str(gnssMeas.Svid(i));
%     text(ti,siCn0DbHz(iF(end)),ts,'Color',colors(i,:));
    
    subplot(4,1,2);
    plot(AzDegUnwrap,Cn0DbHz(:,i),...
    'LineWidth',1.2,...
    'Color',colors(i,:));
    hold on;
%     ti = timeSpan(iF(end));
%     ts = int2str(gnssMeas.Svid(i));
%     text(ti,siCn0DbHz(iF(end)),ts,'Color',colors(i,:));
%     
    subplot(4,1,3);
    plot(timeDeg,Cn0DbHz(:,i),...
    'LineWidth',1.2,...
    'Color',colors(i,:));
    hold on;
%     ti = timeSpan(iF(end));
%     ts = int2str(gnssMeas.Svid(i));
%     text(ti,siCn0DbHz(iF(end)),ts,'Color',colors(i,:));
    
    subplot(4,1,4);
    plot(TimeSpan,newCn0DbHz(:,i),...
    'LineWidth',1.2,...
    'Color',colors(i,:));
    hold on;
%     ti = timeSpan(iF(end));
%     ts = int2str(gnssMeas.Svid(i));
%     text(ti,siCn0DbHz(iF(end)),ts,'Color',colors(i,:));
end

subplot(4,1,1);
title('Time-Cn0');
xlabel('Time/s');
ylabel('Cn0/dBHz');

subplot(4,1,2);
title('Deg-Cn0');
xlabel('Degree/deg');
ylabel('Cn0/dBHz');

subplot(4,1,3);
title('Mapped Time - Cn0 before smoothing');
xlabel('Time/s');
ylabel('Cn0/dBHz');

subplot(4,1,4);
title('Mapped Time - Cn0 after smoothing');
xlabel('Time/s');
ylabel('Cn0/dBHz');

end 

function [linecolor] = grayColor(color)
    hsv = rgb2hsv(color);
    hsv(2) = hsv(2) * 0.75;
    linecolor = hsv2rgb(hsv);
end

function flag = ifflip(degVec)
% description: determine the rotation is clockwise or counterclockwise (head to bottom)
% Input:
%   degVec: the sequence of az degree in the order of time 
% Output:
%   flag: whether the rotation is clockwise or not 
    degRotFre = diff(degVec);
    numDegIncrease = nnz(degRotFre>0);
    % more than half degree are increasing, then clockwise 
    if numDegIncrease>=length(degRotFre)/2
        flag = false;
    else
        flag = true; 
        warning("counter clockwise rotation");
    end 
end

function timeCn0 = dataflip(timeCn0)
% reverse the timeCn0.AzDeg and timeCn0.Cn0DbHz 
    timeCn0.AzDeg = flip(timeCn0.AzDeg, 1);
    timeCn0.Cn0DbHz = flip(timeCn0.Cn0DbHz, 1);
end

function [objectY] = CurveFit(xdata, ydata, objectX, bplot)
%  SmoothFit(XDATA,YDATA, OBJECTX)
%  Data for SmoothFit:
%      Xdata: Time/Deg Vector, gathered from log, Nonuniform distribution
%      Ydata: Cn0DbHz Vector, the correspoding Cn0DbHz for xdata
%      objectX: Time/Deg, the Objective Time/Deg Vector, uniform
%      distribution
%  Output:
%      objectY : The corresponding Cn0DbHz Vector for objectX Vector
%

%% Fit
[xData, yData] = prepareCurveData( xdata, ydata );

% Set up fittype and options.
ft = fittype( 'smoothingspline' );
opts = fitoptions( 'Method', 'SmoothingSpline' );
opts.SmoothingParam = 0.00160675722733738;

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );
objectY = fitresult(objectX);

% Plot fit with data.
if bplot
    figure( 'Name', 'Smoothfitt 1' );
    h = plot( fitresult, xData, yData );
    legend( h, 'ydata vs. xdata', 'untitled fit 1', 'Location', 'NorthEast', 'Interpreter', 'none' );
    % Label axes
    xlabel( 'xdata', 'Interpreter', 'none' );
    ylabel( 'ydata', 'Interpreter', 'none' );
    disp(gof)
    grid on
end

end
