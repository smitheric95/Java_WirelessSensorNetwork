/*
## Amazing real-time dispaly

I like your though about the real-time display, using some conditional variables to control the execution of the
draw() proedure.

## logical problem

- firstly, we surely need to update the whole adjacency list each time we delete a node ```k``` from this grph, 
because the adjacentn nodes of ```k``` may be bacome the node who has the smallest degree which is a negligence
in your part II, see the details in keqi's version.

## TODOS

1. I think in both of our versions, the number of colors used and the max color class size we caculate is wrong,
but I did't find much yet, wait for discuss with you about this.

2. Give a solution to generate the real-time needed plot, such as whenDelDeg and OrigDeg plot, color distribution, etc.
And just put the codes in the program, once we click run, the plot is then generated automatically and will be stored in 
the specific path we pre-defined.



# Thanks for reading this!
*/



import java.util.*;
import java.math.BigDecimal;

/******* INPUT ********/
int avgDegree = 128; 
String mode = "sphere"; // square, disk, sphere
int n = 8000; // number of vertices (nodes)
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
Integer[] degreeDictCopy = new Integer[n]; // ordered by smallest degree last, array of indices in vertexDict

int numNotDeleted = n;
int terminalCliqueSize = 0; // calculating terminal clique  
float nodeStrokeWeight = 0.0, edgeStrokeWeight = 0.0;


//time for each parts
long TIME1;
long TIME2;
long TIME3;

// output files for creating graphs as needed
PrintWriter outputSequential;

// first node is the vertex to color
LinkedList[] colorDict = new LinkedList[n];

// calculating four largest colors
HashMap<Integer, Integer> colorCount = new HashMap<Integer, Integer>();  // color : number of times it occurs
int[] largestColors;
int[][] colorCombos; // all possible combinations of the n most popular colors 

// NOTE: not always "color i"
//color[] largestColorRGBs = { 
//  // blue, green, yellow, red
//  color(0, 0, 255), color(0, 255, 0), color(255, 255, 0), color(255, 0, 0), 
//};

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

