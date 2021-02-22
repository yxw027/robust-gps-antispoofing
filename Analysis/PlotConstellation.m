function PlotConstellation(aer)
% Input:
%         aer: information that contains the angle of the satellite
%
M = length(aer.Svid);

figure('Name', 'Consetllation');
colors = SetColors;
for i = 1:M
    azDeg = aer.AzDeg(:,i);
    elDeg = aer.ElDeg(:,i);

    azMean = mean(azDeg, 'omitnan');
    elMean = mean(elDeg, 'omitnan');
    
    azMean = deg2rad(azMean);
    elMean = deg2rad(elMean);

    polarplot(azMean, cos(elMean),...
        'o',...
        'MarkerEdgeColor',colors(i,:),...
        'MarkerFaceColor',colors(i,:),...
        'MarkerSize',6);
    

%     
%     polarplot([0,azMean], [0,cos(elMean)],...
%     '--',...
%     'Color',colors(i,:),...
%     'LineWidth',1.6);
% 
%     hold on;
%     
%     text(azMean,cos(elMean),...
%         num2str(aer.Svid(i)),...
%         'Color',colors(i,:));

end

% title('Constellation');
end

