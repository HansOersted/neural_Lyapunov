# neural_Lyapunov

This repo constructs the Lyapunov candidate based on neural network.

The controller is specified below:
```
    kD = diag([5,10]);
    de = dq - dr;
    ddq = -kD * de + ddr;
```


## Step 1. Show the tracking error.


Plot the tracking error, e(t).

![image](https://github.com/user-attachments/assets/d56b807d-d17a-4efb-9bdb-8cae41c5071c)



## Step 2. Visualize the reference velocity and the actual velocity.


Plot (dr1,dr2) and (dq1,dq2) diagrams.


https://github.com/user-attachments/assets/b4698118-6534-42a2-91a2-4a1653ebee31




## Step 3. Find the Lyapunov Candidate using Neural Network.


The found Lyapunov candidate has been tested for the unseen intial condition, leading to a good result with negative constraints as expected.