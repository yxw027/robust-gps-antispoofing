function [AZ,EL,LE] = Neu2Aer(S,P)

% AZELLE	Computes elevation angle, range, and azimuth
%		of satellites from a ground station
%		S = ECEF satellite coordinates (m), n x 3 matrix
%		P = ground station coordinates, ECEF (m) (vector)
%		AZ = azimuth (radians CW from north)
%		EL = elevation angle (radians)
%		LE = range (meters)
%
%		[AZ,EL,LE] = Neu2Aer(S,P)
%

% satellite ECEF coordinates (must be in meters)
Xs = S(:,1); Ys = S(:,2); Zs = S(:,3);

% ground station ECEF coordinates (must be in meters)
XR = P(1); YR = P(2); ZR = P(3);

% compute ground-sat vector in ECEF coordinates
Rgs = [Xs-XR Ys-YR Zs-ZR];

% convert to unit vector
rang = sqrt(Rgs(:,1).^2+Rgs(:,2).^2+Rgs(:,3).^2);
Ru = [Rgs(:,1)./rang Rgs(:,2)./rang Rgs(:,3)./rang];

% dummy stdev and correlation for xyz2neu
SV = zeros(length(Ru));
COR = zeros(length(Ru),3);

% rotate from XYZ to NEU
[neu,Cneu] = Xyz2Neu([XR YR ZR],Ru,SV,COR);

% convert neu to azimuth and elevation angle
LE = sqrt(neu(:,1).^2+neu(:,2).^2);
EL = ((pi/2) - atan2(LE,neu(:,3)))/pi * 180;
Az0 = (atan2(neu(:,2),neu(:,1)))/pi * 180;
if Az0 >=0
    AZ = Az0;
else
    AZ = Az0 + 360;
end 