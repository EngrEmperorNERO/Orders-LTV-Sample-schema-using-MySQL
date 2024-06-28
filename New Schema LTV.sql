--  THIS QUERY TRIES TO RECREATE THE ENTIRE SCHEMA OF REPORTING AND CLEAN THE CONNECCTIONS
-- JOIN THE PRODUCTS AND THE ITEMS TABLE

-- BASIS OF ITEMS AND PRODUCT JOINS TABLE BASIS
-- TABLE NAME product_items_table
CREATE TABLE product_items_table AS
SELECT items.id AS items_id, items.product_id, items.og_item_id, items.sku, items.unit, items.name, items.subscription, items.is_frontend,
products.cog, items.unit * products.cog AS cogs_per_item, products.type, products.owned
FROM items
JOIN products ON items.product_id = products.id
GROUP BY Items.id
ORDER BY product_id;

-- JOIN THE PRODUCT ITEMS TABLE TO ORDER_ITEMS TABLE
SELECT * FROM ORDER_ITEMS LIMIT 10;  -- CONNECTION TO THE product_items_table IS THE OG_ITEM_ID TO ITEM_ID
DROP TABLE orderitems_itemsproducts_tablejoin;
CREATE TABLE orderitems_itemsproducts_tablejoin AS  -- TRYING TO REMOVE THE DISTINCT HERE JUST TO CHECK WHAT WILL HAPPEN
SELECT 
  order_items.id AS order_items_id, 
  order_items.order_id, 
  order_items.item_id, 
  order_items.description, 
  order_items.quantity,
  product_items_table.cog,
  product_items_table.cogs_per_item, 
  product_items_table.sku
FROM 
  order_items
JOIN 
  product_items_table ON order_items.item_id = product_items_table.og_item_id
JOIN (
  SELECT DISTINCT order_id 
  FROM order_items
) AS distinct_orders ON order_items.order_id = distinct_orders.order_id
ORDER BY 
  order_items.order_id;


SELECT * FROM orderitems_itemsproducts_tablejoin limit 1000; -- cogs evens up
-- join the orderitems_itemsproducts_tablejoin  to the orders table to get the amount
SELECT * FROM orders LIMIT 10;
-- JOIN TO THE orderitems_itemsproducts_tablejoin  TO THE ORDERS TO GET THE ORDER_TOTAL_COST




SELECT * FROM orderitems_itemsproducts_tablejoin;

-- 9/27/23 dont join the orderitems_itemsproducts_tablejoin to the orders ltv
-- join the  above table   to  the orders ltv
CREATE TABLE final_orders_ltv AS
-- DROP TABLE final_orders_ltv;
SELECT orders_ltv.*, subquery.total_cogs_per_item
FROM orders_ltv
JOIN (
    SELECT order_id, SUM(final_cogs_per_item) as total_cogs_per_item
    FROM orderitems_itemsproducts_tablejoin
    GROUP BY order_id
) as subquery
ON orders_ltv.order_id = subquery.order_id; 

--  created  the final_orders_ltv
SELECT * FROM final_orders_ltv WHERE order_id =  84923; -- why disrepancy? computed is 60.27 on orders ltv it is 112.35
-- check on oder_items
SELECT * FROM order_items  WHERE order_id = 84923; --
SELECT   * FROM  orderitems_itemsproducts_tablejoin WHERE order_id = 84923;
-- intermediate calculation
-- the calculation for final cogs will be done on the intermediate table
CREATE TABLE orderitems_itemsproducts_tablejoin AS
SELECT 
  order_items.id AS order_items_id, 
  order_items.order_id, 
  order_items.item_id, 
  order_items.description, 
  order_items.quantity,
  product_items_table.cog,
  product_items_table.cogs_per_item, 
  product_items_table.cogs_per_item  * order_items.quantity AS Final_cogs_per_item,
  product_items_table.sku
FROM 
  order_items
JOIN 
  product_items_table ON order_items.item_id = product_items_table.og_item_id
JOIN (
  SELECT DISTINCT order_id 
  FROM order_items
) AS distinct_orders ON order_items.order_id = distinct_orders.order_id
ORDER BY 
  order_items.order_id;
  
  select * from orderitems_itemsproducts_tablejoin WHERE quantity > 1;
  
  -- incorporate this to the orders ltv
-- NEW VERSION OF FINAL ORDERS LTV WHERE I DONT SUM THE FINAL COGS PER ITEM
CREATE TABLE final_orders_ltv AS
-- DROP TABLE final_orders_ltv;
SELECT orders_ltv.*, orderitems_itemsproducts_tablejoin.final_cogs_per_item
FROM orders_ltv
JOIN orderitems_itemsproducts_tablejoin
ON orders_ltv.order_id = orderitems_itemsproducts_tablejoin.order_id
GROUP BY orders_ltv.order_id; 
-- above is old
CREATE TABLE final_orders_ltv AS
SELECT orders_ltv.*, subquery.total_cogs_per_item
FROM orders_ltv
JOIN (
    SELECT order_id, SUM(final_cogs_per_item) as total_cogs_per_item
    FROM orderitems_itemsproducts_tablejoin
    GROUP BY order_id
) as subquery
ON orders_ltv.order_id = subquery.order_id;