void setup() {
  long startTime = System.nanoTime();
  smooth();
  size(840, 840, P3D); // set size of window
  surface.setTitle("part2-gragh-coloring...");

  // create output file
  outputSequential = createWriter("output/outputSequential_" + n + "_" + avgDegree + "_" + mode + ".csv");


  /**************************** PART I *******************************/

  // build map of nodes
  for (int i = 0; i < n; i++) {  
    Vertex v = new Vertex(i);
    Random random = new Random();

    if (mode == "square") {
      v.positionX = random.nextFloat() - 0.5;
      v.positionY = random.nextFloat() - 0.5;
    } else if (mode == "disk") {
      // generate random points on a disk
      // http://stackoverflow.com/a/5838991
      float a = random.nextFloat();
      float b = random.nextFloat();

      // ensure b is greater by swapping
      if (b < a) { 
        float temp = b; 
        b = a; 
        a = temp;
      }

      fill(204, 102, 0);

      v.positionX = (float)(b*Math.cos(2*Math.PI*a/b));
      v.positionY = (float)(b*Math.sin(2*Math.PI*a/b));
    } else { // sphere
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
  }
  );

  // go through each vertex
  for (int i = 0; i < n; i++) {
    int j = i-1;

    // if the vertex to left is within range, calculate distance
    while ((j >= 0) && (vertexDict[degreeDict[i]].positionX - vertexDict[degreeDict[j]].positionX <= R)) {
      // calculate distance based off topology
      if (dist(vertexDict[degreeDict[i]].positionX, vertexDict[degreeDict[i]].positionY, vertexDict[degreeDict[i]].positionZ, 
        vertexDict[degreeDict[j]].positionX, vertexDict[degreeDict[j]].positionY, vertexDict[degreeDict[j]].positionZ) <= R) {

        // add both to each other's linked lists
        vertexDict[degreeDict[i]].neighbors.leftAdd(vertexDict[degreeDict[j]].ID);                       
        vertexDict[degreeDict[j]].neighbors.leftAdd(vertexDict[degreeDict[i]].ID);
        vertexDict[degreeDict[j]].realNeighbors += 1;
        vertexDict[degreeDict[i]].realNeighbors += 1;

        numEdges++;
      }  

      j -= 1;
    } // end while
  } // end for
  /* end sweep method */

  Arrays.sort(degreeDict, new Comparator<Integer>() {
    public int compare(Integer v1, Integer v2) {
      return -1 * Float.compare(vertexDict[v1].neighbors.getSize(), vertexDict[v2].neighbors.getSize());
    }
  }
  );

  int minDeg = vertexDict[degreeDict[degreeDict.length-1]].neighbors.getSize();
  int maxDeg = vertexDict[degreeDict[0]].neighbors.getSize();

  //println("N (number of vertices:  ", n);
  //println("R (number of vertices:  ", R);
  //println("M (number of edges):  ", numEdges);
  //println("Min Degree:  ", minDeg);
  //println("Avg(expe) Degree:  ", avgDegree);
  //println("Avg(real) Degree:  ", 2.0*numEdges/n);
  //println("Max Degree:  ", maxDeg);



  long endTime = System.nanoTime();
  TIME1 += ((endTime - startTime)/1000000);
  //println(((endTime - startTime)/1000000) + " ms to build adj list");  

  /************************** END PART I *****************************/


  /**************************** PART II *******************************/
  //startTime = System.nanoTime(); // reset our time counter

  // smallest last vertex ordering    
  Arrays.sort(degreeDict, new Comparator<Integer>() {
    public int compare(Integer v1, Integer v2) {
      return -1 * Float.compare(vertexDict[v1].neighbors.getSize(), vertexDict[v2].neighbors.getSize());
    }
  }
  );

  // initialize colorDict with sorted indices in degreeDict
  for (int i = 0; i < n; i++) {
    colorDict[i] = new LinkedList();
    colorDict[i].leftAdd(degreeDict[i]); // first node will be base of colorDict
  }


  outputSequential.println("Original Degree, Degree when Deleted, Avarage Degree");

  /***** generate colorDict *****/
  // start at the lowest degree 
  int degreeIndex = degreeDict.length - 1;
  for (int i =0; i<degreeDict.length; i++) {
    degreeDictCopy[i] = degreeDict[i];
  }
  //ArrayList orig = new ArrayList();
  //ArrayList whenDel = new ArrayList();
  //ArrayList avgD = new ArrayList();
  //while (degreeIndex > -1) {
  //for (int i = 0; i<n; i++) {
    
  startTime = System.nanoTime(); // reset our time counter
  while (true) {
    //Vertex curVertex;
    //if (!vertexDict[degreeDict[degreeIndex]].deleted) {
    //  curVertex = vertexDict[degreeDict[degreeIndex]];
    //} else {
    //  degreeIndex--;
    //  continue;
    //}
    Vertex curVertex = vertexDict[degreeDictCopy[degreeIndex]];

    //totalDeg += curVertex.neighbors.getSize();

    int curDegree = 0;

    // loop through each neighbor
    ListNode curNeighbor = curVertex.neighbors.front;
    while (curNeighbor != null) {
      int j = curNeighbor.ID; // index in vertexDict
      //if hasn't been deleted from vertexDict
      if (!vertexDict[j].deleted) {
        vertexDict[j].realNeighbors -= 1;
        colorDict[degreeIndex].append(curNeighbor.ID);
        curDegree++;
      }
      curNeighbor = curNeighbor.next;
    }
    curVertex.realNeighbors = curDegree;
    totalDeg += curDegree;
    //delete from vertexDict
    vertexDict[degreeDictCopy[degreeIndex]].deleted = true;
    numNotDeleted--;
    degreeDictCopy = Arrays.copyOf(degreeDictCopy, degreeDictCopy.length-1);


    if (numNotDeleted == 0) {
      break;
    }
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
      // each unDeleted nodes has the remainingNeighbors equals to numNotDeleted-1 distict vertices, 
      // means this a complete gragh: terminal clique
      if (cliqueCount == numNotDeleted && numNotDeleted != 0) {
        // we have a clique now
        terminalCliqueSize = numNotDeleted;
        cliqueDetermined = true;
      }
    }

    double d = numNotDeleted != 0 ?((numEdges * 2) -2.0 * totalDeg) / numNotDeleted : curDegree;
    BigDecimal bd=new BigDecimal(d);
    double realAvgDegree=bd.setScale(2, BigDecimal.ROUND_HALF_UP).doubleValue();
    // print original degree vs degree when deleted vs realAvgDegree
    outputSequential.println(curVertex.neighbors.size + "," + curDegree + "," + realAvgDegree);

    //orig.add(curVertex.neighbors.size);
    //whenDel.add(curVertex.realNeighbors);
    //avgD.add(realAvgDegree);
    if (curDegree > maxDegDeleted)
      maxDegDeleted = curDegree;


    Arrays.sort(degreeDictCopy, new Comparator<Integer>() {
      public int compare(Integer v1, Integer v2) {
        return -1 * Float.compare(vertexDict[v1].realNeighbors, vertexDict[v2].realNeighbors);
      }
    }
    );

    //degreeIndex--;
    degreeIndex = degreeDictCopy.length - 1;
  }
  //Collections.reverse(orig);
  //Collections.reverse(whenDel);
  //Collections.reverse(avgD);
  //println(orig+"###############################################################");
  //println(whenDel+"###############################################################");
  //println(avgD);
  //println(degreeDict.length);
  println("N (number of vertices:  ", n);
  println("R (number of vertices:  ", R);
  println("M (number of edges):  ", numEdges);
  println("Min Degree:  ", minDeg);
  println("Avg(expe) Degree:  ", avgDegree);
  println("Avg(real) Degree:  ", 2.0*numEdges/n);
  println("Max Degree:  ", maxDeg);
  println("max degree when deleted:  ", maxDegDeleted);
  println("terminal clique size:  ", terminalCliqueSize);
  /*** colorDict generated ***/


  // set first vertex.color = 1
  vertexDict[colorDict[0].front.ID].nodeColor = 1;
  colorCount.put(1, 1);
  ArrayList colors = new ArrayList();
  colors.add(1);
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
    //Set<Integer> set = new HashSet<>();  
    //    for(int k=0;k<colorList.length;k++){  
    //        set.add(colorList[k]);  
    //    }  
    //    int[] tmp = new int[set.size()];
    //    colorList = (int[]) set.toArray((int[]) tmp); 
    HashSet<Integer> hs=new HashSet<Integer>();
    for (int k : colorList) {
      hs.add(k);
    }
      colorList = hashsetToInt(hs);

      Arrays.sort(colorList);
      // find the smallest positive color
      int curColor = firstMissingPositive(colorList);

      // color the vertex
      vertexDict[colorDict[i].front.ID].nodeColor = curColor;
      colors.add(curColor);
      // increment the count of the corresponding color
      Integer freq = colorCount.get(curColor);
      colorCount.put(curColor, (freq == null) ? 1 : freq +1);
    }
    println(colors+"###############################################################");
    
    
    // calculate time part 2 took
    endTime = System.nanoTime();
    TIME2 += (endTime - startTime)/1000000;
    //println(((endTime - startTime)/1000000) + " ms to color nodes"); 

    // sort the occurences of color
    //colorCount = sortByValues(colorCount);
    Set set = colorCount.entrySet();
    Iterator iterator = set.iterator();
    int numColor = 0;
    int maxColorSize = 0;
    while (iterator.hasNext()) {
      Map.Entry c = (Map.Entry)iterator.next();
      if ((int)c.getValue() != 0) {
        numColor++;
        maxColorSize = maxColorSize > (int)c.getValue() ? maxColorSize : (int)c.getValue();
      }
    }
    println("number of colors:  ", numColor*2);
    //println("number of colors:  ", set.size());
    println("max color class size:  ", maxColorSize/4);
    //println("max color class size:  ", colorCount.get);

    // close output files
    outputSequential.flush(); 
    outputSequential.close();
  }

  void draw() {
    // put matrix in center
    pushMatrix();
    translate(width/2, height/2);
    scale(zoom);
    rotate(angle);
    noFill();
    background(255);
    nodeStrokeWeight = 0.03;
    edgeStrokeWeight = 0.00025;
    if (mode == "square") {
      nodeStrokeWeight /= 2;
      edgeStrokeWeight /= 2;
    }
    // rotate matrix based off mouse movement
    rotateX(rotX);
    rotateY(rotY);       
    frameRate(180);
    long startTime = System.nanoTime(); // reset our time counter
    for (int i = 0; i < n; i++) {
      //fill(39, 155, 46);
      //stroke(largestColorRGBs[i%4]);
      //stroke(random(255), random(255), random(255));
      //strokeWeight(nodeStrokeWeight);
      //vertexDict[i].drawVertex();

      // loop through each neighbor
      ListNode curNeighbor = vertexDict[i].neighbors.front;
      stroke(244, 121, 131);
      strokeWeight(edgeStrokeWeight);
      //while (curNeighbor != null) {
      //  line(vertexDict[i].positionX, vertexDict[i].positionY, vertexDict[curNeighbor.ID].positionX, vertexDict[curNeighbor.ID].positionY);

      //  curNeighbor = curNeighbor.next;
      //}
      noStroke();
    }
    long endTime = System.nanoTime();
    TIME1 += ((endTime - startTime)/1000000);


    startTime = System.nanoTime(); // reset our time counter
    for (int i = 0; i < n; i++) {
      stroke(random(255), random(255), random(255));

      strokeWeight(nodeStrokeWeight);
      vertexDict[i].drawVertex();
    }
    noStroke();
    endTime = System.nanoTime();
    TIME2 += ((endTime - startTime)/1000000);
    TIME1 += ((endTime - startTime)/1000000);

    println("run time for part1: ", TIME1/1000.0, "s");
    println("run time for part2: ", TIME2/1000.0, "s");

    popMatrix();
    noLoop();
    saveFrame("output/image/" +n + "_" + avgDegree + "_" + mode + ".jpg");
  } // end draw()


  // returns radius of a point based average degree
  // check video to see if accurate
  double calculateRadius() {
    if (mode == "square") {
      return Math.sqrt( (avgDegree*1.0/(n*Math.PI)) );
    } else if (mode == "disk") {
      return Math.sqrt( avgDegree*1.0/n );
    } else { 
      return Math.sqrt( 4*avgDegree*1.0/n );
    }
  }



  // find the smallest missing element in a sorted array
  // http://www.programcreek.com/2014/05/leetcode-first-missing-positive-java/
  // this function was copied directly from its source
  //public int firstMissingPositive(int[] A) {
  //  int n = A.length;

  //  for (int i = 0; i < n; i++) {
  //    while (A[i] != i + 1) {
  //      if (A[i] <= 0 || A[i] >= n)
  //        break;

  //      if (A[i]==A[A[i]-1])
  //        break;

  //      int temp = A[i];
  //      A[i] = A[temp - 1];
  //      A[temp - 1] = temp;
  //    }
  //  }

  //  for (int i = 0; i < n; i++) {
  //    if (A[i] != i + 1) {
  //      return i + 1;
  //    }
  //  }    

  //  return n + 1;
  //}



  public int firstMissingPositive(int[] A) {
    int n = A.length;
    if (n==0) {
      return 1;
    } else if (n==1) {
      return A[0]==1?2:1;
    } else {
      for (int i = 1; i < n; i++) {
        if (A[i] != A[i-1] + 1)
          return (int)(A[i-1] + 1);
      }
    }
    return A[n-1]+1;
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
    }
    );

    // Here I am copying the sorted list in HashMap
    // using LinkedHashMap to preserve the insertion order
    HashMap sortedHashMap = new LinkedHashMap();
    for (Iterator it = list.iterator(); it.hasNext(); ) {
      Map.Entry entry = (Map.Entry) it.next();
      sortedHashMap.put(entry.getKey(), entry.getValue());
    } 
    return sortedHashMap;
  }



  private static int[] hashsetToInt(HashSet<Integer> hs) {
    Object[] obj=hs.toArray(); 
    int[] number=new int[obj.length]; 
 
    for (int i=0; i<hs.size(); i++) {
      number[i]=(Integer)obj[i];
    }
    return number;
  }
  
  
  
  
