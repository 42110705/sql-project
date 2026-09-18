-- =====================================================================
-- DATABASE SETUP & DDL (SPRINT 2)[cite: 1]
-- =====================================================================
CREATE DATABASE IF NOT EXISTS retail_supply_chain;
USE retail_supply_chain;

-- Drop tables in reverse order of foreign key dependency
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS warehouses;

-- 1. Warehouses Table[cite: 1]
CREATE TABLE warehouses (
    warehouse_id VARCHAR(10) PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    warehouse_type VARCHAR(20) NOT NULL,
    storage_capacity_units INT NOT NULL,
    region VARCHAR(20) NOT NULL,
    opened_date DATE NOT NULL
);

-- 2. Suppliers Table[cite: 1]
CREATE TABLE suppliers (
    supplier_id VARCHAR(10) PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    supplier_category VARCHAR(20) NOT NULL,
    reliability_rating DECIMAL(3,2),
    contract_since DATE NOT NULL
);

-- 3. Staff Table[cite: 1]
CREATE TABLE staff (
    staff_id VARCHAR(10) PRIMARY KEY,
    staff_name VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    rating DECIMAL(3,2),
    employment_type VARCHAR(20) NOT NULL,
    is_active VARCHAR(3) NOT NULL DEFAULT 'Yes'
);

-- 4. Vehicles Table[cite: 1]
CREATE TABLE vehicles (
    vehicle_id VARCHAR(10) PRIMARY KEY,
    vehicle_type VARCHAR(20) NOT NULL,
    fuel_type VARCHAR(20) NOT NULL,
    max_payload_kg DECIMAL(8,2) NOT NULL,
    depot_warehouse_id VARCHAR(10) NOT NULL,
    last_service_date DATE,
    is_active VARCHAR(3) NOT NULL DEFAULT 'Yes',
    CONSTRAINT fk_vehicles_depot FOREIGN KEY (depot_warehouse_id) 
        REFERENCES warehouses(warehouse_id)
);

-- 5. Purchase Orders Table[cite: 1]
CREATE TABLE purchase_orders (
    po_id VARCHAR(20) PRIMARY KEY,
    warehouse_id VARCHAR(10) NOT NULL,
    supplier_id VARCHAR(10) NOT NULL,
    order_date DATE NOT NULL,
    product_category VARCHAR(30) NOT NULL,
    order_priority VARCHAR(10) NOT NULL,
    quantity_ordered INT NOT NULL,
    total_cost DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_po_warehouse FOREIGN KEY (warehouse_id) 
        REFERENCES warehouses(warehouse_id),
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) 
        REFERENCES suppliers(supplier_id)
);

-- 6. Shipments Table[cite: 1]
CREATE TABLE shipments (
    shipment_id VARCHAR(20) PRIMARY KEY,
    po_id VARCHAR(20) NOT NULL,
    staff_id VARCHAR(10) NOT NULL,
    vehicle_id VARCHAR(10) NOT NULL,
    dispatch_date DATE NOT NULL,
    arrival_date DATE,
    status VARCHAR(20) NOT NULL,
    shipment_attempt TINYINT NOT NULL DEFAULT 1,
    distance_km DECIMAL(6,2) NOT NULL,
    transit_duration_hrs INT,
    CONSTRAINT fk_shipments_po FOREIGN KEY (po_id) 
        REFERENCES purchase_orders(po_id),
    CONSTRAINT fk_shipments_staff FOREIGN KEY (staff_id) 
        REFERENCES staff(staff_id),
    CONSTRAINT fk_shipments_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES vehicles(vehicle_id)
);

select * from warehouses;
select * from suppliers;
select * from staff;
select * from purchase_orders;
select * from vehicles;
select * from shipments;

-- =====================================================================
-- DATA IMPORT VERIFICATION (SPRINT 2.2)[cite: 1]
-- =====================================================================
SELECT 'warehouses' AS tbl, COUNT(*) AS total_rows FROM warehouses       -- Expected: 30[cite: 1]
UNION ALL
SELECT 'suppliers', COUNT(*) FROM suppliers                             -- Expected: 150[cite: 1]
UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles                               -- Expected: 90[cite: 1]
UNION ALL
SELECT 'purchase_orders', COUNT(*) FROM purchase_orders                 -- Expected: 5000[cite: 1]
UNION ALL
SELECT 'shipments', COUNT(*) FROM shipments                             -- Expected: 5800[cite: 1]
UNION ALL
SELECT 'staff', COUNT(*) FROM staff;                                    -- Expected: 120[cite: 1]

