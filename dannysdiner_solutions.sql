-- 1.What is the total amount each customer spent at the restaurant?

SELECT 
    customer_id, SUM(price) AS money_spent
FROM
    sales
        JOIN
    menu ON menu.product_id = sales.product_id
GROUP BY customer_id;

-- 2.How many days has each customer visited the restaurant?

SELECT 
    customer_id,
    COUNT(DISTINCT (order_date)) AS number_of_visits
FROM
    sales
GROUP BY customer_id;

-- 3.What was the first item from the menu purchased by each customer?

 with first_order  as (select s.customer_id,
	   m.product_name,
       dense_rank() over(partition by s.customer_id order by s.order_date) order_rank
from sales s inner join menu m 
on s.product_id=m.product_id )
select 
      customer_id,
      product_name
	  from first_order
      where order_rank=1;
      
-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
    menu.product_name, COUNT(sales.customer_id) total_sale
FROM
    menu
        INNER JOIN
    sales ON menu.product_id = sales.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
     
-- 5.Which item(s) was the most popular for each customer?
with pop_product as (SELECT  s.customer_id,
        m.product_name,
        COUNT(s.product_id) as count,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS r
FROM menu m 
JOIN sales s 
ON s.product_id = m.product_id
group by 1,2)
select customer_id,
       product_name,
       count
       from pop_product
       where r=1;

-- 6. Which item was purchased first by the customer after they became a member?

with after_member as (select 
      s.customer_id,
      m.product_name,
      s.order_date,
      rank () over (partition by customer_id order by order_date) as first_order
      from sales s inner join menu m
      on s.product_id=m.product_id
      inner join members
      on s.customer_id=members.customer_id
      and s.order_date>=members.join_date
      order by 1,3)
select 
	customer_id,
    product_name
    from after_member
    where first_order=1;
    
-- 7. Which item was purchased just before the customer became a member?
with before_member as (select 
	  s.customer_id,
      m.product_name,
      s.order_date,
	  rank () over (partition by customer_id order by s.order_date) as ranks
      from sales s inner join menu m
      on s.product_id=m.product_id
      inner join members
      on s.customer_id=members.customer_id
      and s.order_date<members.join_date
      )
select  
      customer_id,
      product_name
      from before_member
      where ranks=1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    COUNT(m.product_name) total_item,
    SUM(m.price) total_amount
FROM
    sales s
        INNER JOIN
    menu m ON s.product_id = m.product_id
        INNER JOIN
    members ON s.customer_id = members.customer_id
        AND s.order_date < members.join_date
GROUP BY 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with total_points as (
     select *,
           case when m.product_name='sushi' then price*20
                when m.product_name!= 'sushi' then price*10
		   end as point
	 from menu as m)
	 select s.customer_id,sum(point)
     from total_points inner join sales s
     on
	 total_points.product_id=s.product_id
     group by 1;
      
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select customer_id,sum(total_points)
from (
with p_hist as (select 
      s.customer_id,
      (s.order_date-mem.join_date) as first_week,
      m.price,
      m.product_name,
      s.order_date
from sales s inner join menu m
on s.product_id=m.product_id
join members as mem
on mem.customer_id=s.customer_id
)
select 
      customer_id,
      order_date,
      case when first_week between 0 and 7 then price*20
           when first_week>7 or first_week<0 and product_name='sushi' then price*20
           when first_week>7 or first_week<0 and product_name!='sushi' then price*10 end as total_points
	  from p_hist
      where extract(month from order_date)=1 ) as p
group by 1

      
      
      
