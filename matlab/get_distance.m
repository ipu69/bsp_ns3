function d = get_distance(Ptr, Ltr, Gtr, Grecv, Lrecv, SOM, Precv, ...
    F, K)
% Расчет дальности связи между приемником и передатчиком
% 
% Ptr - мощность передатчика,  [dBm]
% Ltr - потери сигнала в антенном кабеле, [dB]
% Gtr - коэффициент усиления передающей антенны, [dBi]
% Lfs - потери передачи в свободном пространстве, [dB]
% Grecv - коэффициент усиления приемной антенны,  [dBi]
% Lrecv - потери сигнала в антенном кабеле и разъемах приемного трактфа, [dB]
% SOM - запас на замирание сигнала (System Operating Margin) [dB]
% Precv - чувствительность приемника

%% DEFAULT VALUE
% SOM = 10;
% Ltr = 0;
% Lrecv = 0;

%% LINK BUDGET
% Ptr - Ltr + Gtr - Lbf + Grecv - Lrecv = SOM + Precv

% free space path loss
Lfs = Ptr - Ltr + Gtr + Grecv - Lrecv - Precv - SOM;

%% PATH LOSS
% Lbf = 20lgF + 20lgD + K

% для частоты, выраженной в ГГц, и расстояния в киломметрах, K = 92,45
% для частоты, выраженной в МГц, и расстояния в киломметрах, K = 32,4
% для частоты, выраженной в МГц, и расстояния в метрах, K =  -27,55

% DISTANCE

d = floor(10^((Lfs - 20*log10(F) - K)/20));
end