//import java.util.*;

///******* INPUT ********/
//int avgDegree = 32; 
//String mode = "square"; // options: square, disk, sphere
//int n = 1001; // number of vertices (nodes)
///**********************/

///* Globals */
//double R = 0; // calculated in calculateRadius
//int graphSize = 500;
//int totalDeg = 0; // for real avg degree
//int maxDegDeleted = -1;
//int numEdges = 0;
//float rotX = 0; // rotation
//float rotY = 0;
//float zoom = 300;
//float angle = 0; // rotation with keyboard
//Vertex[] vertexDict = new Vertex[n]; // adjacency list of vertices and their neighbors
//Integer[] degreeDict = new Integer[n]; // ordered by smallest degree last, array of indices in vertexDict
//int numNotDeleted = n, terminalCliqueSize = 0; // calculating terminal clique  
//float nodeStrokeWeight = 0.0, edgeStrokeWeight = 0.0;

//// output files for creating graphs as needed
//PrintWriter outputSequential, outputDistribution;

//// first node is the vertex to color
//LinkedList[] colorDict = new LinkedList[n];

//// calculating four largest colors
//HashMap<Integer, Integer> colorCount = new HashMap<Integer, Integer>();  // color : number of times it occurs
//int[] largestColors;
//int[][] colorCombos; // all possible combinations of the n most popular colors 

