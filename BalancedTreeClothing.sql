SELECT *
FROM  sales;

SELECT *
FROM  product_details;

-- What was the total quantity sold for all products?
SELECT SUM(qty) AS Total_quantity
FROM  sales;

-- What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) AS Revenue
FROM sales;

-- What was the total discount amount for all products?
SELECT SUM(discount) AS Total_discount
FROM sales;
 
--  How many unique transactions were there?
SELECT COUNT(DISTINCT(txn_id)) AS unique_transactions
FROM sales;

-- What is the average unique products purchased in each transaction?
SELECT txn_id,ROUND(AVG(unique_products),0) AS avg_unique_products
FROM (
    SELECT txn_id,COUNT(DISTINCT prod_id) AS unique_products
    FROM sales
    GROUP BY txn_id
) AS counts_per_transaction
GROUP BY txn_id;

-- What is the average discount value per transaction?
SELECT txn_id, ROUND(AVG(discount),0) AS avg_discount
FROM sales
GROUP BY txn_id;

-- What is the percentage split of all transactions for members vs non-members?
SELECT
    CASE WHEN 
    member = 't' THEN 'member' ELSE 'non-member' END AS 'member_type',
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 2) * 100 AS percentage
FROM
    sales
GROUP BY
    member;
    
-- What is the average revenue for member transactions and non-member transactions?   
SELECT 
CASE WHEN 
    member = 't' THEN 'member' ELSE 'non-member' END AS 'member_type',
    AVG(qty * price) AS total_revenue
FROM
    sales
GROUP BY
    member_type;
    
-- PRODUCT ANALYSIS
-- What are the top 3 products by total revenue before discount?
SELECT pd.product_name , SUM(s.qty * s.price) AS total_revenue 
FROM product_details AS pd
JOIN sales AS s
ON pd.product_id = s.prod_id 
GROUP BY pd.product_name
ORDER BY SUM(s.qty * s.price) DESC
LIMIT 3;
   
--  What is the total quantity, revenue and discount for each segment? 
SELECT pd.segment_name,
       SUM(s.qty) as total_quantity,
       SUM(s.qty * s.price) AS total_revenue,
       SUM(s.discount) AS total_discount 
FROM product_details AS pd
JOIN sales AS s
ON pd.product_id = s.prod_id
GROUP BY pd.segment_name;

-- What is the top selling product for each segment?
SELECT
    ranked.segment_name,
    ranked.product_name,
    ranked.total_revenue
FROM (
    SELECT
        pd.segment_name,
        pd.product_name,
        SUM(s.qty * s.price) AS total_revenue,
        RANK() OVER (PARTITION BY pd.segment_name ORDER BY SUM(s.qty * s.price) DESC) AS ranks
    FROM
        product_details AS pd
    JOIN
        sales AS s ON pd.product_id = s.prod_id
    GROUP BY
        pd.segment_name, pd.product_name
) AS ranked
WHERE
    ranked.ranks = 1;

-- What is the total quantity, revenue and discount for each category?
SELECT pd.category_name,
       SUM(s.qty) as total_quantity,
       SUM(s.qty * s.price) AS total_revenue,
       SUM(discount) AS total_discount 
FROM product_details AS pd
JOIN sales AS s
ON pd.product_id = s.prod_id
GROUP BY pd.category_name;
    
-- What is the top selling product for each category?
SELECT
      ranked.category_name,
      ranked.product_name,
      ranked.total_revenue
FROM (
       SELECT pd.product_name,
       pd.category_name,
       SUM(s.qty * s.price) AS total_revenue,
       
       RANK() OVER(PARTITION BY pd.category_name ORDER BY SUM(s.qty * s.price) DESC) AS ranks
       
       FROM 
          product_details AS pd
       JOIN 
          sales AS s
       ON 
          pd.product_id = s.prod_id
       GROUP BY pd.category_name,pd.product_name
       ) as ranked
WHERE
    ranked.ranks = 1;  
    
-- What is the percentage split of revenue by product for each segment?
SELECT
    pd.segment_name,
    pd.product_name,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(s.qty * s.price) / SUM(SUM(s.qty * s.price)) OVER (PARTITION BY pd.segment_name), 2) * 100 AS percentage
FROM
    product_details AS pd
JOIN
    sales AS s ON pd.product_id = s.prod_id
GROUP BY
    pd.segment_name, pd.product_name
ORDER BY 
    percentage DESC;
    
--  What is the percentage split of revenue by segment for each category?   
SELECT
    pd.category_name,
    pd.segment_name,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(s.qty * s.price) / SUM(SUM(s.qty * s.price)) OVER (PARTITION BY pd.category_name), 2) * 100 AS percentage
FROM
    product_details AS pd
JOIN
    sales AS s ON pd.product_id = s.prod_id
GROUP BY
    pd.category_name, pd.segment_name
ORDER BY 
    percentage DESC;
    
--  What is the percentage split of total revenue by category?
SELECT 
    pd.category_name,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(s.qty * s.price) / SUM(SUM(s.qty * s.price)) OVER (), 2) * 100 AS percentage
FROM
    product_details AS pd
JOIN
    sales AS s ON pd.product_id = s.prod_id
GROUP BY
    pd.category_name
ORDER BY 
    percentage DESC;

-- What is the total transaction “penetration” for each product? 
-- (hint: penetration = number of transactions where at least 1 quantity of a product was 
-- purchased divided by total number of transactions)
SELECT
    pd.product_name,
    COUNT(DISTINCT CASE WHEN s.qty > 0 THEN s.txn_id END) AS penetrated_transactions,
    COUNT(DISTINCT s.txn_id) AS total_transactions,
    ROUND(COUNT(DISTINCT CASE WHEN s.qty > 0 THEN s.txn_id END) / COUNT(DISTINCT s.txn_id), 2) AS penetration
FROM
    product_details AS pd
JOIN
    sales AS s 
ON 
    pd.product_id = s.prod_id
GROUP BY
    pd.product_name;
    
--  What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
SELECT
    t.combination,
    COUNT(*) AS combination_count
FROM (
    SELECT
        s1.txn_id,
        GROUP_CONCAT(DISTINCT s1.prod_id ORDER BY s1.prod_id) AS combination
    FROM
        sales AS s1
    JOIN
        sales AS s2 ON s1.txn_id = s2.txn_id AND s1.prod_id < s2.prod_id
    JOIN
        sales AS s3 ON s1.txn_id = s3.txn_id AND s2.prod_id < s3.prod_id
    WHERE
        s1.qty > 0 AND s2.qty > 0 AND s3.qty > 0
    GROUP BY
        s1.txn_id
) AS t
GROUP BY
    t.combination
ORDER BY
    combination_count DESC
LIMIT 1;

 
   




    