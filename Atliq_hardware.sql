-- Req 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct market from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

/* Req 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020, unique_products_2021, percentage_chg */

select pr20 as unique_products_2020, pr21 as unique_products_2021, round((pr21-pr20)*100/pr20,2) as percentage_change from
(
(select count(distinct product_code) as pr20 from fact_sales_monthly where fiscal_year=2020) as p20,
(select count(distinct product_code) as pr21 from fact_sales_monthly where fiscal_year=2021) as p21
);

/* Req 3. Provide a report with all the unique product counts for each segment and 
sort them in descending order of product counts. The final output contains 2 fields,
segment, product_count */

select segment, count(distinct product_code) as Product_count 
from dim_product
group by segment
order by Product_count desc;


/* Req 4.  Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

WITH temp_table1 AS
		(
        select pr.segment as segment, count(distinct pr.product_code) as Product_2020 from 
        dim_product pr join	fact_sales_monthly fsm
        on pr.product_code = fsm.product_code
        group by fsm.fiscal_year, pr.segment
		having fsm.fiscal_year= "2020"
        ),
temp_table2 AS
		( select pr.segment as segment, count(distinct pr.product_code) as Product_2021 from 
        dim_product pr join	fact_sales_monthly fsm
        on pr.product_code = fsm.product_code
        group by fsm.fiscal_year, pr.segment
		having fsm.fiscal_year= "2021"
        )
        
select  tb1.segment as segment,
 tb1.Product_2020,
 tb2.Product_2021, 
(Product_2021 - Product_2020) as difference 

from temp_table1 tb1 , temp_table2 tb2
where tb1.segment = tb2.segment
order by difference desc;

/* Req 5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

select pr.product_code, pr.product, fmc.manufacturing_cost  
from dim_product pr join fact_manufacturing_cost fmc
on pr.product_code = fmc.product_code
where manufacturing_cost in 
	(
    select min(manufacturing_cost) from fact_manufacturing_cost
	union
    select max(manufacturing_cost) from fact_manufacturing_cost
    );
    
/* Req 6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */

select 
cu.customer_code, 
cu.customer, 
round(avg(fpi.pre_invoice_discount_pct),2) as avg_discount_percentage

from dim_customer cu join fact_pre_invoice_deductions fpi
on cu.customer_code = fpi.customer_code
where fpi.fiscal_year = "2021" and cu.market = "India"
group by cu.customer_code, cu.customer
order by avg_discount_percentage desc
limit 5;


/* Req 7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount */

select monthname(date) as Months, year(date) as Years,
round(sum(fgp.gross_price * fsm.sold_quantity),2) as Gross_Sales_Amount
from dim_customer dc join fact_sales_monthly fsm 
on dc.customer_code = fsm.customer_code
join fact_gross_price fgp on
fgp.product_code = fsm.product_code
where dc.customer = "Atliq Exclusive" 
group by Months, Years
order by Years;

/* Req 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */

select Case
	when month(date) in (9,10,11) then 'Q1' -- fiscal_year for company starts from September(09)
	when month(date) in (12,1,2) then 'Q2'
	when month(date) in (3,4,5) then 'Q3'
    when month(date) in (6,7,8) then 'Q4'
    end as Quaters,
sum(sold_quantity) as total_sold_quantity    
from fact_sales_monthly
where fiscal_year = 2020
group by Quaters
order by total_sold_quantity desc;

/* Req 9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */

with temp_table as 
(
select dc.channel,  round(sum(fgp.gross_price * fsm.sold_quantity/1000000),2) as gross_sales_min

from dim_customer dc join fact_sales_monthly fsm on dc.customer_code = fsm.customer_code 
join fact_gross_price fgp on fgp.product_code = fsm.product_code
where fsm.fiscal_year = 2021
group by dc.channel
order by gross_sales_min desc
)

select channel, gross_sales_min, round(gross_sales_min *100 / (select sum(gross_sales_min) from temp_table),2) as percerntage
from temp_table;


/* Req 10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order */


With Table1 as (  /*creating a CTE for getting top selling products for all divisions*/

	select dp.division, dp.product_code, dp.product, sum(fsm.sold_quantity) as total_sold_quantity,
	dense_rank() over(partition by division order by sum(fsm.sold_quantity) desc) as rank_order
	from dim_product dp join fact_sales_monthly fsm on 
	dp.product_code = fsm.product_code
	where fsm.fiscal_year = 2021
	group by dp.division, dp.product_code, dp.product
	order by total_sold_quantity desc)
    
select * from table1 where rank_order in (1,2,3);



