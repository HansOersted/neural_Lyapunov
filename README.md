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

![image](https://github.com/user-attachments/assets/255bb0d5-d2b9-49b9-a45d-aa678e940c22)


## Step 2. Visualize the reference velocity and the actual velocity.


Plot (dr1,dr2) and (dx1,dx2) diagrams.


## Step 3. Find the Lyapunov Candidate using Neural Network.