-- =====================================================================
-- SPRINT 3: BASIC ANALYSIS / DATA EXPLORATION[cite: 1]
-- =====================================================================

-- 1. What is the total number of warehouses?[cite: 1]
SELECT COUNT(*) AS total_warehouses 
FROM warehouses;

-- 2. What is the total number of purchase orders?[cite: 1]
SELECT COUNT(*) AS total_purchase_orders 
FROM purchase_orders;

-- 3. What is the total number of shipments?[cite: 1]
SELECT COUNT(*) AS total_shipments 
FROM shipments;

-- 4. What are the different product categories ordered?[cite: 1]
SELECT DISTINCT product_category 
FROM purchase_orders;

-- 5. How many staff members are currently active?[cite: 1]
SELECT COUNT(*) AS active_staff 
FROM staff 
WHERE is_active = 'Yes';

-- 6. What are the different vehicle types in the fleet?[cite: 1]
SELECT DISTINCT vehicle_type 
FROM vehicles;

-- 7. What is the total cost of all purchase orders?[cite: 1]
SELECT SUM(total_cost) AS total_order_cost 
FROM purchase_orders;

-- 8. What is the average quantity ordered per purchase order?[cite: 1]
SELECT AVG(quantity_ordered) AS avg_quantity 
FROM purchase_orders;

-- =====================================================================
-- SPRINT 4: OBJECTIVE-BASED ANALYSIS[cite: 1]
-- =====================================================================

-- ---------------------------------------------------------------------
-- 4.1 Understand Purchase Order Demand[cite: 1]
-- ---------------------------------------------------------------------

-- Q1: How many orders and how much total money was spent on each product category?[cite: 1]
SELECT 
    product_category,
    COUNT(po_id) AS total_orders,
    SUM(total_cost) AS total_spend
FROM purchase_orders
GROUP BY product_category;

-- Q2: How does order volume change month by month?[cite: 1]
SELECT 
    MONTH(order_date) AS order_month,
    COUNT(po_id) AS total_orders
FROM purchase_orders
GROUP BY MONTH(order_date);

-- Q3: How many orders were placed for each order priority (High, Medium, Low)?[cite: 1]
SELECT 
    order_priority,
    COUNT(po_id) AS total_orders
FROM purchase_orders
GROUP BY order_priority;

-- Q4: Which supplier category (Manufacturer vs. Distributor) received more orders?[cite: 1]
SELECT 
    s.supplier_category,
    COUNT(p.po_id) AS total_orders
FROM suppliers s
JOIN purchase_orders p ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_category;

-- Q5: Who are the top 5 suppliers with the most orders?[cite: 1]
SELECT 
    supplier_id,
    COUNT(po_id) AS total_orders
FROM purchase_orders
GROUP BY supplier_id
ORDER BY total_orders DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- 4.2 Understand Warehouse Ordering Behaviour[cite: 1]
-- ---------------------------------------------------------------------

-- Q1: Which warehouses placed the highest number of purchase orders?[cite: 1]
SELECT 
    warehouse_id,
    COUNT(po_id) AS total_orders
FROM purchase_orders
GROUP BY warehouse_id
ORDER BY total_orders DESC;

-- Q2: What is the total spending on orders for each warehouse?[cite: 1]
SELECT 
    warehouse_id,
    SUM(total_cost) AS total_spend
FROM purchase_orders
GROUP BY warehouse_id
ORDER BY total_spend DESC;

-- Q3: Which region placed the most purchase orders?[cite: 1]
SELECT 
    w.region,
    COUNT(p.po_id) AS total_orders
FROM warehouses w
JOIN purchase_orders p ON w.warehouse_id = p.warehouse_id
GROUP BY w.region;

-- Q4: How does order volume compare across warehouse types (Regional, Local, Distribution Center)?[cite: 1]
SELECT 
    w.warehouse_type,
    COUNT(p.po_id) AS total_orders
FROM warehouses w
JOIN purchase_orders p ON w.warehouse_id = p.warehouse_id
GROUP BY w.warehouse_type;

-- Q5: What is the average order quantity per warehouse?[cite: 1]
SELECT 
    warehouse_id,
    AVG(quantity_ordered) AS avg_quantity
FROM purchase_orders
GROUP BY warehouse_id;

-- ---------------------------------------------------------------------
-- 4.3 Evaluate Shipment Performance[cite: 1]
-- ---------------------------------------------------------------------

-- Q1: What is the total count of shipments for each status (Delivered, Delayed, Damaged, In-Transit)?[cite: 1]
SELECT 
    status,
    COUNT(shipment_id) AS total_shipments
