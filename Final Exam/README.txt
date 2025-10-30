          
HAKIZIMANA Emmanuel                                              29th October 2025
Reg No: 224019436
Year of Study: 2
UR-CBE Gikondo Campus
African Center of Excellence in Data Science (ACE-DS)
Masters of Data Science in Mining
________________________________________
Case Study: Retail Inventory and Sales Management System 
Project Title : Distributed Database Simulation
Tool used: Oracle 19c / XE, SQL*Plus
Nodes created: 
a. Node A (local node) called S_BranchDB_A
b.Node B (remote node) called BranchDB_B

 OVERVIEW OF THE PROJECT

This project aimed at showing the implementation of a distributed database system using oracle across two database nodes (local and remote) that are interconnected using a link. This will simulate the following:
a)	Horizontal fragmentation of a table (split across nodes) 
b)	Database links for remote access
c)	Distributed view and joins 
d)	Parallel and serial query execution
e)	Two-phase commit and failure recovery
f)	Lock conflict diagnosis in a distributed system


1.	Fragmentation of data: Data fragmentation divides data into logical subsets stored at different created nodes.
 CREATE TABLE OrderDetail_A (
    OrderID NUMBER(10),
    ProductID NUMBER(10),
    Quantity NUMBER,
    SubTotal NUMBER(12, 2),
    CONSTRAINT PK_ODA PRIMARY KEY (OrderID, ProductID)
);
INSERT INTO OrderDetail_A VALUES (101, 1, 2, 20.00);
INSERT INTO OrderDetail_A VALUES (102, 2, 1, 15.50);
COMMIT;

 The above syntax created a table called OrderDetail_A, stored in local node, PRIMARY KEY (OrderID, ProductID) ensures each order-product pair is unique and
 NUMBER (12, 2) defines numeric values with two decimal places.  COMMIT is for finishing a transaction just to make the data inserted permanently.

 CREATE TABLE OrderDetail_B (
    OrderID NUMBER(10),
    ProductID NUMBER(10),
    Quantity NUMBER,
    SubTotal NUMBER(12, 2),
    CONSTRAINT PK_ODB PRIMARY KEY (OrderID, ProductID)
);
GRANT SELECT ON OrderDetail_B TO S_BranchDB_A;

The above is another table created in node B (remote node) and the Grant is there to read access to node A (local node)

2.	Database link configuration: This a way of having access so that node A can be connected to node B, 
for facilitating access of one node using only one without running codes in all nodes.

 CREATE DATABASE LINK PROJ_LINK
CONNECT TO BranchDB_B IDENTIFIED BY "Emm788@enna"
USING '//Localhost:1521/XE';
The  above syntax defines a connection to a remote database , where the “USING” clause specifies the remote listener (host, port, service) , 
and tables in node B can be accessed by typing “table_name@PROJ_LINK”, and automatically the output comes to node A easily. 

3.	Distributed view (Union of Fragments): refers to a virtual table that combines data stored across multiple database nodes or 
fragments into a single unified view

  CREATE OR REPLACE VIEW OrderDetail_ALL AS
SELECT * FROM OrderDetail_A
UNION ALL
SELECT * FROM OrderDetail_B@PROJ_LINK;

The above code shows how UNION ALL merge data from both nodes without removing duplicates, and create a logical global view combining all fragments.
Validation: Thhis ensures the total count from both fragments = 10 rows, below is the code for validation:
SELECT COUNT(*) AS Fragment_Count
FROM OrderDetail_ALL;


4.	Cross-Node Join:  This joins local and remote data across the link by combining every row from the first table (node A) with 
every row of the second table (node B). like in the below code, the remote object reference is Product@PROJ_LINK, and “ON……..WHERE “
specifies which element will be in the resulting table.
 
SELECT
    ODA.OrderID,
    P.ProductName,
    ODA.Quantity,
    P.Category
FROM
    OrderDetail_A ODA
JOIN
    Product@PROJ_LINK P
