function R = Xyz2Wgs(S)

% XYZ2WGS      	converts cartesian coordinates (x,y,z) into
%		ellipsoidal coordinates (lat,lon,alt) on WGS-84
%		according to a non iterative method (Bowring 76,
%		see also GPS Theory and Practice, p. 258).
%               Call: R = xyz2wgs(S)
%               S is a nx4 matrix with time, X, Y, Z
%		A! first column of S is time but can be dummy.
%               R is a nx4 matrix with time, lon (lam), lat (phi), alt
%		                             (lon,lat in degrees!)

% WGS-84 PARAMETERS
% semimajor and semiminor axis
a = 6378137.0;
b = 6356752.314;
% flattening
f = 1.0/298.257222101;
% eccentricity
eo = 2*f - f^2;

% second numerical eccentricity
e1 = (a^2-b^2)/b^2;

% read data
t = S(:,1);
x = S(:,2);
y = S(:,3);
z = S(:,4);

% auxiliary quantities
p = sqrt(x.^2+y.^2);
theta = atan2(z.*a,p*b);

% longitude
lam = atan2(y,x);

% latitude
phi = atan2(z + (sin(theta)).^3*e1*b , p - (cos(theta)).^3*eo^2*a);

% radius of curvature in prime vertical
N = a / sqrt((cos(phi)).^2*a^2 + (sin(phi)).^2*b^2);

% geocentric (?) altitude
alt_g = (p ./ cos(phi)) - N';

% ellipsoidal altitude
alt = p.*cos(phi) + z.*sin(phi) - a.*sqrt(1.0 - eo.*sin(phi).^2);

% fill out result matrix
R = [t lam*180.0/pi phi*180.0/pi alt];