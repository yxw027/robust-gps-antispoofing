function [angArrEph] = AnalyzeSpectrumAz(timeCn0,modFreq,bPlot)
% Description: conduct spectrum analyze on Time-Cn0 sequence
%
% Input:
%       timeCn0: Time-CN0 sequence
%       modFreq: spoofer's modulation frequency 
%       bPlot: whether plot fitting result
% Output:
%       angArrEph.AoA : estimated AoAs 
%

%% Prepare Data
fs = 1; %Sampling frequency (Hz)
fhp = 0.008; %Compress DC 
N = 1024; %X[k] length 

rotFreq = timeCn0.rotFre;
bHasMod = ~isnan(modFreq);% see if has modulation


M = length(timeCn0.Svid); % number of sv
L = length(timeCn0.Cn0DbHz(:,1)); % number of sample
% processing sequence
x = zeros(N,1);

% window function
w = hamming(L); 

% spectrum data
mag = zeros(N/2,M);
phase = zeros(N/2,M);

% base freq peak search range
iRotPeak = round(rotFreq / fs * N);% index of rotation frequency 
iModPeak = round(modFreq / fs * N);% index of modulation frequency 
iHP = round(2*fhp / fs * N);

%% Init angArrEph struct
angArrEph.Svid = timeCn0.Svid;
angArrEph.AoE = timeCn0.AoE;
angArrEph.AoA = zeros(1,M) + NaN;
angArrEph.absDiffRaw = zeros(1,M) + NaN;
angArrEph.refId = [];
angArrEph.absDiff = zeros(1,M);
angArrEph.relDiff = zeros(1,M);
angArrEph.Amp = zeros(1,M);

%% Calculate magnitude & phase spectrum
for i=1:M
    % prepare data for FFT
    x(1:L) = timeCn0.Cn0DbHz(:,i) .* w;
    x = x - mean(x);
    
    % FFT
    X = fft(x);
    
    % magnitude from FFT result 
    mag(:,i) = abs(X(1:N/2));
    mag(1:iHP,i) = 0;
    
    % phase angles from FFT result 
    phase(:,i) = rad2deg(angle(X(1:N/2)));
    
    % magnitude at rotation frequency 
    angArrEph.Amp(i) = mag(iRotPeak);
    
    % phase angle from at rotation frequency
    rotPhase = phase(iRotPeak,i);
    % AoA = receiver's initial facing angle - phase angle
    angArrEph.AoA(i) = mod(timeCn0.AzDeg(1) - rotPhase, 360);
end

if bPlot
    figure('name','Spectrum Analysis Az');
    % frequency span
    f = linspace(0,fs*0.5,N/2);

    %% Find rotation and modulation frequency peak
    maxRotPeakVal = max(mag(iRotPeak,:));

    if bHasMod
        maxModPeakVal = max(mag(iModPeak,:));
    else
        maxModPeakVal = 0;
    end
    
    maxMag = max(maxRotPeakVal, maxModPeakVal);

    %% Plot Result
    colors = SetColors;
    ax1 = subplot(3,1,1);
    ax2 = subplot(3,1,2);
    ax3 = subplot(3,1,3);

    for i = 1:M
        ts = int2str(timeCn0.Svid(i));

        subplot(3,1,1);
        plot(1:1:L, timeCn0.Cn0DbHz(:,i),...
        'LineWidth',1.5,...
        'Color',colors(i,:));

        text(N,timeCn0.Cn0DbHz(end,i),ts,'Color',colors(i,:));

        hold on;

        subplot(3,1,2);
        plot(f,mag(:,i),...
        'LineWidth',1.5,...
        'Color',colors(i,:));
        hold on;

        plot(f(iRotPeak),mag(iRotPeak,i),'o',...
        'LineWidth',1.5,...
        'Color',colors(i,:));
        hold on;

        if bHasMod
            plot(f(iModPeak),mag(iModPeak,i),'o',...
            'LineWidth',1.5,...
            'Color',colors(i,:));
            hold on;
        end

        text(f(end),mag(end),ts,'Color',colors(i,:));

        subplot(3,1,3);
        plot(f,phase(:,i),...
        'LineWidth',1.5,...
        'Color',colors(i,:));
        hold on;

        plot(f(iRotPeak),phase(iRotPeak,i),'o',...
        'LineWidth',1.5,...
        'Color',colors(i,:));
        hold on;

        if bHasMod
            plot(f(iModPeak),phase(iModPeak,i),'o',...
            'LineWidth',1.5,...
            'Color',colors(i,:));
            hold on;
        end

        text(f(end),phase(end),ts,'Color',colors(i,:));
    end

    % time-cn0
    subplot(3,1,1);
    title('Time-Cn0');
    xlabel('Time/s');
    ylabel('Cn0/dBHz');
    axis(ax1, [1,L,15,60]);

    % draw magnitude
    subplot(3,1,2);

    plot([f(iRotPeak), f(iRotPeak)], [0, maxRotPeakVal], ...
    '--', 'Color', 'black', 'LineWidth',2.0);
    text(f(iRotPeak), maxMag * 1.1, '$$f_{r}$$',...
        'FontSize',14,'Interpreter','latex');

    if bHasMod
        plot([f(iModPeak), f(iModPeak)], [0, maxModPeakVal], ...
        '--', 'Color', 'black', 'LineWidth',2.0);
        text(f(iModPeak), maxMag * 1.1, '$$f_{m}$$',...
            'FontSize',14,'Interpreter','latex');
    end

    title('Spectrum-Magnitude');
    xlabel('Frequency/Hz');
    ylabel('Magnitude');
%     axis(ax2, [0,fs*0.5,0,maxMag]);
    axis(ax2, [0,fs*0.5,0,120]);
    % draw phase
    subplot(3,1,3);
    
    plot([f(iRotPeak), f(iRotPeak)], [-180, 180], ...
    '--', 'Color', 'black', 'LineWidth',2.4);
    text(f(iRotPeak), 200, '$$f_{r}$$',...
        'FontSize',14,'Interpreter','latex');

    if bHasMod
        plot([f(iModPeak), f(iModPeak)], [-180, 180], ...
        '--', 'Color', 'black', 'LineWidth',2.4);
        text(f(iModPeak), 200, '$$f_{m}$$',...
        'FontSize',14,'Interpreter','latex');
    end

    title('Spectrum-Phase');
    xlabel('Frequency/Hz');
    ylabel('Phase/Degree');
    axis(ax3, [0,fs*0.5,-180, 180]);

end
% fprintf('rotPeriod:%.2f\n',1/rotFreq);
if bHasMod
    fprintf('modPeriod:%.2f\n',1/modFreq);
end
% fprintf('beginAzimuth:%.2f\n',timeCn0.AzDeg(1));
% fprintf('rotPhase:%.2f\n',rotPhase);
% fprintf('spooferAoA:%.2f\n\n',spooferAoA);

end