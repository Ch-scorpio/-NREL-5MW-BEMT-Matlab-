%% 风力发电机 叶素-动量理论 (BEMT) 计算程序
% 适用于水平轴风力发电机 (如 NREL 5MW)
%clc; clear; close all;

%% 1. 用户输入：环境与宏观几何参数 (以简化版 NREL 5MW 为例)
air.rho = 1.225;         % 空气密度 [kg/m^3]
prop.B = 3;              % 叶片数 [-]
prop.R = 63;             % 风机转子半径 [m]
prop.Rh = 1.5;           % 轮毂半径 [m]

% 工况设置
Vinf_array = 5:1:25;     % 来流风速范围 [m/s]
Omega_rpm = 12.1;        % 转子转速 [rpm] (NREL 5MW 额定转速)
Omega = Omega_rpm * pi / 30; % 转换为 [rad/s]——单位转化
pitch_angle = 0;         % 整体变桨角 [deg] (正常运行通常为0，高风速时增大)

%% 2. 构造叶片几何分布 (需替换为真实的 NREL 5MW 分布表)
% 此处生成一个简化的 17 个节点的展向分布用于测试
r_array = [2.8667
5.6
8.3333
11.75
15.85
19.95
24.05
28.15
32.25
36.35
40.45
44.55
48.65
52.75
56.1667
58.9
61.6333];                  % 叶素距离其回转中心半径 [m]
% 简化的弦长和扭转角分布 (模拟真实风机：根部弦长大、扭转角大，尖部小)
c_array = [3.542
3.854
4.167
4.557
4.652
4.458
4.249
4.007
3.748
3.502
3.256
3.01
2.764
2.518
2.313
2.086
1.419];         % 弦长 [m]
theta_array = [0.232268417
0.232268417
0.232268417
0.232268417
0.200363798
0.177360359
0.157271619
0.136048415
0.114214346
0.093567101
0.073094389
0.054541539
0.040474185
0.026633724
0.015062191
0.006457718
0.001850049]; % 气动扭转角 [rad]

% 实时计算无量纲展向位置 (避免因变量名丢失导致的报错)
span_ratio = r_array / prop.R; 


