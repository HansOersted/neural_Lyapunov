clear
clc
close all

%% Start idx: 1372,  End idx: 2340
% takes: idx_init = 1380,  idx_final = 2330

idx_init = 1380;
idx_final = 2330;

UR5_experiment = readtable('robot_data.csv');

sample_time = 0.002; % 500 Hz

time = UR5_experiment.timestamp;

q_ref = UR5_experiment.target_q_0;
dq_ref = UR5_experiment.target_qd_0;
ddq_ref = UR5_experiment.target_qdd_0;

q = UR5_experiment.actual_q_0;
dq = UR5_experiment.actual_qd_0;

e = q - q_ref;
de = dq - dq_ref;

dde = diff(de) / sample_time;  % lose 1 row
dde = smooth(dde);
% time_dde = time(1:end-1);

time_interested = time(idx_init:idx_final) - time(idx_init);


de_interested = de(idx_init:idx_final);
dde_interested = dde(idx_init:idx_final);

%% plot

% only plot several points
step = 50;
de_sampled = de_interested(1:step:end);
dde_sampled = dde_interested(1:step:end);
time_sampled = time_interested(1:step:end);

figure
hold on
plot(de_sampled, dde_sampled, '-o');
xlabel('de', 'Interpreter', 'latex');
ylabel('dde', 'Interpreter', 'latex');
title('Phase Diagram (de vs. dde)');
grid on;

% mark the time
for i = 1:1:length(time_sampled)
    text(de_sampled(i), dde_sampled(i), sprintf('%.2f s', time_sampled(i)), 'FontSize', 20);
end

hold off

%%