public class Vertex implements Comparable<Vertex> {
    int ID;
    float positionX;
    float positionY;
    float positionZ;
    private boolean sortByDegree;
    LinkedList neighbors;
    
    public Vertex(int ID) {
        this.ID = ID;   
        this.positionX = 0;
        this.positionY = 0;
        this.positionZ = 0;
        this.sortByDegree = false;
        this.neighbors = new LinkedList();
    }
    
    public int getNumNeighbors() {
        return this.neighbors.size;
    }
    
    public void drawVertex() {
        strokeWeight(0.01);
        point(this.positionX, this.positionY, this.positionZ);
    }
    
    public void printVertex() {
        System.out.println("[" + this.ID + "]: " + this.positionX + ", " + this.positionY + ", " + this.positionZ);
        this.neighbors.printList();
    }
    
    @Override
    public int compareTo(Vertex v) {
        if (sortByDegree) {
            return Integer.compare(this.neighbors.getSize(), v.neighbors.getSize());
        }
        else {
            sortByDegree = true;
            return Float.compare(this.positionX, v.positionX);
        }
    }
}