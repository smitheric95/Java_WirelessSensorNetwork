import java.util.*;

/* Globals */
int graphSize = 500;
String mode = "disk";
int avgDegree = 128; //input from user
int n = 20; // number of vertices (nodes)
float rotX = 0; // rotation
float rotY = 0;
float zoom = 300;
float angle = 0; // rotation with keyboard
Vertex[] vertexDict = new Vertex[n]; // adjacency list of vertices and their neighbors
Integer[] degreeDict = new Integer[n]; // ordered by smallest degree last, array of indices in vertexDict

// first node is the vertex to color
LinkedList[] colorDict = new LinkedList[n];

// calculating four largest colors
HashMap<Integer, Integer> colorCount = new HashMap<Integer, Integer>();  // color : number of times it occurs
int[] largestColors;
int[][] colorCombos; // all possible combinations of the n most popular colors 

color[] colorArr = { 
    color(0,0,255), color(0,255,0), 
    color(255,0,0), color(255,255,0)
};

// logic for real time display
int nodeDrawCount = 0;
boolean nodesDrawn = false;
int lineDrawCount = 0;
int colorDrawCount = 0;
int time = 0;
boolean userDrawLines = false, userColorNodes = false;
//int color1 = 1, color2 = 2;
 
double r = 0; // calculated in calculateRadius

