CREATE DATABASE synergix;

USE synergix;

SELECT * FROM offline_data;
SHOW COLUMNS FROM offline_data;

SELECT * FROM online_data;
SHOW COLUMNS FROM online_data;

SELECT * FROM pos_data;
SHOW COLUMNS FROM pos_data;

SELECT * FROM prod_data;
SHOW COLUMNS FROM prod_data;

SELECT * FROM search_rank_data;
SHOW COLUMNS FROM search_rank_data;

SELECT * FROM vpc_data;
SHOW COLUMNS FROM vpc_data;

/*Basic Querying of Data............
retrieve the starting and ending dates first from the dataset using max and min functions.*/
SELECT MIN(pos_date), MAX(pos_date) FROM pos_data;

/*looking for the overall yearly revenue of the company using the data in the pure state the table.*/
SELECT YEAR(pos_date) AS date_year,
SUM(revenue) AS total_revenue
FROM pos_data
GROUP BY date_year;
/*notice that there is over 28 per cent growth in the overall revenue of the company.*/

/*Checking is  it across all segments?
 using the concept of key statement to find segment wise, total revenue, and displayed them column wise to compare the results.*/
SELECT YEAR(pos_date) AS date_year,
SUM(revenue) AS total_revenue,
SUM(CASE WHEN segment = 'Hair Care' THEN revenue ELSE 0 END) AS Haircare_revenue,
SUM(CASE WHEN segment = 'Makeup' THEN revenue ELSE 0 END) AS Makeup_revenue,
SUM(CASE WHEN segment = 'Skincare' THEN revenue ELSE 0 END) AS Skincare_revenue
FROM pos_data
GROUP BY date_year;
/*total revenue, and then the percentage change in total revenue over the years. 
You're subtracting the revenue from last year, from the revenue this year. */
SELECT date_year,
total_revenue,
ROUND((total_revenue - LAG(total_revenue) OVER (ORDER BY date_year)) / LAG(total_revenue) OVER (ORDER BY date_year) * 100) AS Skincare_percentagechange,
Haircare_revenue,
ROUND((Haircare_revenue - LAG(Haircare_revenue) OVER (ORDER BY date_year)) / LAG(Haircare_revenue) OVER (ORDER BY date_year) * 100) AS Haircare_percentagechange,
Makeup_revenue,
ROUND((Makeup_revenue - LAG(Makeup_revenue) OVER (ORDER BY date_year)) / LAG(Makeup_revenue) OVER (ORDER BY date_year) * 100) AS Makeup_percentagechange,
Skincare_revenue,
ROUND((Skincare_revenue - LAG(Skincare_revenue) OVER (ORDER BY date_year)) / LAG(Skincare_revenue) OVER (ORDER BY date_year) * 100) AS Skincare_percentagechange
FROM
(SELECT YEAR(pos_date) AS date_year,
SUM(revenue) AS total_revenue,
SUM(CASE WHEN segment = 'Hair Care' THEN revenue ELSE 0 END) AS Haircare_revenue,
SUM(CASE WHEN segment = 'Makeup' THEN revenue ELSE 0 END) AS Makeup_revenue,
SUM(CASE WHEN segment = 'Skincare' THEN revenue ELSE 0 END) AS Skincare_revenue
FROM pos_data
GROUP BY date_year)t1;
/*over the years, the overall revenue for each segment has increased. With hair care products growing by 31 percent. 
Skincare products growing by 27.6 percent(28), and makeup by 27.5 percent(28). 
When we see that the sales have not been going up as predicted, 
it may not be with respect to the overall sales or sales for each segment of products, but it could be at a product level. 
May be only certain products drive the sales.*/

/*Product Based Analysis of Sales*/
SELECT COUNT(DISTINCT SKU_ID) FROM pos_data;

/*checking the revenue for all the 297 products.*/
SELECT SKU_ID,
SUM(Revenue)AS total_rev
FROM pos_data
GROUP BY  SKU_ID
ORDER BY total_rev DESC;

/*there are a lot of products with zero revenue. 
These are those products which are not contributing to the growth of the company, 
but are these products experiencing any traffic or is the traffic zero for them as well? */
SELECT SKU_ID,
SUM(Revenue)AS total_rev,
SUM(page_traffic)AS total_taff
FROM pos_data
GROUP BY  SKU_ID
ORDER BY total_rev ASC;
/*in addition to zero revenue, there is zero traffic for some products. 
There are some products with no revenue, but positive traffic, while some with no traffic and no revenue. 
Also, there are some products with positive traffic and positive revenue.*/

/* finding the total revenue and total traffic contribution from each product type.*/
SELECT SKU_ID, total_rev, total_taff,
CASE
WHEN total_rev!=0 AND total_taff!=0 THEN 'A'
WHEN total_rev=0 AND total_taff=0 THEN 'B'
WHEN total_rev!=0 AND total_taff=0 THEN 'C'
WHEN total_rev=0 AND total_taff!=0 THEN 'D'
END AS prod_type
FROM(
SELECT SKU_ID,
SUM(Revenue)AS total_rev,
SUM(page_traffic)AS total_taff
FROM pos_data
GROUP BY  SKU_ID
ORDER BY total_rev ASC
)t1;

