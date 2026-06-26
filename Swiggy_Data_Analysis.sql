use Swiggy

select * from Swiggy_Data

--Data Validation
--Null check
select 
sum(case when State is null then 1 else 0 end) as state_null,
sum(case when City is null then 1 else 0 end) as City_null,
sum(case when Order_Date is null then 1 else 0 end) as Order_date_null,
sum(case when Restaurant_Name is null then 1 else 0 end) as Restaurant_Name_null,
sum(case when Location is null then 1 else 0 end) as Location_null,
sum(case when Category is null then 1 else 0 end) as Category_null,
sum(case when Dish_Name is null then 1 else 0 end) as Didh_Name_null,
sum(case when Price_INR is null then 1 else 0 end) as Price_INR_null,
sum(case when Rating is null then 1 else 0 end) as Rating_null,
sum(case when Rating is null then 1 else 0 end) as Rating_count_null from Swiggy_Data

--Black or Empty String 
Select * 
from Swiggy_Data
where State='' OR City='' OR Order_Date='' OR Restaurant_Name=''
OR  Location=''

--Duplicates Detections

Select State,City,Order_Date,Restaurant_name,Location,Category,
Dish_Name,Price_INR,Rating,Rating_Count,count(*) as cnt
from Swiggy_Data
group by State,City,Order_Date,Restaurant_name,Location,Category,
Dish_Name,Price_INR,Rating,Rating_Count
having count(*)>1

--Duplicates Deletions

With cte as(
select *,ROW_NUMBER() 
over(Partition by State,City,Order_Date,Restaurant_name,Location,Category,
Dish_Name,Price_INR,Rating,Rating_Count 
order by(select Null)
) as  rn
from Swiggy_Data)

Delete  from cte where rn>1

--CREATING SCHEMA
--DIMENSION TABLES
--DATE TABLE

CREATE TABLE dim_date(
    Date_id int identity(1,1) primary key,
	Full_date Date,
	Year int,
	Month int,
	Month_Name varchar(20),
	Quarter int,
	Day int,
	Week int
	)
select * from dim_date

--dim Location

create table dim_location(
    Location_id int identity(1,1) primary key,
	State varchar(100),
	City varchar(100),
	Location varchar(200)
	);

--dim restaurant

create table dim_restaurant(
   Restaurant_id int identity(1,1) primary key,
   Restaurant_Name varchar(200)
   );

--dim category
create table dim_category(
   Category_id int identity(1,1) primary key,
   Category varchar(200)
   );

--dim dish
create table dim_dish(
   Dish_id int identity(1,1) primary key,
   Dish_Name varchar(200)
   );

   --FACT TABLE

create table fact_swiggy_orders(
    Order_id int identity(1,1) primary key,


	Date_id int,

	Price_INR decimal(10,2),
	Rating decimal(4,2),
	Rating_Count int,

	Location_id int,
	Restaurant_id int,
	Category_id int,
	Dish_id int,

	foreign key (Date_id) references dim_date(date_id),
	foreign key (Location_id) references dim_location(Location_id),
	foreign key (Restaurant_id) references dim_restaurant(Restaurant_id),
	foreign key (Category_id) references dim_category(Category_id),
	foreign key (Dish_id) references dim_dish(Dish_id)

	);


select * from Swiggy_Data

--Inserting the data 
--dim-date Table

Insert into dim_date(Full_date,Year,Month,Month_Name,Quarter,Day,Week)
Select distinct 
  Order_Date,
  YEAR(Order_Date),
  Month(Order_Date),
  DateName(Month,Order_Date),
  DatePart(Quarter,Order_Date),
  DAY(Order_Date),
  DATEPART(Week,Order_Date)
  from Swiggy_Data where Order_Date is not null;


  select * from dim_date

  --Inserting to dim_location
  insert into dim_location(State,City,Location)
  select distinct 
     State,City,Location 
	 from Swiggy_Data


--dim restaurant 

insert into dim_restaurant(Restaurant_Name)
  select distinct
  Restaurant_Name from 
  Swiggy_Data;

  --category
  insert into dim_category(Category)
  select distinct
  Category from 
  Swiggy_Data;


--dish
insert into dim_dish(Dish_Name)
  select distinct
  Dish_Name from 
  Swiggy_Data;

  --inserting to fact swiggy data

INSERT INTO fact_swiggy_orders(
        Date_id,
		Price_INR,
		Rating,
		Rating_Count,
		Location_id,
		Restaurant_id,
		Category_id,
		Dish_id
)SELECT
  dd.Date_id,
  s.Price_INR,
  s.Rating,
  s.Rating_Count,

  dl.Location_id,
  dr.Restaurant_id,
  dc.Category_id,
  dsh.Dish_id

  from Swiggy_Data s
  join dim_date dd 
  on dd.Full_date=s.Order_Date

  join dim_location dl
  on dl.State=s.State
  and dl.City=s.City
  and dl.Location=s.Location

  join dim_restaurant dr
  on dr.Restaurant_Name=s.Restaurant_Name

  join dim_category dc
  on dc.Category=s.Category

  join dim_dish dsh
  on dsh.Dish_Name=s.Dish_Name;


select * from fact_swiggy_orders


