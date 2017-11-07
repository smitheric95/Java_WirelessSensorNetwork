import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Java_WirelessSensorNetwork extends PApplet {



/******* INPUT ********/
int avgDegree = 32; 
String mode = "sphere"; // options: square, disk, sphere
int n = 1001; // number of vertices (nodes)
/**********************/

/* Globals */
double R = 0; // calculated in calculateRadius
int graphSize = 500;
int totalDeg = 0; // for real avg degree
int maxDegDeleted = -1;
int numEdges = 0;
float rotX = 0; // rotation
float rotY = 0;
float zoom = 300;
float angle = 0; // rotation with keyboard
Vertex[] vertexDict = new Vertex[n]; // adjacency list of vertices and their neighbors
Integer[] degreeDict = new Integer[n]; // ordered by smallest degree last, array of indices in vertexDict
int numNotDeleted = n, terminalCliqueSize = 0; // calculating terminal clique  
float nodeStrokeWeight = 0.0f, edgeStrokeWeight = 0.0f;

// output files for creating graphs as needed
PrintWriter outputSequential, outputDistribution;

// first node is the vertex to color
LinkedList[] colorDict = new LinkedList[n];

// calculating four largest colors
HashMap<Integer, Integer> colorCount = new HashMap<Integer, Integer>();  // color : number of times it occurs
int[] largestColors;
int[][] colorCombos; // all possible combinations of the n most popular colors 

// NOTE: not always "color i"
int[] largestColorRGBs = { 
    // blue, green, yellow, red
    color(0, 0, 255), color(0, 255, 0), color(255,255,0), color(255, 0, 0), 
};

// logic for real time display
int nodeDrawCount = 0;
boolean nodesDrawn = false;
int lineDrawCount = 0;
int colorDrawCount = 0;
int time = 0;
boolean userDrawLines = false, 
        userColorNodes = false, 
        userDrawFirstComponent = false, 
        userDrawSecondComponent = false,
        firstComponentDrawn = false,
        cliqueDetermined = false;

public void setup() {
    long startTime = System.nanoTime();
    
     // set size of window
    surface.setTitle("Drawing Vertices...");
    
    // create output file
    outputSequential = createWriter("output/outputSequential_" + n + "_" + avgDegree + "_" + mode + ".csv");
    outputDistribution = createWriter("output/outputDistribution_" + n + "_" + avgDegree + "_" + mode + ".csv");
    
    /**************************** PART I *******************************/
    
    // build map of nodes
    for(int i = 0; i < n; i++) {  
        Vertex v = new Vertex(i);
        Random random = new Random();
        
        if (mode == "square") {
            v.positionX = random.nextFloat() - 0.5f;
            v.positionY = random.nextFloat() - 0.5f;
        }
        else if (mode == "disk") {
            // generate random points on a disk
            // http://stackoverflow.com/a/5838991
            float a = random.nextFloat();
            float b = random.nextFloat();
                
            // ensure b is greater by swapping
            if (b < a) { float temp = b; b = a; a = temp; }
            
            fill(204, 102, 0);
            
            v.positionX = (float)(b*Math.cos(2*Math.PI*a/b));
            v.positionY = (float)(b*Math.sin(2*Math.PI*a/b));
        }
        else { // sphere
            // generate random points on the surface of a sphere
            // http://corysimon.github.io/articles/uniformdistn-on-sphere/
            float theta = (float)(2 * Math.PI * random.nextFloat());
            float phi = (float)(Math.acos(2 * random.nextFloat() - 1));
            v.positionX = sin(phi) * cos(theta);
            v.positionY = sin(phi) * sin(theta);
            v.positionZ = cos(phi);
        }
        
        vertexDict[i] = v;
        degreeDict[i] = i;
    }// end build map
    
    R = calculateRadius(); // calculate radius based off avgDegree
    
    // build vertexDict using sweep method
    // sort degreeDict, which currently is an array of IDs in vertexDict, based on X positions
    // to be sorted by another comparison later on
    Arrays.sort(degreeDict, new Comparator<Integer>() {
        public int compare(Integer v1, Integer v2) {
            return Float.compare(vertexDict[v1].positionX, vertexDict[v2].positionX);
        }
    });
   
    // go through each vertex
    for (int i = 0; i < n; i++) {
        int j = i-1;
        
        // if the vertex to left is within range, calculate distance
        while ((j >= 0) && (vertexDict[degreeDict[i]].positionX - vertexDict[degreeDict[j]].positionX <= R)) {
            // calculate distance based off topology
            if (dist(vertexDict[degreeDict[i]].positionX, vertexDict[degreeDict[i]].positionY, vertexDict[degreeDict[i]].positionZ, 
                     vertexDict[degreeDict[j]].positionX, vertexDict[degreeDict[j]].positionY, vertexDict[degreeDict[j]].positionZ) <= R) {
                    
                    // add both to each other's linked lists
                    vertexDict[degreeDict[i]].neighbors.add(vertexDict[degreeDict[j]].ID);                       
                    vertexDict[degreeDict[j]].neighbors.add(vertexDict[degreeDict[i]].ID);
                    
                    numEdges++;
            }  
            
            j -= 1;
            
        } // end while
    } // end for
    /* end sweep method */
    
    // calculate time part 2 took
    long endTime = System.nanoTime();
    println(((endTime - startTime)/1000000) + " ms to build adj list");  
    
    /************************** END PART I *****************************/
    
    
    /**************************** PART II *******************************/
    startTime = System.nanoTime(); // reset our time counter
    
    // smallest last vertex ordering    
    Arrays.sort(degreeDict, new Comparator<Integer>() {
        public int compare(Integer v1, Integer v2) {
            return -1 * Float.compare(vertexDict[v1].neighbors.getSize(), vertexDict[v2].neighbors.getSize());
        }
    });
    
    // initialize colorDict with sorted indices in degreeDict
    for (int i = 0; i < n; i++) {
        colorDict[i] = new LinkedList();
        colorDict[i].add(degreeDict[i]); // first node will be base of colorDict
    }

    
    outputSequential.println("Original Degree, Degree when Deleted");
    
    /***** generate colorDict *****/
    // start at the lowest degree 
    int degreeIndex = degreeDict.length - 1;
    while (degreeIndex > -1) {
        Vertex curVertex = vertexDict[degreeDict[degreeIndex]];
        totalDeg += curVertex.neighbors.getSize();
        int curDegree = 0;
        
        // loop through each neighbor
        ListNode curNeighbor = curVertex.neighbors.front;
        while (curNeighbor != null) {
            int j = curNeighbor.ID; // index in vertexDict
            //if hasn't been deleted from vertexDict
            if (!vertexDict[j].deleted) {
                colorDict[degreeIndex].append(curNeighbor.ID);
                curDegree++;
            }
            curNeighbor = curNeighbor.next; 
        }
        
        //delete from vertexDict
        vertexDict[degreeDict[degreeIndex]].deleted = true;
        numNotDeleted--;
        
        // determine terminal clique
        // source: http://stackoverflow.com/a/30106072
        if (!cliqueDetermined) {
            int cliqueCount = 0;
            // for each node in the adjacency list (that hasn't been deleted)
            for (int j = 0; j < vertexDict.length; j++) {
                if (!vertexDict[j].deleted) {
                    // loop through each neighbor
                    int remainingNeighbors = 0;
                    ListNode curNode = vertexDict[j].neighbors.front;
                    while (curNode != null) {
                        // count the ones that haven't been deleted
                        if (!vertexDict[curNode.ID].deleted)
                            remainingNeighbors++;
                        curNode = curNode.next;
                    }
                    // if the number of remaining neighbors == numNotDeleted-1 distict vertices (candidate for clique)
                    if (remainingNeighbors == numNotDeleted - 1) 
                        cliqueCount++;
                    else break;
                }
            }
            if (cliqueCount == numNotDeleted && numNotDeleted != 0) {
                // we have a clique, ladies and gentlemen!
                terminalCliqueSize = numNotDeleted;
                cliqueDetermined = true;
            }
        }
        
        // print original degree vs degree when deleted
        outputSequential.println(curVertex.neighbors.size + "," + curDegree);
        if (curDegree > maxDegDeleted)
            maxDegDeleted = curDegree;
        
        degreeIndex--;
    }
    /*** colorDict generated ***/
    
    // set first vertex.color = 1
    vertexDict[colorDict[0].front.ID].nodeColor = 1;
    colorCount.put(1, 1);
    
    // starting at 1, color all other nodes in colorDict
    for (int i = 1; i < colorDict.length; i++) {
        // make an array of the nodes' linkedlist size-1
        int[] colorList = new int[ colorDict[i].size - 1 ];
           
        // initialize array
        int count = 0;
        ListNode curNode = colorDict[i].front.next; 
        while (curNode != null) {
            colorList[count] = vertexDict[curNode.ID].nodeColor;
            curNode = curNode.next;
            count++;
        }
               
        // find the smallest positive color
        int curColor = firstMissingPositive(colorList);
        
        // color the vertex
        vertexDict[colorDict[i].front.ID].nodeColor = curColor;
        
        // increment the count of the corresponding color
        Integer freq = colorCount.get(curColor);
        colorCount.put(curColor, (freq == null) ? 1 : freq +1);
    }
    // calculate time part 2 took
    endTime = System.nanoTime();
    println(((endTime - startTime)/1000000) + " ms to color nodes");  
    
    /**************************** PART III *******************************/
    /***** Bipartite backbone selection *****/
    // sort the occurences of color
    colorCount = sortByValues(colorCount); 
    
    // determine the number of colors in colorCount (at most 4)
    int numLargestColors = colorCount.size();
    if (numLargestColors > 4)
        numLargestColors = 4;
    largestColors = new int[numLargestColors];
    
    // find the four (at most) largest colors - store in largestColors
    // print color distribution to output file
    outputDistribution.println("Color Number, Percentage of Distribution");
    Set set = colorCount.entrySet();
    Iterator iterator = set.iterator();
    int itCount = 0;
    while (iterator.hasNext()) {
        Map.Entry c = (Map.Entry)iterator.next();
        if (itCount < numLargestColors)
            largestColors[itCount] = (int)c.getKey();
        
        // ouput color and the number of times it occurs
        outputDistribution.println(c.getKey() + "," + ((int)c.getValue() * 1.0f / n));
        itCount++;
    }
    
    // initialize colorCombos to have all possible cominations of the (at most)
    // four most common colors: AB, AC, AD, BC, BD, CD
    int numCombos = (int)choose(numLargestColors, 2);
    colorCombos = new int[numCombos][2]; // r = itCount nCr 2
    
    // calculate the different combinations (nCr)
    int r = 0, c1 = 0;
    while (c1 < numLargestColors-1) {
        int c2 = c1+1;
        while (c2 < numLargestColors) {
            colorCombos[r][0] = largestColors[c1];
            colorCombos[r][1] = largestColors[c2];
            c2++;
            r++;
        }
        c1++;
    }
    
    // try all combinations to find two largest backbones
    // first and second largest sizes and their starting nodes
    int[] largestStarterNodes = new int[2], largestSizes = new int[2];
    int[][] largestColorCombos = new int[2][2]; // the color comination of the two largest backbones

    
    // for each color combination, calculate the backbone 
    // (largest connected component of each bipartite subgraph)
    for (int j = 0; j < numCombos; j++) {
        int curColor1 = colorCombos[j][0];
        int curColor2 = colorCombos[j][1];
         // size of the bipartite subgraph = sizes of the two current colors 
        int bipartiteSize = colorCount.get(curColor1) + colorCount.get(curColor2);
        int numNodesVisited = 0;
        
        while (numNodesVisited < bipartiteSize) {
            // pick the node that will be the starting point of the BFS
            // (first node in vertexDict that's of color1 or 2 that hasn't been visited
            int curStarterNode = 0;
            while (curStarterNode < vertexDict.length && (vertexDict[curStarterNode].visited[j] ||
                   vertexDict[curStarterNode].nodeColor != curColor1 &&
                   vertexDict[curStarterNode].nodeColor != curColor2)) 
                       curStarterNode++;
            
            // nodes visited in the traversal
            int curSize = BFS(curStarterNode, j, curColor1, curColor2);

            // if curSize is the largest so far, remember starting node and largest size
            if (curSize > largestSizes[0]) {
                // store the previous largest as the second largest
                largestSizes[1] = largestSizes[0];
                largestStarterNodes[1] = largestStarterNodes[0];
                largestColorCombos[1][0] = largestColorCombos[0][0];
                largestColorCombos[1][1] = largestColorCombos[0][1];
                
                largestSizes[0] = curSize;
                largestStarterNodes[0] = curStarterNode;
                largestColorCombos[0][0] = curColor1;
                largestColorCombos[0][1] = curColor2;
            }
            else if(curSize > largestSizes[1]) {
                largestSizes[1] = curSize;
                largestStarterNodes[1] = curStarterNode;
                largestColorCombos[1][0] = curColor1;
                largestColorCombos[1][1] = curColor2;
            }
            
            // reduce the remaining nodes to visit
            numNodesVisited += curSize;
        }
    }
    // calculate time part 3 took
    endTime = System.nanoTime();
    println(((endTime - startTime)/1000000) + " ms to find backbones");  
    
    // exist for drawing only
    BFS(largestStarterNodes[0], -1, largestColorCombos[0][0], largestColorCombos[0][1]);
    BFS(largestStarterNodes[1], -2, largestColorCombos[1][0], largestColorCombos[1][1]);

    /********** Logic for Summary Table ************/
    int minDeg = vertexDict[degreeDict[degreeDict.length-1]].neighbors.getSize();
    int maxDeg = vertexDict[0].neighbors.getSize();
    
    // println("----------------- Summary Table ----------------");
    // N, R, M (numEdges), min degree, avg degree, real avg degree, max degree,
    // max degree when deleted, number of colors, size of largest color class
    // terminal clique size, n of largest backbone, m of largest backbone, domination percentage
    
    //println(n, R, numEdges, minDeg, avgDegree, totalDeg/n, maxDeg);
    //println(maxDegDeleted, colorCount.size(), largestSizes[0], terminalCliqueSize, largestSizes[0], largestSizes[0] - 1, (largestSizes[0]*1.0)/n);
    //println("------------------------------------------------");
    
    println(); 
    println("1st Largest subgraph starts at: " + largestStarterNodes[0] + " with a size of: " + largestSizes[0] + " and of color combo of " + largestColorCombos[0][0] + ", " + largestColorCombos[0][1]); 
    println("2nd Largest subgraph starts at: " + largestStarterNodes[1] + " with a size of: " + largestSizes[1] + " and of color combo of " + largestColorCombos[1][0] + ", " + largestColorCombos[1][1]);
    
    // close output files
    outputSequential.flush(); 
    outputSequential.close(); 
    outputDistribution.flush(); 
    outputDistribution.close(); 
}

public void draw() {
    // put matrix in center
    pushMatrix();
    translate(width/2, height/2);
    scale(zoom);
    rotate(angle);
    noFill();
    background(0);
    
    // rotate matrix based off mouse movement
    rotateX(rotX);
    rotateY(rotY);       
    
    // delay drawing
    // source: https://forum.processing.org/one/topic/how-do-you-make-a-program-wait-for-one-or-two-seconds.html
    if (millis() > time){
        if (!firstComponentDrawn)
            time = millis() + 1;
        if (nodeDrawCount < n)
            nodeDrawCount++;
        else if (userDrawLines){ 
            nodesDrawn = true;
            if (n > 20)
                lineDrawCount += n/20;
            else lineDrawCount = 20;
            if (userColorNodes)
                if (n > 20)
                    colorDrawCount += n/20;
                else colorDrawCount = 20; 
            if (userDrawFirstComponent && !firstComponentDrawn) {
                firstComponentDrawn = true;
                nodeDrawCount = n;   
            }
        }
    }
    
    // count what's been drawn
    int linesDrawn = lineDrawCount;
    int colorsDrawn = colorDrawCount;
    
    // calculate stroke weight depending on graph type and size
    nodeStrokeWeight = 0.03f;
    edgeStrokeWeight = 0.005f;
    if ((!userDrawFirstComponent && !userDrawSecondComponent)) {
        if (n > 1000) {
            nodeStrokeWeight = 0.02f;
            edgeStrokeWeight = 0.001f;
        }
        else if (n > 10000) {
            nodeStrokeWeight = 0.0001f;
            edgeStrokeWeight = 0.00001f;
        }
    }
    if (mode == "square") {
        nodeStrokeWeight /= 2;
        edgeStrokeWeight /= 2;
    }

    // draw nodes
    for (int i = 0; i < nodeDrawCount; i++) {
        stroke(255);
        strokeWeight(nodeStrokeWeight);
        
        Vertex curVertex = vertexDict[i];
        
        if ((!userDrawFirstComponent && !userDrawSecondComponent) || (userDrawFirstComponent && curVertex.toDraw[0]) || (userDrawSecondComponent && curVertex.toDraw[1])) {
            // find appropriate color 
            int j;
            for (j = 0; j < largestColors.length; j++)
                if (largestColors[j] == curVertex.nodeColor) break;
            
            if (j < largestColors.length && (colorsDrawn > 0 || userDrawFirstComponent || userDrawSecondComponent)) {
                // set color based off... well, color
                stroke(largestColorRGBs[j]);
            }
            else if (userColorNodes) stroke((curVertex.nodeColor*50)%255, (curVertex.nodeColor*20)%255,(curVertex.nodeColor*70)%255);
            colorsDrawn--;
            curVertex.drawVertex(); // draw!
        }
        
        stroke(0, 255, 255);
        strokeWeight(edgeStrokeWeight);
        // draw line between vertex and its neighbors
        if (userDrawFirstComponent || userDrawSecondComponent || nodesDrawn && (linesDrawn > 0)) {
            ListNode curNeighbor = curVertex.neighbors.front;
            
            while (curNeighbor != null) {
                int index = curNeighbor.ID;
                if ((!userDrawFirstComponent && !userDrawSecondComponent) || (userDrawFirstComponent && curVertex.toDraw[0] && vertexDict[curNeighbor.ID].toDraw[0]) || (userDrawSecondComponent && curVertex.toDraw[1] && vertexDict[curNeighbor.ID].toDraw[1]))
                    line(curVertex.positionX, curVertex.positionY, curVertex.positionZ, vertexDict[index].positionX, vertexDict[index].positionY, vertexDict[index].positionZ);
                curNeighbor = curNeighbor.getNext();
            }
            linesDrawn--;  
        }
    }
    //println("userDrawFirstComponent: " + userDrawFirstComponent + ", " + "userDrawSecondComponent: " + userDrawSecondComponent);

    popMatrix();
} // end draw()
            
// returns radius of a point based average degree
// check video to see if accurate
public double calculateRadius() {
    if (mode == "square") {
        return Math.sqrt( (avgDegree*1.0f/(n*Math.PI)) );
    }
    else if (mode == "disk") {
        return Math.sqrt( avgDegree*1.0f/n );
    }
    else { 
        return Math.sqrt( 4*avgDegree*1.0f/n );
    }
}

// prints BFS traversal on an adjacency list
// edited from source: http://www.geeksforgeeks.org/breadth-first-traversal-for-a-graph/
// colorCombo == -1 if the node is to be drawn (part of the 1st largest componenent)
// colorCombo == -2 if the node is to be drawn (part of the 2nd largest componenent)
public int BFS(int v, int colorCombo, int c1, int c2) {
    java.util.LinkedList<Integer> queue = new java.util.LinkedList<Integer>(); 
    int count = 0; // number of nodes visited
    
    // mark the current node as visited and enqueue it
    if (colorCombo > -1)
        vertexDict[v].visited[colorCombo] = true;
    queue.add(v);
    
    while (queue.size() != 0) {
        // Dequeue a vertex from queue and print it
        v = queue.poll();
        
        /* Get all adjacent vertices of the dequeued vertex s
        If a adjacent has not been visited, then mark it
        visited and enqueue it */
        ListNode curNode = vertexDict[v].neighbors.front; 
        while (curNode != null) {
            // if the node hasn't been visited (or it needs to be drawn) 
            // and it's the right color, mark it visited
            if (((colorCombo > -1 && !vertexDict[curNode.ID].visited[colorCombo]) || ((colorCombo == -1 && !vertexDict[curNode.ID].visitedWhileDrawn[0]) || (colorCombo == -2 && !vertexDict[curNode.ID].visitedWhileDrawn[1]))) 
                && (vertexDict[curNode.ID].nodeColor == c1 || vertexDict[curNode.ID].nodeColor == c2)) {
                // mark the node as visited
                if (colorCombo > -1)
                    vertexDict[curNode.ID].visited[colorCombo] = true;
                
                // draw the node if necessary
                else {
                    // mark 
                    if (colorCombo == -1) {
                        vertexDict[curNode.ID].visitedWhileDrawn[0] = true;
                        vertexDict[curNode.ID].toDraw[0] = true;
                    }
                    else {
                        vertexDict[curNode.ID].visitedWhileDrawn[1] = true;
                        vertexDict[curNode.ID].toDraw[1] = true;
                    }
                }
                queue.add(curNode.ID);
                count++;
            }
            curNode = curNode.next;
        }
    }
    return count + 1;
}

// find the smallest missing element in a sorted array
// http://www.programcreek.com/2014/05/leetcode-first-missing-positive-java/
// this function was copied directly from its source
public int firstMissingPositive(int[] A) {
    int n = A.length;
 
    for (int i = 0; i < n; i++) {
        while (A[i] != i + 1) {
            if (A[i] <= 0 || A[i] >= n)
                break;
 
                if(A[i]==A[A[i]-1])
                        break;
 
            int temp = A[i];
            A[i] = A[temp - 1];
            A[temp - 1] = temp;
        }
    }
 
    for (int i = 0; i < n; i++){
        if (A[i] != i + 1){
            return i + 1;
        }
    }    
 
    return n + 1;
}

// sort HashMap by value
// source: http://beginnersbook.com/2013/12/how-to-sort-hashmap-in-java-by-keys-and-values/
// this function was copied directly from its source
private static HashMap sortByValues(HashMap map) { 
       List list = new java.util.LinkedList(map.entrySet());
       // Defined Custom Comparator here
       Collections.sort(list, new Comparator() {
            public int compare(Object o1, Object o2) {
               return -1 * ((Comparable) ((Map.Entry) (o1)).getValue())
                  .compareTo(((Map.Entry) (o2)).getValue());
            }
       });

       // Here I am copying the sorted list in HashMap
       // using LinkedHashMap to preserve the insertion order
       HashMap sortedHashMap = new LinkedHashMap();
       for (Iterator it = list.iterator(); it.hasNext();) {
              Map.Entry entry = (Map.Entry) it.next();
              sortedHashMap.put(entry.getKey(), entry.getValue());
       } 
       return sortedHashMap;
  }
  
// x choose y
// source: http://stackoverflow.com/a/1678715
// this function was copied directly from its source
public static double choose(int x, int y) {
    if (y < 0 || y > x) return 0;
    if (y > x/2) {
        // choose(n,k) == choose(n,n-k), 
        // so this could save a little effort
        y = x - y;
    }

    double denominator = 1.0f, numerator = 1.0f;
    for (int i = 1; i <= y; i++) {
        denominator *= i;
        numerator *= (x + 1 - i);
    }
    return numerator / denominator;
}

public void mouseDragged() {
    rotX += (pmouseY-mouseY) * 0.1f;
    rotY += -1 * (pmouseX-mouseX) * 0.1f;
}

public void keyPressed() {
    // https://forum.processing.org/two/discussion/2151/zoom-in-and-out
    if (keyCode == UP) {
        zoom += 20;
    }
    else if (keyCode == DOWN) {
        zoom -= 20;
    }
    else if (keyCode == RIGHT) {
        angle += .03f;
    }
    else if (keyCode == LEFT) {
        angle -= .03f;
    }
    if (key == 32) { // space
        if (userDrawSecondComponent) {
            userDrawSecondComponent = false;
            colorDrawCount = n;
            surface.setTitle("All Vertices and Edges");
        }
        else if (userDrawFirstComponent) {
            userDrawSecondComponent = true;
            userDrawFirstComponent = false;
            surface.setTitle("2nd Largest Component");
        }
        else if (userColorNodes) {
            userDrawFirstComponent = true;
            surface.setTitle("1st Largest Component");
        }
        else if (userDrawLines) {
            userColorNodes = true;
            surface.setTitle("Coloring");
        }
        else if (nodeDrawCount < n) {
            nodeDrawCount = n;
            surface.setTitle("All Vertices");
        }
        else {
            userDrawLines = true;
            surface.setTitle("All Vertices and Edges");
        }
    }
}
    
public class LinkedList {
    ListNode front;
    ListNode back;
	
    private int size;
    
    public LinkedList() {
        this.size = 0;
        this.front = null;
        this.back = null;
    }
    
    // add to front
    public void add(int ID) {
        ListNode node = new ListNode(ID);
        node.next = this.front;
        this.front = node;
        if (this.back == null)
            this.back = this.front;
            
        this.size++;
    }
    
    // add directly to back
    public void append(int ID) {
        ListNode node = new ListNode(ID);
        if (this.back != null)
            this.back.next = node;
            
        this.back = node;
        
        if (this.front == null) 
            this.front = node;
            
        this.size++;
    }
    
    public void printList() {
        ListNode cur = this.front;
        
        System.out.print("    ");
        while (cur != null) {
            System.out.print("[" + cur.ID + "]->");
            cur = cur.getNext();
        }
        System.out.println("X\n");
    }
    
    // delete from list and return whether it got delted 
    public boolean delete(int ID) {
        // empty list
        if (this.size == 0) 
            return false;

        ListNode cur = this.front;
        
        // delete head
        if (cur.ID == ID) {
            this.front = cur.next;
        }
        
        // loop till we find node with the right ID
        while (cur.next != null) {
            if (cur.next.ID == ID) {
                cur.next = cur.next.next; // delete
                return true;
            }
            cur = cur.next;
        }
        
        // node not found
        return false;
    }
    
    public ListNode getFront() {
        return this.front;
    }
    
    public int getSize() {
        return this.size;
    }
}
public class ListNode {
    int ID; // index in vertexDict 
    ListNode next;
    
    public ListNode(int ID) {
        this.ID = ID;
        this.next = null;
    }
    
    public ListNode getNext() {
        return this.next;
    }
   
}
public class Vertex {
    int ID;
    float positionX;
    float positionY;
    float positionZ;
    LinkedList neighbors;
    private boolean sortByDegree;
    boolean deleted; // pseudo deleted for coloring
    int nodeColor;
    boolean[] visited; // for calculating largest backbone (index for each color combo)
    boolean[] visitedWhileDrawn;
    boolean[] toDraw; // whether or not to draw the vertex
    
    public Vertex(int ID) {
        this.ID = ID;   
        this.positionX = 0;
        this.positionY = 0;
        this.positionZ = 0;
        this.sortByDegree = false;
        this.neighbors = new LinkedList();
        this.deleted = false;
        this.nodeColor = 0;
        this.visited = new boolean[6];
        this.toDraw = new boolean[2];
        this.visitedWhileDrawn = new boolean[2];    
    }
    
    public int getNumNeighbors() {
        return this.neighbors.size;
    }
    
    public void drawVertex() {
        //strokeWeight(0.05);
        point(this.positionX, this.positionY, this.positionZ);
    }
    
    public void printVertex() {
        System.out.println("[" + this.ID + " (" + this.toString().substring(33, this.toString().length()) + ")]: " + this.positionX + ", " + this.positionY + ", " + this.positionZ + " Color: " + this.nodeColor);
        this.neighbors.printList();
    }
}
    public void settings() {  size(840, 840, P3D);  smooth(); }
    static public void main(String[] passedArgs) {
        String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--stop-color=#cccccc", "Java_WirelessSensorNetwork" };
        if (passedArgs != null) {
          PApplet.main(concat(appletArgs, passedArgs));
        } else {
          PApplet.main(appletArgs);
        }
    }
}
