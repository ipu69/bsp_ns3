
clear;

fname = 'input.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
json_data = jsondecode(str);

l = json_data.placement';
l_end = json_data.gateway_placement(2);
cost_limit = json_data.cost_limit;

Precv_gateway = json_data.gateway.Precv;
Lrecv_gateway = json_data.gateway.Lrecv;
Grecv_gateway = json_data.gateway.Grecv;

Ptr_ud = json_data.user_device.Ptr;
Gtr_ud = json_data.user_device.Gtr;

frequency = json_data.frequency;

Ptr_link = [];
Gtr_link = [];
Precv_link = [];
Precv_coverage = [];
Grecv_coverage = [];
c = [];
fn = fieldnames(json_data.sta);
for k = 1:numel(fn)
    Ptr_link = [Ptr_link; json_data.sta.(fn{k}).Ptr_link];
    Gtr_link = [Gtr_link; json_data.sta.(fn{k}).Gtr_link];
    Precv_link = [Precv_link; json_data.sta.(fn{k}).Precv_link];
    % coverage
    Precv_coverage = [Precv_coverage; json_data.sta.(fn{k}).Precv_coverage];

    Grecv_coverage = [Grecv_coverage; json_data.sta.(fn{k}).Grecv_coverage];
    c = [c; json_data.sta.(fn{k}).c];
end

[R, r] = get_sta_value(Ptr_link, Gtr_link, Precv_link, ...
    Precv_coverage, Grecv_coverage, ...
    Precv_gateway, Grecv_gateway, frequency, ...
    Ptr_ud, Gtr_ud);


%% SOLUTION

output_MILP = {};

[print_solution, solution, Xname] = ILP_problem_coverage_link_cost(cost_limit, ...
    l, l_end, r, R, c);
%     xIntSol = table2array(solution);
VarName = solution.Properties.VariableNames;
if ~isempty(xIntSol)
    solution = array2table(xIntSol');
    solution.Properties.VariableNames = VarName;
end

output_data = struct;

for k = 1 : height(solution)
    n = length(l);
    m = length(Ptr_link);
    Placed = ones(1, n)*inf;

    solution_name = solution.Properties.VariableNames;
    [~, row_x, ~] = intersect(solution_name, Xname);
    p = zeros(1, n*m);
    s = zeros(1, n*m);
    solution_x = table2array(solution(k, row_x));
    index = 1;

    sta_num = 0;
    for i = 1 : n
        for j = 1 : m
            p(index) = i;
            s(index) = j;

            if int8(solution_x(index)) == 1
                Placed(i) = j;
                sta_num = sta_num + 1;
                sta.coordinate = l(p(index)); 
                sta.P_tr = Ptr_link(s(index));
                sta.G_tr = Gtr_link(s(index));
                sta.P_recv = Precv_link(s(index));
                sta.Precv_coverage = Precv_coverage(s(index));
                sta.Grecv_coverage = Grecv_coverage(s(index));
                output_data(k).sta(sta_num) =  sta;
            end
            index = index + 1;
        end
    end
    output_data(k).frequency = frequency'
    output_data(k).Grecv_gateway = Grecv_gateway;
    output_data(k).Precv_gateway = Precv_gateway
    output_data(k).gateway_coordinate = l_end;
end
print_solution    

fname = 'output_data.txt'; 
fid = fopen(fname, 'w'); 
raw = fwrite(fid, jsonencode(output_data));
fclose(fid)