select  * from final_orders_ltv where ORDER_ID = 15; -- ORDER ID 15 ON ORDERS LTV 39.06 ON COMPUTED 78.12
SELECT * FROM final_orders_ltv WHERE order_id = 84923; -- CCOGS COST IS 112.35 COMPUTED IS 73.29
SELECT * FROM  orderitems_itemsproducts_tablejoin WHERE order_id = 15; -- COGS COST ON ORDERS LTV IS 112.35
select * FROM order_items WHERE id = 84923; -- item id is SATBSS01



SELECT * FROM final_orders_ltv WHERE cogs_cost -  total_cogs_per_item != 0;
-- order id 4 orig cogs cost
-- order_id 4, order_id 15 order_id 20 and order_id 23
SELECT * FROM orderitems_itemsproducts_tablejoin WHERE order_id  IN(4,15,20,23);
-- go to the joining of produccts and items 
SELECT * FROM orders_ltv WHERE order_id = 84923;

SELECT * FROM final_orders_ltv WHERE order_id = 4;

-- CURRENT PROBLEM AS OF 5:14 AM IS THE DUPLICATS ON orderitems_itemsproducts_tablejoin
DROP TABLE orderitems_itemsproducts_tablejoin;
CREATE TABLE orderitems_itemsproducts_tablejoin AS
SELECT DISTINCT
  order_items.id AS order_items_id, 
  order_items.order_id, 
  order_items.item_id, 
  order_items.description, 
  order_items.quantity,
  product_items_table.cog,
  product_items_table.cogs_per_item, 
  product_items_table.cogs_per_item  * order_items.quantity AS Final_cogs_per_item,
  product_items_table.sku
FROM 
  order_items
JOIN 
  product_items_table ON order_items.item_id = product_items_table.og_item_id
JOIN (
  SELECT DISTINCT order_id 
  FROM order_items
) AS distinct_orders ON order_items.order_id = distinct_orders.order_id
ORDER BY 
  order_items.order_id;
  
-- drop final order_ltv then join it
DROP table final_orders_ltv;
CREATE TABLE final_orders_ltv AS
SELECT orders_ltv.*, subquery.total_cogs_per_item
FROM orders_ltv
JOIN (
    SELECT order_id, SUM(final_cogs_per_item) as total_cogs_per_item
    FROM orderitems_itemsproducts_tablejoin
    GROUP BY order_id
) as subquery
ON orders_ltv.order_id = subquery.order_id;

SELECT * FROM final_orders_ltv;
-- checking for the difference

SELECT * FROM final_orders_ltv WHERE cogs_cost -  total_cogs_per_item > 1;
-- initial judgement --  the  final orders_ltv is ready to go
-- Now that the orders ltv recreate is solve -- You can solve the INV products to have a zero cogs as well
SELECT * FROM final_orders_ltv WHERE EMAIL = 'nickr@beverlyhills-md.com'; -- THIS EMAIL IS NOT HERE 
SELECT * FROM final_orders_ltv WHERE EMAIL = 'mozes@healthlifeny.com'; -- NOT HERE  ALSO THIS EMAIL
SELECT * FROM final_orders_ltv WHERE EMAIL = 'orders@upwellness.com'; -- THIS EMAIL IS HERE
-- THE final_orders_ltv WE MIGHT CONSIDER THE OUTER JOIN SO WE CAN SEE THE mozes@healthlifeny.com THIS EMAIL
SELECT * FROM orders_ltv WHERE email = 'mozes@healthlifeny.com'; -- order id of this email is  275647, 276575
SELECT  * FROM order_items WHERE order_id  IN (275647, 276575);
select * from orderitems_itemsproducts_tablejoin  WHERE order_id  IN (275647, 276575); -- the order id is not here.  Why?


-- use final_orders_ltv1: used left join instead of inner join to query those orders
-- observation:use left join to the orderitems_itemsproducts_tablejoin 
SELECT * FROM items WHERE og_item_id = 'SARPAS';
-- USE LEFT OUTER JOIN FOR FINAL ORDERS LTV1
CREATE TABLE final_orders_ltv1 AS
SELECT orders_ltv.*, subquery.total_cogs_per_item
FROM orders_ltv
LEFT JOIN (
    SELECT order_id, SUM(final_cogs_per_item) as total_cogs_per_item
    FROM orderitems_itemsproducts_tablejoin
    GROUP BY order_id
) as subquery
ON orders_ltv.order_id = subquery.order_id;
SELECT * FROM final_orders_ltv1 WHERE email = 'mozes@healthlifeny.com';
SELECT * FROM final_orders_ltv1 WHERE TOTAL_COGS_PER_ITEM IS NULL;
-- ORDER_ITEMS AND PRODUCT AND ITEMS MUST BE UPDATED
-- DO THE TASK TASK 1 DAVID
SELECT 
    o.ref_id_orig, 
    SUM(o.order_total) AS Gross_Sales, 
    COUNT(o.customer_id) AS Total_number_of_orders,
    SUM(o.refund_amount) AS Total_Refund, 
    SUM(o.total_cogs_per_item) AS Total_cogs, 
    SUM(shipping_cost),
    SUM(other_cost),
    SUM(o.order_total - o.SHIPPING_COST - o.REFUND_AMOUNT - o.TOTAL_COGS_PER_ITEM - o.other_cost) AS PROFIT
FROM final_orders_ltv1 o
GROUP BY  o.ref_id_orig
ORDER BY PROFIT DESC;

