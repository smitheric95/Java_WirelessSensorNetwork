public class LinkedList {
    ListNode front;
    int size;
    
    public LinkedList() {
        this.size = 0;
        this.front = null;
    }
    
    public void add(int ID, int index) {
        ListNode node = new ListNode(ID, index);
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
}