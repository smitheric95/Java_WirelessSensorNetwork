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