void setup() {
    size(900, 900, P3D); // set size of window
    
    /**************************** PART I *******************************/
    r = calculateRadius(); // calculate radius based off avgDegree
    
    /*
     * TESTING ONLY
     */ 
     r = 0.4;
     
    // build map of nodes
    for(int i = 0; i < n; i++) {  
        Vertex v = new Vertex(i);
        Random random = new Random();
        
        if (mode == "square") {
            v.positionX = random.nextFloat() - 0.5;
            v.positionY = random.nextFloat() - 0.5;
        }
        else if (mode == "disk") {
            // generate random points on a disk
            // http://stackoverflow.com/questions/5837572/generate-a-random-point-within-a-circle-uniformly
            float a = random.nextFloat();
            float b = random.nextFloat();
                
            // ensure a is greater by swapping
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
    
    // build adjacency list using sweep method
    sweepNodes();
    /************************** END PART I *****************************/
    
    /**************************** PART II *******************************/
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

    /***** generate colorDict *****/
    // start at the lowest degree 
    int degreeIndex = degreeDict.length - 1;
    while (degreeIndex > -1) {
        Vertex curVertex = vertexDict[degreeDict[degreeIndex]];
        
        // loop through each neighbor
        ListNode curNeighbor = curVertex.neighbors.front;
        while (curNeighbor != null) {
            int j = curNeighbor.ID; // index in vertexDict
            //if hasn't been deleted from vertexDict
            if (!vertexDict[j].deleted)
                colorDict[degreeIndex].append(curNeighbor.ID);
                
            curNeighbor = curNeighbor.next; 
        }
        
        //delete from vertexDict
        vertexDict[degreeDict[degreeIndex]].deleted = true;
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
    
    /***** Bipartite backbone selection *****/
    // sort the occurences of color
    colorCount = sortByValues(colorCount); 
    
    // determine the number of colors in colorCount (at most 4)
    int numLargestColors = colorCount.size();
    if (numLargestColors > 4)
        numLargestColors = 4;
    largestColors = new int[numLargestColors];
    
    // find the four (at most) largest colors - store in largestColors
    Set set = colorCount.entrySet();
    Iterator iterator = set.iterator();
    int itCount = 0;
    while (iterator.hasNext() && itCount < numLargestColors) {
        Map.Entry c = (Map.Entry)iterator.next();
        largestColors[itCount] = (int)c.getKey();
        // println(c.getKey() + ": " + c.getValue());
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
    
   
   
    //use BFS to draw nodes and edges
    println("------------------------------------------------");

    BFS(largestStarterNodes[0], -1, largestColorCombos[0][0], largestColorCombos[0][1]); //<>//
    //BFS(largestStarterNodes[1], -1, largestColorCombos[1][0], largestColorCombos[1][1]);
    
    println();
    println("------------------------------------------------");
    //print adjacency list
    print("Adjacency List: \n");
    for (int j = 0; j < n; j++)
        vertexDict[j].printVertex();
    println("------------------------------------------------");
    print("Degree List: \n");
    for (int j = 0; j < n; j++) 
        vertexDict[degreeDict[j]].printVertex();
    println("------------------------------------------------");
    println("Color Dict: ");
    for (int j = 0; j < n; j++) 
        colorDict[j].printList();
    println("------------------------------------------------");
    println("Largest colors: ");
    for (int j = 0; j < largestColors.length; j++) println(largestColors[j]);
    println("------------------------------------------------");
    println("Color Combos: ");
    for (int k = 0; k < colorCombos.length; k++) {
        for (int l = 0; l < colorCombos[k].length; l++) {
            print(colorCombos[k][l] + " ");
        }
        println();
    }
     
     // BUG!
    println("1st Largest subgraph starts at: " + largestStarterNodes[0] + " with a size of: " + largestSizes[0] + " and of color combo of " + largestColorCombos[0][0] + ", " + largestColorCombos[0][1]); 
    println("2nd Largest subgraph starts at: " + largestStarterNodes[1] + " with a size of: " + largestSizes[1] + " and of color combo of " + largestColorCombos[1][0] + ", " + largestColorCombos[1][1]);
}

void draw() {
    // put matrix in center
    pushMatrix();
    translate(width/2, height/2);
    scale(zoom);
    rotate(angle);
    noFill();
    background(0);
    stroke(255);
    
    // rotate matrix based off mouse movement
    rotateX(rotX);
    rotateY(rotY);       
    
    // delay drawing
    // source: https://forum.processing.org/one/topic/how-do-you-make-a-program-wait-for-one-or-two-seconds.html
    if (millis() > time){
        time = millis() + 50;
        if (nodeDrawCount < n) // replace with press space!
            nodeDrawCount++;
        else if (userDrawLines){ 
            nodesDrawn = true;
            lineDrawCount++;
            if (userColorNodes)
                colorDrawCount++;
        }
    }
    
    int linesDrawn = lineDrawCount;
    int colorsDrawn = colorDrawCount;
    // draw nodes
    for (int i = 0; i < nodeDrawCount; i++) {
        Vertex curVertex = vertexDict[i];
        
        //if (curVertex.toDraw) {
            // find appropriate color
            int j;
            for (j = 0; j < largestColors.length; j++)
                if (largestColors[j] == curVertex.nodeColor) break;
            if (j < 4 && colorsDrawn > 0) {
                stroke(colorArr[j]);
            }
            colorsDrawn--;
            
            // set color based off... well, color
            
            curVertex.drawVertex(); // draw!
        //}
        
        // draw line between vertex and its neighbors
        
        if (nodesDrawn && linesDrawn > 0) {
            ListNode curNeighbor = curVertex.neighbors.front;
            stroke(255);
            strokeWeight(0.005);
            
            while (curNeighbor != null) {
                int index = curNeighbor.ID;
                //if (curVertex.toDraw && vertexDict[curNeighbor.ID].toDraw)
                   line(curVertex.positionX, curVertex.positionY, curVertex.positionZ, vertexDict[index].positionX, vertexDict[index].positionY, vertexDict[index].positionZ);
                 
                curNeighbor = curNeighbor.getNext();
            }
            linesDrawn--;  
        }
    }
       
    popMatrix();
}

// build vertexDict using sweep method
void sweepNodes() {
    long startTime = System.nanoTime();

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
        while ((j >= 0) && (vertexDict[degreeDict[i]].positionX - vertexDict[degreeDict[j]].positionX <= r)) {
            // calculate distance based off topology
            if (dist(vertexDict[degreeDict[i]].positionX, vertexDict[degreeDict[i]].positionY, vertexDict[degreeDict[i]].positionZ, 
                     vertexDict[degreeDict[j]].positionX, vertexDict[degreeDict[j]].positionY, vertexDict[degreeDict[j]].positionZ) <= r) {
                    
                    // add both to each other's linked lists
                    vertexDict[degreeDict[i]].neighbors.add(vertexDict[degreeDict[j]].ID);                       
                    vertexDict[degreeDict[j]].neighbors.add(vertexDict[degreeDict[i]].ID);
            }  
            
            j -= 1;
            
        } // end while
    } // end for
    
    // calculate time it took
    long endTime = System.nanoTime();
    println(((endTime - startTime)/1000000) + " ms to build adj list");  
}             
// returns radius of a point based average degree
// check video to see if accurate
double calculateRadius() {
    if (mode == "square") {
        return Math.sqrt( (avgDegree*1.0/(n*Math.PI)) );
    }
    else if (mode == "disk") {
        return Math.sqrt( avgDegree*1.0/n );
    }
    else { 
        return Math.sqrt( 4*avgDegree*1.0/n );
    }
}

// prints BFS traversal on an adjacency list
// edited from source: http://www.geeksforgeeks.org/breadth-first-traversal-for-a-graph/
// colorCombo == -1 if the node is too be drawn
int BFS(int v, int colorCombo, int c1, int c2) {
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
            if (((colorCombo > -1 && !vertexDict[curNode.ID].visited[colorCombo]) || colorCombo < 0 && !vertexDict[curNode.ID].visitedWhileDrawn) && (vertexDict[curNode.ID].nodeColor == c1 || vertexDict[curNode.ID].nodeColor == c2)) { //<>//
                // mark the node as visited
                if (colorCombo > -1)
                    vertexDict[curNode.ID].visited[colorCombo] = true;
                
                // draw the node if necessary
                else {
                    vertexDict[curNode.ID].visitedWhileDrawn = true;
                    vertexDict[curNode.ID].toDraw = true;
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
public static double choose(int x, int y) {
    if (y < 0 || y > x) return 0;
    if (y > x/2) {
        // choose(n,k) == choose(n,n-k), 
        // so this could save a little effort
        y = x - y;
    }

    double denominator = 1.0, numerator = 1.0;
    for (int i = 1; i <= y; i++) {
        denominator *= i;
        numerator *= (x + 1 - i);
    }
    return numerator / denominator;
}

void mouseDragged() {
    rotX += (pmouseY-mouseY) * 0.1;
    rotY += -1 * (pmouseX-mouseX) * 0.1;
}

void keyPressed() {
    // https://forum.processing.org/two/discussion/2151/zoom-in-and-out
    if (keyCode == UP) {
        zoom += 10;
    }
    else if (keyCode == DOWN) {
        zoom -= 10;
    }
    else if (keyCode == RIGHT) {
        angle += .03;
    }
    else if (keyCode == LEFT) {
        angle -= .03;
    }
    if (key == 32) { // space
        angle = rotX = rotY = 0;
        zoom = 300;
        
        if (userDrawLines)
            userColorNodes = true;
        else
            userDrawLines = true;
    }
}
    