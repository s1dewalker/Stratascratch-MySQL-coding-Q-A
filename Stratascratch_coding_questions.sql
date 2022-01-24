--Stratascratch coding questions 

--easy

/*
1) Salaries Differences

Write a query that calculates the difference between the highest salaries found in the marketing and engineering departments. 
Output just the absolute difference in salaries.
*/

with
cte1 as (select max(salary) a from db_employee e inner join db_dept d on e.department_id=d.id where department = 'marketing'),
cte2 as (select max(salary) b from db_employee e inner join db_dept d on e.department_id=d.id where department = 'engineering')
select abs(a-b) from cte1, cte2


/*
2) Finding Updated Records

We have a table with employees and their salaries, however, some of the records are old and contain outdated salary information. 
Find the current salary of each employee assuming that salaries increase each year. 
Output their id, first name, last name, department ID, and current salary. 
Order your list by employee ID in ascending order.
*/

select id, first_name, last_name, department_id, max(salary) 
from ms_employee_salary
group by id
order by id;

/*
3) Customer Details

Find the details of each customer regardless of whether the customer made an order. 
Output the customer's first name, last name, and the city along with the order details.
You may have duplicate rows in your results due to a customer ordering several of the same items. 
Sort records based on the customer's first name and the order details in ascending order.
*/

select first_name, last_name, city, o.id, cust_id, order_date, order_details, total_order_cost 
from customers c  left join orders o 
on c.id=o.cust_id
order by first_name asc;

/*
4) Number Of Bathrooms And Bedrooms

Find the average number of bathrooms and bedrooms for each city’s property types. 
Output the result along with the city name and the property type.
*/

select city, property_type, avg(bathrooms), avg(bedrooms) 
from airbnb_search_details
group by city, property_type
order by city, property_type;

/*
5) Popularity of Hack

Meta/Facebook has developed a new programing language called Hack.
To measure the popularity of Hack they ran a survey with their employees. 
The survey included data on previous programing familiarity as well as the number of years of experience, age, gender and most importantly satisfaction with Hack. 
Due to an error location data was not collected, but your supervisor demands a report showing average popularity of Hack by office location. 
Luckily the user IDs of employees completing the surveys were stored.
Based on the above, find the average popularity of the Hack per office location.
Output the location along with the average popularity.
*/

select location, avg(popularity) 
from facebook_employees e inner join facebook_hack_survey h
on e.id=h.employee_id
group by location;

/*
6) Average Salaries

Compare each employee's salary with the average salary of the corresponding department.
Output the department, first name, and salary of employees along with the average salary of that department.
*/

select department, first_name, salary, avg(salary) over (partition by department) from employee

--medium

/*
1) Acceptance Rate By Date

What is the overall friend acceptance rate by date? Your output should have the rate of acceptances by the date the request was sent. 
Order by the earliest date to latest.

Assume that each friend request starts by a user sending (i.e., user_id_sender) a friend request to another user (i.e., user_id_receiver) that's logged in the table with action = 'sent'. 
If the request is accepted, the table logs action = 'accepted'. 
If the request is not accepted, no record of action = 'accepted' is logged.
*/

select date, s/t from
(
select date, action, id, sum(accepted) as s, count(accepted) as t
from
(
select date, action, id, if(c_count=2,1,0) as accepted
from
(
select date, action, concat(user_id_sender,user_id_receiver) as id
, count(concat(user_id_sender,user_id_receiver)) as c_count
from fb_friend_requests
group by id
order by date
) t
) t1
group by date
) t2
group by date

/*
2) Highest Energy Consumption

Find the date with the highest total energy consumption from the Meta/Facebook data centers. 
Output the date along with the total energy consumption across all data centers.
*/

select d,tc
from
(
select d, tc, rank() over(order by tc desc) as r
from
(
select distinct(date) as d
, sum(consumption) over(partition by date) as tc
from
(
SELECT * FROM fb_eu_energy
UNION ALL
SELECT * FROM fb_asia_energy
UNION ALL
SELECT * FROM fb_na_energy
GROUP BY date
) t
) t1
) t2 
where r=1

/*
3) Finding User Purchases

Write a query that'll identify returning active users. 
A returning active user is a user that has made a second purchase within 7 days of any other of their purchases. 
Output a list of user_ids of these returning active users.
*/

select distinct(user_id)
from
(
select user_id, created_at, lag(created_at,1) over (partition by user_id order by created_at) as date2, timestampdiff(day,lag(created_at,1) over (partition by user_id order by created_at),created_at) as ddif
from amazon_transactions a
order by user_id, created_at
) t
where t.ddif<=7

