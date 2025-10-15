CREATE TABLE Supplier(
supplier_id INT PRIMARY KEY NOT NULL,
firstname varchar(20) NOT NULL,
lastname varchar(20) NOT NULL,
contact varchar(10),
email varchar(25) UNIQUE,
city varchar(10) NOT NULL
);

CREATE TABLE Category(
category_id INT PRIMARY KEY NOT NULL,
category_name VARCHAR(50),
description TEXT NOT NULL
);

CREATE TABLE Product(
product_id INT PRIMARY KEY NOT NULL,
product_name VARCHAR(40) NOT NULL,
purchase_price DECIMAL(10,2),
selling_price DECIMAL(10,2),
current_stock INT DEFAULT 0,
created_by VARCHAR(20) NOT NULL,
category_id INT,
FOREIGN KEY(category_id) REFERENCES Category(category_id) ON DELETE CASCADE
);

CREATE TABLE OrderInfo(
order_info_id INT PRIMARY KEY NOT NULL,
amount NUMERIC (10,2),
order_date DATE DEFAULT CURRENT_DATE,
order_type VARCHAR(255) CHECK(order_type IN('sale','purchase')),
total_qty INT,
status VARCHAR(20) CHECK(status IN('paid','unpaid')),
supplier_id INT,
FOREIGN KEY(supplier_id) REFERENCES Supplier(supplier_id)
);

CREATE TABLE OrderDetail(
order_detail_id INT PRIMARY KEY NOT NULL,
product_id INT,
FOREIGN KEY(product_id) REFERENCES Product(product_id),
quantity INT CHECK(quantity>=0),
unit_price NUMERIC(6,2),
sub_total DECIMAL(10,2) CHECK(sub_total>=0)
);

CREATE TABLE Customers(
customer_id INT PRIMARY KEY,
firstname VARCHAR(20) NOT NULL,
lastname VARCHAR(20)NOT NULL,
email VARCHAR(30) UNIQUE,
phone VARCHAR(20),
city VARCHAR(20) 
);

INSERT INTO Supplier(supplier_id,firstname,lastname,contact,email,city)
values
(1, 'karangwa','betty','0785044405','ehakizimana55@gmail.com','musanze'),
(2,'plan','boaz','0786256322','gatseeleo@gmail.com', 'Kigali'),
(3,'tumukunde','monica','0788597722','monituku22@gmail.com','rwamagana');

INSERT INTO Category(category_id,category_name,description)
values
(1,'electronics','gadgets and devices'),
(2,'home appliances','household equipments'),
(3,'agricultural','farming and garden tool');

INSERT INTO Product(product_id,product_name,purchase_price,selling_price,current_stock,created_by,category_id)
values
(1,'computer',1000,1500,10,'emma',1),
(2,'phone',4500,5000,20,'emma',1),
(3,'iron',100,500,50,'kenny',2),
(4, 'refrigerator',2000,3000,5,'enna',2),
(5,'hoe',300,500,10,'emmy',3),
(6,'tractor',15000,20000,2,'emmy',3),
(7,'irrigation pum',1200.35,1300,11,'emmy',3),
(8,'microwave',100.69,2000,6,'kenny',2),
(9,'washing machine',20000,25000,7,'kenny',2),
(10,'television',1000.45,1450.58,30,'emma',1);


