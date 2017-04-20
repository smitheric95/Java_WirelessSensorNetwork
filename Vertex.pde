public class Vertex {
    int ID;
    float positionX;
    float positionY;
    float positionZ;
    private boolean sortByDegree;
    LinkedList neighbors;
    boolean deleted; // pseudo deleted for coloring
    int nodeColor;
    boolean visited; // for calculating largest backbone
    
    public Vertex(int ID) {
        this.ID = ID;   
        this.positionX = 0;
        this.positionY = 0;
        this.positionZ = 0;
        this.sortByDegree = false;
        this.neighbors = new LinkedList();
        this.deleted = false;
        this.nodeColor = 0;
        this.visited = false;
    }
    
    public int getNumNeighbors() {
        return this.neighbors.size;
    }
    
    public void drawVertex() {
        strokeWeight(0.03);
        point(this.positionX, this.positionY, this.positionZ);
    }
    
    public void printVertex() {
        System.out.println("[" + this.ID + " (" + this.toString().substring(33, this.toString().length()) + ")]: " + this.positionX + ", " + this.positionY + ", " + this.positionZ + " Color: " + this.nodeColor);
        this.neighbors.printList();
    }
}