FROM shipments
GROUP BY status;

-- Q2: What is the average transit duration (in hours) across all shipments?[cite: 1]
SELECT 
    AVG(transit_duration_hrs) AS avg_transit_hours
FROM shipments;

-- Q3: How do shipment statuses compare between Manufacturers and Distributors?[cite: 1]
SELECT 
    sup.supplier_category,
    s.status,
    COUNT(s.shipment_id) AS total_shipments
FROM suppliers sup
JOIN purchase_orders po ON sup.supplier_id = po.supplier_id
JOIN shipments s ON po.po_id = s.po_id
GROUP BY sup.supplier_category, s.status;

-- Q4: What is the average transit duration for each order priority?[cite: 1]
SELECT 
    po.order_priority,
    AVG(s.transit_duration_hrs) AS avg_transit_hours
FROM purchase_orders po
JOIN shipments s ON po.po_id = s.po_id
GROUP BY po.order_priority;

-- Q5: How many shipments were dispatched in each month?[cite: 1]
SELECT 
    MONTH(dispatch_date) AS dispatch_month,
    COUNT(shipment_id) AS total_dispatches
FROM shipments
GROUP BY MONTH(dispatch_date);

-- ---------------------------------------------------------------------
-- 4.4 Understand Staff and Vehicle Performance[cite: 1]
-- ---------------------------------------------------------------------

-- Q1: How many shipments did each vehicle type make?[cite: 1]
SELECT 
    v.vehicle_type,
    COUNT(s.shipment_id) AS total_shipments
FROM vehicles v
JOIN shipments s ON v.vehicle_id = s.vehicle_id
GROUP BY v.vehicle_type;

-- Q2: Which 5 vehicles completed the highest number of trips?[cite: 1]
SELECT 
    vehicle_id,
    COUNT(shipment_id) AS total_trips
FROM shipments
GROUP BY vehicle_id
ORDER BY total_trips DESC
LIMIT 5;

-- Q3: Which staff members handled the highest number of shipments?[cite: 1]
SELECT 
    staff_id,
    COUNT(shipment_id) AS total_shipments
FROM shipments
GROUP BY staff_id
ORDER BY total_shipments DESC;

-- Q4: What is the average transit duration for each staff member?[cite: 1]
SELECT 
    staff_id,
    AVG(transit_duration_hrs) AS avg_hours
FROM shipments
GROUP BY staff_id;

-- Q5: What is the recorded rating of staff members who handled shipments?[cite: 1]
SELECT 
    st.staff_id,
    st.staff_name,
    st.rating,
    COUNT(s.shipment_id) AS total_shipments
FROM staff st
JOIN shipments s ON st.staff_id = s.staff_id
GROUP BY st.staff_id, st.staff_name, st.rating;

-- ---------------------------------------------------------------------
-- 4.5 Identify Shipment Problems[cite: 1]
-- ---------------------------------------------------------------------

-- Q1: Which purchase orders required more than 1 shipment attempt?[cite: 1]
SELECT 
    po_id,
    MAX(shipment_attempt) AS total_attempts
FROM shipments
GROUP BY po_id
HAVING MAX(shipment_attempt) > 1;

-- Q2: How many shipments were Delivered, Delayed, or Damaged?[cite: 1]
SELECT 
    status,
    COUNT(shipment_id) AS total_shipments
FROM shipments
WHERE status IN ('Delivered', 'Delayed', 'Damaged')
GROUP BY status;

-- Q3: Which warehouses received the most delayed shipments?[cite: 1]
SELECT 
    po.warehouse_id,
    COUNT(s.shipment_id) AS delayed_shipments
FROM purchase_orders po
JOIN shipments s ON po.po_id = s.po_id
WHERE s.status = 'Delayed'
GROUP BY po.warehouse_id
ORDER BY delayed_shipments DESC;

-- Q4: Which suppliers had the highest number of damaged shipments?[cite: 1]
SELECT 
    po.supplier_id,
    COUNT(s.shipment_id) AS damaged_shipments
FROM purchase_orders po
JOIN shipments s ON po.po_id = s.po_id
WHERE s.status = 'Damaged'
GROUP BY po.supplier_id
ORDER BY damaged_shipments DESC;

-- Q5: How many shipments required repeated attempts (attempt number greater than 1)?[cite: 1]
SELECT 
    shipment_attempt,
    COUNT(shipment_id) AS total_shipments
FROM shipments
WHERE shipment_attempt > 1
GROUP BY shipment_attempt;