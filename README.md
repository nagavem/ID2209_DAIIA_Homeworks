# ID2209_DAIIA_Homeworks

Collection of the homework assignments for the course ID2209 Distributed Artificial Intelligence and Intelligent Agents. Course taken as a part of the masters program in Software Engineering of Distributed Systems.

# How to run

The following are the guidelines for homework 1 but can be used as a general guideline for running the simulation for all homework problems.
Run Gama 1.8 and import Festival.gaml,Festival_Challenge.gaml and Festival_Creative.gaml as new projects. Press main to run the simulation for the same and use the slider to vary the speed of the simulation.


## Homework 1

In this assignment the objective is to get an introduction to the GAMA programming language and do our first implementation which is simulating a festival experience with guests, information centers and some stores for food and drinks. We get introduced to different types of actors/agents and learn about their movements and behaviours.

## Homework 2

This assignment is a continuation of the previous one. It focusses on the FIPA communication protocol that is used for communication between agents. A new type of agent called auctioneer is added to the simulation and the guests at the festival have to interact with them using FIPA. The type of auction to be carried out is the Dutch Auction.

## Homework 3

Consists of 2 tasks:

### Task 1

The first task in this assignment is a solution to the N queens problem using the gama environment , what we try to do here is essentially create a NxN size chessboard consisting of N queens on it. The rules have been provided and we must provide multiple arrangements based on the value of N.

### Task 2

For the second task similar to assignments 1 and 2 this assignment is based in the festival setting with the addition of stages where the performers play and guests travel to stages based on their affinity to the act that is playing. This is computed using a variable called utility.Guests communicate with the stages present through FIPA to know the individual attribute values. For the challenge we are required to develop an algorithm to calculate the utilities of all agents and find a way to increase the global utility as a whole by making some adjustments in their personal preferences.

## Final Project

The final project is for adding beliefs, desires and intentions to the agents present at the festival and for this the FIPA protocol has been used. 
The Main purpose of this project is to simulate a festival with different types of guests wherein we get to observe their interactions and behaviour as a result of their traits and personality values. When different agents meet in such a manner what would be the expected outcome? That is one of the prime questions we are trying to answer . In addition to their traits even the location where the agents meet can influence how they behave in the situation.
