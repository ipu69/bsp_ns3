function [R, r] = get_sta_value(Ptr_link, Gtr_link, Precv_link, ...
    Precv_coverage, Grecv_coverage, ...
    Precv_gateway, Grecv_gateway, frequency, ...
    Ptr_ud, Gtr_ud)
% Get link distance station R(i,j)
% and
% Get coverage radius r(i)

%% CONST
SOM = 10; %System Operating Margins
F = frequency; % frequency
K = - 27.55;
% для частоты, выраженной в ГГц, и расстояния в киломметрах, K = 92,45
% для частоты, выраженной в МГц, и расстояния в киломметрах, K = 32,4
% для частоты, выраженной в МГц, и расстояния в метрах, K =  -27,55
Ltr = 1; % TX cable loss
Lrecv = 1;% RX cable loss
Lrecv_coverage = 0;
% Gtr_coverage = 0;
% Grecv_coverage = 0;
% Precv_coverage = -67;
%% GATEWAY
% Gtr_gateway = 3;
% Precv_gateway = -67;

%% STA
% The last element is the gateway parameter (Ptr_link(1), Gtr_link(1), etc.)
% % link
% Ptr_link = [20; 19; 18; 19; 20; 22; 19;];
% Gtr_link = [5; 4; 6; 5; 5; 5; 5];
% Precv_link = [-69; -80; -69; -83; -85; -69; -69];
% % coverage
% Ptr_coverage = [20; 19; 20; 19; 20; 20; 20];

BS = table(Ptr_link, Gtr_link, Precv_link, Precv_coverage, Grecv_coverage);
% 
r = zeros(1, height(BS));
R_sta = zeros(height(BS), height(BS));
for i = 1 : height(BS)
    for j = 1 : height(BS)
        if i == j
            R_sta(i,j) = inf;
        else
            R_sta(i,j) = get_distance(BS.Ptr_link(i), Ltr, ...
                BS.Gtr_link(i), BS.Gtr_link(j), Lrecv, SOM, ...
                BS.Precv_link(j), F, K);
        end          
    end
%     r(i) = get_distance(BS.Ptr_coverage(i), Ltr, BS.Gtr_coverage(i), ...
%         Grecv_coverage, Lrecv_coverage, SOM, ...
%         Precv_coverage, F, K);
    r(i) = get_distance(Ptr_ud, 0, Gtr_ud, ... 
        BS.Grecv_coverage(i), Lrecv, SOM, ...
        BS.Precv_coverage(i), F, K);
end
R_sta2gateway = zeros(height(BS), 1);

for k = 1 : height(BS)
    R_sta2gateway(k, 1) = get_distance(BS.Ptr_link(k), Ltr, ...
        BS.Gtr_link(k, 1), Grecv_gateway, Lrecv, SOM, ...
        Precv_gateway, F, K);
end
R = [R_sta, R_sta2gateway];

end