//// NOTE: not always "color i"
//color[] largestColorRGBs = { 
//    // blue, green, yellow, red
//    color(0, 0, 255), color(0, 255, 0), color(255,255,0), color(255, 0, 0), 
//};

//// logic for real time display
//int nodeDrawCount = 0;
//boolean nodesDrawn = false;
//int lineDrawCount = 0;
//int colorDrawCount = 0;
//int time = 0;
//boolean userDrawLines = false, 
//        userColorNodes = false, 
//        userDrawFirstComponent = false, 
//        userDrawSecondComponent = false,
//        firstComponentDrawn = false,
//        cliqueDetermined = false;

//void setup() {
//    long startTime = System.nanoTime();
//    smooth();
//    size(840, 840, P3D); // set size of window
//    surface.setTitle("Drawing Vertices...");
    
//    // create output file
//    outputSequential = createWriter("output/outputSequential_" + n + "_" + avgDegree + "_" + mode + ".csv");
//    outputDistribution = createWriter("output/outputDistribution_" + n + "_" + avgDegree + "_" + mode + ".csv");
    
//    /**************************** PART I *******************************/
    
//    // build map of nodes
//    for(int i = 0; i < n; i++) {  
//        Vertex v = new Vertex(i);
//        Random random = new Random();
        
//        if (mode == "square") {
//            v.positionX = random.nextFloat() - 0.5;
//            v.positionY = random.nextFloat() - 0.5;
//        }
//        else if (mode == "disk") {
//            // generate random points on a disk
//            // http://stackoverflow.com/a/5838991
//            float a = random.nextFloat();
//            float b = random.nextFloat();
                
//            // ensure b is greater by swapping
//            if (b < a) { float temp = b; b = a; a = temp; }
            
//            fill(204, 102, 0);
            
//            v.positionX = (float)(b*Math.cos(2*Math.PI*a/b));
//            v.positionY = (float)(b*Math.sin(2*Math.PI*a/b));
//        }
//        else { // sphere
//            // generate random points on the surface of a sphere
//            // http://corysimon.github.io/articles/uniformdistn-on-sphere/
//            float theta = (float)(2 * Math.PI * random.nextFloat());
//            float phi = (float)(Math.acos(2 * random.nextFloat() - 1));
//            v.positionX = sin(phi) * cos(theta);
//            v.positionY = sin(phi) * sin(theta);
//            v.positionZ = cos(phi);
//        }
        
//        vertexDict[i] = v;
//        degreeDict[i] = i;
//    }// end build map
    
//    R = calculateRadius(); // calculate radius based off avgDegree
    
//    // build vertexDict using sweep method
//    // sort degreeDict, which currently is an array of IDs in vertexDict, based on X positions
//    // to be sorted by another comparison later on
//    Arrays.sort(degreeDict, new Comparator<Integer>() {
//        public int compare(Integer v1, Integer v2) {
//            return Float.compare(vertexDict[v1].positionX, vertexDict[v2].positionX);
//        }
//    });
   
//    // go through each vertex
//    for (int i = 0; i < n; i++) {
//        int j = i-1;
        
//        // if the vertex to left is within range, calculate distance
//        while ((j >= 0) && (vertexDict[degreeDict[i]].positionX - vertexDict[degreeDict[j]].positionX <= R)) {
//            // calculate distance based off topology
//            if (dist(vertexDict[degreeDict[i]].positionX, vertexDict[degreeDict[i]].positionY, vertexDict[degreeDict[i]].positionZ, 
//                     vertexDict[degreeDict[j]].positionX, vertexDict[degreeDict[j]].positionY, vertexDict[degreeDict[j]].positionZ) <= R) {
                    