%% 3. 计算过程与预分配
N_v = length(Vinf_array); % 获取来流风速数组的长度（即：我们要计算多少个不同的风速工况）
N_r = length(r_array); % 获取叶片展向节点的数量（即：把一根叶片切成了多少个“叶素”）
% 使用 deal 函数批量初始化变量，为三个无量纲系数分配 N_v 行 1 列的全零矩阵
% C_P_arr: 预分配用于存储不同风速下的“风能利用系数 (功率系数)”
% C_T_arr: 预分配用于存储不同风速下的“推力系数”
% lambda_arr: 预分配用于存储不同风速下的“叶尖速比 (TSR)”
[C_P_arr, C_T_arr, lambda_arr] = deal(zeros(N_v, 1));
Power_arr = zeros(N_v, 1); % Power_arr: 预分配用于存储绝对机械功率，单位为瓦特 (W)
Thrust_arr = zeros(N_v, 1); % Thrust_arr: 预分配用于存储转子受到的绝对轴向推力，单位为牛顿 (N)
% 【新增修改】预分配用于存储诱导因子的二维矩阵
% 行对应不同的风速工况，列对应叶片不同的展向位置
a_arr = zeros(N_v, N_r);       % 轴向诱导因子 (a)
a_prime_arr = zeros(N_v, N_r); % 周向诱导因子 (a')
%% 4. 主循环：遍历不同风速
for i = 1:N_v
    Vinf = Vinf_array(i);
    lambda = (Omega * prop.R) / Vinf; % 计算叶尖速比 (TSR)
    
    dT = zeros(N_r, 1); % 叶素推力
    dQ = zeros(N_r, 1); % 叶素扭矩
    
    % 遍历叶片展向各叶素
    for j = 1:N_r
        r = r_array(j);
        c = c_array(j);
        theta = theta_array(j) + deg2rad(pitch_angle);
        
        % 局部实度
        sigma = (prop.B * c) / (2 * pi * r);
        
        % 迭代初值
        a = 0;       % 轴向诱导因子 (风机为减速，公式中为 1-a)
        a_prime = 0; % 周向诱导因子 (公式中为 1+a')
        
        tol = 1e-5;  % 迭代误差容限
        maxIter = 100;
        
        % BEMT 迭代求解
        for iter = 1:maxIter
            % 1. 计算入流角 phi (注意风机的符号：轴向风减速 1-a，切向 1+a')
            phi = atan2( Vinf * (1 - a), Omega * r * (1 + a_prime) );
            
            % 2. 计算局部迎角(攻角) alpha
            alpha = phi - theta;
            
            % 3. 获取翼型升阻力系数 (使用真实 NREL 5MW 翼型表插值)
            % 首先将当前的迎角从弧度转为角度，因为官方数据表的迎角单位是 Degree
            alpha_deg = rad2deg(alpha); 
            
            % 根据当前叶素所在的无量纲位置 r_R(j) (或相对厚度)，判断该用哪个翼型表
            % (以下分段依据 NREL 报告中分布式叶片的气动节点分布)
            %files={'table_Cylinder1.mat','table_Cylinder2.mat','table_DU21.mat','table_DU25.mat','table_DU30.mat','table_DU35.mat','table_DU40.mat','table_NACA64.mat'};

            if span_ratio(j) <= 0.089
                % 纯圆柱段 (Cylinder1)
                Cl = interp1(table_Cylinder1(:,1), table_Cylinder1(:,2), alpha_deg, 'linear', 'extrap');
                Cd = interp1(table_Cylinder1(:,1), table_Cylinder1(:,3), alpha_deg, 'linear', 'extrap');
            elseif span_ratio(j)  > 0.089 && span_ratio(j) <= 0.132
                % 纯圆柱段 (Cylinder2)
                Cl = interp1(table_Cylinder2(:,1), table_Cylinder2(:,2), alpha_deg, 'linear', 'extrap');
                Cd = interp1(table_Cylinder2(:,1), table_Cylinder2(:,3), alpha_deg, 'linear', 'extrap');
                
            elseif span_ratio(j) > 0.132 && span_ratio(j) <= 0.187
                % 过渡段：使用厚度 40% 的 DU40 翼型
                Cl = interp1(table_DU40(:,1), table_DU40(:,2), alpha_deg, 'linear', 'extrap');
                Cd = interp1(table_DU40(:,1), table_DU40(:,3), alpha_deg, 'linear', 'extrap');
                
            elseif span_ratio(j) > 0.187 && span_ratio(j) <= 0.32
                % DU35 翼型
                Cl = interp1(table_DU35(:,1), table_DU35(:,2), alpha_deg, 'linear', 'extrap');
                Cd = interp1(table_DU35(:,1), table_DU35(:,3), alpha_deg, 'linear', 'extrap');
            
            elseif span_ratio(j) > 0.32 && span_ratio(j) <= 0.3817
                % DU30 翼型
                Cl = interp1(table_DU30(:,1), table_DU30(:,2), alpha_deg, 'linear', 'extrap');
                Cd = interp1(table_DU30(:,1), table_DU30(:,3), alpha_deg, 'linear', 'extrap');

            elseif span_ratio(j) > 0.3817 && span_ratio(j) <= 0.5119
                % DU25 翼型
                Cl = interp1(table_DU25(:,1), table_DU25(:,2), alpha_deg, 'linear', 'extrap');
                Cd = interp1(table_DU25(:,1), table_DU25(:,3), alpha_deg, 'linear', 'extrap');

            elseif span_ratio(j) > 0.5119 && span_ratio(j) <= 0.6421
                % DU21 翼型
                Cl = interp1(table_DU21(:,1), table_DU21(:,2), alpha_deg, 'linear', 'extrap');
                Cd = interp1(table_DU21(:,1), table_DU21(:,3), alpha_deg, 'linear', 'extrap');
           
            elseif span_ratio(j) > 0.6421
                % 叶尖段：使用 NACA 64-A17 翼型
                Cl = interp1(table_NACA64(:,1), table_NACA64(:,2), alpha_deg, 'linear', 'extrap');
                Cd = interp1(table_NACA64(:,1), table_NACA64(:,3), alpha_deg, 'linear', 'extrap');
            end
            
            % 4. 计算推力方向和切向系数 (保持原样即可)
            Cn = Cl * cos(phi) + Cd * sin(phi);
            Ct = Cl * sin(phi) - Cd * cos(phi);
            
            % 5. Prandtl 桨尖与轮毂损失修正
            f_tip = (prop.B / 2) * (prop.R - r) / (r * abs(sin(phi)));
            F_tip = (2 / pi) * acos(exp(-max(f_tip, 0.001)));
            
            f_hub = (prop.B / 2) * (r - prop.Rh) / (prop.Rh * abs(sin(phi)));
            F_hub = (2 / pi) * acos(exp(-max(f_hub, 0.001)));
            
            F = F_tip * F_hub;
            F = max(F, 0.0001); % 防止除以零
            
            % 6. 更新诱导因子并引入 Glauert 高诱导修正
            % 计算理论新 a 值
            K = (4 * F * sin(phi)^2) / (sigma * Cn);
            
            if a <= 0.4 % 正常状态
                a_new = 1 / (K + 1);
            else % Glauert 紊流尾流状态修正 (Buhl修正法)
                ac = 0.4;
                a_new = 0.5 * (2 + K*(1 - 2*ac) - sqrt((K*(1 - 2*ac) + 2)^2 + 4*(K*ac^2 - 1)));
            end
            
            % 计算新的 a' 值
            a_prime_new = 1 / ( (4 * F * sin(phi) * cos(phi)) / (sigma * Ct) - 1 );
            
            % 判断是否收敛
            if abs(a_new - a) < tol && abs(a_prime_new - a_prime) < tol
                a = a_new;
                a_prime = a_prime_new;
                break;
            end
            
            % 松弛迭代 (防止震荡发散)
            relax = 0.25; 
            a = a * (1 - relax) + a_new * relax;
            a_prime = a_prime * (1 - relax) + a_prime_new * relax;
        end % BEMT 迭代循环结束
        
        % 【新增修改】：在迭代收敛后，将当前风速(i)下、当前节点(j)的诱导因子保存下来
        a_arr(i, j) = a;
        a_prime_arr(i, j) = a_prime;
        
        % 7. 计算叶素局部气动力
        % V_rel = Vinf * (1 - a) / sin(phi); 相对速度
        q_rel = 0.5 * air.rho * (Vinf * (1 - a) / sin(phi))^2;
        dT(j) = q_rel * prop.B * c * Cn;
        dQ(j) = q_rel * prop.B * c * Ct * r / (cos(phi)*(1-a));
    end
    
    % 8. 对展向进行积分求总推力和总功率
    Thrust = trapz(r_array, dT);
    Torque = trapz(r_array, dQ);
    Power = Torque * Omega;
    
    % 9. 计算风机标准无量纲系数
    Swept_Area = pi * prop.R^2;
    P_avail = 0.5 * air.rho * Swept_Area * Vinf^3; % 扫掠面积内的风能
    T_avail = 0.5 * air.rho * Swept_Area * Vinf^2;
    
    C_P = Power / P_avail;
    C_T = Thrust / T_avail;
    
    % 保存数据
    C_P_arr(i) = C_P;
    C_T_arr(i) = C_T;
    Power_arr(i) = Power;
    Thrust_arr(i) = Thrust;
    lambda_arr(i) = lambda;
end

%% 5. 结果可视化绘制
figure('Name', 'Wind Turbine BEMT Performance', 'Color', 'w', 'Position', [100, 100, 900, 400]);

subplot(1,3,1);
plot(Vinf_array, Power_arr / 1e6, 'b-o', 'LineWidth', 1.5);
grid on; xlabel('Wind Speed V_{\infty} [m/s]'); ylabel('Power [MW]');
title('机械功率曲线');

subplot(1,3,2);
plot(lambda_arr, C_P_arr, 'r-o', 'LineWidth', 1.5);
grid on; xlabel('Tip Speed Ratio \lambda'); ylabel('Power Coefficient C_P');
title('风能利用系数 C_P');

subplot(1,3,3);
plot(lambda_arr, C_T_arr, 'g-o', 'LineWidth', 1.5);
grid on; xlabel('Tip Speed Ratio \lambda'); ylabel('Thrust Coefficient C_T');
title('推力系数 C_T');

%% 6. 本地子函数：模拟风机翼型气动数据(模拟C_l、C_d)
%function [Cl, Cd] = get_airfoil_data(alpha)
    % 这是一个解析拟合的临时升阻力模型，用于确保代码可直接运行。
    % 【关键修改】：替换真实数据时，将此函数改为读取你的 .mat 极曲线表，
    % 并使用 interp1() 根据局部 alpha 查出 Cl 和 Cd。
    
%    alpha_deg = rad2deg(alpha);
    
    % 简单的线性升力区 + 失速模拟
%    if alpha_deg >= -10 && alpha_deg <= 15
%        Cl = 0.11 * alpha_deg + 0.2; % 线性段
%    elseif alpha_deg > 15 && alpha_deg <= 25
%        Cl = 1.85 - 0.05 * (alpha_deg - 15); % 轻微失速降落
%    else
%        Cl = 0.5 * sin(2 * alpha); % 深失速近似
%    end
    
    % 阻力抛物线模型
%    Cd = 0.01 + 0.005 * (alpha_deg)^2 / 100;
%end
%% 7. 【新增】诱导因子沿展向分布的可视化
% 我们选择一个特定风速来查看其诱导因子分布，例如选取额定风速附近的工况
target_wind_speed = 11; % 设定目标风速为 11 m/s
[~, idx] = min(abs(Vinf_array - target_wind_speed)); % 找到最接近该风速的索引

figure('Name', 'Induction Factors Distribution', 'Color', 'w', 'Position', [150, 150, 600, 400]);

% 绘制轴向诱导因子 a
plot(span_ratio, a_arr(idx, :), 'b-o', 'LineWidth', 1.5, 'DisplayName', '轴向诱导因子 (a)');
hold on;

% 绘制周向诱导因子 a'
plot(span_ratio, a_prime_arr(idx, :), 'r-s', 'LineWidth', 1.5,'DisplayName', '切向诱导因子 (a'')');

grid on;
xlabel('无量纲展向位置 r/R');
ylabel('诱导因子数值');
title(['风速 V_{\infty} = ', num2str(Vinf_array(idx)), ' m/s 时的诱导因子分布']);
legend('Location', 'best');