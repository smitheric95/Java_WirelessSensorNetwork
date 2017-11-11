# Wireless Sensor Network Simulator

This simulation is able to distribute nodes on the surfaces of multiple shapes - representing different network topologies.

![Drawing Vertices](Screenshots/1.png)

It can even connect these nodes given some calculated distance.

![Connecting nodes](Screenshots/2.png)

From there, the program has the ability to “color” each node based off its neighbors.

![Coloring](Screenshots/3.png)

Finally, the program can display the two largest backbones of the graph, i.e. the structures that connect the largest amount of nodes on the network.

![First Largest Bipartite](Screenshots/4.png)
![Second Largest Bipartite](Screenshots/5.png)

The program supports spheres, disks, and squares.

![Disk](Screenshots/6.png)
![Square](Screenshots/7.png)

For a more detailed explanation of this program including performance statistics and a reduction to practice, please see Smith_WSN.pdf.
Please read it. It took me forever to write.

## How to Run:

Navigate to the Executables/ folder and then to the correct application folder for your operating system and run the executable!

## Controls:
* Press space to navigate through the different steps.
* Up/down arrows to zoom
* Mouse to drag 

## Changing variables:

If you would like to change the type of graph being displayed, you may do so on lines 4-6 of Java-WirelessSensorNetwork.pde

Please see "How to Compile" below.

## How to Compile:
1. Download [Processing 3](https://processing.org/download/) 
2. Open Java_WirelessSensorNetwork.pde
3. Click run :)

..