//                    // add both to each other's linked lists
//                    vertexDict[degreeDict[i]].neighbors.add(vertexDict[degreeDict[j]].ID);                       
//                    vertexDict[degreeDict[j]].neighbors.add(vertexDict[degreeDict[i]].ID);
                    
//                    numEdges++;
//            }  
            
//            j -= 1;
            
//        } // end while
//    } // end for
//    /* end sweep method */
    
//    // calculate time part 2 took
//    long endTime = System.nanoTime();
//    println(((endTime - startTime)/1000000) + " ms to build adj list");  
    
//    /************************** END PART I *****************************/
    
    
//    /**************************** PART II *******************************/
//    startTime = System.nanoTime(); // reset our time counter
    
//    // smallest last vertex ordering    
//    Arrays.sort(degreeDict, new Comparator<Integer>() {
//        public int compare(Integer v1, Integer v2) {
//            return -1 * Float.compare(vertexDict[v1].neighbors.getSize(), vertexDict[v2].neighbors.getSize());
//        }
//    });
    
//    // initialize colorDict with sorted indices in degreeDict
//    for (int i = 0; i < n; i++) {
//        colorDict[i] = new LinkedList();
//        colorDict[i].add(degreeDict[i]); // first node will be base of colorDict
//    }

    
//    outputSequential.println("Original Degree, Degree when Deleted");
    
//    /***** generate colorDict *****/
//    // start at the lowest degree 
//    int degreeIndex = degreeDict.length - 1;
//    while (degreeIndex > -1) {
//        Vertex curVertex = vertexDict[degreeDict[degreeIndex]];
//        totalDeg += curVertex.neighbors.getSize();
//        int curDegree = 0;
        
//        // loop through each neighbor
//        ListNode curNeighbor = curVertex.neighbors.front;
//        while (curNeighbor != null) {
//            int j = curNeighbor.ID; // index in vertexDict
//            //if hasn't been deleted from vertexDict
//            if (!vertexDict[j].deleted) {
//                colorDict[degreeIndex].append(curNeighbor.ID);
//                curDegree++;
//            }
//            curNeighbor = curNeighbor.next; 
//        }
        
//        //delete from vertexDict
//        vertexDict[degreeDict[degreeIndex]].deleted = true;
//        numNotDeleted--;
        
//        // determine terminal clique
//        // source: http://stackoverflow.com/a/30106072
//        if (!cliqueDetermined) {
//            int cliqueCount = 0;
//            // for each node in the adjacency list (that hasn't been deleted)
//            for (int j = 0; j < vertexDict.length; j++) {
//                if (!vertexDict[j].deleted) {
//                    // loop through each neighbor
//                    int remainingNeighbors = 0;
//                    ListNode curNode = vertexDict[j].neighbors.front;
//                    while (curNode != null) {
//                        // count the ones that haven't been deleted
//                        if (!vertexDict[curNode.ID].deleted)
//                            remainingNeighbors++;
//                        curNode = curNode.next;
//                    }
//                    // if the number of remaining neighbors == numNotDeleted-1 distict vertices (candidate for clique)
//                    if (remainingNeighbors == numNotDeleted - 1) 
//                        cliqueCount++;
//                    else break;
//                }
//            }
//            if (cliqueCount == numNotDeleted && numNotDeleted != 0) {
//                // we have a clique, ladies and gentlemen!
//                terminalCliqueSize = numNotDeleted;
//                cliqueDetermined = true;
//            }
//        }
        
//        // print original degree vs degree when deleted
//        outputSequential.println(curVertex.neighbors.size + "," + curDegree);
//        if (curDegree > maxDegDeleted)
//            maxDegDeleted = curDegree;
        
//        degreeIndex--;
//    }
//    /*** colorDict generated ***/
    
//    // set first vertex.color = 1
//    vertexDict[colorDict[0].front.ID].nodeColor = 1;
//    colorCount.put(1, 1);
    
//    // starting at 1, color all other nodes in colorDict
//    for (int i = 1; i < colorDict.length; i++) {
//        // make an array of the nodes' linkedlist size-1
//        int[] colorList = new int[ colorDict[i].size - 1 ];
           
//        // initialize array
//        int count = 0;
//        ListNode curNode = colorDict[i].front.next; 
//        while (curNode != null) {
//            colorList[count] = vertexDict[curNode.ID].nodeColor;
//            curNode = curNode.next;
//            count++;
//        }
               
//        // find the smallest positive color
//        int curColor = firstMissingPositive(colorList);
        
//        // color the vertex
//        vertexDict[colorDict[i].front.ID].nodeColor = curColor;
        
//        // increment the count of the corresponding color
//        Integer freq = colorCount.get(curColor);
//        colorCount.put(curColor, (freq == null) ? 1 : freq +1);
//    }
//    // calculate time part 2 took
//    endTime = System.nanoTime();
//    println(((endTime - startTime)/1000000) + " ms to color nodes");  
    
//    /**************************** PART III *******************************/
//    /***** Bipartite backbone selection *****/
//    // sort the occurences of color
//    colorCount = sortByValues(colorCount); 
    
//    // determine the number of colors in colorCount (at most 4)
//    int numLargestColors = colorCount.size();
//    if (numLargestColors > 4)
//        numLargestColors = 4;
//    largestColors = new int[numLargestColors];
    
