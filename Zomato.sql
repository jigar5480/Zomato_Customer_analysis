create database zomato;
use zomato;

---create different table 

---
create table golden_users
(
userid int primary key,
gold_users_signupdate date
);

insert into golden_users
values
(1,'09-22-2017'),
(3,'04-21-2017');

---
create table users
(
userid int primary key,
signup_date date
);

insert into users
values 
(1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

---
create table products
(
product_id int primary key,
product_name varchar(50),
price int
);

insert into products
values 
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

---
create table sales
(
userid int,
orderdate date,
product_id int
);

insert into sales
values 
(1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

---reading data

select * from golden_users;
select * from users;
select * from products;
select * from sales;

---solve the different problem 

---what is the total amount each customer spent on zomato?

select s.userid , sum(price) as Total_amount from 
sales s join products p
on s.product_id=p.product_id
group by s.userid;

---how many days has each customer visited zomato?

select userid,COUNT(distinct orderdate) as No_days from sales
group by userid;

---what was the firt product purchsed by each customer?

with cte as(
select userid,s.product_id, DENSE_RANK() over(partition by userid order by orderdate) as rank from 
sales s join products p
on s.product_id=p.product_id 
)
select * from cte
where rank=1;

---what is the most purchased item on the menu and how many times was it purchsed by all customers?

select top 1 s.product_id,count(s.product_id) as cnt from
sales s join products p 
on s.product_id=p.product_id
group by s.product_id
order by cnt desc;

select userid,count(userid) as No_of_order from sales
where product_id=2
group by userid
order by No_of_order desc;

---which item was the popular for each customer?

with cte as(
select userid, product_id, count(product_id) as cnt, DENSE_RANK() over(partition by userid order by count(product_id) desc) as rank from sales
group by userid, product_id
)
select userid, product_id from cte
where rank=1;

---which item was purchsed first by the customer after they became a member?

with cte as(
select s.*,gold_users_signupdate from 
sales s join golden_users g
on s.userid=g.userid and orderdate>=gold_users_signupdate
),
cte1 as(
select *,DENSE_RANK() over(partition by userid order by orderdate) as rnk from cte
)
select * from cte1
where rnk=1;

---which item was purchsed just before the customer became a member?

with cte as(
select s.*,gold_users_signupdate from 
sales s join golden_users g
on s.userid=g.userid and orderdate<=gold_users_signupdate
),
cte1 as(
select *,DENSE_RANK() over(partition by userid order by orderdate desc) as rnk from cte
)
select * from cte1
where rnk=1;

---what is the orders and amount spent for each member before they became a member?

with cte as(
select s.*,gold_users_signupdate,product_name,price from 
sales s join golden_users g
on s.userid=g.userid and orderdate<=gold_users_signupdate
join products p
on p.product_id=s.product_id
)
select userid,count(userid) as No_of_orders,sum(price) as Total_amount from cte
group by userid;

--- if buying each product generates points for eg. 5rs=2 zomato point and each product has different purchasing points
--- for eg. for p1 5rs=1, p2 10rs=5, p3=5rs=1 zomato point
--- calculate points collected by each customers and find out the cashback
--- product most points have been given till now

	---problem 1
	with cte as(
	select s.*,price from 
	sales s join products p
	on s.product_id=p.product_id
	),
	cte1 as(
	select *,
	case 
	when product_id=1 then 5
	when product_id=2 then 2
	when product_id=3 then 5
	end as point
	from cte
	),
	cte2 as(
	select *,(price/point) as total_points from cte1
	),
	cte3 as(
	select userid,sum(total_points) as Total_points_earn  from cte2
	group by userid
	)
	select *,(Total_points_earn/2.5) as Total_cashback from cte3
	order by Total_points_earn desc;

	---problem 2

	with cte as(
	select s.*,price from 
	sales s join products p
	on s.product_id=p.product_id
	),
	cte1 as(
	select *,
	case 
	when product_id=1 then 5
	when product_id=2 then 2
	when product_id=3 then 5
	end as point
	from cte
	),
	cte2 as(
	select *,(price/point) as total_points from cte1
	),
	cte3 as(
	select product_id,sum(total_points) as Total_points_earn  from cte2
	group by product_id
	)
	select top 1 * from cte3
	order by Total_points_earn desc;

--- In the first one year after a customer joins the gold program irrespective of what the customer has purchased they earn 5 zomato points
--- for every 10 rs spent who earned more 1 or 3 and what was their points earnings	in their first year?

with cte as(
select s.*, price, gold_users_signupdate from 
sales s join products p
on s.product_id=p.product_id 
join golden_users g
on g.userid=s.userid and orderdate>=gold_users_signupdate and orderdate<=DATEADD(year,1,gold_users_signupdate)
)
select *, (price*0.5) as total_points from cte

---rank all the transaction of the customers

select *,rank() over(partition by userid order by orderdate desc) as rnk from sales;

---rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction mark as na

with cte as(
select s.*, gold_users_signupdate from 
sales s left join golden_users g
on s.userid=g.userid and orderdate>=gold_users_signupdate
),
cte1 as(
select *,rank() over(partition by userid order by orderdate desc) as rnk from cte
),
cte2 as(
select userid,product_id,orderdate,gold_users_signupdate,
case
when gold_users_signupdate is null then 'na' else convert(char,rnk) end as ranking
from cte1
)
select * from cte2;