/*
4) Users By Avg Session time

Calculate each user's average session time. A session is defined as the time difference between a page_load and page_exit. 
For simplicity, assume an user has only 1 session per day and if there are multiple of the same events in that day, consider only the latest page_load and earliest page_exit. 
Output the user_id and their average session time.
*/

select user_id
, avg(time_to_sec(timediff(page_exit_time, page_load_time)))
from (
select user_id
     , date(timestamp) as session_dt
     , max(case when action = 'page_load' then timestamp end) as page_load_time
     , min(case when action = 'page_exit' then timestamp end) as page_exit_time
from facebook_web_log
group by user_id, date(timestamp)
) a
where page_load_time is not null
and page_exit_time is not null
group by user_id

/*
5) Customer Revenue In March

Calculate the total revenue from each customer in March 2019. 

Output the revenue along with the customer id and sort the results based on the revenue in descending order.
*/

select cust_id, sum(total_order_cost) 
from orders
where month(order_date) = 03
group by cust_id
order by sum(total_order_cost)  

/*
6) Classify Business Type

Classify each business as either a restaurant, cafe, school, or other. 
A restaurant should have the word 'restaurant' in the business name. For cafes, either 'cafe', 'café', or 'coffee' can be in the business name. 
'School' should be in the business name for schools. All other businesses should be classified as 'other'. 
Output the business name and the calculated classification.
*/

select business_name ,
(case 
when lower(business_name) like '%school%' then 'School' 
when lower(business_name) like '%restaurant%' then 'restaurant'
when lower(business_name) like '%cafe%'  then 'cafe'
when lower(business_name) like '%café%' then 'cafe'
when lower(business_name) like '%coffee%' then 'cafe'
else 'other'
end) as business_type
from sf_restaurant_health_violations
where business_id not in (85051,86780,32823,80302)
group by business_id, business_city
order by business_name

/*
7) Top Cool Votes

Find the review_text that received the highest number of  'cool' votes.
Output the business name along with the review text with the highest numbef of 'cool' votes.
*/

select business_name, review_text from yelp_reviews
order by cool desc limit 2;

/*
8) Order Details

Find order details made by Jill and Eva.
Consider the Jill and Eva as first names of customers.
Output the order date, details and cost along with the first name.
Order records based on the customer id in ascending order.
*/

select first_name, order_date, order_details, total_order_cost 
from customers c inner join orders o on c.id=o.cust_id
where first_name in ('Jill','Eva')
order by cust_id;

/*
9) Workers With The Highest Salaries

Find the titles of workers that earn the highest salary. Output the highest-paid title or multiple titles that share the highest salary.
*/

select worker_title from worker w inner join title t on w.worker_id=t.worker_ref_id
where salary = (select max(salary) from worker)

/*
10) Highest Salary In Department

Find the employee with the highest salary per department.
Output the department name, employee's first name along with the corresponding salary.
*/

select department, first_name, salary from employee
where salary in(select max(salary) sal from employee group by department)

/*
11) Employee and Manager Salaries

Find employees who are earning more than their managers. Output the employee name along with the corresponding salary.
*/

select b.id, b.first_name, b.salary from employee b
where b.salary>(select a.salary from employee a where b.manager_id=a.id)
and b.id<>b.manager_id

/*
12) Number of violations

You're given a dataset of health inspections. Count the number of violation in an inspection in 'Roxanne Cafe' for each year. 
If an inspection resulted in a violation, there will be a value in the 'violation_id' column. 
Output the number of violations by year in ascending order.
*/

select year(inspection_date),  count(violation_id) 
from sf_restaurant_health_violations
where business_name = 'Roxanne Cafe'
group by year(inspection_date)
order by year(inspection_date);

/*
13) Highest Target Under Manager

Find the highest target achieved by the employee or employees who works under the manager id 13. 
Output the first name of the employee and target achieved. 
The solution should show the highest target achieved under manager_id=13 and which employee(s) achieved it.
*/

select first_name, target 
from salesforce_employees
where manager_id=13
and target=(select max(target) from salesforce_employees where manager_id=13)

--hard

/*
1) Popularity Percentage

Find the popularity percentage for each user on Meta/Facebook. 
The popularity percentage is defined as the total number of friends the user has divided by the total number of users on the platform, then converted into a percentage by multiplying by 100.
Output each user along with their popularity percentage. Order records in ascending order by user id.
The 'user1' and 'user2' column are pairs of friends.
*/

with users_union as
(SELECT user1, user2
FROM facebook_friends
UNION 
SELECT user2 AS user1, user1 AS user2
FROM facebook_friends)

SELECT user1, 
count(*)/
(SELECT count(DISTINCT user1) FROM users_union)*100 AS popularity_percent
FROM users_union
GROUP BY 1
ORDER BY 1