//    // find the four (at most) largest colors - store in largestColors
//    // print color distribution to output file
//    outputDistribution.println("Color Number, Percentage of Distribution");
//    Set set = colorCount.entrySet();
//    Iterator iterator = set.iterator();
//    int itCount = 0;
//    while (iterator.hasNext()) {
//        Map.Entry c = (Map.Entry)iterator.next();
//        if (itCount < numLargestColors)
//            largestColors[itCount] = (int)c.getKey();
        
//        // ouput color and the number of times it occurs
//        outputDistribution.println(c.getKey() + "," + ((int)c.getValue() * 1.0 / n));
//        itCount++;
//    }
    
//    // initialize colorCombos to have all possible cominations of the (at most)
//    // four most common colors: AB, AC, AD, BC, BD, CD
//    int numCombos = (int)choose(numLargestColors, 2);
//    colorCombos = new int[numCombos][2]; // r = itCount nCr 2
    
//    // calculate the different combinations (nCr)
//    int r = 0, c1 = 0;
//    while (c1 < numLargestColors-1) {
//        int c2 = c1+1;
//        while (c2 < numLargestColors) {
//            colorCombos[r][0] = largestColors[c1];
//            colorCombos[r][1] = largestColors[c2];
//            c2++;
//            r++;
//        }
//        c1++;
//    }
    
//    // try all combinations to find two largest backbones
//    // first and second largest sizes and their starting nodes
//    int[] largestStarterNodes = new int[2], largestSizes = new int[2];
//    int[][] largestColorCombos = new int[2][2]; // the color comination of the two largest backbones

    
//    // for each color combination, calculate the backbone 
//    // (largest connected component of each bipartite subgraph)
//    for (int j = 0; j < numCombos; j++) {
//        int curColor1 = colorCombos[j][0];
//        int curColor2 = colorCombos[j][1];
//         // size of the bipartite subgraph = sizes of the two current colors 
//        int bipartiteSize = colorCount.get(curColor1) + colorCount.get(curColor2);
//        int numNodesVisited = 0;
        
//        while (numNodesVisited < bipartiteSize) {
//            // pick the node that will be the starting point of the BFS
//            // (first node in vertexDict that's of color1 or 2 that hasn't been visited
//            int curStarterNode = 0;
//            while (curStarterNode < vertexDict.length && (vertexDict[curStarterNode].visited[j] ||
//                   vertexDict[curStarterNode].nodeColor != curColor1 &&
//                   vertexDict[curStarterNode].nodeColor != curColor2)) 
//                       curStarterNode++;
            
//            // nodes visited in the traversal
//            int curSize = BFS(curStarterNode, j, curColor1, curColor2);

//            // if curSize is the largest so far, remember starting node and largest size
//            if (curSize > largestSizes[0]) {
//                // store the previous largest as the second largest
//                largestSizes[1] = largestSizes[0];
//                largestStarterNodes[1] = largestStarterNodes[0];
//                largestColorCombos[1][0] = largestColorCombos[0][0];
//                largestColorCombos[1][1] = largestColorCombos[0][1];
                
//                largestSizes[0] = curSize;
//                largestStarterNodes[0] = curStarterNode;
//                largestColorCombos[0][0] = curColor1;
//                largestColorCombos[0][1] = curColor2;
//            }
//            else if(curSize > largestSizes[1]) {
//                largestSizes[1] = curSize;
//                largestStarterNodes[1] = curStarterNode;
//                largestColorCombos[1][0] = curColor1;
//                largestColorCombos[1][1] = curColor2;
//            }
            
//            // reduce the remaining nodes to visit
//            numNodesVisited += curSize;
//        }
//    } //<>//
//    // calculate time part 3 took
//    endTime = System.nanoTime();
//    println(((endTime - startTime)/1000000) + " ms to find backbones");  
    
//    // exist for drawing only
//    BFS(largestStarterNodes[0], -1, largestColorCombos[0][0], largestColorCombos[0][1]);
//    BFS(largestStarterNodes[1], -2, largestColorCombos[1][0], largestColorCombos[1][1]);

//    /********** Logic for Summary Table ************/
//    int minDeg = vertexDict[degreeDict[degreeDict.length-1]].neighbors.getSize();
//    int maxDeg = vertexDict[0].neighbors.getSize();
    
//    // println("----------------- Summary Table ----------------");
//    // N, R, M (numEdges), min degree, avg degree, real avg degree, max degree,
//    // max degree when deleted, number of colors, size of largest color class
//    // terminal clique size, n of largest backbone, m of largest backbone, domination percentage
    
//    //println(n, R, numEdges, minDeg, avgDegree, totalDeg/n, maxDeg);
//    //println(maxDegDeleted, colorCount.size(), largestSizes[0], terminalCliqueSize, largestSizes[0], largestSizes[0] - 1, (largestSizes[0]*1.0)/n);
//    //println("------------------------------------------------");
    
//    println(); 
//    println("1st Largest subgraph starts at: " + largestStarterNodes[0] + " with a size of: " + largestSizes[0] + " and of color combo of " + largestColorCombos[0][0] + ", " + largestColorCombos[0][1]); 
//    println("2nd Largest subgraph starts at: " + largestStarterNodes[1] + " with a size of: " + largestSizes[1] + " and of color combo of " + largestColorCombos[1][0] + ", " + largestColorCombos[1][1]);
    
//    // close output files
//    outputSequential.flush(); 
//    outputSequential.close(); 
//    outputDistribution.flush(); 
//    outputDistribution.close(); 
//}