select * from fact_swiggy_orders s
join dim_date d on s.Date_id=d.Date_id
join dim_category c on s.Category_id=c.Category_id
join dim_dish dsh on s.Dish_id=dsh.Dish_id
join dim_location l on s.Location_id=l.Location_id
join dim_restaurant dr on s.Restaurant_id=dr.Restaurant_id


-----------------------------------------------------------------------------------------
-----------KPI's-----------------------------
---Total orders
select count(*) as total_orders from fact_swiggy_orders

--Total Revenue INR

select sum(Price_INR) as Total_Revenue  from fact_swiggy_orders 

--Average dish Price
select avg(Price_INR) as Average_Dish_Price from fact_swiggy_orders

--Average Rating
select avg(Rating) as Average_Rating from fact_swiggy_orders

  
---------------MOnthly Analysis-----------------------------------------------------------------
select dd.year,
dd.Month,dd.Month_Name,
count(*) as Total_Orders_Per_Month
from dim_date dd 
join fact_swiggy_orders f
on dd.Date_id=f.Date_id 
group by dd.Year,dd.Month,dd.Month_Name
order by Total_Orders_Per_Month desc 

--Total Revenue for Each Month
select dd.year,
dd.Month,dd.Month_Name,
sum(Price_INR) as Total_Revenue_Per_Month
from dim_date dd 
join fact_swiggy_orders f
on dd.Date_id=f.Date_id 
group by dd.Year,dd.Month,dd.Month_Name
order by Total_Revenue_Per_Month desc 

--Quarterly order trends 
select dd.Quarter,
count(*) as Total_Orders_Per_Month
from dim_date dd 
join fact_swiggy_orders f
on dd.Date_id=f.Date_id 
group by dd.Quarter
order by Total_Orders_Per_Month desc 
     
--Yearly trend
select dd.Year,
count(*) as Total_Orders_Per_Year
from dim_date dd 
join fact_swiggy_orders f
on dd.Date_id=f.Date_id 
group by dd.Year

--Orders by Day of week
select 
  Datename(Weekday,d.Full_date) as Day_name,
  count(*) as Total_orders
  from fact_swiggy_orders f
  join dim_date d
  on f.Date_id=d.Date_id
  group by  Datename(Weekday,d.Full_date),DatePart(Weekday,d.Full_date)
  order by DatePart(Weekday,d.Full_date)
----------------------------------------------------------------------------------------------
--Location Based Analysis

select Top 10
dl.City,count(*) as Total_Order_for_Each_City from fact_swiggy_orders f
join dim_location dl
on f.Location_id=dl.Location_id
group by dl.City
order by Total_Order_for_Each_City desc

--Revenue Generated by Each State
select 
dl.City,Sum(f.Price_INR) as Total_Order_for_Each_City from fact_swiggy_orders f
join dim_location dl
on f.Location_id=dl.Location_id
group by dl.City
order by Total_Order_for_Each_City desc

-----------------------------------------------------------------------------------------
--------Food Performance Analysis--------------------

--1.Top 10 Restaurants which Prefered by Customers
select Top 10 dr.Restaurant_Name,
    count(*) as Total_Orders_for_each_Restaurant
	from fact_swiggy_orders f
	join dim_restaurant dr
	on f.Restaurant_id=dr.Restaurant_id
	group by dr.Restaurant_Name
	order by Total_Orders_for_each_Restaurant desc

--2.Top 10 Restaurants by Revenue Generated
	select Top 10 dr.Restaurant_Name,
    Sum(f.Price_INR) as Total_Revenue_for_each_Restaurant
	from fact_swiggy_orders f
	join dim_restaurant dr
	on f.Restaurant_id=dr.Restaurant_id
	group by dr.Restaurant_Name
	order by Total_Revenue_for_each_Restaurant desc

  --3.Top 10 Dishes
  select Top 10 dsh.Dish_Name,
    count(*) as Total_Orders_for_each_Dish
	from fact_swiggy_orders f
	join dim_dish dsh
	on f.Dish_id=dsh.Dish_id
	group by dsh.Dish_Name
	order by  Total_Orders_for_each_Dish desc

	--4 Top 10 categories

	select Top 10 dc.Category ,count(*) as Total_orders_for_Each_Category
	from fact_swiggy_orders f  
	join dim_category dc
	on f.Category_id=dc.Category_id
	group by dc.Category
	order by Total_orders_for_Each_Category desc


select 
  case 
  when Price_INR<100 then 'Under 100'
  when Price_INR between 100 and 199 then 'Under 100-199'
  when  Price_INR between 200 and 299 then 'Under 100-199'
  when  Price_INR between 300 and 499 then 'Under 300-499'
  else '500+' 
  end as Price_Range,count(*) as Total_orders
 
 from fact_swiggy_orders 
 group by 
 case 
  when Price_INR<100 then 'Under 100'
  when Price_INR between 100 and 199 then 'Under 100-199'
  when  Price_INR between 200 and 299 then 'Under 100-199'
  when  Price_INR between 300 and 499 then 'Under 300-499'
  else '500+' end
  order by Total_orders desc
  
--Top rating counts
select  Rating,count(*) as Count_Of_Each_Rating from fact_swiggy_orders
group by Rating  order by Count_Of_Each_Rating
desc


 
 

     