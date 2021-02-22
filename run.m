%% Initialize

clear;
clc;
close all;

addpath ./Constants;
addpath ./Config;
addpath ./Utils;
addpath ./LoadData;
addpath ./Analysis;

% set the GNSS logs that will be processed
config = SetConfig;

%% Run
results = results_table; 
% process the GNSS log file one by one
for logindex = 1 : length(config.LogFile)
    warning('off')
    
    %% Load log data
    logfile = config.LogFile{logindex};
    dataFilter = SetDataFilter;
    % Read values of different fields from the GNSS log file
    [gnssRaw,gnssAnalysis] = ReadGnssLogger(config.Base,logfile,dataFilter);
    if isempty(gnssRaw), return, end
    % Process raw measurements read from ReadGnssLogger
    gnssMeas = ProcessGnssMeas(gnssRaw);
    
    %% Calculate AoE and so on
    fctSeconds = 1e-3*double(gnssRaw.allRxMillis(end));
    utcTime = Gps2Utc([],fctSeconds);
    % Get hourly ephemeris files
    allGpsEph = ReadNasaHourlyEphemeris(utcTime);
    if isempty(allGpsEph), return, end
    % calculate the receiver's location (lat,lon,alt) based on the GNSS log
    location = getLocation(gnssMeas, allGpsEph);
    % Compute residuals containning satellites' positions from GPS Accumulated Delta Ranges
    aer = GpsSvAer(gnssMeas,allGpsEph, location);
    
    %% Apply detection algorithms
    timeSpan = 1 : length(gnssMeas.AngleZ);
    % Extract Time-CN0 from gnssMeas
    timeCn0 = SliceTimeCn0(gnssMeas,timeSpan,aer,false);
    % map the Time-CN0 sequences to Degree-CN0 sequences
    angleCn0 = RemapAngleCn0(timeCn0,18);
    % estimate satellites' AoAs by fitting sinewave on Degree-CN0 sequences
    aoaFitting = AnalyzeFittingAz(angleCn0, false, false);
    % calculate AoA-Dev
    aoa_dev = anglestddev(aoaFitting.AoA);
    % average CN0 over rotation cycles 
    AORCFitting = AnalyzeFittingAz(angleCn0, false, true);
    % calculate AROC-Dev 
    roac_dev = anglestddev(AORCFitting.AoA);
    % calculate CN0-Corr
    groupNorm = AnalyzeXcorrTimeCn0(timeCn0, false);
    
    % preprocess the time-cn0 sequence before FFT
    timeCn0 = timeMap(timeCn0,false); 
    % estimate AoAs using spectrum analysis
    angArrEph = AnalyzeSpectrumAz(timeCn0,NaN,false);
    % calculate SA-Dev
    sa_dev = anglestddev(angArrEph.AoA);
    
    % Write results to table
    results.LogName{logindex} = logfile;
    results.AoA_Diff(logindex) = mean(abs(aoaFitting.absDiffRaw), 2, 'omitnan');
    results.CN0_Corr(logindex) = groupNorm;
    results.AoA_Dev(logindex) = aoa_dev;
    results.AORC_Dev(logindex) = roac_dev;
    results.SA_Dev(logindex) = sa_dev;
    
end

% Display the results
disp(results)

%% Sub functions

function results = results_table
% Create a table to store the algorithm output

% Table fields: 
%   LogName: file name of the GNSS log 
%   Results for basic attack detection: 
%       AoA_Diff, AoA_Dev, CN0-Corr 
%   Results for adaptive attack: 
%       AORC_Dev, SA_Dev

    results = table();
    results.LogName = zeros(0);
    results.AoA_Diff = zeros(0);
    results.CN0_Corr = zeros(0);
    results.AoA_Dev = zeros(0);
    results.AORC_Dev = zeros(0);
    results.SA_Dev = zeros(0);
end