# BALANCED TREE CLOTHING 

## PROJECT OVERVIEW 
Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the 
modern adventurer! Kinama, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales 
performance and generate a basic financial report to share with the wider business.

## ANALYSIS APPROACH

The following questions can be considered key business questions and metrics that the Balanced Tree team requires for their monthly reports.

#### HIGH-LEVEL SALES ANALYSIS.
- What was the total quantity sold for all products?
- What is the total generated revenue for all products before discounts?
- What was the total discount amount for all products?

#### TRANSACTION ANALYSIS
- How many unique transactions were there?
- What is the average unique products purchased in each transaction?
- What are the 25th, 50th and 75th percentile values for the revenue per transaction?
- What is the average discount value per transaction? What is the percentage split of all transactions for members vs non-members?
- What is the average revenue for member transactions and non-member transactions?

#### PRODUCT ANALYSIS
- What are the top 3 products by total revenue before discount?
- What is the total quantity, revenue and discount for each segment?
- What is the top selling product for each segment?
- What is the total quantity, revenue and discount for each category?
- What is the top selling product for each category?
- What is the percentage split of revenue by product for each segment?
- What is the percentage split of revenue by segment for each category? What is the percentage split of total revenue by category?
- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)?
- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

##### SQL SCRIPT FOR COMPLEX QUESTIONS: 
1. What is the average unique products purchased in each transaction?
``` sql
SELECT txn_id,ROUND(AVG(unique_products),0) AS avg_unique_products
FROM (
    SELECT txn_id,COUNT(DISTINCT prod_id) AS unique_products
    FROM sales
    GROUP BY txn_id
) AS counts_per_transaction
GROUP BY txn_id;
```
2. What is the percentage split of all transactions for members vs non-members?
``` sql
SELECT
    CASE 
		WHEN member = 't' THEN 'member' 
        ELSE 'non-member' 
	END AS 'member_type',
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 2) * 100 AS percentage
FROM
    sales
GROUP BY
    member;
```
3. What is the average revenue for member transactions and non-member transactions?   
``` sql
SELECT 
CASE WHEN 
    member = 't' THEN 'member' ELSE 'non-member' END AS 'member_type',
    AVG(qty * price) AS total_revenue
FROM
    sales
GROUP BY
    member_type;
```
4. What is the top selling product for each segment?
``` sql
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
```
5. What is the top selling product for each category?
``` sql
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
```
6. What is the percentage split of revenue by product for each segment?
``` sql
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
```
7. What is the percentage split of revenue by segment for each category?   
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
    
8. What is the percentage split of total revenue by category?
``` sql
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
```
9. What is the total transaction “penetration” for each product? 
-- (hint: penetration = number of transactions where at least 1 quantity of a product was 
-- purchased divided by total number of transactions)
``` sql
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
```
