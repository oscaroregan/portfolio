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

**Eco Mode**
- Strong fuel consumption penalty  
- SOC deadband for smoother control  
- Prioritizes efficiency  

**Normal Mode**
- Balanced fuel and SOC penalties  
- SOC regulated toward a target value  

**Sport Mode**
- Reduced fuel penalty  
- SOC floor instead of target  
- Performance reward tied to acceleration  

Distinct behaviors emerged purely from reward design.

---

## Performance Results

The PPO agents were evaluated against optimized fixed torque-split baselines.

**Results:**
- Eco and Normal modes outperformed their fixed baselines  
- Sport mode achieved comparable high-performance behavior  
- Controllers remained consistent across:
  - Baseline
  - Urban stop-and-go
  - Highway drive cycles  

Learned policies showed intuitive trends such as engine-dominant acceleration and increased electric cruising.

<!-- IMAGE PLACEHOLDER -->
<!-- Torque split plots -->
<!-- Power distribution plots -->
<!-- SOC plots -->

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

<!-- IMAGE PLACEHOLDER -->
<!-- Mode selection vs time plot -->

---

## Skills & Tools Applied

- Reinforcement Learning (PPO)  
- MATLAB & Simulink vehicle modeling  
- Hybrid powertrain simulation  
- Reward function design  
- Control systems analysis  
- Data analysis and visualization  


