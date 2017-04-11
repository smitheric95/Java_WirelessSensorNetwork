public class ListNode {
    int ID;
    int index;
    ListNode next;
    
    public ListNode(int ID, int index) {
        this.ID = ID;
        this.index = index;
        this.next = null;
    }
    
    public ListNode getNext() {
        return this.next;
    }
    
    public int getIndex() {
        return this.index;
    }
}