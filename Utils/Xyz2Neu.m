function [NEU,CNEU,E] = Xyz2Neu(O,V,SV,COR)

% XYZ2NEU	Convert ECEF into local topocentric
%
%		Input:
%		  O = origin vector in ECEF frame (m)
%		  V = relative position or velocity vector in ECEF frame w.r.t. origin vector 0 (m or m/yr)
%                 SV = stdev in ECEF frame (m or m/yr)
%                 COR = correlations, XY XZ YZ
%                 (NOTE: O, V, SV, COR can be n x 3 matrices, n = # of sites)
%
%		Output:
%		  NEU = output on NEU frame (m)
%		  CNEU = associated covariance (m), format is:
%                        Cnn Cne Cnu Cee Ceu Cuu
%                 (NOTE: NEU and CNEU will be matrices with n rows)
%
%		Call: [NEU,CNEU] = xyz2neu(O,V,SV,COR);

% if O is a single point, make it the same size as V
if (size(O,1) == 1)
  XR = ones(size(V,1),1) .* O(1);  
  YR = ones(size(V,1),1) .* O(2);  
  ZR = ones(size(V,1),1) .* O(3);  
else
  XR = O(:,1); YR = O(:,2); ZR = O(:,3);
end

% read rest of input
vx = V(:,1); vy = V(:,2); vz = V(:,3);
svx = SV(:,1); svy = SV(:,2); svz = SV(:,3);
cxy = COR(:,1); cxz = COR(:,2); cyz = COR(:,3);

% convert origin vector to ellipsoidal coordinates
T = zeros(size(XR,1),1);
E = Xyz2Wgs([T XR YR ZR]);

% compute sines and cosines
cp = cos(E(:,2).*pi/180); sp = sin(E(:,2).*pi/180); % longitude
cl = cos(E(:,3).*pi/180); sl = sin(E(:,3).*pi/180); % latitude

% for each site
NEU = [];
CNEU = [];
for i=1:size(V,1)
  % build the rotation matrix
  R = [ -sl(i)*cp(i)   -sl(i)*sp(i)    cl(i);
         -sp(i)            cp(i)           0;
         cl(i)*cp(i)    cl(i)*sp(i)    sl(i)];

  % apply the rotation
  NEUi = R * [vx(i);vy(i);vz(i)];

  % build covariance for that site
  CVi = [svx(i)^2 cxy(i)   cxz(i);
         cxy(i)   svy(i)^2 cyz(i);
         cxz(i)   cyz(i)   svz(i)^2];

  % propagate covariance
  CNEUi = R * CVi * R';

  % increment result matrices
  NEU = [NEU;
         NEUi(1) NEUi(2) NEUi(3)];
  CNEU = [CNEU;
          CNEUi(1,1) CNEUi(1,2) CNEUi(1,3) CNEUi(2,2) CNEUi(2,3) CNEUi(3,3)];
end
