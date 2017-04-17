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
    
    // delete from list and return whether it got delted 
    public boolean delete(int ID) {
        // empty list
        if (this.size == 0) 
            return false;

        ListNode cur = this.front;
        
        // delete head
        if (cur.ID == ID) {
            this.front = cur.next;
        }
        
        // loop till we find node with the right ID
        while (cur.next != null) {
            if (cur.next.ID == ID) {
                cur.next = cur.next.next; // delete
                return true;
            }
            cur = cur.next;
        }
        
        // node not found
        return false;
    }
    
    public ListNode getFront() {
        return this.front;
    }
    
    public int getSize() {
        return this.size;
    }
}