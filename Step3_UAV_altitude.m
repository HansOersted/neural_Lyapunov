clear
close all
clc
warning on
%% Highlight the important training parameters
lambda_val = 1.5;  % maximum record: 1.5
num_epochs = 600;
learning_rate = 1e-2;

gamma = 1e-4;

%% Parameters in the controller
k1 = 1;
k2 = 2;

%% Simulate and Save Data
sample_time = 0.05;
length = 200;
simulation_time = sample_time * length;

n1 = 20; % Number of samples
dimension = 2;

for i = 1 : n1
    initial(i).init_X = [0.8/i; 0.5/i];
end

for i = 1 : n1
    init_X = initial(i).init_X;
    
    data_from_simulink = sim('UAV_altitude');

    e_values = squeeze(data_from_simulink.e.signals.values);
    de_values = squeeze(data_from_simulink.de.signals.values);

    derivative_training_sample(i).data = e_values;
    derivative_derivative_training_sample(i).data = de_values;
end

%% Prepare for Training
h = 32; % Width of the hidden layer

% Define NN Weights
L1 = randn(h, dimension); % Input to hidden layer 1
b1 = zeros(h, 1);

L2 = randn(h, h); % Hidden layer 1 to hidden layer 2
b2 = zeros(h, 1);

L_out = randn(dimension * (dimension + 1)/2 , h); % Hidden layer to output
b_out = zeros(dimension * (dimension + 1)/2 , 1);

%% Training Loop
loss_history = zeros(num_epochs, 1);
A_history = [];
L_history = [];
constraint_history = zeros(num_epochs, 1);

constraint_first_epoch = []; % Store the constraint in the first epoch (debug)
constraint_last_epoch = []; % Store the constraint in the last epoch (debug)