/*
2) Highest Cost Orders

Find the customer with the highest daily total order cost between 2019-02-01 to 2019-05-01. 
If customer had more than one order on a certain day, sum the order costs on daily basis. 
Output their first name, total cost of their items, and the date.
 
For simplicity, you can assume that every first name in the dataset is unique.
*/

with cte as 
(select cust_id, order_date
, sum(total_order_cost) over(partition by cust_id, order_date order by cust_id, order_date) sd, row_number() over(partition by cust_id, order_date order by cust_id, order_date) r
from orders)

select c.first_name, order_date, max(sd) from cte
inner join customers c on c.id=cte.cust_id
where r = 1

/*
3) Monthly Percentage Difference

Given a table of purchases by date, calculate the month-over-month percentage change in revenue. 
The output should include the year-month date (YYYY-MM) and percentage change, rounded to the 2nd decimal point, and sorted from the beginning of the year to the end of the year.
The percentage change column will be populated from the 2nd month forward and can be calculated as ((this month's revenue - last month's revenue) / last month's revenue)*100.
*/

with cte as
(select date_format(created_at, '%Y-%m') d
, sum(value) over(partition by month(created_at)) s
, row_number() over(partition by month(created_at)) r
from sf_transactions)

select d,round((diff/s0)*100,2)
from
(
select d, lag(s,1) over() s0,s, s-lag(s,1) over() diff from cte
where r=1
) t

/*
4) Premium vs Freemium

Find the total number of downloads for paying and non-paying users by date. 
Include only records where non-paying customers have more downloads than paying customers. 
The output should be sorted by earliest date first and contain 3 columns date, non-paying downloads, paying downloads.
*/

with cte1 as
(select date, paying_customer p, sum(downloads) s
from ms_user_dimension u 
inner join ms_acc_dimension a on u.acc_id=a.acc_id inner join ms_download_facts d on u.user_id=d.user_id
group by paying_customer, date
order by date)

select a.date, a.s '#no', b.s '#yes'
from cte1 a, cte1 b
where a.date=b.date and a.p='no' and b.p='yes' and a.s>b.s

/*
5) Top 5 States With 5 Star Businesses

Find the top 5 states with the most 5 star businesses. 
Output the state name along with the number of 5-star businesses and order records by the number of 5-star businesses in descending order. 
In case there are ties in the number of businesses, return all the unique states. 
If two states have the same result, sort them in alphabetical order.
*/

with cte as
(select state, count(*) s, rank() over(order by count(*) desc) r
from yelp_business
where stars=5
group by state
order by s desc, state)

select state, s from cte
where r<5

/*
6) Marketing Campaign Success [Advanced]

You have a table of in-app purchases by user. 
Users that make their first in-app purchase are placed in a marketing campaign where they see call-to-actions for more in-app purchases. 
Find the number of users that made additional in-app purchases due to the success of the marketing campaign.

The marketing campaign doesn't start until one day after the initial in-app purchase 
so users that make multiple purchases on the same day do not count, nor do we count users that make only the same purchases over time.
*/

with cte as
(select user_id u, created_at d, product_id p
, dense_rank() over(partition by user_id order by created_at) c1
, dense_rank() over(partition by user_id, product_id order by created_at) c2
from marketing_campaign
order by user_id, created_at)

select count(distinct u) from cte
where c1>1 and c2=1

/*
7) Host Popularity Rental Prices

You’re given a table of rental property searches by users. The table consists of search results and outputs host information for searchers. 
Find the minimum, average, maximum rental prices for each host’s popularity rating. The host’s popularity rating is defined as below:
    0 reviews: New
    1 to 5 reviews: Rising
    6 to 15 reviews: Trending Up
    16 to 40 reviews: Popular
    more than 40 reviews: Hot

Tip: The `id` column in the table refers to the search ID. 
You'll need to create your own host_id by concating price, room_type, host_since, zipcode, and number_of_reviews.

Output host popularity rating and their minimum, average and maximum rental prices.
*/

with cte as
(select *
, (case
when number_of_reviews=0 then 'New'
when number_of_reviews>=1 and number_of_reviews<=5 then 'Rising'
when number_of_reviews>=6 and number_of_reviews<=15 then 'Trending Up'
when number_of_reviews>=16 and number_of_reviews<=40 then 'Popular'
when number_of_reviews>40 then 'Hot' end) as popularity,
concat(price, room_type, host_since, zipcode, number_of_reviews) as new_id
from airbnb_host_searches)

select popularity, min(price), avg(price), max(price)
from
(select distinct new_id, price, popularity from cte) t
group by popularity