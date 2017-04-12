import java.util.*;

/* Globals */
int graphSize = 500;
String mode = "sphere";
int avgDegree = 32; //input form user
int n = 10000; // number of vertices (nodes)
float rotX = 0; // rotation
float rotY = 0;
float zoom = 300;
float angle = 0; // rotation with keyboard
Vertex[] vertexDict = new Vertex[n]; // adjacency list of vertices and their neighbors
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
    
    }// end build map
    
    // build adjacency list
    sweepNodes();
    
    // smallest last vertex ordering
    Arrays.sort(vertexDict, new Comparator<Vertex>() {
        public int compare(Vertex v1, Vertex v2) {
            return Float.compare(v1.neighbors.getSize(), v2.neighbors.getSize());
        }
    });
    
    // print adjacency list
    //for (int i = 0; i < n; i++) {
    //    vertexDict[i].printVertex();
    //}
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
        vertexDict[i].drawVertex(); 
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
                    vertexDict[i].neighbors.add(vertexDict[j].ID, j);                       
                    vertexDict[j].neighbors.add(vertexDict[i].ID, i);
            }  
            
            j -= 1;
            
        } // end while
    } // end for
    
    long endTime = System.nanoTime();

    println(((endTime - startTime)/1000000000) + " seconds to build adj list");  
}             
// returns radius of a point based average degree
// check video to see if accurate
double calculateRadius() {
    if (mode == "square") {
        return Math.sqrt( (avgDegree*1.0/n*Math.PI) );
    }
    else if (mode == "disk") {
        return Math.sqrt( avgDegree*1.0/n );
    }
    else { 
        return Math.sqrt( 4*avgDegree*1.0/n );
    }
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
    