-- DO TASK 2
SELECT
    Order_Month,
    Order_Year,
    Gross_Sales,
    Total_number_of_orders,
    Total_Shipping_cost,
    Sum_other_cost,
    Total_Refund, 
    Total_cogs, 
    (Gross_Sales - Total_Shipping_cost - Total_Refund - Total_cogs - Sum_other_cost) AS PROFIT
FROM (
    SELECT
        MONTH(o.purchase_date) AS Order_Month,
        YEAR(o.purchase_date) AS Order_Year,
        SUM(o.order_total) AS Gross_Sales, 
        COUNT(o.customer_id) AS Total_number_of_orders,
        SUM(shipping_cost) AS Total_Shipping_cost,
        SUM(other_cost) AS Sum_other_cost,
        SUM(o.refund_amount) AS Total_Refund, 
        SUM(o.total_cogs_per_item) AS Total_cogs
    FROM final_orders_ltv1 o
    WHERE o.order_seq = 1 AND purchase_date >= '2020-09-01'
    GROUP BY YEAR(o.purchase_date), MONTH(o.purchase_date)
) AS subquery
ORDER BY Order_Year, Order_Month ASC;

-- possible changes to the query is the min purchase order for every order

SELECT
    Order_Month,
    Order_Year,
    Gross_Sales,
    Total_number_of_orders,
    Total_Shipping_cost,
    Sum_other_cost,
    Total_Refund, 
    Total_cogs, 
    (Gross_Sales - Total_Shipping_cost - Total_Refund - Total_cogs - Sum_other_cost) AS PROFIT
FROM (
    SELECT
        MONTH(o.purchase_date) AS Order_Month,
        YEAR(o.purchase_date) AS Order_Year,
        SUM(o.order_total) AS Gross_Sales, 
        COUNT(o.customer_id) AS Total_number_of_orders,
        SUM(shipping_cost) AS Total_Shipping_cost,
        SUM(other_cost) AS Sum_other_cost,
        SUM(o.refund_amount) AS Total_Refund, 
        SUM(o.total_cogs_per_item) AS Total_cogs
    FROM final_orders_ltv1 o
    WHERE o.order_seq = 1 AND purchase_date >= '2020-09-01'
    GROUP BY YEAR(o.purchase_date), MONTH(o.purchase_date)
) AS subquery
ORDER BY Order_Year, Order_Month ASC;


SELECT
    Order_Month,
    Order_Year,
    Gross_Sales,
    Total_number_of_orders,
    Total_Shipping_cost,
    Sum_other_cost,
    Total_Refund, 
    Total_cogs, 
    (Gross_Sales - Total_Shipping_cost - Total_Refund - Total_cogs - Sum_other_cost) AS PROFIT
FROM (
    SELECT
        MONTH(o.purchase_date) AS Order_Month,
        YEAR(o.purchase_date) AS Order_Year,
        SUM(o.order_total) AS Gross_Sales, 
        COUNT(o.customer_id) AS Total_number_of_orders,
        SUM(shipping_cost) AS Total_Shipping_cost,
        SUM(other_cost) AS Sum_other_cost,
        SUM(o.refund_amount) AS Total_Refund, 
        SUM(o.total_cogs_per_item) AS Total_cogs
    FROM (
        SELECT
            customer_id,
            MIN(purchase_date) as first_purchase_date
        FROM final_orders_ltv1
        GROUP BY customer_id
    ) first_orders
    JOIN final_orders_ltv1 o ON first_orders.customer_id = o.customer_id AND first_orders.first_purchase_date = o.purchase_date
    WHERE o.purchase_date >= '2020-09-01'
    GROUP BY YEAR(o.purchase_date), MONTH(o.purchase_date)
) AS subquery
ORDER BY Order_Year, Order_Month ASC;
-- another version of task ii
SELECT
    Order_Month,
    Order_Year,
    Gross_Sales,
    Total_number_of_orders,
    Total_Shipping_cost,
    Sum_other_cost,
    Total_Refund, 
    Total_cogs, 
    (Gross_Sales - Total_Shipping_cost - Total_Refund - Total_cogs - Sum_other_cost) AS PROFIT
FROM (
    SELECT
        MONTH(o.purchase_date) AS Order_Month,
        YEAR(o.purchase_date) AS Order_Year,
        SUM(o.order_total) AS Gross_Sales, 
        COUNT(o.customer_id) AS Total_number_of_orders,
        SUM(shipping_cost) AS Total_Shipping_cost,
        SUM(other_cost) AS Sum_other_cost,
        SUM(o.refund_amount) AS Total_Refund, 
        SUM(o.total_cogs_per_item) AS Total_cogs,
        COUNT(o.customer_id) / SUM(shipping_cost) AS average_cost_per_shipping
    FROM (
        SELECT
            customer_id,
            MIN(purchase_date) as first_purchase_date
        FROM final_orders_ltv1
        WHERE order_seq = 1  -- Add this condition to filter only first orders
        GROUP BY customer_id
    ) first_orders
    JOIN final_orders_ltv1 o ON first_orders.customer_id = o.customer_id AND first_orders.first_purchase_date = o.purchase_date
    WHERE o.purchase_date >= '2020-09-01'
    GROUP BY YEAR(o.purchase_date), MONTH(o.purchase_date)
) AS subquery
ORDER BY Order_Year, Order_Month ASC;

