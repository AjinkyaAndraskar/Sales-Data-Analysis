--- Inspecting Data
select * from [dbo].[sales_data_sample]

--CHecking unique values
select distinct status from [dbo].[sales_data_sample] 
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] 
select distinct COUNTRY from [dbo].[sales_data_sample] 
select distinct DEALSIZE from [dbo].[sales_data_sample] 
select distinct TERRITORY from [dbo].[sales_data_sample] 

select distinct MONTH_ID from [dbo].[sales_data_sample]
where year_id = 2003

---ANALYSIS
----Let's start by grouping sales by productline
select PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

----Let's start by grouping sales by YEAR
select YEAR_ID, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc
	
----Let's start by grouping sales by DEALSIZE
select  DEALSIZE,  sum(sales) Revenue
from [dbo].[sales_data_sample]
group by  DEALSIZE
order by 2 desc


----What was the best month for sales in a specific year? How much was earned that month? 
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 --change year to see the rest
group by  MONTH_ID
order by 2 desc


--November seems to be the month, what product do they sell in November, Classic I believe

select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER)
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc

----Who is our best customer (this could be best answered with RFM)

DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c



select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
         when rfm_recency = 1 and rfm_frequency = 1 and rfm_monetary = 1 then 'Best Customer' ---Best Customer
         when rfm_recency between 2 and 4 and rfm_frequency between 2 and 4  and rfm_monetary = 1 then 'Big Spenders' ---Big Spenders
         when rfm_recency between 2 and 4 and rfm_frequency = 1 and rfm_monetary between 1 and 4 then 'Loyal Customers'  ---Loyal Customers
         when rfm_recency = 1 and rfm_frequency between 1 and 4 and rfm_monetary between 1 and 4 then 'Recent Customers' ---Recent Customers'
         when rfm_recency = 3 and rfm_frequency = 1 and rfm_monetary = 1 then 'Almost lost' ---Almost lost
         when rfm_recency = 4 and rfm_frequency = 1 and rfm_monetary = 1 then 'Lost Customers' ---Lost Customers
         when rfm_recency = 4 and rfm_frequency between 3 and 4 and rfm_monetary between 3 and 4 then 'Lost Cheap Customers' ---Lost Cheap Customers
         when rfm_recency between 2 and 4 and rfm_frequency between 2 and 4 and rfm_monetary between 2 and 4 then 'Others' ---Others
	 end rfm_segment

from #rfm

--What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc


---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
