function groundTurth = getLocation(gnssMeas, allGpsEph)
    count = length(gnssMeas.ClkDCount);
    for i = 1: count
        gpsPvt = GpsWlsPvt(gnsspick(gnssMeas, i),allGpsEph);
        groundTurth = gpsPvt.allLlaDegDegM(1, :);
        if ~isnan(groundTurth)
            break
        end
    end
end

function gnssMeas = gnsspick(gnssMeas, span)
    gnssMeas.FctSeconds([1: span - 1, span + 1:end], :) = [];
    gnssMeas.ClkDCount([1: span - 1, span + 1:end], :) = [];
    gnssMeas.HwDscDelS([1: span - 1, span + 1:end], :) = [];
    gnssMeas.AzDeg([1: span - 1, span + 1:end], :) = [];
    gnssMeas.ElDeg([1: span - 1, span + 1:end], :) = [];
    gnssMeas.tRxSeconds([1: span - 1, span + 1:end], :) = [];
    gnssMeas.tTxSeconds([1: span - 1, span + 1:end], :) = [];
    gnssMeas.PrM([1: span - 1, span + 1:end], :) = [];
    gnssMeas.PrSigmaM([1: span - 1, span + 1:end], :) = [];
    gnssMeas.DelPrM([1: span - 1, span + 1:end], :) = [];
    gnssMeas.PrrMps([1: span - 1, span + 1:end], :) = [];
    gnssMeas.PrrSigmaMps([1: span - 1, span + 1:end], :) = [];
    gnssMeas.AdrM([1: span - 1, span + 1:end], :) = [];
    gnssMeas.AdrSigmaM([1: span - 1, span + 1:end], :) = [];
    gnssMeas.AdrState([1: span - 1, span + 1:end], :) = [];
    gnssMeas.Cn0DbHz([1: span - 1, span + 1:end], :) = [];
    gnssMeas.AngleZ([1: span - 1, span + 1:end], :) = [];
    gnssMeas.AngleX([1: span - 1, span + 1:end], :) = [];
    gnssMeas.AngleY([1: span - 1, span + 1:end], :) = [];
end