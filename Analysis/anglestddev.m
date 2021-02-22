function s = anglestddev(aoa)
%  Discription: calculated the standard devation of AoAs
%  Input: 
%	aoa : 1 * n Angle vector
%  Output:
% 	s: Stander deviation

 % Remove NaN
 aoa(isnan(aoa)) = [];
 if length(aoa) <= 1
    s = nan;
    return
 end
 
 %  Compute the AoA range and calculated mean value on the range
 aoa = sort(aoa);
 aoadiff = [aoa(1) + 360 - aoa(end), diff(aoa)];
 % Find the maximal gap in AoA, break here, get AoA range
 [~, index] = max(aoadiff); 
 if index == 1
  aoabar = mean(aoa);
 else
  % Remap AoA value
  aoarerange = [aoa(index: end), aoa(1: index -1) + 360]; 
  aoabar = mean(aoarerange); 
 end
 if aoabar > 360
  aoabar = aoabar - 360;
 end
 
 %  Coumpute the Stander Deviation with AoA and AoA.avg
 aoanum = length(aoa);
 % compuate residuals to mean
 aoadis = aoaminus(aoa, aoabar); 
 s = sqrt( sum(aoadis.^2) ./ (aoanum - 1) ); 

end

function aoadis = aoaminus(A, a)
% Description: return the substraction result of angles
% Input: 
%	A: 1 * n angle value vector
% 	a: scalar, angle value
% Output:
% 	aoadis: 1 * n angle value vector 
	aoadis = abs(A - a);
	aoadis(aoadis > 180) = 360 - aoadis(aoadis > 180);
end
