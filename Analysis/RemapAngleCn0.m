function [angleCn0] = RemapAngleCn0(timeCn0,N)
% Description: Remap the Angle-Cn0 pair to a vector
% also sort and remove outliers from the original data
%
% Input:
%       gnssMeas: Data we get from the log file
%       N: Length of remap vector (divide 360бу into N spans)
% Output:
%       angleCn0.Svid: Svid of satellites
%       angleCn0.Cn0DbHz: sorted and outliers removed Cn0DbHz data in
%           order of degrees
%       angleCn0.AzDeg: sorted and outliers removed Azimute data
%%      Following fields are used for average methods: 
%       angleCn0.AngleSpan: the angle span for each vector element
%       angleCn0.MappedVec: the averaged CN0 value in each angleSpan
%       angleCn0.MappedAzDeg: the central angle in each AngleSpan

%% Angle window span
angleSpan = 360 / N; % split the 360 degrees into N angleSpans

M = length(timeCn0.Svid); % number of satellites 
angleCn0.Svid = timeCn0.Svid;
angleCn0.MappedVec = [];
angleCn0.AngleSpan = angleSpan;

angleCn0.Cn0DbHz = [];
angleCn0.AoE = timeCn0.AoE;

% sort the AzDeg in ascending order
[azDeg,iAz] = sort(timeCn0.AzDeg);
angleCn0.AzDeg = azDeg;

% the central angles in N angleSpans 
angleCn0.MappedAzDeg = [angleSpan/2:angleSpan:360-angleSpan/2]';

%% Start process data of each satellite
for i = 1:M
    %% Pick out data of single satellite
    % sort the Cn0 sequence accoring to its az degree
    siCn0DbHz = timeCn0.Cn0DbHz(iAz,i);

    %% Init data
    pos = 1;
    siMappedVec = zeros(N,1);
    
    %% Remap
    % for each angleSpan
    for j = 1:N
        cn0InWindow = [];
        % fill the CN0 whose azAngle smaller than j*angleSpan into cn0InWindow
        while (pos <= length(azDeg) && ~isnan(azDeg(pos))...
                && azDeg(pos) < j*angleSpan)
            cn0InWindow(end+1) = siCn0DbHz(pos);
            pos = pos+1;
        end
        
        %% If no angle-cn0 pair in the window, fill NaN
        if isempty(cn0InWindow)
            siMappedVec(j) = NaN;
            continue;
        end
      
        %% Remove outliers
        sampleCount = length(cn0InWindow);
        
        if sampleCount > 3
            % find the outliers
            posOutlier = isoutlier(cn0InWindow,'grubbs','ThresholdFactor',0.05);
               
            % if any outliers 
            if any(posOutlier) == true
%                 disp('spot outlier!');
%                 disp(cn0InWindow');
%                 disp(posOutlier);

                % remove the outliers from cn0InWindow
                cn0InWindow = cn0InWindow(~posOutlier);
                
                % set the CN0 value in original siCn0DbHz to NaN
                iOrigin = pos-sampleCount:1:pos-1;
                iOrigin = iOrigin(posOutlier);
                siCn0DbHz(iOrigin) = NaN;
            end
        end
        
        % calculate the mean CN0 in each cn0InWindow and fill it into siMappedVec
        siMappedVec(j) = mean(cn0InWindow);
    end
    
    %% zero-order hold for missing values
    siMappedVec = fillmissing(siMappedVec, 'nearest');
    siMappedVec(isnan(siMappedVec)) = siMappedVec(end);
    
    % averaged CN0 in each angleSpan
    angleCn0.MappedVec(:,i) = siMappedVec;
    
    %% angle-cn0 pais with outlier removed
    angleCn0.Cn0DbHz(:,i) = siCn0DbHz;
end

end %End of the function

function [bEven] = IsAzRotateEvenly(azDeg, N)
    azDeg = azDeg(~isnan(azDeg));
    azSegment = zeros(1,N);
    for i = 1:length(azDeg)
        k = floor(azDeg(i) / 360 * N) + 1;
        azSegment(k) = azSegment(k) + 1;
    end
    azSegment = azSegment / length(azDeg);
    bEven = std(azSegment);
end


