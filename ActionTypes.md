## Action Type Assignment
Vendor | Range Start | Range End | Description
:--- | :--- | :--- | :---
Reserved | 00.00.00.00 | 00.00.00.00 | Reserved
free | 00.00.00.01 | 00.00.FF.FF | Free for experimental use
IBM | 10.14.00.00 | 10.14.00.00 | SNAP framework example
IBM | 10.14.00.01 | 10.14.00.01 | HDL NVMe example
IBM | 10.14.00.02 | 10.14.0F.FF | Reserved for IBM Actions
IBM | 10.14.10.00 | 10.14.10.00 | HLS Memcopy
IBM | 10.14.10.01 | 10.14.10.01 | HLS Sponge
IBM | 10.14.10.02 | 10.14.10.02 | HLS HashJoin
IBM | 10.14.10.03 | 10.14.10.03 | HLS Text Search
IBM | 10.14.10.04 | 10.14.10.04 | HLS BFS (Breadth First Search)
IBM | 10.14.10.05 | 10.14.10.05 | HLS Intersection (By Hashing)
IBM | 10.14.10.06 | 10.14.10.06 | HLS Intersection (By Sorting)
IBM | 10.14.10.07 | 10.14.10.07 | HLS NVMe memcopy
IBM | 10.14.10.08 | 10.14.10.08 | HLS Hello World
IBM | 10.14.10.09 | 10.14.10.09 | HLS Latency Evaluation
IBM | 10.14.10.0A | 10.14.10.0A | HLS WED/STATUS Sharing and MatrixMultiply
IBM | 10.14.10.0B | 10.14.FF.FF | Reserved for IBM Actions
MLE | 22.DB.00.01 | 22.DB.00.01 | HDL 10G Ethernet TCP/UDP/IP Accelerator Demo
MLE | 22.DB.00.02 | 22.DB.00.02 | HDL 25G Ethernet TCP/UDP/IP Accelerator Demo
Reserved | FF.FF.00.00 | FF.FF.FF.FF | Reserved

### How to apply for a new Action Type

With every line in the table above a range of Action Type IDs is
being reserved for a specific vendor or the range is defined as
*reserved* (not to be used) or as *free* (for experimental use).

Each new action type should get a unique number.
The number is defined as pair of 16-bit vendor and 16-bit action id.
To obtain a number, please add the new action type in the table above.
Create a git pull request and get it approved and included
(see instructions in [./CONTRIBUTING.md](./CONTRIBUTING.md).
By following this procedure duplicate action types will be avoided.
For the first 16 bit of your action types you may use your own 16-bit
vendor id.