SELECT * FROM final_orders_ltv1 WHERE order_seq=1;


-- this is the version of the task 2 where i used order_seq =1
SELECT
    Order_Month,
    Order_Year,
    Gross_Sales,
    Total_number_of_orders,
    Total_Shipping_cost,
    Sum_other_cost,
    Total_Refund, 
    Total_cogs, 
    (Gross_Sales - Total_Shipping_cost - Total_Refund - Total_cogs - Sum_other_cost) AS PROFIT
FROM (
    SELECT
        MONTH(o.purchase_date) AS Order_Month,
        YEAR(o.purchase_date) AS Order_Year,
        SUM(o.order_total) AS Gross_Sales, 
        COUNT(o.order_id) AS Total_number_of_orders,
        SUM(shipping_cost) AS Total_Shipping_cost,
        SUM(other_cost) AS Sum_other_cost,
        SUM(o.refund_amount) AS Total_Refund, 
        SUM(o.total_cogs_per_item) AS Total_cogs
    FROM final_orders_ltv1 o
    WHERE o.purchase_date >= '2020-09-01'
      AND o.order_seq = 1  -- Filter only the first purchase for each customer
    GROUP BY YEAR(o.purchase_date), MONTH(o.purchase_date)
) AS subquery
ORDER BY Order_Year, Order_Month ASC;


-- another approach use intermediate table to get the customers very first orders after sep 2020
CREATE TABLE First_purchaseLTV AS
SELECT * FROM final_orders_ltv1 WHERE order_seq = 1 AND purchase_date >= '2020-09-01';

SELECT 
    SUM(shipping_cost)
FROM 
    First_purchaseLTV 
WHERE 
    MONTH(PURCHASE_DATE) = 9;  -- 77,547,79

SELECT 
    COUNT(order_id)
FROM 
    First_purchaseLTV 
WHERE 
    MONTH(PURCHASE_DATE) = 9 AND YEAR(purchase_date) = 2020; -- 38,943 -- must be order_id

-- try to  grab the shipping cost  on order_items
SELECT * FROM order_items;
SELECT * FROM orders;
CREATE TABLE orderitems_itemsproducts_tablejoin AS  -- TRYING TO REMOVE THE DISTINCT HERE JUST TO CHECK WHAT WILL HAPPEN
SELECT 
  order_items.id AS order_items_id, 
  order_items.order_id, 
  order_items.item_id, 
  order_items.description, 
  order_items.quantity,
  product_items_table.cog,
  product_items_table.cogs_per_item, 
  product_items_table.sku
FROM 
  order_items
JOIN 
  product_items_table ON order_items.item_id = product_items_table.og_item_id
JOIN (
  SELECT DISTINCT order_id 
  FROM order_items
) AS distinct_orders ON order_items.order_id = distinct_orders.order_id
ORDER BY 
  order_items.order_id;
  
  -- FIRST PURCHASE LTV ARE THE FIRST PURCHASES OF EVERY CUSTOMER
  SELECT * FROM first_purchaseltv ORDER BY purchase_date ASC;
  -- YOU CAN ALREADY GROUP BY THE MONTH FOR THIS
SELECT 
		MONTH(purchase_date) AS Order_Month,
        YEAR(purchase_date) AS Order_Year,
        SUM(order_total) AS Gross_Sales, 
        COUNT(id) AS Total_number_of_orders,
        SUM(shipping_cost) AS Total_Shipping_cost,
        SUM(other_cost) AS Sum_other_cost,
        SUM(refund_amount) AS Total_Refund, 
        SUM(total_cogs_per_item) AS Total_cogs,
        SUM(order_total) - SUM(shipping_cost) - SUM(other_cost) - SUM(refund_amount) - SUM(total_cogs_per_item) AS profit
FROM first_purchaseltv
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
ORDER BY Order_Year, Order_Month ASC; 
--  COUNT THE SHIPPING COST WHERE IT HAS VALUE IF IT  ZERO  THEN  DONT
--  getting the month of september
SELECT 
		order_id,
        order_total,
        shipping_cost,
        other_cost,
        refund_amount, 
        total_cogs_per_item
FROM first_purchaseltv
WHERE  MONTH(purchase_date) = 10 AND YEAR(purchase_date) =2020
ORDER BY Order_Year, Order_Month ASC; 
-- order 88338 has 466 order_total
SELECT * FROM  orders WHERE id = 88338;
-- Testing the shipping cost on orders table
SELECT SUM(shipping_cost) FROM orders
WHERE MONTH(purchase_date) = 9 AND YEAR(purchase_date) = 2020;
CREATE TABLE orders_temptable AS
SELECT * FROM orders;
ALTER TABLE orders_temptable
ADD COLUMN new_shipping_cost DECIMAL(10,2);
UPDATE orders_temptable
SET new_shipping_cost = CAST(REPLACE(shipping_cost, '$', '') AS DECIMAL(10,2));

-- UPDATE orders_temptable
-- SET new_shipping_cost = CAST(new_shipping_cost AS INT);



