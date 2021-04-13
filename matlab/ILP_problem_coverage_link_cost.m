 function [print_solution, solution, Xname] = ILP_problem_coverage_link_cost(cost_limit, ... 
    l, l_end, r, R, c)

tic

n = length(l);
m = length(r);

%% objective_function
[T, Yname, Xname] = objective_funcion(l, n, m);

%% ADD Inequality conditions

%% condition 7Ю,А
[A_7a, b_7a] = add_condition_7ab(T, r, 'plus', n, m);
[A_7b, b_7b] = add_condition_7ab(T, r, 'minus', n, m);

%% Condition 8Ю,А
[A_8a, b_8a] = add_condition_8ab(T, l, l_end, n, 'a');
[A_8b, b_8b] = add_condition_8ab(T, l, l_end, n, 'b');

%% Condition (9Ю, 9А)
[A_9a, b_9a] = add_condition_9ab(T, n, m, 'a'); % N 18
[A_9b, b_9b] = add_condition_9ab(T, n, m, 'b'); % N 19

%% 20 НОВЫЙ 
[A_20, b_20] = add_condition_20(T, n, m); % N10a

%% 20 Линк только с одной станцией на к-ой точки справа (неравентство)
[A_26, b_26] = add_condition_26(T, n, m);

%% 25 НОВЫЙ  
[A_25, b_25] = add_condition_25(T, n, m); % N10a для станции k

%% Тот же 25 толко для станций справа от k 
[A_28, b_28] = add_condition_28(T, n, m); % N10a для станции k

%% Тот же 25 толко для станций слева от k
[A_29, b_29] = add_condition_29(T, n, m); % N10a для станции k

%% 21 НОВЫЙ 
[A_21, b_21] = add_condition_21(T, n, m); % N10b

%% 21 Линк только с одной станцией на к-ой точки слева (неравентство)
[A_27, b_27] = add_condition_27(T, n, m);

%% 22 НОВЫЙ (10Б)SUMZij1 >= e1
[A_22, b_22] = add_condition_22(T, n, m);


%% 23 НОВЫЙ
% ДОДЕЛАТЬ
[A_23, b_23] = add_condition_23(T, l, l_end, r, R, n, m);

%% 24 НОВЫЙ
% ДОДЕЛАТЬ
[A_24, b_24] = add_condition_24(T, l, l_end, r, R, n, m);


%% Condition 13 Cost limit
[A_13, b_13] = add_condition_13(T, n, m, c, cost_limit);

%% ADD Equality conditions
%% Condition 7
[A_7, b_7] = add_condition_7(T, n, m);

%% Equality Condition 7 hatch SUM(xi1) = 1
[A_7h, b_7h] = add_condition_7hatch(T, n, m);

%% Equality Condition 12 Y0,n+1 = 0; E0,n+1 = 1.
[A_12, b_12] = add_condition_12(T, n);

%% Matrix preparation
f = table2array(T);
% coverage is not integer
% gateway_coverage + placed_sta_coverage + gateway_coverage) * 2
% and next values is integer
intcon = (1 + n + 1) * 2 + 1 : length(f);



%% CONSTRINTS
% linear inequality constraints.
total_A = [A_7h; A_7a; A_7b; A_8a; A_8b; A_9a; A_9b; ...
     A_23; A_24; A_13; ];
A = table2array(total_A);

b = [b_7h; b_7a; b_7b; b_8a; b_8b; b_9a; b_9b; ...
     b_23; b_24; b_13;]; 

% linear equality constraints.
total_Aeq = [A_7; A_12; A_20; A_21; A_28; A_29];
Aeq = table2array(total_Aeq);
beq = [b_7; b_12;  b_20; b_21; b_28; b_29];

%%

% bound constraints.
total_AVarName = total_A.Properties.VariableNames;
[~, row_Yname, ~] = intersect(total_AVarName,Yname,'stable');
% bound constraints.
% low bound 
lb = zeros(1, width(total_A));

