public class LinkedList {
    ListNode front;
    private int size;
    
    public LinkedList() {
        this.size = 0;
        this.front = null;
    }
    
    public void add(int ID) {
        ListNode node = new ListNode(ID);
        node.next = this.front;
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
    
    public ListNode getFront() {
        return this.front;
    }
    
    public int getSize() {
        return this.size;
    }
}