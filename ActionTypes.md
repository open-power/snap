## Action Type Assignment
Vendor | Range Start | Range End | Description
:--- | :--- | :--- | :---
Reserved | 00.00.00.00 | 00.00.00.00 | Reserved
free | 00.00.00.01 | 00.00.FF.FF | Free for experimental use
IBM | 10.14.00.00 | 10.14.00.00 | SNAP framework example
IBM | 10.14.00.01 | 10.14.0F.FF | Reserved for IBM Actions
IBM | 10.14.10.00 | 10.14.10.00 | HLS Memcopy
IBM | 10.14.10.01 | 10.14.10.01 | HLS Sponge
IBM | 10.14.10.02 | 10.14.10.02 | HLS HashJoin
IBM | 10.14.10.03 | 10.14.10.03 | HLS Text Search
IBM | 10.14.10.04 | 10.14.10.04 | HLS BFS (Breadth First Search)
IBM | 10.14.10.05 | 10.14.10.05 | HLS Intersection
IBM | 10.14.00.06 | 10.14.FF.FF | Reserved for IBM Actions
Reserved | FF.FF.00.00 | FF.FF.FF.FF | Reserved

### How to apply for a new ActionType

Each new action type should get a unique number. The number is defined as pair of 16-bit vendor and 16-bit action id. To obtain a number, please add the new action type in the table above. Create a git merge request and get it approved and included. Following this procedure duplicate action types should be avoided. You may use your own 16-bit vendor id in your action type.