ON ODA.ProductID = P.ProductID
WHERE
    ODA.ProductID IN (1, 3);

5.	Parallel and Serial Aggregation

a)	Serial aggregation:  In serial aggregation the entire dataset is processed one piece at a time to compute the final aggregate result, which result in poor ( slower) performance for larger datasets,
 it is generally suitable for small datasets. The word “AUTOTRACE” in syntax means performance starts.
 
SET AUTOTRACE ON STATISTICS
SET TIMING ON

SELECT ProductID,
       COUNT(*) AS TotalLines,
       SUM(Quantity) AS TotalQtySold,
       SUM(SubTotal) AS TotalRevenue
FROM OrderDetail_ALL
GROUP BY ProductID;

b)	Parallel aggregation: In parallel aggregation the dataset is divided into smaller chunks, and multiple worker processes or threads simultaneously compute 
partial aggregate results on their respective chunks. It is significantly faster for larger datasets.
for example multiple customers can ordering separate items concurrently and finally the supplier adding up each customer’s order to get the total ordered.
 In the below syntax  SELECT /*+ PARALLEL(ODA, 8) */ is a query that tells Oracle to use 8 parallel execution threads.
SELECT /*+ PARALLEL(ODA, 8) */
       ProductID,
       COUNT(*) AS TotalLines,
       SUM(Quantity) AS TotalQtySold,
       SUM(SubTotal) AS TotalRevenue
FROM (
    SELECT * FROM OrderDetail_A ODA
    UNION ALL
    SELECT * FROM OrderDetail_B@PROJ_LINK
)
GROUP BY ProductID;

Note that: The remote fragment executes serially unless configured for parallelism

6.	Two-Phase Commit (2PC) and Recovery: This is a basic atomic commitment protocol (ACP) used in distributed systems, 
it makes sure that a single transaction involving several independent resource managers (referred to as participants) is either committed in its entirety 
across all participants or aborted (rolled back) in its entirety.
BEGIN
    INSERT INTO OrderInfo_KGL VALUES (1000, 10, DATE '2025-10-28');
    INSERT INTO OrderInfo@PROJ_LINK VALUES (1001, 11, DATE '2025-10-28');
    COMMIT;
END;
/
 
It can be possible that the network disconnects before COMMIT, in that case the transaction becomes “in-doubt” 
and this is verified by running the following code in local nodes: 
 SELECT LOCAL_TRAN_ID, GLOBAL_TRAN_ID, STATE
FROM DBA_2PC_PENDING;

If its found to be in-doubt , we can resolve the unresolved transaction, by forcing the ROLLBACK (ensures that half-committed distributed transactions are undone safely )
 described by the following code: 
 
ROLLBACK FORCE 'LOCAL_TRAN_ID';


7.	Distributed Lock Conflict: In a distributed system, a Distributed Lock Conflict (also known as lock contention) arises when several independent nodes or 
processes try to get an exclusive distributed lock at the same time in order to access a shared resource's critical section. It demonstrates concurrency control between nodes.
UPDATE OrderDetail_B@PROJ_LINK
SET SubTotal = SubTotal * 1.1
WHERE OrderID = 201 AND ProductID = 1;

 This step requires almost 5 sessions: 
a)	Session 1 will be run on node A but without committing it 
b)	Session 2 will be run on node B , resulting in a waiting session.
c)	Session 3 will be to diagnose the waiting session by the following code:
 SELECT
    L.SID, L.BLOCKING_SESSION, S.EVENT
FROM V$SESSION S
JOIN V$LOCK L ON S.SID = L.SID
WHERE S.STATE = 'WAITING';

d)	Session 4, after diagnosing the waiting session, now COMMIT.
e)	Session 5, reconnect to node B (remote), I realized the waited transaction is also committed in a mean time. Now the lock is released and both updates are visible.

