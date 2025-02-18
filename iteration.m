clear
format long

next_iter = true;

while next_iter
    Step3_UAV_altitude  % clear is included
    next_iter = (total_loss_clean ~= 0.0);
end