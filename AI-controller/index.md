# AI-Based Hybrid Vehicle Mode Controller

**A reinforcement learning–based torque-split controller for a parallel hybrid electric vehicle.**

This project explores the use of **Reinforcement Learning (RL)** to design intelligent driving modes for a hybrid electric vehicle. Using **Proximal Policy Optimization (PPO)**, separate control policies were trained to learn optimal torque-split behavior between an internal combustion engine and an electric motor.

The result is a simulation-based hybrid controller capable of exhibiting distinct **Eco**, **Normal**, and **Sport** driving behaviors, along with a supervisory controller that automatically selects between them based on driving conditions.

---

## Project Overview

<img width="576" height="335" alt="Screen Shot 2026-01-05 at 12 17 33 PM" src="https://github.com/user-attachments/assets/b0464148-3447-4668-8b73-388ee184408a" />

**Objective:**  
Demonstrate that reinforcement learning can learn meaningful, mode-dependent hybrid powertrain control strategies without hard-coded rules.

**Key Outcomes:**
- PPO agents learned distinct torque-split behaviors
- Learned controllers outperformed fixed torque-split baselines
- Policies generalized across multiple drive cycles
- Automatic mode switching produced intuitive behavior

---

## System Architecture

The project was implemented in **MATLAB** using a custom parallel hybrid vehicle model:

- **Engine:** GM EcoTec inline-4 (85 kW peak)  
- **Electric Motor:** UQM PowerPhase PMSM (150 kW peak)  
- **Battery:** 14 kWh Li-ion pack (96s8p)  
- **Driveline:** 2-speed gearbox with final drive  

The RL agent controls a single continuous action: the **engine–motor torque split**, while observing vehicle speed, acceleration demand, and battery state of charge (SOC).

<img width="388" height="391" alt="Screen Shot 2026-01-05 at 12 19 33 PM" src="https://github.com/user-attachments/assets/569cd786-58ed-4eaf-b39d-e47e48c3c902" />

---

## Reinforcement Learning Approach

Each driving mode is represented by a **separately trained PPO agent** sharing the same environment but using **mode-specific reward functions**.

Training used a two-stage strategy:
1. Rapid exploration with high learning rates   
<img width="744" height="450" alt="Screen Shot 2026-01-05 at 4 15 59 PM" src="https://github.com/user-attachments/assets/f7ed8436-c7ce-452f-a6e7-eab0a94d12d8" />
2. Policy refinement with reduced learning rates
<img width="714" height="400" alt="Screen Shot 2026-01-05 at 4 16 15 PM" src="https://github.com/user-attachments/assets/3fb59b6b-f5bc-4ec8-80d3-03529def6021" />

This approach produced stable, smooth control policies with reasonable training time.


---

## Driving Modes

The controller was trained and evaluated using a baseline drive cycle, then tested on additional urban and highway cycles to assess generalization.

Baseline drive cycle used for training and evaluation.

<img 
  src="https://github.com/user-attachments/assets/eacaae4e-4ee5-4dee-a2f1-e978f0cfbe96"
  alt="Baseline drive cycle velocity profile"
  width="500"
/>

### Eco Mode
- Strong fuel consumption penalty  
- SOC deadband for smoother control  
- Prioritizes efficiency  

### Normal Mode
- Balanced fuel and SOC penalties  
- SOC regulated toward a target value  

### Sport Mode
- Reduced fuel penalty  
- SOC floor instead of target  
- Performance reward tied to acceleration  

Distinct behaviors emerged purely from reward design.

---

## Performance Results

PPO agents were evaluated using episode reward values and compared against fixed torque-split baselines (constant split). These rewards reflect the defined cost function (fuel usage, SOC behavior, and feasibility penalties), not direct real-world vehicle performance.

Based on reward values, the learned policies improved on the best fixed baselines for two of the three modes:

- Normal: -1914.99 (PPO) vs -2016.18 (best fixed baseline)  
- Eco: -3295.63 (PPO) vs -3342.69 (best fixed baseline)  
- Sport: -3230.79 (PPO), comparable to an engine-heavy baseline (split = 0.8) at -3189.2  

Generalization was evaluated across a Baseline, Urban, and Highway drive cycle. Across all cycles, consistent reward-driven behavior emerged: engine-dominant torque during acceleration and increased electric motor usage during steady cruising, resulting in gradual SOC decline.

#### Baseline Drive Cycle Results

Torque split behavior and power distribution for Eco, Normal, and Sport modes on the baseline drive cycle.

<img 
  src="https://github.com/user-attachments/assets/a1c0c0c0-36d6-405f-be61-0986bb5ae184"
  alt="Torque split over time on baseline drive cycle"
  width="600"
/>

<img 
  src="https://github.com/user-attachments/assets/55165459-7029-4c23-8fbd-6e4c1a3d9c93"
  alt="Engine and motor power distribution on baseline drive cycle"
  width="600"
/>

Mode separation was clearly reflected in reward-aligned trends. Eco minimized fuel-related reward penalties at the expense of deeper SOC usage, Sport accepted higher fuel penalties to preserve SOC during high-demand events, and Normal produced the most balanced fuel–SOC trade-off.

---

## Supervisory Mode Controller

A rule-based supervisory controller integrates the three PPO agents by selecting modes based on:
- Driver acceleration demand  
- Battery SOC  

Observed behavior included:
- Sport during aggressive acceleration  
- Normal during moderate demand  
- Eco during steady cruising  

This produced intuitive, human-like mode transitions without manual input.

---

## Generalization Across Drive Cycles

Urban short and highway drive cycles used to test generalization beyond the training data.

<img 
  src="https://github.com/user-attachments/assets/386810a3-0afa-4517-8bd5-7c66bb0ed037"
  alt="Urban and highway drive cycle velocity profiles"
  width="600"
/>

### Highway Drive Cycle

Power distribution and SOC behavior across driving modes on the highway cycle.

<img 
  src="https://github.com/user-attachments/assets/49d8872d-5ee6-40ab-bfea-4cd9c04fad87"
  alt="Torque split on highway drive cycle"
  width="600"
/>

<img 
  src="https://github.com/user-attachments/assets/7cd96fcd-f784-47c3-98da-3218dc93a6f5"
  alt="Power distribution on highway drive cycle"
  width="600"
/>

### Urban Drive Cycle

Mode-dependent behavior under frequent stop-and-go conditions.

<img 
  src="https://github.com/user-attachments/assets/3b59ce1b-447e-48d9-b3c2-94395b17b89e"
  alt="Torque split on urban drive cycle"
  width="600"
/>

<img 
  src="https://github.com/user-attachments/assets/1bd655c4-ae53-4e36-8816-34ff6970c05e"
  alt="Power distribution on urban drive cycle"
  width="600"
/>

---

## Skills & Tools Applied

- Reinforcement Learning (PPO)  
- MATLAB & Simulink vehicle modeling  
- Hybrid powertrain simulation  
- Reward function design  
- Control systems analysis  
- Data analysis and visualization  