8.	Execution Plan Analysis: Execution Plan Analysis is the methodical study of the comprehensive, 
sequential plan also known as a query plan that is produced by the query optimizer of a Database Management System (DBMS) in order to process a particular SQL statement, simply its capturing the query execution strategy
 EXPLAIN PLAN FOR
SELECT ProductID, COUNT(*), SUM(SubTotal)
FROM OrderDetail_ALL
GROUP BY ProductID;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

The output of the above syntax will be a table that shows a series of operations in a specific order, 
detailing how the database expects to satisfy the query. The last line containing SELECT, is the one which retrieves and formats the plan that was just generated.

9.	Declarative Rules Hardening: The main objective of declarative Rules and Hardening is to ensure data integrity through declarative rules such as NOT NULL and CHECK constraints in both fragments (OrderDetail_A and OrderDetail_B).

Below are 3 steps on Declarative Hardening:

First step: Add Constraints on node A 
ALTER TABLE OrderDetail_A 
ADD CONSTRAINT NN_ODA_QTY CHECK (Quantity IS NOT NULL) ENABLE NOVALIDATE;

ALTER TABLE OrderDetail_A 
ADD CONSTRAINT CK_ODA_QTY CHECK (Quantity > 0) ENABLE NOVALIDATE;

ALTER TABLE OrderDetail_A 
ADD CONSTRAINT CK_ODA_SUBTOTAL CHECK (SubTotal > 0) ENABLE NOVALIDATE;

 
Where, CHECK (Quantity IS NOT NULL) ensures that quantity cannot be null, CHECK (Quantity > 0) and CHECK (SubTotal > 0) , enforce business rules preventing invalid or negative data and 
ENABLE NOVALIDATE, activates the constraint for new rows only, without scanning existing data.

Second step: Add Constraints on node B
Similar command are executed on OrderDetail_B
Third step:Constraints Validation Test
In this step, there are almost 3 key important syntaxes: the fisrt is "SQLCODE = -2290" which detects a check constraint violation,
the second is "DBMS_OUTPUT.PUT_LINE" that prints feedback messages in SQL*Plus, and the last is "COMMIT" that finalizes only successful inserts.
In the syntaxes , After committing valid rows (106, 107), two old ones are deleted to maintain ≤ 10 records overall.

10. E–C–A Trigger for Denormalized Totals: The aim of this step in distributed database is to automatically update the OrderInfo_KGL.TotalAmount 
whenever changes occur in OrderDetail_A. Also record changes in an audit table for traceability. It involves five main steps :
Step 1: Pre-Update Totals , where MERGE combines INSERT and UPDATE logic.
Step 2: Create Audit Table , with purpose of log before/after values for any total changes.
Step 3: Create the Trigger,where there are 4 important stages in the syntax 
     Event: AFTER INSERT OR UPDATE OR DELETE — runs after any data change.
     Condition: None explicitly; applies to all affected orders.
     Action: Recalculates totals and logs changes — this is the E–C–A pattern (Event → Condition → Action).
     NVL(SUM(...), 0) ensures a value of 0 if no matching rows exist.
Step 4: Prepare Base Data
Step 5: Execute DML Script, where each statement fires the trigger once, updating totals and writing audit entries.
Step 6:Validate Results, where the audit table shows 2–3 entries recording before/after totals.

  Conclusion 

This project shows how distributed database systems combine performance, dependability, and data management across several nodes. 
It demonstrates how Oracle facilitates transparent data access and processing across networked databases using distributed views,
 database links, table fragmentation, and parallel execution. 
The system's capacity to preserve consistency and bounce back from errors is further demonstrated by the use of two-phase commit and lock management. 
All things considered, the project offers a useful comprehension of how distributed databases accomplish fault tolerance, scalability,
 and effective coordination between distant nodes.

Declarative constraints ensure only valid, meaningful data is stored, while triggers implement real-time synchronization between detailed and 
summarized records. Together, they improve reliability, maintainability, and data consistency across distributed nodes 
illustrating how Oracle’s integrity mechanisms support robust, enterprise-grade database design.
