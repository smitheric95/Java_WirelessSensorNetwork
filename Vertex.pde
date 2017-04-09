public class Vertex implements Comparable<Vertex> {
    int ID;
    float positionX;
    float positionY;
    float positionZ;
    LinkedList neighbors;
    
    public Vertex(int ID) {
        this.ID = ID;   
        this.positionX = 0;
        this.positionY = 0;
        this.positionZ = 0;
        this.neighbors = new LinkedList();
    }
    
    public void drawVertex() {
        strokeWeight(3);
        point(this.positionX, this.positionY, this.positionZ);
    }
    
    public void printVertex() {
        System.out.println("[" + this.ID + "]: " + this.positionX + ", " + this.positionY);
        this.neighbors.printList();
    }
    
    @Override
    public int compareTo(Vertex v) {
        return Float.compare(this.positionX, v.positionX);
    }
}