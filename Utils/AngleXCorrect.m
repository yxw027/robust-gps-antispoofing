function [outVec] = AngleXCorrect(inVec)
% change degree vector from [-180,180] to [0,360]
outVec = inVec;
for i=1:length(inVec)
    if inVec(i) < 0
        outVec(i) = inVec(i) + 360;
    end
end

