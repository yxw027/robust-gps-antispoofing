function [outData] = KalmanFilter(inData,Q,R)
% Description: 1-D KalmanFilter
%
% Input:
%       inData: input data sequence;
%       Q: the covariance of the process noise;
%       R: the covariance of the observation noise;
% Output:
%       outData: output filtered data sequence;
%
N = length(inData);
K = zeros(N,1);
P = zeros(N,1);
outData = zeros(N,1);

outData(1) = inData(1); 
P(1) = 1;

for i = 2:N 
    K(i) = P(i-1) / (P(i-1) + R);
    outData(i) = outData(i-1) + K(i) * (inData(i) - outData(i-1));
    P(i) = P(i-1) - K(i) * P(i-1) + Q;
end

end

