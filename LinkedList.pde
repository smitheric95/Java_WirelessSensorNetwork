public class LinkedList {
    ListNode front;
    ListNode back;
	
    private int size;
    
    public LinkedList() {
        this.size = 0;
        this.front = null;
        this.back = null;
    }
    
    // add to front
    public void leftAdd(int ID) {
        ListNode node = new ListNode(ID);
        node.next = this.front;
        this.front = node;
        if (this.back == null)
            this.back = this.front;
            
        this.size++;
    }
    
    // add directly to back
    public void append(int ID) {
        ListNode node = new ListNode(ID);
        if (this.back != null)
            this.back.next = node;
            
        this.back = node;
        
        if (this.front == null) 
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
