#Tow Boogie

A Tow Boogie is a remotely operated personal watercraft designed to tow a rider while foiling — combining elements of power, control, and efficiency in a compact form. My Tow Boogie is the result of extensive design, prototyping, and testing aimed at creating a reliable solo towing system for foil sessions without the need for a boat or partner.

The project brings together mechanical, electrical, and control systems engineering into one integrated platform. Every component — from propulsion to electronics to structural design — has been carefully developed and refined through continuous experimentation and iteration.

Propulsion System

My Tow Boogie is powered by two Flipsky 6384 brushless motors, each capable of delivering up to 4400 W peak power. These motors are controlled by Flipsky 75100 VESCs, providing precise throttle response and differntial steering.

To maintain continuous operation at high currents, I designed a custom water-cooling system using a 15mm aluminum water cooling block and 8 mm inner-diameter tubing. The 3D-printed ASA motor pods feature integrated channels for wiring and water intake, using the board’s forward velocity to circulate cooling water effectively.

Power System

My Tow Boogie runs on a 14s10P lithium-ion battery pack built from LG M50LT cells. These cells were chosen for their excellent efficiency and thermal stability at low to moderate current levels. The pack includes a battery management system (BMS) for monitoring voltage, temperature, and balancing, ensuring safe and reliable operation.

Controller System

To control my Tow Boogie, I designed a custom handheld controller built around the Heltec WiFi LoRa 32 (V3) microcontroller unit. Communication between the controller and board is handled via LoRa, providing excellent long-range, low-latency performance even over open water.

The throttle and steering inputs are measured using magnetic rotary encoders, giving precise and drift-free control. For the steering mechanism, I drew inspiration from _Ludwig Bre’s_ helical spring design, integrating a torsional spring system that offers smooth, centered steering feedback and durability.

This controller system has demonstrated excellent range and responsiveness during testing and has been fully integrated into the board’s VESC communication network.

Fabrication & Enclosure

All electronics in my Tow Boogie are housed within a Pelican 1500 case, chosen for its waterproof and impact-resistant construction. I incorporated custom connectors by _Hang Loose_ to link the internal VESCs with the external motor pods, allowing for quick disconnection and maintenance.

Board

The propulsion system of my Tow Boogie is mounted to a Catch Surf Stump surfboard, offering a balance of buuverability, and compactness. Its stability makes it ideal for towing and foiling applications.oyancy, mane

Project Overview

From CAD modeling and 3D printing to embedded programming and battery assembly, this project pushed me to combine theory with hands-on engineering practice.