% upper bound 
ub = ones(1, width(total_A));
ub(row_Yname([1, 2])) = inf;
ub(row_Yname([end-1, end])) = inf;
ub(row_Yname(3 : end-2)) = inf;
%% Solution
options = optimoptions(@intlinprog,'OutputFcn',@savemilpsolutions)
[x,fval] = intlinprog(f,intcon,A,b,Aeq,beq,lb,ub, options);
solution = array2table(x');
solution.Properties.VariableNames = total_AVarName;

% fval
% exitflag
% output
t = toc

Cost_estimate = calculate_constraints(solution, Xname, ...
    A_13);
Placed_stations = get_placed_sta(solution, Xname, n, m);
% Placed_stations
print_solution = ['Placed stations = [', num2str(Placed_stations),']', ...
    ' ; Total coverage = ', num2str(-fval), ' ; Cost = ', ...
    num2str(Cost_estimate)];
end

function [table, Yname, Xname] = objective_funcion(place, n, m)
%% yi
index = sort([0 : n + 1, 0 : n + 1]);
Yname = strings(1, length(index));

for i = 1:2:length(index)
    Yname(i) = ['y', num2str(index(i)), 'plus'];
    Yname(i+1) = ['y', num2str(index(i+1)), 'minus'];
end

f =[zeros(1,2), -1*ones(1,length(place)*2), zeros(1,2)];

%% xij
i = 1 : n;
j = 1 : m;
Xname = strings(1, length(i)*length(j));
index = 1;
for i = 1 : n 
    for j = 1 : m
        Xname(index) = ['x', num2str(i), num2str(j)];
        index = index + 1;
    end
end
f = [f, 0*ones(1, n * m)]; 

%% ei
Ename = strings(1, length(0 : n + 1));
index = 1;
for i = 0 : n + 1
    Ename(index) = ['e', num2str(i)];
    index = index +  1;
end
f = [f, 0 * ones(1,n + 2)];

%% zijk
Zname = {};


for i = 1 : n
    for j = 1 : m
        for k = 0 : n + 1
            if i ~= k
                if k == 0 || k == n + 1 ... gateway S_0 and S_{n+1}
                    Z = ['z', num2str(i), '_', ... 
                        num2str(j), '_', num2str(k), ...
                        '_', num2str(m+1)];
                    Zname = [Zname, Z];
                
                else                
                    for q = 1 : m ... Stations
                        if j~= q
                            Z = ['z', num2str(i), '_', ... 
                                num2str(j), '_', num2str(k), ...
                                '_', num2str(q)];
                            Zname = [Zname, Z];
                        end
                    end
                end
              
            end
        end
    end
end

f = [f, 0*ones(1,length(Zname))];

%% Total objective function
VarName = [Yname, Xname, Ename, Zname];

table = array2table(f);

table.Properties.VariableNames = VarName;
table.Properties.RowNames = {'f'};
end

function [A_7, b_7] = add_condition_7(table, n, m)
tableVarName = table.Properties.VariableNames;
A = zeros(n, width(table));
RowNames = {};

for i = 1 : n
    var_e = ['e', num2str(i)];
    [~, row_e, ~] = intersect(tableVarName, var_e);
    A(i, row_e) = 1;
    for j = 1 : m
        var_x = ['x', num2str(i), num2str(j)];
        [~, row_x, ~] = intersect(tableVarName, var_x);
        A(i, row_x) = -1;
    end
    RowNames = [RowNames, ['e', num2str(i)]];
end

A_7 = array2table(A,'VariableNames', tableVarName);
A_7.Properties.RowNames = RowNames;
b_7 = zeros(height(A_7),1);
end

function [A_7ab, b_7ab] = add_condition_7ab(table, r, symbol, n, m)
tableVarName = table.Properties.VariableNames;
A = zeros(n, width(table));
RowNames = {};
for i = 1 : n
    var_y = ['y', num2str(i), symbol];
    [~, row_y, ~] = intersect(tableVarName, var_y);
    A(i, row_y) = 1;
    for j = 1 : m
        var_x = ['x', num2str(i), num2str(j)];
        [~, row_x, ~] = intersect(tableVarName,var_x);
    A(i, row_x) = -1 * r(j);
    end
    RowNames = [RowNames, ['y', num2str(i), symbol]];
end
A_7ab = array2table(A,'VariableNames', tableVarName);
A_7ab.Properties.RowNames = RowNames;
b_7ab = zeros(height(A_7ab),1);
end

function [A_8, b_8] = add_condition_8ab(table, place, place_end, n, key)
tableVarName = table.Properties.VariableNames;
A = [];
% b_2 = [];
RowNames = {};
if key == 'a'
    symbol1 = 'plus';
    symbol2 = 'minus';
elseif key == 'b'
    symbol1 = 'minus';
    symbol2 = 'plus';
end
place = [0, place, place_end];
for i = 1 : n
    yi = ['y', num2str(i), symbol1];
    [~, row_yi, ~] = intersect(tableVarName, yi);
    
    ei = ['e', num2str(i)];
    [~, row_ei, ~] = intersect(tableVarName, ei);
    
    switch key
        case 'a'        
            for k = i + 1 : n + 1
                yk = ['y', num2str(k), symbol2];
                [~, row_yk, ~] = intersect(tableVarName, yk);
                ek = ['e', num2str(k)];
                [~, row_ek, ~] = intersect(tableVarName, ek);
                
                mas = zeros(1, width(table));
                mas(1, row_yi) = 1;
                mas(1, row_ei) = -1*(0.5 * (place(k+1) - place(i+1)) ...
                    - place_end);
                
                mas(1, row_yk) = 1;
                mas(1, row_ek) = -1*(0.5 * (place(k+1) - place(i+1)) ...
                    - place_end);
                A = [A; mas];
                RowNames = [RowNames, ...
                    ['y', num2str(i), symbol1, '-y', num2str(k)]];
            end
        case 'b'
            for k = i - 1 : -1: 0
                yk = ['y', num2str(k), symbol2];
                [~, row_yk, ~] = intersect(tableVarName, yk);
                ek = ['e', num2str(k)];
                [~, row_ek, ~] = intersect(tableVarName, ek);
                
                mas = zeros(1, width(table));
                mas(1, row_yi) = 1;
                mas(1, row_ei) = -1*(0.5 * (place(i+1) - place(k+1)) ...
                    - place_end);
                
                mas(1, row_yk) = 1;
                mas(1, row_ek) = -1*(0.5 * (place(i+1) - place(k+1)) ...
                    - place_end);
                A = [A; mas];
                RowNames = [RowNames, ...
                    ['y', num2str(i), symbol1, '-y', num2str(k)]];
            end    
    end
end
A_8 = array2table(A,'VariableNames', tableVarName);
A_8.Properties.RowNames = RowNames;
b_8 = ones(height(A_8),1) * 2 * place_end;
end

function [A_9, b_9] = add_condition_9ab(table, n, m, key)
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

%%
for i = 1 : n
    for j = 1 : m
        for k = 0 : n + 1
            if i ~= k
                switch key
                    case 'a'
                        index_e = i;
                    case 'b'
                        index_e = k;
                end
                if k == 0 || k == n + 1 ... gateway S_0 and S_{n+1}
%                     Z = ['z', num2str(i), '_', ... 
%                         num2str(j), '_', num2str(k), ...
%                         '_', num2str(0)];
%                     Zname = [Zname, Z];
                    
                    var_e = ['e', num2str(index_e)];
                    var_z = ['z', num2str(i), '_', ... 
                            num2str(j), '_', num2str(k), ...
                            '_', num2str(m+1)];
                    RowNames = [RowNames, ...
                        ['z', num2str(i), '_', ... 
                        num2str(j), '_', num2str(k), ...
                        '_', num2str(m+1), '-e', num2str(index_e)];];
                    
                    [~, row_e, ~] = intersect(tableVarName, var_e);
                    [~, row_z, ~] = intersect(tableVarName, var_z);
                    mas = zeros(1, width(table));
                    mas(1, row_e) = -1;
                    mas(1, row_z) = 1;
                    A = [A; mas];
                
                else                
                    for q = 1 : m ... Stations
                        if j~= q
                            var_e = ['e', num2str(index_e)];
                            var_z = ['z', num2str(i), '_', ... 
                                    num2str(j), '_', num2str(k), ...
                                    '_', num2str(0)];
                            RowNames = [RowNames, ...
                                ['z', num2str(i), '_', ... 
                                num2str(j), '_', num2str(k), ...
                                '_', num2str(q), '-e', num2str(index_e)];];
                            [~, row_e, ~] = intersect(tableVarName, var_e);
                            [~, row_z, ~] = intersect(tableVarName, var_z);
                            mas = zeros(1, width(table));
                            mas(1, row_e) = -1;
                            mas(1, row_z) = 1;
                            A = [A; mas];                            
                        end
                    end
                end
              
            end
        end
    end
end
%5

A_9 = array2table(A,'VariableNames', tableVarName);
A_9.Properties.RowNames = RowNames;
b_9 = zeros(height(A_9),1);
end

function [A_20, b_20] = add_condition_20(table, n, m)
% Условие радиорелейной связи
% 
% Обеспечить связи со станцией k, k = i + 1 : n + 1
% 
% Sum{для k=i+1:n+1}Zijkq >= (или =) xij для всех i, j, q
% 
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

for i = 1 : n
    for j = 1 : m
        mas = zeros(1, width(table));
        var_z = {};
        var_x = ['x', num2str(i), num2str(j)];
        [~, row_x, ~] = intersect(tableVarName, var_x);
        mas(1, row_x) = 1;
        for k = i + 1 : n + 1
            if k == n + 1
                var_z = [var_z, ...
                    ['z', num2str(i), '_', ... 
                    num2str(j), '_', num2str(k), ...
                    '_', num2str(m+1)]];
            else
                for q = 1 : m
                    if j ~= q
                        var_z = [var_z, ...
                        ['z', num2str(i), '_', ... 
                        num2str(j), '_', num2str(k), ...
                        '_', num2str(q)]];
                    end

                end
            end
        end
        [~, row_z, ~] = intersect(tableVarName, var_z);
        mas(1, row_z) = -1;
        RowNames = [RowNames, ['x', num2str(i), num2str(j), ...
            '-SUMz', num2str(i), '_', ... 
            num2str(j), '_', num2str(k), ...
            '_', num2str(m+1)]];
        A = [A; mas];        
             
    end
end
A_20 = array2table(A,'VariableNames', tableVarName);
A_20.Properties.RowNames = RowNames;
b_20 = zeros(height(A_20),1);
end

function [A_26, b_26] = add_condition_26(table, n, m)
% Условие радиорелейной связи
% 
% Обеспечить связи со станцией k, k = i + 1 : n + 1
% 
% Линк только с одной станцией на к-ой точки справа (равентство)
% 
% Sum{для k=i+1:n+1}Zijkq >= (или =) xij для всех i, j, q
% 
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

for i = 1 : n
    for j = 1 : m
        mas = zeros(1, width(table));
        var_z = {};
        var_x = ['x', num2str(i), num2str(j)];
        [~, row_x, ~] = intersect(tableVarName, var_x);
        mas(1, row_x) = 1;
        for k = i + 1 : n + 1
            if k == n + 1
                var_z = [var_z, ...
                    ['z', num2str(i), '_', ... 
                    num2str(j), '_', num2str(k), ...
                    '_', num2str(m+1)]];
            else
                for q = 1 : m
                    if j ~= q
                        var_z = [var_z, ...
                        ['z', num2str(i), '_', ... 
                        num2str(j), '_', num2str(k), ...
                        '_', num2str(q)]];
                    end

                end
            end
        end
        [~, row_z, ~] = intersect(tableVarName, var_z);
        mas(1, row_z) = -1;
        RowNames = [RowNames, ['SUMz', num2str(i), '_', ... 
            num2str(j), '_', 'k_q = 1 (k is right from i)']];
        A = [A; mas];        
             
    end
end
A_26 = array2table(A,'VariableNames', tableVarName);
A_26.Properties.RowNames = RowNames;
b_26 = zeros(height(A_26),1);
end


function [A_25, b_25] = add_condition_25(table, n, m)
% Условие радиорелейной связи
% 
% Обеспечить связи со станцией k, k = 1 : n
% 
% Sum{для k=i+1:n+1}Zijkq >= (или =) xkq для всех i, j, q
% 
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

for k = 1 : n
    for q = 1 : m
        mas = zeros(1, width(table));
        var_z = {};
        if k == 0 || k == n + 1
            var_x = ['x', num2str(k), num2str(m+1)];
        else
            var_x = ['x', num2str(k), num2str(q)];
        end
        [~, row_x, ~] = intersect(tableVarName, var_x);
        mas(1, row_x) = 1;
        for i = 1 : n
            if i ~= k
                for j = 1 : m
                    if k == 0 || k == n + 1 
                        var_z = [var_z, ...
                            ['z', num2str(i), '_', ... 
                            num2str(j), '_', num2str(k), ...
                            '_', num2str(m+1)]];
                    else
                        if j ~= q
                            var_z = [var_z, ...
                            ['z', num2str(i), '_', ... 
                            num2str(j), '_', num2str(k), ...
                            '_', num2str(q)]];
                        end

                    end
                end
            end
            
        end
        [~, row_z, ~] = intersect(tableVarName, var_z);
        mas(1, row_z) = -1;
        if k == 0 || k == n + 1
            RowNames = [RowNames, ['x', num2str(k), num2str(m+1), ...
                '-SUMzijkq']];
        else
            RowNames = [RowNames, ['x', num2str(k), num2str(q), ...
                '-SUMzijkq']];
        end
        A = [A; mas];       
        
    end
        
end

A_25 = array2table(A,'VariableNames', tableVarName);
% A_25.Properties.RowNames = RowNames;
b_25 = zeros(height(A_25),1);
end

function [A_28, b_28] = add_condition_28(table, n, m)
% Условие радиорелейной связи
% 
% Обеспечить связи со станцией k, k = 1 : n - 1
% 
% Sum{для k=i+1:n+1}Zijkq >= (или =) xkq для всех i, j, q
% 
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

for k = 1 : n - 1
    for q = 1 : m
        mas = zeros(1, width(table));
        var_z = {};
        if k == 0 || k == n + 1
            var_x = ['x', num2str(k), num2str(m+1)];
        else
            var_x = ['x', num2str(k), num2str(q)];
        end
        [~, row_x, ~] = intersect(tableVarName, var_x);
        mas(1, row_x) = 1;
        for i = k + 1 : n + 1
            if i ~= k
                for j = 1 : m
                    if k == 0 || k == n + 1 
                        var_z = [var_z, ...
                            ['z', num2str(i), '_', ... 
                            num2str(j), '_', num2str(k), ...
                            '_', num2str(m+1)]];
                    else
                        if j ~= q
                            var_z = [var_z, ...
                            ['z', num2str(i), '_', ... 
                            num2str(j), '_', num2str(k), ...
                            '_', num2str(q)]];
                        end

                    end
                end
            end
            
        end
        [~, row_z, ~] = intersect(tableVarName, var_z);
        mas(1, row_z) = -1;
        if k == 0 || k == n + 1
            RowNames = [RowNames, ['x', num2str(k), num2str(m+1), ...
                '-SUMzijkq']];
        else
            RowNames = [RowNames, ['x', num2str(k), num2str(q), ...
                '-SUMzijkq']];
        end
        A = [A; mas];       
        
    end
        
end

A_28 = array2table(A,'VariableNames', tableVarName);
% A_28.Properties.RowNames = RowNames;
b_28 = zeros(height(A_28),1);
end

function [A_29, b_29] = add_condition_29(table, n, m)
% Условие радиорелейной связи
% 
% Обеспечить связи со станцией k, k = 1 : n - 1
% 
% Sum{для k=i+1:n+1}Zijkq >= (или =) xkq для всех i, j, q
% 
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

for k = 2 : n
    for q = 1 : m
        mas = zeros(1, width(table));
        var_z = {};
        if k == 0 || k == n + 1
            var_x = ['x', num2str(k), num2str(m+1)];
        else
            var_x = ['x', num2str(k), num2str(q)];
        end
        [~, row_x, ~] = intersect(tableVarName, var_x);
        mas(1, row_x) = 1;
        for i = 0 : k - 1
            if i ~= k
                for j = 1 : m
                    if k == 0 || k == n + 1 
                        var_z = [var_z, ...
                            ['z', num2str(i), '_', ... 
                            num2str(j), '_', num2str(k), ...
                            '_', num2str(m+1)]];
                    else
                        if j ~= q
                            var_z = [var_z, ...
                            ['z', num2str(i), '_', ... 
                            num2str(j), '_', num2str(k), ...
                            '_', num2str(q)]];
                        end

                    end
                end
            end
            
        end
        [~, row_z, ~] = intersect(tableVarName, var_z);
        mas(1, row_z) = -1;
        if k == 0 || k == n + 1
            RowNames = [RowNames, ['x', num2str(k), num2str(m+1), ...
                '-SUMzijkq']];
        else
            RowNames = [RowNames, ['x', num2str(k), num2str(q), ...
                '-SUMzijkq']];
        end
        A = [A; mas];       
        
    end
        
end

A_29 = array2table(A,'VariableNames', tableVarName);
% A_29.Properties.RowNames = RowNames;
b_29 = zeros(height(A_29),1);
end


function [A_21, b_21] = add_condition_21(table, n, m)
% Условие радиорелейной связи
% 
% Обеспечить связи со станцией k, k = 0 : i - 1
% 
% Sum{для k=0:i-1}Zijkq >= (или =) xij для всех i, j, q
% 
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

for i = 1 : n
    for j = 1 : m
        mas = zeros(1, width(table));
        var_z = {};
        var_x = ['x', num2str(i), num2str(j)];
        [~, row_x, ~] = intersect(tableVarName, var_x);
        mas(1, row_x) = 1;
        for k = 0 : i - 1
            if k == 0
                var_z = [var_z, ...
                    ['z', num2str(i), '_', ... 
                    num2str(j), '_', num2str(k), ...
                    '_', num2str(m+1)]];
            else
                for q = 1 : m
                    if j ~= q
                        var_z = [var_z, ...
                        ['z', num2str(i), '_', ... 
                        num2str(j), '_', num2str(k), ...
                        '_', num2str(q)]];
                    end

                end
            end
        end
        [~, row_z, ~] = intersect(tableVarName, var_z);
        mas(1, row_z) = -1;
        RowNames = [RowNames, ['x', num2str(i), num2str(j), ...
            '-SUMz', num2str(i), '_', ... 
            num2str(j), '_', num2str(k), ...
            '_', num2str(m+1)]];
        A = [A; mas];        
             
    end
end
A_21 = array2table(A,'VariableNames', tableVarName);
A_21.Properties.RowNames = RowNames;
b_21 = zeros(height(A_21),1);
end

function [A_27, b_27] = add_condition_27(table, n, m)
% Условие радиорелейной связи
% 
% Обеспечить связи со станцией k, k = 0 : i - 1
% 
% Линк только с одной станцией на к-ой точки справа (равентство)
% 
% Sum{для k=i+1:n+1}Zijkq >= (или =) xij для всех i, j, q
% 
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

for i = 1 : n
    for j = 1 : m
        mas = zeros(1, width(table));
        var_z = {};
        var_x = ['x', num2str(i), num2str(j)];
        [~, row_x, ~] = intersect(tableVarName, var_x);
        mas(1, row_x) = 1;
        for k = 0 : i - 1
            if k == 0
                var_z = [var_z, ...
                    ['z', num2str(i), '_', ... 
                    num2str(j), '_', num2str(k), ...
                    '_', num2str(m+1)]];
            else
                for q = 1 : m
                    if j ~= q
                        var_z = [var_z, ...
                        ['z', num2str(i), '_', ... 
                        num2str(j), '_', num2str(k), ...
                        '_', num2str(q)]];
                    end

                end
            end
        end
        [~, row_z, ~] = intersect(tableVarName, var_z);
        mas(1, row_z) = -1;
        RowNames = [RowNames, ['SUMz', num2str(i), '_', ... 
            num2str(j), '_', 'k_q = 1 (k is left from i)']];
        A = [A; mas];        
             
    end
end
A_27 = array2table(A,'VariableNames', tableVarName);
A_27.Properties.RowNames = RowNames;
b_27 = zeros(height(A_27),1);
end


function [A_23, b_23] = add_condition_23(table, place, place_end, ...
    r, R, n, m)

% Условие: Радиус связи не меньше расстояния между станциями
% 
% Обеспечить:
% 
% Zijkq(Rjq 0 (ai - ak) >= 0 k = i - 1, ..., 0.
% 

tableVarName = table.Properties.VariableNames;
RowNames = {};
A = [];
place = [0, place, place_end];

for i = 1 : n
    for j = 1 : m
        for k = i - 1 : -1 : 0
            if k == 0
                var_z = ['z', num2str(i), '_', num2str(j), '_', ...
                num2str(k), '_', num2str(m+1)];

                RowNames = [RowNames, ['-z', num2str(i), num2str(j), ...
                num2str(k),num2str(m+1) '(R', num2str(j), '_',...
                num2str(m+1), '-(a', num2str(i), ...
                '-a', num2str(k), '))']];

                [~, row_z, ~] = intersect(tableVarName, var_z);

                mas = zeros(1, width(table));
                mas(1, row_z) = -(R(j,m+1) - (place(i+1) - place(k+1)));
                A = [A; mas];
                
            else
                for q = 1 : m
                    if j ~= q
                        var_z = ['z', num2str(i), '_', num2str(j), '_', ...
                        num2str(k), '_', num2str(q)];
                    
                        RowNames = [RowNames, ['-z', num2str(i), num2str(j), ...
                        num2str(k),num2str(q) '(R', num2str(j), '_',...
                        num2str(q), '-(a', num2str(i), ...
                        '-a', num2str(k), '))']];
                    
                        [~, row_z, ~] = intersect(tableVarName, var_z);
                    
                        mas = zeros(1, width(table));
                        mas(1, row_z) = -(R(j,q) - (place(i+1) - place(k+1)));
                        A = [A; mas];
                        
                    end
                end
            end
        end
    end
end

A_23 = array2table(A,'VariableNames', tableVarName);
A_23.Properties.RowNames = RowNames;
b_23 = zeros(height(A_23),1);
end

function [A_24, b_24] = add_condition_24(table, place, place_end, ...
    r, R, n, m)

% Условие: Радиус связи не меньше расстояния между станциями
% 
% Обеспечить:
% 
% Zijkq(Rjq 0 (ak - ai) >= 0 k = i + 1 : n + 1.
% 

tableVarName = table.Properties.VariableNames;
RowNames = {};
A = [];
place = [0, place, place_end];

for i = 1 : n
    for j = 1 : m
        for k = i + 1 : n + 1
            if k == n + 1
                var_z = ['z', num2str(i), '_', num2str(j), '_', ...
                num2str(k), '_', num2str(m+1)];

                RowNames = [RowNames, ['-z', num2str(i), num2str(j), ...
                num2str(k),num2str(m+1) '(R', num2str(j), '_',...
                num2str(m+1), '-(a', num2str(k), ...
                '-a', num2str(i), '))']];

                [~, row_z, ~] = intersect(tableVarName, var_z);

                mas = zeros(1, width(table));
                mas(1, row_z) = -(R(j,m+1) - (place(k+1) - place(i+1)));
                A = [A; mas];
                
            else
                for q = 1 : m
                    if j ~= q
                        var_z = ['z', num2str(i), '_', num2str(j), '_', ...
                        num2str(k), '_', num2str(q)];
                    
                        RowNames = [RowNames, ['-z', num2str(i), num2str(j), ...
                        num2str(k),num2str(q) '(R', num2str(j), '_',...
                        num2str(q), '-(a', num2str(k), ...
                        '-a', num2str(i), '))']];
                    
                        [~, row_z, ~] = intersect(tableVarName, var_z);
                    
                        mas = zeros(1, width(table));
                        mas(1, row_z) = -(R(j,q) - (place(k+1) - place(i+1)));
                        A = [A; mas];
                        
                    end
                end
            end
        end
    end
end

A_24 = array2table(A,'VariableNames', tableVarName);
A_24.Properties.RowNames = RowNames;
b_24 = zeros(height(A_24),1);
end


function [A_7h, b_7h] = add_condition_7hatch(table, n, m)
tableVarName = table.Properties.VariableNames;
RowNames = cell(1,m);
var_x = cell(m, n);
A = zeros(m, width(table));
b_7h = zeros(m, 1);
for j = 1 : m
    for i = 1 : n
        var_x{j,i} = ['x', num2str(i), num2str(j)];
    end
    [~, row_x, ~] = intersect(tableVarName, var_x(j,:));
    A(j, row_x) = 1;
    b_7h(j, 1) = 1;
    RowNames{1,j} = ['SUMxi', num2str(j), '=1'];
end

A_7h = array2table(A,'VariableNames', tableVarName);
A_7h.Properties.RowNames = RowNames;
end

function [A_12, b_12] = add_condition_12(table, n)
tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

mas = zeros(1, width(table));
var_y = ['y', num2str(0), 'plus'];
[~, row_y, ~] = intersect(tableVarName, var_y);
mas(1, row_y) = 1;
A = [A; mas];

mas = zeros(1, width(table));
var_y = ['y', num2str(0), 'minus'];
[~, row_y, ~] = intersect(tableVarName, var_y);
mas(1, row_y) = 1;
A = [A; mas];

mas = zeros(1, width(table));
var_y = ['y', num2str(n + 1), 'plus'];
[~, row_y, ~] = intersect(tableVarName, var_y);
mas(1, row_y) = 1;
A = [A; mas];

mas = zeros(1, width(table));
var_y = ['y', num2str(n + 1), 'minus'];
[~, row_y, ~] = intersect(tableVarName, var_y);
mas(1, row_y) = 1;
A = [A; mas];


mas = zeros(1, width(table));
var_e = ['e', num2str(0)];
[~, row_e, ~] = intersect(tableVarName, var_e);
mas(1, row_e) = 1;
A = [A; mas];

mas = zeros(1, width(table));
var_e = ['e', num2str(n + 1)];
[~, row_e, ~] = intersect(tableVarName, var_e);
mas(1, row_e) = 1;
A = [A; mas];

A_12 = array2table(A,'VariableNames', tableVarName);
A_12.Properties.RowNames = RowNames;
b_12 = [zeros(4,1); ones(2,1)];
end


function [A_22, b_22] = add_condition_22(table, n, m)

% Условие радиорелейной связи
% 
% Обеспечить для всех k
% 
% Sum{для i=1:n}Sum{для k=0:i-1}Zijkq >= (или =) ek для всех k


tableVarName = table.Properties.VariableNames;
A = [];
RowNames = {};

for k = 0 : n + 1
    mas = zeros(1, width(table));
    var_z = {};
    var_e = ['e', num2str(k)];
    [~, row_e, ~] = intersect(tableVarName, var_e);
    mas(1, row_e) = 1;
    for i = 1 : n
        if i ~= k
            for j = 1 : m
                if k == 0 || k == n + 1
                   var_z = [var_z, ...
                        ['z', num2str(i), '_', ... 
                        num2str(j), '_', num2str(k), ...
                        '_', num2str(m+1)]];

                else
                    for q = 1 : m
                        if j ~= q
                            var_z = [var_z, ...
                                ['z', num2str(i), '_', ... 
                                num2str(j), '_', num2str(k), ...
                                '_', num2str(q)]];
                            [~, row_z, ~] = intersect(tableVarName, var_z);
                            mas(1, row_z) = -1;
                            
                        end
                    end
                end
                [~, row_z, ~] = intersect(tableVarName, var_z);
                mas(1, row_z) = -1;
            end
        end
    end
    RowNames = [RowNames, ['e', num2str(k), ...
            '-SUMz', num2str(i), '_', ... 
            num2str(j), '_', num2str(k), ...
            '_', num2str(m+1)]];
    A = [A; mas];
end        

A_22 = array2table(A,'VariableNames', tableVarName);
A_22.Properties.RowNames = RowNames;
b_22 = zeros(height(A_22),1);
end

function [A_13, b_13] = add_condition_13(table, n, m, c, cost_limit)
tableVarName = table.Properties.VariableNames;
RowNames = {'SUMxij is less than Cost Limit'};
var_x = cell(m, n);
A = zeros(1, width(table));
b_13 = cost_limit;

for j = 1 : m
    for i = 1 : n
        var_x{j,i} = ['x', num2str(i), num2str(j)];
    end
    [~, row_x, ~] = intersect(tableVarName, var_x(j,:));
    A(1, row_x) = c(j);
end

A_13 = array2table(A,'VariableNames', tableVarName);
A_13.Properties.RowNames = RowNames;
end

function [A_14, b_14] = add_condition_14(table, n, m, throughput, ...
    package_size, arival, delay)
tableVarName = table.Properties.VariableNames;
RowNames = {'SUMxij is less than Delay Limit'};
var_x = cell(m, n);
A = zeros(1, width(table));
b_14 = delay;

for j = 1 : m
    for i = 1 : n
        var_x{j,i} = ['x', num2str(i), num2str(j)];
    end
    [~, row_x, ~] = intersect(tableVarName, var_x(j,:));
    if (throughput(j)/package_size) < arival
        rho = 0.999999999;
    else
        rho = arival / (throughput(j)/package_size);
    end
    mean_sustem_size = rho / (1 - rho);
    node_delay = round(mean_sustem_size / arival, 5);
    A(1, row_x) = node_delay;
end

A_14 = array2table(A,'VariableNames', tableVarName);
A_14.Properties.RowNames = RowNames;
end

function Cost = calculate_constraints(solution, xname, ...
    cost_ineq)
    solution_name = solution.Properties.VariableNames;
    [~, row_x, ~] = intersect(solution_name, xname);
    
    solution_array = table2array(solution(1, row_x));
    cost_array = table2array(cost_ineq(1, row_x));
    
    Cost = sum(cost_array .* solution_array);
end

function [Placed] = get_placed_sta(solution, xname, n, m)
    Placed = ones(1, n)*inf;
    
    solution_name = solution.Properties.VariableNames;
    [~, row_x, ~] = intersect(solution_name, xname);
    p = zeros(1, n*m);
    s = zeros(1, n*m);
    solution_x = table2array(solution(1, row_x));
    index = 1;

    for i = 1 : n
        for j = 1 : m
            p(index) = i;
            s(index) = j;
            
            
            if int8(solution_x(index)) == 1
                Placed(i) = j;
            end
            index = index + 1;
        end
    end
end
