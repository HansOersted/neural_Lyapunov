clear
close all

%% simulate and save the data

sample_time = 0.05;
length = 100;
simulation_time = sample_time * length;

n1 = 1;
dimension = 2;

init_dr = [1; 1];

for i = 1 : n1
    initial(i).init_dq = [0.8/i; 0.5/i];
    initial(i).init_q = [0; 0];
end

for i = 1 : n1
    init_dq = initial(i).init_dq;
    init_q = initial(i).init_q;
    
    data_from_simulink = sim('circular_data');
    
    q_values = data_from_simulink.q.signals.values;
    dq_values = data_from_simulink.dq.signals.values;
    ddq_values = data_from_simulink.ddq.signals.values;

    de_values = data_from_simulink.de.signals.values;
    dde_values = -ddq_values;
    
    q_vec = squeeze(q_values)';
    dq_vec = squeeze(dq_values)';
    ddq_vec = squeeze(ddq_values)';
    
    de_vec = squeeze(de_values)';
    dde_vec = squeeze(dde_values)';

    derivative_training_sample(i).data = de_vec;
    derivative_derivative_training_sample(i).data = dde_vec;
end