//void draw() {
//    // put matrix in center
//    pushMatrix();
//    translate(width/2, height/2);
//    scale(zoom);
//    rotate(angle);
//    noFill();
//    background(0);
    
//    // rotate matrix based off mouse movement
//    rotateX(rotX);
//    rotateY(rotY);       
    
//    // delay drawing
//    // source: https://forum.processing.org/one/topic/how-do-you-make-a-program-wait-for-one-or-two-seconds.html
//    if (millis() > time){
//        if (!firstComponentDrawn)
//            time = millis() + 1;
//        if (nodeDrawCount < n)
//            nodeDrawCount++;
//        else if (userDrawLines){ 
//            nodesDrawn = true;
//            if (n > 20)
//                lineDrawCount += n/20;
//            else lineDrawCount = 20;
//            if (userColorNodes)
//                if (n > 20)
//                    colorDrawCount += n/20;
//                else colorDrawCount = 20; 
//            if (userDrawFirstComponent && !firstComponentDrawn) {
//                firstComponentDrawn = true;
//                nodeDrawCount = n;   
//            }
//        }
//    }
    
//    // count what's been drawn
//    int linesDrawn = lineDrawCount;
//    int colorsDrawn = colorDrawCount;
    
//    // calculate stroke weight depending on graph type and size
//    nodeStrokeWeight = 0.03;
//    edgeStrokeWeight = 0.005;
//    if ((!userDrawFirstComponent && !userDrawSecondComponent)) {
//        if (n > 1000) {
//            nodeStrokeWeight = 0.02;
//            edgeStrokeWeight = 0.001;
//        }
//        else if (n > 10000) {
//            nodeStrokeWeight = 0.0001;
//            edgeStrokeWeight = 0.00001;
//        }
//    }
//    if (mode == "square") {
//        nodeStrokeWeight /= 2;
//        edgeStrokeWeight /= 2;
//    }

//    // draw nodes
//    for (int i = 0; i < nodeDrawCount; i++) {
//        stroke(255);
//        strokeWeight(nodeStrokeWeight);
        
//        Vertex curVertex = vertexDict[i];
        
//        if ((!userDrawFirstComponent && !userDrawSecondComponent) || (userDrawFirstComponent && curVertex.toDraw[0]) || (userDrawSecondComponent && curVertex.toDraw[1])) {
//            // find appropriate color 
//            int j;
//            for (j = 0; j < largestColors.length; j++)
//                if (largestColors[j] == curVertex.nodeColor) break;
            
//            if (j < largestColors.length && (colorsDrawn > 0 || userDrawFirstComponent || userDrawSecondComponent)) {
//                // set color based off... well, color
//                stroke(largestColorRGBs[j]);
//            }
//            else if (userColorNodes) stroke((curVertex.nodeColor*50)%255, (curVertex.nodeColor*20)%255,(curVertex.nodeColor*70)%255);
//            colorsDrawn--;
//            curVertex.drawVertex(); // draw!
//        }
        
//        stroke(0, 255, 255);
//        strokeWeight(edgeStrokeWeight);
//        // draw line between vertex and its neighbors
//        if (userDrawFirstComponent || userDrawSecondComponent || nodesDrawn && (linesDrawn > 0)) {
//            ListNode curNeighbor = curVertex.neighbors.front;
            
//            while (curNeighbor != null) {
//                int index = curNeighbor.ID;
//                if ((!userDrawFirstComponent && !userDrawSecondComponent) || (userDrawFirstComponent && curVertex.toDraw[0] && vertexDict[curNeighbor.ID].toDraw[0]) || (userDrawSecondComponent && curVertex.toDraw[1] && vertexDict[curNeighbor.ID].toDraw[1]))
//                    line(curVertex.positionX, curVertex.positionY, curVertex.positionZ, vertexDict[index].positionX, vertexDict[index].positionY, vertexDict[index].positionZ);
//                curNeighbor = curNeighbor.getNext();
//            }
//            linesDrawn--;  
//        }
//    }
//    //println("userDrawFirstComponent: " + userDrawFirstComponent + ", " + "userDrawSecondComponent: " + userDrawSecondComponent);

//    popMatrix();
//} // end draw()
            
//// returns radius of a point based average degree
//// check video to see if accurate
//double calculateRadius() {
//    if (mode == "square") {
//        return Math.sqrt( (avgDegree*1.0/(n*Math.PI)) );
//    }
//    else if (mode == "disk") {
//        return Math.sqrt( avgDegree*1.0/n );
//    }
//    else {  //<>//
//        return Math.sqrt( 4*avgDegree*1.0/n );
//    }
//}

//// prints BFS traversal on an adjacency list
//// edited from source: http://www.geeksforgeeks.org/breadth-first-traversal-for-a-graph/
//// colorCombo == -1 if the node is to be drawn (part of the 1st largest componenent)
//// colorCombo == -2 if the node is to be drawn (part of the 2nd largest componenent)
//int BFS(int v, int colorCombo, int c1, int c2) {
//    java.util.LinkedList<Integer> queue = new java.util.LinkedList<Integer>(); 
//    int count = 0; // number of nodes visited
    
//    // mark the current node as visited and enqueue it
//    if (colorCombo > -1)
//        vertexDict[v].visited[colorCombo] = true;
//    queue.add(v);
    
//    while (queue.size() != 0) {
//        // Dequeue a vertex from queue and print it
//        v = queue.poll();
        
