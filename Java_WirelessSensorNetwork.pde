import java.util.*;

/* Globals */
int graphSize = 500;
String mode = "sphere";
int avgDegree = 2; //input form user
int n = 5; // number of vertices (nodes)
float rotX = 0; // rotation
float rotY = 0;
float zoom = 300;
float angle = 0; // rotation with keyboard
Vertex[] vertexDict = new Vertex[n]; // adjacency list of vertices and their neighbors
Integer[] degreeDict = new Integer[n];
// ordered by smallest degree last, linked list of indices in vertexDict

// first node is the vertex to color
LinkedList[] colorDict = new LinkedList[n];

// calculating four largest colors
HashMap<Integer, Integer> colorCount = new HashMap<Integer, Integer>();  // color : number of times it occurs
int[] largestColors;
int[][] colorCombos; // all possible combinations of the n most popular colors 

color [] colorArr = { 
    color(255,0,0), color(0,255,0), color(0,0,255),
    color(255,255,0), color(0,255,255), color(255,0,255),
    color(128,0,0), color(0,128,0), color(0,128,128)
};

int color1 = 1, color2 = 2;
 
double r = 0; // calculated in calculateRadius

void setup() {
  // global n, graphSize, mode, nodeDict
    size(800, 800, P3D);
    
    // calculate radius
    r = calculateRadius();
    
    // build map
    for(int i = 0; i < n; i++) {  
        Vertex v = new Vertex(i);
        Random random = new Random();
        
        if (mode == "square") {
            float a = random.nextFloat() - 0.5;
            float b = random.nextFloat() - 0.5;
            
            v.positionX = a;
            v.positionY = b;
        }
        else if (mode == "disk") {
            // generate random points on a disk
            // http://stackoverflow.com/questions/5837572/generate-a-random-point-within-a-circle-uniformly
            float a = random.nextFloat();
            float b = random.nextFloat();
                
            // ensure a is greater
            if (b < a) {
                float temp = b;
                b = a;
                a = temp;
            }
            
            fill(204, 102, 0);
            
            v.positionX = (float)(b*Math.cos(2*Math.PI*a/b));
            v.positionY = (float)(b*Math.sin(2*Math.PI*a/b));
        }
        else {
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
    
    // build adjacency list
    sweepNodes();
    
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
    
    // determine the number of colors in colorCount
    int numLargestColors = colorCount.size();
    if (numLargestColors < 4)
        largestColors = new int[numLargestColors];
    else largestColors = new int[4];
    
    // find the four largest colors - store in largestColors
    Set set = colorCount.entrySet(); //<>//
    Iterator iterator = set.iterator();
    int itCount = 0;
    while (iterator.hasNext() && itCount < numLargestColors) {
        Map.Entry c = (Map.Entry)iterator.next();
        largestColors[itCount] = (int)c.getKey();
        println(c.getKey() + ": " + c.getValue());
        itCount++;
    }
    
    // initialize colorCombos to have all possible cominations of the (at most)
    // four most common colors: AB, AC, AD, BC, BD, CD
    int numCombos = (int)choose(numLargestColors, 2);
    colorCombos = new int[numCombos][2]; // r = itCount nCr 2
    
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
    
    // try all combinations to find two largest backbones
    int numNodesVisited = 0, curLargestStarterNode = -1, curLargestSize = -1;
    int[] largestStartingNodes = new int[6]; // largest starter for each color combo
    
    // for each color combination, calculate the backbone 
    // (largest connected component of each bipartite subgraph)
    for (int j = 0; j < colorCombos.length; j++) {
        int curColor1 = colorCombos[j][0];
        int curColor2 = colorCombos[j][1];
         // size of the bipartite subgraph = sizes of the two current colors 
        int bipartiteSize = colorCount.get(curColor1) + colorCount.get(curColor2); 
        while (numNodesVisited < bipartiteSize) {
            // pick the node that will be the starting point of the BFS
            // (first node in vertexDict that's of color1 or 2 that hasn't been visited
            int curStarterNode = 0;
            while (curStarterNode < vertexDict.length && (vertexDict[curStarterNode].visited || //<>//
                   vertexDict[curStarterNode].nodeColor != curColor1 &&
                   vertexDict[curStarterNode].nodeColor != curColor2)) 
                       curStarterNode++;
            
            int curSize = BFS(curStarterNode, curColor1, curColor2);
            
            // if curSize is the largets so far, remember starting node and largest size
            if (curSize > curLargestSize) {
                curLargestSize = curSize;
                curLargestStarterNode = curStarterNode;
            }
            
            // reduce the remaining nodes to visit
            numNodesVisited += curSize;
        }
    }
    
}

void draw() {
    // put matrix in center
    pushMatrix();
    translate(width/2, height/2);
    scale(zoom);
    rotate(angle);
    
    // rotate matrix based off mouse movement
    rotateX(rotX);
    rotateY(rotY);       
    
    noFill();
    background(0);
    
    stroke(100, 0, 200);
    
    // draw nodes
    for (int i = 0; i < n; i++) {
        if (vertexDict[i].nodeColor < 9)
            stroke(colorArr[vertexDict[i].nodeColor]);
        else stroke(255,255,255);
       
        Vertex curVertex = vertexDict[i];
        
        if (curVertex.nodeColor == color1 || curVertex.nodeColor == color2)
            curVertex.drawVertex(); 
        
        // draw line between vertex and its neighbors
        ListNode curNeighbor = curVertex.neighbors.front;
        stroke(255,255,255);
        strokeWeight(0.005);
        while (curNeighbor != null) {
            int index = curNeighbor.ID;
            if ((curVertex.nodeColor == color1 && vertexDict[index].nodeColor == color2) || (curVertex.nodeColor == color2 && vertexDict[index].nodeColor == color1))
               line(curVertex.positionX, curVertex.positionY, curVertex.positionZ, vertexDict[index].positionX, vertexDict[index].positionY, vertexDict[index].positionZ);
            curNeighbor = curNeighbor.getNext();
        }
    }
    
    popMatrix();
}

void sweepNodes() {
    long startTime = System.nanoTime();

    // sort dictionary based on X position
    Arrays.sort(vertexDict, new Comparator<Vertex>() {
        public int compare(Vertex v1, Vertex v2) {
            return Float.compare(v1.positionX, v2.positionX);
        }
    });
    
    // go through each vertex
    for (int i = 0; i < n; i++) {
        int j = i-1;
        
        // if the vertex to left is within range, calculate distance
        while ((j >= 0) && (vertexDict[i].positionX - vertexDict[j].positionX <= r)) {
            // calculate distance based off topology
            if (dist(vertexDict[i].positionX, vertexDict[i].positionY, vertexDict[i].positionZ, 
                     vertexDict[j].positionX, vertexDict[j].positionY, vertexDict[j].positionZ) <= r) {
                    
                    // add both to each other's linked lists
                    vertexDict[i].neighbors.add(vertexDict[j].ID);                       
                    vertexDict[j].neighbors.add(vertexDict[i].ID);
            }  
            
            j -= 1;
            
        } // end while
    } // end for
    
    long endTime = System.nanoTime();

    println(((endTime - startTime)/1000000000) + " seconds to build adj list");  
    
    // sort dictionary based on ID again
    Arrays.sort(vertexDict, new Comparator<Vertex>() {
        public int compare(Vertex v1, Vertex v2) {
            return Float.compare(v1.ID, v2.ID);
        }
    });
    
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
int BFS(int v, int c1, int c2) {
    java.util.LinkedList<Integer> queue = new java.util.LinkedList<Integer>(); 
    int count = 0; // number of nodes visited
    
    // mark the current node as visited and enqueue it
    vertexDict[v].visited = true;
    queue.add(v);
    
    while (queue.size() != 0) {
        // Dequeue a vertex from queue and print it
        v = queue.poll();
        // print(v + " ");
        
        /* Get all adjacent vertices of the dequeued vertex s
        If a adjacent has not been visited, then mark it
        visited and enqueue it */
        ListNode curNode = vertexDict[v].neighbors.front; 
        while (curNode != null) {
            if (!vertexDict[curNode.ID].visited && (vertexDict[curNode.ID].nodeColor == c1 || vertexDict[curNode.ID].nodeColor == c2)) {
                vertexDict[curNode.ID].visited = true;
                queue.add(curNode.ID);
                count++;
            }
            curNode = curNode.next;
        }
    }
    return count++;
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
    if (key == 32) {
        angle = rotX = rotY = 0;
        zoom = 1;
    }
}
    