/*calculating the total revenue and total traffic grouped by the product type.*/
SELECT prod_type, SUM(total_taff) AS TotalTraffic, SUM(total_rev) AS TotalRevenue, COUNT(prod_type) AS TotalProducts
FROM
(
SELECT SKU_ID, total_rev, total_taff,
CASE
WHEN total_rev!=0 AND total_taff!=0 THEN 'A'
WHEN total_rev=0 AND total_taff=0 THEN 'B'
WHEN total_rev!=0 AND total_taff=0 THEN 'C'
WHEN total_rev=0 AND total_taff!=0 THEN 'D'
END AS prod_type
FROM(
SELECT SKU_ID,
SUM(Revenue)AS total_rev,
SUM(page_traffic)AS total_taff
FROM pos_data
GROUP BY  SKU_ID
ORDER BY total_rev ASC
)t1
)t2 GROUP BY prod_type
ORDER BY prod_type;
/*Product Type A has positive traffic and positive revenue, and also the number of unique products at the highest for it. 
For productive Type B the traffic is zero and so is the revenue. For product Type C, traffic is zero while revenue is not zero. 
Finally, for product Type D, traffic is not zero while revenue is zero. We can also see that more than 110 products, 
or about 37 products in total belonging to product Type B and D, did not bring in any revenue and out of these 110 products, 
they are 52 products on which we have received traffic, which is greater than 300,000, but it still did not get any revenue. 
As highlighted in our problem statement, having 37% products unsold is a big liability for any e-commerce business and this needs to improve. 
Now, it could be that the campaigns are not working for Products B, C, and D.*/ 

/*Looking for the number of campaigns for each product has had an impact on the traffic and indirectly the revenue.*/
SELECT sku_id, SUM(num_unique_campaigns) AS total_camp 
FROM online_data
GROUP BY sku_id;

/*let's combine this with the resulting table from the previous table. 
We found the total revenue and total traffic for each product category. 
You will need to make use of the right joint concept here, as well as the concept of subquery.*/
SELECT prod_type, SUM(total_camp) AS TotalCampaigns,
SUM(total_taff) AS TotalTraffic, 
SUM(total_rev) AS TotalRevenue, 
COUNT(prod_type) AS TotalProducts
FROM
(
SELECT t2.sku_id, prod_type, total_rev, total_taff, total_camp
FROM
(
SELECT sku_id, SUM(num_unique_campaigns) AS total_camp 
FROM online_data
GROUP BY sku_id
)t0
RIGHT JOIN
(
SELECT SKU_ID, total_rev, total_taff,
CASE
WHEN total_rev!=0 AND total_taff!=0 THEN 'A'
WHEN total_rev=0 AND total_taff=0 THEN 'B'
WHEN total_rev!=0 AND total_taff=0 THEN 'C'
WHEN total_rev=0 AND total_taff!=0 THEN 'D'
END AS prod_type
FROM
(
SELECT SKU_ID,
SUM(Revenue)AS total_rev,
SUM(page_traffic)AS total_taff
FROM pos_data
GROUP BY  SKU_ID
)t1
)t2
ON
t0.sku_id = t2.sku_id
)t3
GROUP BY prod_type
ORDER BY TotalCampaigns DESC;
/*Now, notice our product type A has positive revenue and positive traffic. 
The campaigns are also the highest. Then for product type B the traffic and revenue is zero, 
even though the campaigns are more than 500. This could mean that the campaigns launched for each product did not do well here. 
So we need to improve the marketing campaigns for each production over here. 
Then for product type C, the traffic is zero, but the revenue is not equal to zero. 
This is not possible because any product selling will have a positive traffic. 
Therefore, looking at the data here, we can assume that maybe the traffic was not captured for such products, 
and it could just be an issue on the technical side and we need to communicate that to the engineering team. 
Finally, for product type D the traffic is greater than zero, but the revenue is zero fail. 
This means that maybe the products are not very appealing. We need to improve such products and make the most syllable. 
Or we can put those resources into other products to drive sales over there and completely let go of such products.*/

/*finding the ratio of total traffic to total campaigns for each product type to further 
solidify our understanding of which product type campaigns are doing well.*/
SELECT prod_type, SUM(total_camp) AS TotalCampaigns,
SUM(total_taff) AS TotalTraffic, 
SUM(total_rev) AS TotalRevenue, 
COUNT(prod_type) AS TotalProducts,
SUM(total_taff) / SUM(total_camp) AS CampRatio -- the ratio of total traffic to total campaigns
FROM
(
SELECT t2.sku_id, prod_type, total_rev, total_taff, total_camp
FROM
(
SELECT sku_id, SUM(num_unique_campaigns) AS total_camp 
FROM online_data
GROUP BY sku_id
)t0
RIGHT JOIN
(
SELECT SKU_ID, total_rev, total_taff,
CASE
WHEN total_rev!=0 AND total_taff!=0 THEN 'A'
WHEN total_rev=0 AND total_taff=0 THEN 'B'
WHEN total_rev!=0 AND total_taff=0 THEN 'C'
WHEN total_rev=0 AND total_taff!=0 THEN 'D'
END AS prod_type
FROM
(
SELECT SKU_ID,
SUM(Revenue)AS total_rev,
SUM(page_traffic)AS total_taff
FROM pos_data
GROUP BY  SKU_ID
)t1
)t2
ON
t0.sku_id = t2.sku_id
)t3
GROUP BY prod_type
ORDER BY TotalCampaigns DESC;
/* As you can notice, product type A is doing very well and bringing it a good amount of traffic. 
Each campaign for product type A brings in an average traffic of 2,115. While each campaign for product type D, 
it's bringing in only about an average traffic of 300. But the rest of the product types are not bringing in any traffic. 
This means we need to work more on campaigns of product type D to bring in more traffic and in turn, increase the revenue.*/

/*********************
As for product type B and C, we need to investigate whether campaigns
are not bringing in the traffic to increase the contribution to the overall revenue. 
***************************/

