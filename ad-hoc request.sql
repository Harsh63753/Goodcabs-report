use targets_db;
use trips_db;
#Business report 1
with trip_data as (select c.city_id, c.city_name, count(t.trip_id) as total_trip, sum(t.distance_travelled_km) as total_distance_travelled,
sum(fare_amount) as total_amount from dim_city c
join fact_trips t on c.city_id = t.city_id
group by c.city_id, c.city_name)
select city_name, total_trip, total_amount * 1.0/ total_distance_travelled as avg_fare_per_km,
total_amount * 1.0 / total_trip as avg_fare_per_trip,
total_trip * 100.0 / (Select count(trip_id) from fact_trips) as contribution_to_total_trip from trip_data
group by city_id, city_name;
# Insights-
# contribution of jaipur is the most in total trip across country
# city with least contribution is Mysore

# Business report 2
use trips_db;
with actual as(select c.city_id, c.city_name,month(d.date) as month_num,d.month_name,  count(t.trip_id)  as actual_trip from trips_db.dim_city c
join trips_db.fact_trips t on c.city_id = t.city_id
join trips_db.dim_date d on t.date = d.date
group by c.city_id, c.city_name, d.month_name, month(d.date)),
target as( select  month(mt.month) as months, city_id, total_target_trips from targets_db.monthly_target_trips mt)
select distinct(a.city_name),a.month_name, a.actual_trip,ta.total_target_trips,
(a.actual_trip - ta.total_target_trips) * 100.0 / ta.total_target_trips as percentage_diff,
(case when a.actual_trip > ta.total_target_trips then "Above Target"
when  a.actual_trip < ta.total_target_trips then "Below Target"
else null 
end) as Performance_status from actual a
join target ta on a.city_id = ta.city_id
order by a.city_name, a.month_name;
# most successful city in terms of target achieveing is jaipur in month february and january
# most unsuccessful are kochin(june), vadodra(june, january), lucknow(May), jaipur(june)

#Business 3 report
#City level repeat passenger
select c.city_name,
round(sum(case when r.trip_count ="2-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "2_Trips",
round(sum(case when r.trip_count ="3-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "3_Trips",
round(sum(case when r.trip_count ="4-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "4_Trips",
round(sum(case when r.trip_count ="5-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "5_Trips",
round(sum(case when r.trip_count ="6-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "6_Trips",
round(sum(case when r.trip_count ="7-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "7_Trips",
round(sum(case when r.trip_count ="8-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "8_Trips",
round(sum(case when r.trip_count ="9-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "9_Trips",
round(sum(case when r.trip_count ="10-Trips" then r.repeat_passenger_count else 0 end)* 100.0 / sum(r.repeat_passenger_count) , 2) as "10_Trips"
from dim_city c
join dim_repeat_trip_distribution r on c.city_id = r.city_id
group by c.city_name
order by c.city_name;

##Business report 4
with data as ( select c.city_name, sum(p.new_passengers) as Total_new_passengers from fact_passenger_summary p
join dim_city c on p.city_id = c.city_id
group by c.city_name), ranked_data as
(select city_name, Total_new_passengers,
rank() over(order by Total_new_passengers desc) as top_rank,
rank() over(order by Total_new_passengers asc) as bottom_rank from data)
select city_name, Total_new_passengers,
case when top_rank <= 3 then "Top-3"
when bottom_rank <= 3 then "Bottom-3" else 0 end as City_category
from ranked_data
where top_rank <= 3 or bottom_rank <= 3
group by city_name
order by city_name;

#Business report 5
with data as(select c.city_name, d.month_name, sum(fare_amount) as Total_revenue from fact_trips t
join dim_city c on t.City_id = c.city_id
join dim_date d on t.date = d.date
group by  c.city_name, d.month_name),
city_data as(
select c.city_name, sum(fare_amount) as revenue from fact_trips t
join dim_city c on t.city_id = c.city_id
group by c.city_name), highest as
(select city_name, month_name as highest_revenue_month,
total_revenue from data
where(city_name, total_revenue) in (select city_name,max(total_revenue) from data group by city_name))
select h.city_name, h.highest_revenue_month, c.revenue,
round(h.total_revenue *100.0 / c.revenue, 2) as percentage_contribution from highest h
join city_data c on h.city_name = c.city_name;

#Business report 6
with monthly_report as (select c.city_name, d.month_name,sum(p.repeat_passengers) as repeat_passengers,
sum(total_passengers) as total_passengers from fact_passenger_summary p
join dim_date d on p.month = d.start_of_month
join dim_city c on p.city_id = c.city_id
group by c.city_name,d.month_name), city_report as (
select c.city_name, sum(repeat_passengers) as repeat_passengers,
sum(total_passengers) as total_passengers  from fact_Passenger_summary p 
join dim_city c on p.city_id = c.city_id
group by c.city_name)
select m.city_name, m.month_name, m.total_passengers, m.repeat_passengers,
round(m.repeat_passengers *100.0 / m.total_passengers , 2) as monthly_repeat_passenger_rate,
round(cd.repeat_passengers *100.0 / cd.total_passengers) as city_repeat_passenger_rate from 
monthly_report m 
join city_report cd on m.city_name =cd.city_name;
