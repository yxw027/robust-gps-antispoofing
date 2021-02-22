function [normAz, normRelAz] =  PrintAngArrEph(angArrEph)

for i = 1:length(angArrEph.Svid)
    fprintf('[%02d] AoA: %5.1f, AoE: %5.1f, Diff: %5.1f\n',...
        angArrEph.Svid(i),...
        angArrEph.AoA(i), angArrEph.AoE(i), angArrEph.absDiffRaw(i));
end
    
    normAz = mean(abs(angArrEph.absDiff),'omitnan');
    normRelAz = mean(abs(angArrEph.relDiff),'omitnan');
    fprintf('\nabsNorm: %5.1f, relNorm: %5.1f\n',normAz, normRelAz);
end %End of Function