SELECT shipping_cost
FROM orders_temptable
WHERE NOT shipping_cost REGEXP '^[0-9]+(\.[0-9]+)?$';
-- group by customer id -- every customer has many orders
SELECT * FROM first_purchaseltv ORDER BY customer_id ASC;
-- the plan is on the first_purchase ltv get the sum of all per customer-
-- then compute it that's how
-- but still the sum of the shipping cost is the sum of shipping cost? Weird? right?



-- analysis task 2
SELECT 
    MONTH(purchase_date) AS Order_Month,
    YEAR(purchase_date) AS Order_Year,
    SUM(order_total) AS Gross_Sales, 
    COUNT(id) AS Total_number_of_orders,
    SUM(shipping_cost) AS Total_Shipping_cost,
    SUM(other_cost) AS Sum_other_cost,
    SUM(refund_amount) AS Total_Refund, 
    SUM(total_cogs_per_item) AS Total_cogs,
    SUM(order_total) 
        - SUM(shipping_cost) 
        - SUM(other_cost) 
        - SUM(refund_amount) 
        - SUM(total_cogs_per_item) AS profit,
    SUM(CASE WHEN shipping_cost = 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Zero_Shipping_Fee,
    SUM(CASE WHEN shipping_cost != 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Shipping_Fee,
    SUM(CASE WHEN shipping_cost = 0 THEN order_total ELSE 0 END) AS Total_Order_Total_No_Shipping_Fee,
    SUM(CASE WHEN shipping_cost != 0 THEN order_total ELSE 0 END) AS Total_Order_Total_With_Shipping_Fee
FROM first_purchaseltv
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
ORDER BY Order_Year, Order_Month ASC;

-- check for duplicates 
SELECT customer_id, COUNT(customer_id) as count
FROM first_purchaseltv
GROUP BY customer_id
HAVING COUNT(customer_id) > 1;

SELECT fp.*
FROM first_purchaseltv fp
JOIN (
    SELECT customer_id
    FROM first_purchaseltv
    GROUP BY customer_id
    HAVING COUNT(customer_id) > 1
) dup ON fp.customer_id = dup.customer_id
ORDER BY customer_id, purchase_date;



-- create orders mini table and customers mini table using final_orders_ltv1
-- ORDERS MINI TABLE







-- CUSTOMERS MINI TABLE

--  CLEANING THE ORDERS TABLE




-- redoing the task 2
-- the  problem  with task 2 is it   is not  really  the  first purchase of customer
--  there are lots  or  order seq 1
SELECT * FROM orders WHERE id = 89650;
SELECT * FROM order_items WHERE order_id = 89650;
SELECT 
    MONTH(purchase_date) AS Order_Month,
    YEAR(purchase_date) AS Order_Year,
    SUM(order_total) AS Gross_Sales, 
    COUNT(id) AS Total_number_of_orders,
    SUM(shipping_cost) AS Total_Shipping_cost,
    SUM(other_cost) AS Sum_other_cost,
    SUM(refund_amount) AS Total_Refund, 
    SUM(total_cogs_per_item) AS Total_cogs,
    SUM(order_total) 
        - SUM(shipping_cost) 
        - SUM(other_cost) 
        - SUM(refund_amount) 
        - SUM(total_cogs_per_item) AS profit,
    SUM(CASE WHEN shipping_cost = 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Zero_Shipping_Fee,
    SUM(CASE WHEN shipping_cost != 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Shipping_Fee,
    SUM(CASE WHEN shipping_cost = 0 THEN order_total ELSE 0 END) AS Total_Order_Total_No_Shipping_Fee,
    SUM(CASE WHEN shipping_cost != 0 THEN order_total ELSE 0 END) AS Total_Order_Total_With_Shipping_Fee
FROM final_orders_ltv1
GROUP BY YEAR(purchase_date), MONTH(purchase_date)
ORDER BY Order_Year, Order_Month ASC;

-- get the 1st ever purchase of customer through min purchase date then aggregate
-- updated task ii
SELECT 
    MONTH(purchase_date) AS Order_Month,
    YEAR(purchase_date) AS Order_Year,
    SUM(order_total) AS Gross_Sales, 
    COUNT(id) AS Total_number_of_orders,
    SUM(shipping_cost) AS Total_Shipping_cost,
    SUM(other_cost) AS Sum_other_cost,
    SUM(refund_amount) AS Total_Refund, 
    SUM(total_cogs_per_item) AS Total_cogs,
    SUM(order_total) 
        - SUM(shipping_cost) 
        - SUM(other_cost) 
        - SUM(refund_amount) 
        - SUM(total_cogs_per_item) AS profit,
    SUM(CASE WHEN shipping_cost = 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Zero_Shipping_Fee,
    SUM(CASE WHEN shipping_cost != 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Shipping_Fee,
    SUM(CASE WHEN shipping_cost = 0 THEN order_total ELSE 0 END) AS Total_Order_Total_No_Shipping_Fee,
    SUM(CASE WHEN shipping_cost != 0 THEN order_total ELSE 0 END) AS Total_Order_Total_With_Shipping_Fee
FROM 
(
    SELECT 
        customer_id,
        MIN(purchase_date) as first_purchase_date
    FROM final_orders_ltv1
    WHERE purchase_date >= '2020-09-01'
    GROUP BY customer_id
) first_purchase_dates
JOIN final_orders_ltv1 ON first_purchase_dates.customer_id = final_orders_ltv1.customer_id 
                      AND first_purchase_dates.first_purchase_date = final_orders_ltv1.purchase_date
GROUP BY YEAR(final_orders_ltv1.purchase_date), MONTH(final_orders_ltv1.purchase_date)
ORDER BY Order_Year, Order_Month ASC;
--  extract first time orders 09-01-23
CREATE TABLE first_time_purchase_ltv AS
SELECT o.*
FROM final_orders_ltv1 o
JOIN (
    SELECT 
        customer_id,
        MIN(purchase_date) as first_purchase_date
    FROM final_orders_ltv1
    GROUP BY customer_id
) first_purchase_dates ON o.customer_id = first_purchase_dates.customer_id 
                       AND o.purchase_date = first_purchase_dates.first_purchase_date
WHERE o.purchase_date >= '2020-09-01';

SELECT * FROM first_time_purchase_ltv JOIN
orderitems_itemsproducts_tablejoin ON first_time_purchase_ltv.order_id = orderitems_itemsproducts_tablejoin.order_id
ORDER BY first_time_purchase_ltv.purchase_date;
-- filter by months
SELECT * 
FROM first_time_purchase_ltv 
JOIN orderitems_itemsproducts_tablejoin ON first_time_purchase_ltv.order_id = orderitems_itemsproducts_tablejoin.order_id
WHERE first_time_purchase_ltv.purchase_date BETWEEN '2020-09-01' AND '2020-09-30'
ORDER BY first_time_purchase_ltv.purchase_date;


SELECT* FROM first_time_purchase_ltv WHERE purchase_date BETWEEN '2020-09-01' AND '2020-09-30';
SELECT SUM(order_total) AS Total_Order_Amount
FROM first_time_purchase_ltv 
WHERE purchase_date BETWEEN '2020-09-01' AND '2020-09-30';

WITH DistinctOrders AS (
    SELECT DISTINCT first_time_purchase_ltv.order_id
    FROM first_time_purchase_ltv 
    JOIN orderitems_itemsproducts_tablejoin ON first_time_purchase_ltv.order_id = orderitems_itemsproducts_tablejoin.order_id
    WHERE first_time_purchase_ltv.purchase_date BETWEEN '2020-09-01' AND '2020-09-30'
)

SELECT first_time_purchase_ltv.*
FROM first_time_purchase_ltv
JOIN DistinctOrders ON first_time_purchase_ltv.order_id = DistinctOrders.order_id
ORDER BY first_time_purchase_ltv.purchase_date;


-- USE THE FIRST_TIME_PURCHASE_LTV
SELECT 
    MONTH(purchase_date) AS Order_Month,
    YEAR(purchase_date) AS Order_Year,
    SUM(order_total) AS Gross_Sales, 
    COUNT(id) AS Total_number_of_orders,
    SUM(shipping_cost) AS Total_Shipping_cost,
    SUM(other_cost) AS Sum_other_cost,
    SUM(refund_amount) AS Total_Refund, 
    SUM(total_cogs_per_item) AS Total_cogs,
    SUM(order_total) 
        - SUM(shipping_cost) 
        - SUM(other_cost) 
        - SUM(refund_amount) 
        - SUM(total_cogs_per_item) AS profit,
    SUM(CASE WHEN shipping_cost = 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Zero_Shipping_Fee,
    SUM(CASE WHEN shipping_cost != 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Shipping_Fee,
    SUM(CASE WHEN shipping_cost = 0 THEN order_total ELSE 0 END) AS Total_Order_Total_No_Shipping_Fee,
    SUM(CASE WHEN shipping_cost != 0 THEN order_total ELSE 0 END) AS Total_Order_Total_With_Shipping_Fee
FROM 
(
    SELECT 
        customer_id,
        MIN(purchase_date) as first_purchase_date
    FROM first_time_purchase_ltv
    WHERE purchase_date >= '2020-09-01'
    GROUP BY customer_id
) first_purchase_dates
JOIN first_time_purchase_ltv ON first_purchase_dates.customer_id = first_time_purchase_ltv.customer_id 
                      AND first_purchase_dates.first_purchase_date = first_time_purchase_ltv.purchase_date
GROUP BY YEAR(first_time_purchase_ltv.purchase_date), MONTH(first_time_purchase_ltv.purchase_date)
ORDER BY Order_Year, Order_Month ASC;

-- Grab Zero Shipping costfrom final_orders_ltv1
SELECT  * FROM final_orders_ltv1 WHERE  shipping_cost =  0;

WITH DistinctOrders AS (
    SELECT DISTINCT final_orders_ltv1.order_id
    FROM final_orders_ltv1
    JOIN orderitems_itemsproducts_tablejoin ON final_orders_ltv1.order_id = orderitems_itemsproducts_tablejoin.order_id
    WHERE final_orders_ltv1.purchase_date BETWEEN '2020-09-01' AND '2020-09-30'
    AND final_orders_ltv1.shipping_cost = 0
)

SELECT final_orders_ltv1.*, orderitems_itemsproducts_tablejoin.*
FROM final_orders_ltv1
JOIN DistinctOrders ON final_orders_ltv1.order_id = DistinctOrders.order_id
JOIN orderitems_itemsproducts_tablejoin ON final_orders_ltv1.order_id = orderitems_itemsproducts_tablejoin.order_id
ORDER BY final_orders_ltv1.purchase_date;


WITH DistinctOrders AS (
    SELECT DISTINCT final_orders_ltv1.order_id
    FROM final_orders_ltv1
    JOIN orderitems_itemsproducts_tablejoin ON final_orders_ltv1.order_id = orderitems_itemsproducts_tablejoin.order_id
    WHERE final_orders_ltv1.purchase_date BETWEEN '2020-09-01' AND '2020-09-30'
    AND final_orders_ltv1.shipping_cost = 0
)

SELECT final_orders_ltv1.*, orderitems_itemsproducts_tablejoin.*
FROM (
    SELECT DISTINCT order_id
    FROM DistinctOrders
) DistinctOrders
JOIN final_orders_ltv1 ON DistinctOrders.order_id = final_orders_ltv1.order_id
JOIN orderitems_itemsproducts_tablejoin ON DistinctOrders.order_id = orderitems_itemsproducts_tablejoin.order_id
ORDER BY final_orders_ltv1.purchase_date;


--  check group by order_id on  final_orders_ltv
SELECT * FROM  final_orders_ltv1 ORDER BY order_id;
SELECT * FROM  orders_ltv ORDER BY order_id;
SELECT * FROM order_items ORDER BY order_id;

 SELECT id,order_id, COUNT(order_id)
    FROM order_items
    GROUP BY order_id
    HAVING COUNT(order_id) > 1;


SELECT o.id, o.order_id, sub.count_per_order
FROM order_items o
JOIN (
    SELECT order_id, COUNT(order_id) AS count_per_order
    FROM order_items
    GROUP BY order_id
    HAVING COUNT(order_id) > 1
) sub ON o.order_id = sub.order_id
ORDER  BY o.id;

-- if 1 to many  relationship orders to order items
-- there's wrong with the joining of order items and product and item joint table
-- checking the order items and product and item joint table
SELECT * FROM orderitems_itemsproducts_tablejoin WHERE order_id = 84679;  -- MANY ORDER ID TO ITEM THAT'S GOOD
SELECT * FROM final_orders_ltv1 WHERE order_id =84679;

SELECT customer_id, count(order_id) FROM final_orders_ltv1
group by customer_id;
-- it is okay because we sum it up
-- thpbook
SELECT * FROM ITEMS WHERE og_item_id = 'THPBOOK';
select * from ORDER_ITEMS WHERE order_id = 84679;
select * from orderitems_itemsproducts_tablejoin WHERE order_id = 84679;
SELECT * FROM final_orders_ltv1  WHERE order_id = 84679;
 -- item id on final_orders_ltv1 is misleading
-- SMHM00003 MANUKA MIRACLE  SAHNY000  FREE BOOK THE HONEY PHENOMENON
-- every id on order items many order_id
--  the problem is the joining of orderitems_itemsproducts_tablejoin AND the orders_ltv
 SELECT id, order_id, COUNT(order_id)
    FROM orders_ltv
    GROUP BY order_id
    HAVING COUNT(order_id) > 1;

SELECT id, order_id, COUNT(order_id)
FROM orders_ltv
GROUP BY id, order_id
HAVING COUNT(order_id) > 1;
-- orders ltv is summary already

-- SOLVE ORDERS TABLE SHIPPING COST AND OTHERS WITH $0.00 VARCHAR TO DECIMAL

-- SEND DAVID ORDERS WITH ZERO SHIPPING COST (DONE)
WITH DistinctOrders AS (
    SELECT DISTINCT final_orders_ltv1.order_id
    FROM final_orders_ltv1
    JOIN orderitems_itemsproducts_tablejoin ON final_orders_ltv1.order_id = orderitems_itemsproducts_tablejoin.order_id
    WHERE final_orders_ltv1.purchase_date BETWEEN '2020-09-01' AND '2020-09-30'
    AND final_orders_ltv1.shipping_cost = 0
)

SELECT final_orders_ltv1.*, orderitems_itemsproducts_tablejoin.*
FROM (
    SELECT DISTINCT order_id
    FROM DistinctOrders
) DistinctOrders
JOIN final_orders_ltv1 ON DistinctOrders.order_id = final_orders_ltv1.order_id
JOIN orderitems_itemsproducts_tablejoin ON DistinctOrders.order_id = orderitems_itemsproducts_tablejoin.order_id
ORDER BY final_orders_ltv1.purchase_date;

-- BREAKDOWN OF ITEMS PER MONTH AND EVERY ORDER STARTING FROM OCTOBER 2020 TO AUGUST 2023 (MUST BE DONE)
WITH DistinctOrders AS (
    SELECT DISTINCT final_orders_ltv1.order_id
    FROM final_orders_ltv1
    JOIN orderitems_itemsproducts_tablejoin ON final_orders_ltv1.order_id = orderitems_itemsproducts_tablejoin.order_id
    WHERE final_orders_ltv1.purchase_date BETWEEN '2020-10-01' AND '2020-10-31'
)

SELECT final_orders_ltv1.*, orderitems_itemsproducts_tablejoin.*
FROM (
    SELECT DISTINCT order_id
    FROM DistinctOrders
) DistinctOrders
JOIN final_orders_ltv1 ON DistinctOrders.order_id = final_orders_ltv1.order_id
JOIN orderitems_itemsproducts_tablejoin ON DistinctOrders.order_id = orderitems_itemsproducts_tablejoin.order_id
ORDER BY final_orders_ltv1.purchase_date;

-- trying another query
WITH DistinctOrders AS (
    SELECT DISTINCT first_time_purchase_ltv.order_id
    FROM first_time_purchase_ltv 
    JOIN orderitems_itemsproducts_tablejoin ON first_time_purchase_ltv.order_id = orderitems_itemsproducts_tablejoin.order_id
    WHERE first_time_purchase_ltv.purchase_date BETWEEN '2020-09-01' AND '2020-09-30'
)

SELECT first_time_purchase_ltv.*
FROM first_time_purchase_ltv
JOIN DistinctOrders ON first_time_purchase_ltv.order_id = DistinctOrders.order_id
ORDER BY first_time_purchase_ltv.purchase_date;

-- redoing task 2
SELECT * FROM final_orders_ltv1 LIMIT 10;
SELECT 
    MONTH(first_purchase_dates.first_purchase_date) AS Order_Month,
    YEAR(first_purchase_dates.first_purchase_date) AS Order_Year,
    SUM(final_orders_ltv1.order_total) AS Gross_Sales, 
    COUNT(final_orders_ltv1.id) AS Total_number_of_orders,
    SUM(final_orders_ltv1.shipping_cost) AS Total_Shipping_cost,
    SUM(final_orders_ltv1.other_cost) AS Sum_other_cost,
    SUM(final_orders_ltv1.refund_amount) AS Total_Refund, 
    SUM(final_orders_ltv1.total_cogs_per_item) AS Total_cogs,
    SUM(final_orders_ltv1.order_total) 
        - SUM(final_orders_ltv1.shipping_cost) 
        - SUM(final_orders_ltv1.other_cost) 
        - SUM(final_orders_ltv1.refund_amount) 
        - SUM(final_orders_ltv1.total_cogs_per_item) AS profit,
    SUM(CASE WHEN final_orders_ltv1.shipping_cost = 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Zero_Shipping_Fee,
    SUM(CASE WHEN final_orders_ltv1.shipping_cost != 0 THEN 1 ELSE 0 END) AS Number_of_Orders_with_Shipping_Fee,
    SUM(CASE WHEN final_orders_ltv1.shipping_cost = 0 THEN final_orders_ltv1.order_total ELSE 0 END) AS Total_Order_Total_No_Shipping_Fee,
    SUM(CASE WHEN final_orders_ltv1.shipping_cost != 0 THEN final_orders_ltv1.order_total ELSE 0 END) AS Total_Order_Total_With_Shipping_Fee
FROM 
(
    SELECT 
        customer_id,
        MIN(purchase_date) as first_purchase_date
    FROM final_orders_ltv1
    GROUP BY customer_id
) first_purchase_dates
JOIN final_orders_ltv1 ON first_purchase_dates.customer_id = final_orders_ltv1.customer_id 
                      AND first_purchase_dates.first_purchase_date = final_orders_ltv1.purchase_date
WHERE first_purchase_dates.first_purchase_date >= '2020-09-01'
GROUP BY YEAR(first_purchase_dates.first_purchase_date), MONTH(first_purchase_dates.first_purchase_date)
ORDER BY Order_Year, Order_Month ASC;

-- september
-- order units will be the basis of the shipping and handling per order
SELECT * FROM final_orders_ltv1 WHERE order_id = 40;
SELECT * FROM order_items WHERE order_id = 40;
select * from orderitems_itemsproducts_tablejoin LIMIT 10;
SELECT * FROM first_time_purchase_ltv order by purchase_date;

SELECT first_time_purchase_ltv.order_id, orderitems_itemsproducts_tablejoin.item_id, orderitems_itemsproducts_tablejoin.quantity,first_time_purchase_ltv.quantity,
orderitems_itemsproducts_tablejoin.item_id, orderitems_itemsproducts_tablejoin.description
FROM first_time_purchase_ltv.order_id
JOIN orderitems_itemsproducts_tablejoin on first_time_purchase_ltv.order_id = orderitems_itemsproducts_tablejoin.order_id;

-- THE first_time_purchase_ltv HAS FILTER STARTING FROM 09-01-20 THEN MIN PURCHASE DATE FOR EVERY CUSTOMER
-- this query gets the item breakdown for very first order of customers
SELECT * FROM first_time_purchase_ltv where purchase_date BETWEEN '2020-11-01' AND '2020-11-31';
-- confirm no first time buyer nov 2020
SELECT * FROM orders_ltv where purchase_date BETWEEN '2020-11-01' AND '2020-11-30' ORDER BY purchase_date;
-- monthly selection of breakdown of items for every order
SELECT 
    first_time_purchase_ltv.order_id, 
    orderitems_itemsproducts_tablejoin.item_id, 
    orderitems_itemsproducts_tablejoin.quantity, 
    first_time_purchase_ltv.order_units,
    orderitems_itemsproducts_tablejoin.item_id, 
    orderitems_itemsproducts_tablejoin.description
FROM 
    first_time_purchase_ltv
JOIN 
    orderitems_itemsproducts_tablejoin 
    ON first_time_purchase_ltv.order_id = orderitems_itemsproducts_tablejoin.order_id
WHERE 
    first_time_purchase_ltv.purchase_date BETWEEN '2020-12-01' AND '2020-12-31'
ORDER  BY first_time_purchase_ltv.order_id;


