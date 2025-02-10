clear
close all

%% simulate and save the data

sample_time = 0.05;
length = 100;
simulation_time = sample_time * length;

n1 = 1;
dimension = 2;

for i = 1 : n1
    initial(i).init_dq = [0.8/i; 0.5/i];
    initial(i).init_q = [0; 0];

    initial(i).init_dr = [1; 1];
end

for i = 1 : n1
    init_dq = initial(i).init_dq;
    init_q = initial(i).init_q;

    init_dr = initial(i).init_dr;
    
    data_from_simulink = sim('circular_data');
    
    q_values = data_from_simulink.q.signals.values;
    dq_values = data_from_simulink.dq.signals.values;
    ddq_values = data_from_simulink.ddq.signals.values;

    dr_values = data_from_simulink.dr.signals.values;

    de_values = data_from_simulink.de.signals.values;
    dde_values = data_from_simulink.dde.signals.values;
    
    q_vec = squeeze(q_values)';
    dq_vec = squeeze(dq_values)';
    ddq_vec = squeeze(ddq_values)';
    
    dr_vec = dr_values;

    de_vec = squeeze(de_values)';
    dde_vec = squeeze(dde_values)';

    % derivative_training_sample(i).data = de_vec;
    % derivative_derivative_training_sample(i).data = dde_vec;
end

%% Plot the reference velocity and the actual velocity
% reference velocity: dr_vec
% actual velocity: dq_vec

close all

N = size(dr_vec, 1);

videoFileName = 'velocity_animation.avi';
videoWriter = VideoWriter(videoFileName, 'Motion JPEG AVI');
videoWriter.FrameRate = 10;
open(videoWriter);

figure;
hold on;
grid on;
xlabel('dq1 (rad/s)');
ylabel('dq2 (rad/s)');
title('Reference and Actual Velocity Animation');

h1 = animatedline('Color', 'r', 'LineWidth', 5);
h2 = animatedline('Color', 'b', 'LineWidth', 2);
legend({'Reference Velocity', 'Actual Velocity'}, 'Location', 'southeast');

for i = 1:N
    addpoints(h1, dr_vec(i,1), dr_vec(i,2));
    addpoints(h2, dq_vec(i,1), dq_vec(i,2));
    drawnow;
    
    frame = getframe(gcf);
    writeVideo(videoWriter, frame);
    
    pause(0.1);
end

close(videoWriter);

hold off;

disp(['Animation saved as ', videoFileName]);
