public class LinkedList {
    ListNode front;
    int size;
    
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
        
        while (cur != null) {
            System.out.print("    [" + cur.ID + "]->");
        }
        System.out.println();
    }
}