for epoch = 1 : num_epochs
    total_loss_clean = 0;
    currentEpochs = epoch;
    
    % Initialize Gradients
    dL1 = zeros(size(L1));
    db1 = zeros(size(b1));
    dL2 = zeros(size(L2));
    db2 = zeros(size(b2));
    dL_out = zeros(size(L_out));
    db_out = zeros(size(b_out));

    for i = 1 : n1
        for t = 1 : (length + 1)
            % Extract Current Time Step Data
            de = derivative_training_sample(i).data(t, :)'; % Tracking error derivative
            dde = derivative_derivative_training_sample(i).data(t, :)'; % Second derivative
            
            % Forward Pass (Using ReLU Instead of tanh)
            hidden1 = max(0, L1 * de + b1); % ReLU activation
            hidden2 = max(0, L2 * hidden1 + b2); % ReLU activation

            % Construct Lower Triangular L_pred
            L_flat = L_out * hidden2 + b_out;
            L_pred = zeros(dimension, dimension);
            L_pred(tril(true(dimension, dimension))) = L_flat;
            L_pred(logical(eye(dimension))) = log(1 + exp(L_pred(logical(eye(dimension))))); % Softplus activation
            if any(isinf(L_pred), 'all')  % check if L_pred contains Inf
                warning('L_pred contains Inf values!');
            end
            if any(isnan(L_pred), 'all')
                warning('L_pred contains NaN values!');
            end
            % if any(L_pred < 1e-8)
            %     warning('L_pred contains values smaller than 0.00000001!');
            % end

            % Constraint Computation
            A = L_pred * L_pred'; % Coefficient matrix
            if any(isinf(A), 'all')  % check if L_pred contains Inf
                warning('A contains Inf values!');
            end
            if any(isnan(A), 'all')
                warning('A contains NaN values!');
            end
            % if any(A < 1e-8)
            %     warning('A contains values smaller than 0.00000001!');
            % end
            constraint = dde' * A * de + de' * A * dde + lambda_val * de' * A * de + gamma;
            constraint_clean = constraint - gamma;

            % Store the constraint in the first epoch (debug)
            if epoch == 1
                constraint_first_epoch = [constraint_first_epoch, constraint_clean];
            end

            if epoch == num_epochs
                constraint_last_epoch = [constraint_last_epoch, constraint_clean];
            end

            % Loss Computation
            constraint_violation = max(0, constraint);
            loss_clean = max(0, constraint_clean);
            total_loss_clean = total_loss_clean + loss_clean;

            % Compute Gradient
            if constraint_violation > 0
                A1 = dde'; B1 = de;
                A2 = de'; B2 = dde;
                A3 = de'; B3 = de;
            
                grad_constraint = (A1' * B1' + B1 * A1) * L_pred ...
                                + (A2' * B2' + B2 * A2) * L_pred ...
                                + lambda_val * (A3' * B3' + B3 * A3) * L_pred;
            
                % Softplus gradient correction
                softplus_derivative = 1 ./ (1 + exp(-L_pred)); % Softplus derivative
                % grad_constraint = grad_constraint .* softplus_derivative; % gradient correction
                % gradient correction is corrected only on the diagnal
                grad_constraint(logical(eye(dimension))) = grad_constraint(logical(eye(dimension))) ...
                                          .* softplus_derivative(logical(eye(dimension)));
            else
                grad_constraint = zeros(size(L_pred));
            end
            
            % Lower triangular gradient
            grad_L_flat = grad_constraint(tril(true(dimension, dimension))); 
            
            % update the gradient
            dL_out = dL_out + grad_L_flat * hidden2';
            db_out = db_out + grad_L_flat;

            % Update Hidden Layers (ReLU Derivative)
            grad_hidden2 = (L_out' * grad_L_flat) .* (hidden2 > 0);
            dL2 = dL2 + grad_hidden2 * hidden1';
            db2 = db2 + grad_hidden2;
            
            grad_hidden1 = (L2' * grad_hidden2) .* (hidden1 > 0);
            dL1 = dL1 + grad_hidden1 * de';
            db1 = db1 + grad_hidden1;
        end
    end

    % Update Weights
    L1 = L1 - learning_rate * dL1 / (n1 * (length + 1));
    b1 = b1 - learning_rate * db1 / (n1 * (length + 1));
    L2 = L2 - learning_rate * dL2 / (n1 * (length + 1));
    b2 = b2 - learning_rate * db2 / (n1 * (length + 1));
    L_out = L_out - learning_rate * dL_out / (n1 * (length + 1));
    b_out = b_out - learning_rate * db_out / (n1 * (length + 1));
    
    A_history = [A_history; A];
    L_history = [L_history; L_pred];

    
    % Save History
    loss_history(epoch) = total_loss_clean;
    constraint_history(epoch) = constraint;
    
    % Debugging (Optional)
    if mod(epoch, 50) == 0
        fprintf('Epoch %d, Loss (clean): %.4f\n', epoch, total_loss_clean);
        L_pred
        A
    end
end

%% Plot Results
figure;
plot(loss_history, 'LineWidth', 2);
xlabel('Epoch');
ylabel('Loss');
title('Training Loss');
grid on;

% figure;
% plot(constraint_history, 'LineWidth', 2);
% xlabel('Epoch');
% ylabel('Constraint');
% title('Constraint History');
% grid on;

%% Plot First and Last Epoch Constraints
figure;
plot(1:size(constraint_first_epoch,2), constraint_first_epoch, 'LineWidth', 2);
xlabel('Training Sample Index');
ylabel('Constraint Value');
title('Constraints in the First Epoch (Clean)');
grid on;

figure;
plot(1:size(constraint_last_epoch,2), constraint_last_epoch, 'LineWidth', 2);
xlabel('Training Sample Index');
ylabel('Constraint Value');
title('Constraints in the Last Epoch (Clean)');
grid on;

%%
[e,de] = meshgrid(-20:1:20,-20:1:20);

A_plot = A;

eig(A)

Lyap = zeros(size(e));

for i = size(e,1):-1:1
    for j = size(e,1):-1:1
        Lyap(i,j) = [e(i,j)  de(i,j)] * A_plot * [e(i,j) ; de(i,j)];
    end
end
figure
surf(e,de,Lyap)
xlabel('$e$', 'Interpreter', 'latex', 'FontSize', 18);
ylabel('$\dot{e}$', 'Interpreter', 'latex', 'FontSize', 18);
zlabel('$V(e, \dot{e})$', 'Interpreter', 'latex', 'FontSize', 16);
title(['Lyapunov Function ($\lambda = ' num2str(lambda_val) '$)'], 'Interpreter', 'latex', 'FontSize', 16);