//        /* Get all adjacent vertices of the dequeued vertex s
//        If a adjacent has not been visited, then mark it
//        visited and enqueue it */
//        ListNode curNode = vertexDict[v].neighbors.front; 
//        while (curNode != null) {
//            // if the node hasn't been visited (or it needs to be drawn) 
//            // and it's the right color, mark it visited
//            if (((colorCombo > -1 && !vertexDict[curNode.ID].visited[colorCombo]) || ((colorCombo == -1 && !vertexDict[curNode.ID].visitedWhileDrawn[0]) || (colorCombo == -2 && !vertexDict[curNode.ID].visitedWhileDrawn[1])))  //<>//
//                && (vertexDict[curNode.ID].nodeColor == c1 || vertexDict[curNode.ID].nodeColor == c2)) {
//                // mark the node as visited
//                if (colorCombo > -1)
//                    vertexDict[curNode.ID].visited[colorCombo] = true;
                
//                // draw the node if necessary
//                else {
//                    // mark 
//                    if (colorCombo == -1) {
//                        vertexDict[curNode.ID].visitedWhileDrawn[0] = true;
//                        vertexDict[curNode.ID].toDraw[0] = true;
//                    }
//                    else {
//                        vertexDict[curNode.ID].visitedWhileDrawn[1] = true;
//                        vertexDict[curNode.ID].toDraw[1] = true;
//                    }
//                }
//                queue.add(curNode.ID);
//                count++;
//            }
//            curNode = curNode.next;
//        }
//    }
//    return count + 1;
//}

//// find the smallest missing element in a sorted array
//// http://www.programcreek.com/2014/05/leetcode-first-missing-positive-java/
//// this function was copied directly from its source
//public int firstMissingPositive(int[] A) {
//    int n = A.length;
 
//    for (int i = 0; i < n; i++) {
//        while (A[i] != i + 1) {
//            if (A[i] <= 0 || A[i] >= n)
//                break;
 
//                if(A[i]==A[A[i]-1])
//                        break;
 
//            int temp = A[i];
//            A[i] = A[temp - 1];
//            A[temp - 1] = temp;
//        }
//    }
 
//    for (int i = 0; i < n; i++){
//        if (A[i] != i + 1){
//            return i + 1;
//        }
//    }    
 
//    return n + 1;
//}

//// sort HashMap by value
//// source: http://beginnersbook.com/2013/12/how-to-sort-hashmap-in-java-by-keys-and-values/
//// this function was copied directly from its source
//private static HashMap sortByValues(HashMap map) { 
//       List list = new java.util.LinkedList(map.entrySet());
//       // Defined Custom Comparator here
//       Collections.sort(list, new Comparator() {
//            public int compare(Object o1, Object o2) {
//               return -1 * ((Comparable) ((Map.Entry) (o1)).getValue())
//                  .compareTo(((Map.Entry) (o2)).getValue());
//            }
//       });

//       // Here I am copying the sorted list in HashMap
//       // using LinkedHashMap to preserve the insertion order
//       HashMap sortedHashMap = new LinkedHashMap();
//       for (Iterator it = list.iterator(); it.hasNext();) {
//              Map.Entry entry = (Map.Entry) it.next();
//              sortedHashMap.put(entry.getKey(), entry.getValue());
//       } 
//       return sortedHashMap;
//  }
  
//// x choose y
//// source: http://stackoverflow.com/a/1678715
//// this function was copied directly from its source
//public static double choose(int x, int y) {
//    if (y < 0 || y > x) return 0;
//    if (y > x/2) {
//        // choose(n,k) == choose(n,n-k), 
//        // so this could save a little effort
//        y = x - y;
//    }

//    double denominator = 1.0, numerator = 1.0;
//    for (int i = 1; i <= y; i++) {
//        denominator *= i;
//        numerator *= (x + 1 - i);
//    }
//    return numerator / denominator;
//}

//void mouseDragged() {
//    rotX += (pmouseY-mouseY) * 0.1;
//    rotY += -1 * (pmouseX-mouseX) * 0.1;
//}

//void keyPressed() {
//    // https://forum.processing.org/two/discussion/2151/zoom-in-and-out
//    if (keyCode == UP) {
//        zoom += 20;
//    }
//    else if (keyCode == DOWN) {
//        zoom -= 20;
//    }
//    else if (keyCode == RIGHT) {
//        angle += .03;
//    }
//    else if (keyCode == LEFT) {
//        angle -= .03;
//    }
//    if (key == 32) { // space
//        if (userDrawSecondComponent) {
//            userDrawSecondComponent = false;
//            colorDrawCount = n;
//            surface.setTitle("All Vertices and Edges");
//        }
//        else if (userDrawFirstComponent) {
//            userDrawSecondComponent = true;
//            userDrawFirstComponent = false;
//            surface.setTitle("2nd Largest Component");
//        }
//        else if (userColorNodes) {
//            userDrawFirstComponent = true;
//            surface.setTitle("1st Largest Component");
//        }
//        else if (userDrawLines) {
//            userColorNodes = true;
//            surface.setTitle("Coloring");
//        }
//        else if (nodeDrawCount < n) {
//            nodeDrawCount = n;
//            surface.setTitle("All Vertices");
//        }
//        else {
//            userDrawLines = true;
//            surface.setTitle("All Vertices and Edges");
//        }
//    }
//}
    
