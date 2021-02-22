function output = aoarange(aoa)
    % Returns the minimal length that covers all AoAs
    aoamat = aoa - aoa';
    aoamat(aoamat > 180) = 360 - aoamat(aoamat > 180);
    output = max(max(aoamat));
end
