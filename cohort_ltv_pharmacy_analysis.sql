select
	*
from checks

/*==================================================
  VIEW: checks_filtered
  Описание: Подготовка к проведению когортного анализа
==================================================*/
create or replace view checks_filtered as 
select
    card,
    datetime,
    summ_with_disc
from checks
where card like '2000%'
  and summ_with_disc > 0
  and datetime >= '2021-01-01'
  and datetime <= now()
order by datetime

/*==================================================
  Описание: Анализ кол-ва дней в месяце
==================================================*/

select
    date_trunc('month', datetime)::date cohort_month,
    min(datetime)::date first_date,
    max(datetime)::date last_date,
    (max(datetime)::date - min(datetime)::date) + 1  days_in_month
from checks
where card like '2000%'
  and summ_with_disc > 0
  and datetime >= '2021-01-01'
  and datetime <= now()
group by date_trunc('month', datetime)::date
order by days_in_month


/*==================================================
  Описание: Когортный анализ
==================================================*/

with pre_data as(
	select
		card,
		first_value(date_trunc('month', datetime)::date) over(partition by card order by date_trunc('month', datetime)::date) cohort,
		date_trunc('month', datetime)::date as month,
		summ_with_disc
	from checks_filtered
), pre_data_2 as(
	select
		card,
		month,
		cohort,
		(extract(year from month) - extract(year from cohort)) * 12 + 
		extract(month from month) - extract(month from cohort) num_of_months,
		summ_with_disc
	from pre_data
	where cohort not in ('2021-07-01', '2022-06-01')
)

select
	cohort,
	count(distinct card) as cohort_clients,
	round(sum(case when num_of_months <= 0 then summ_with_disc end) / count(distinct card)) m0,
	round(case when max(num_of_months) > 0 then sum(case when num_of_months <= 1 then summ_with_disc end) / count(distinct card) end) m1,
	round(case when max(num_of_months) > 1 then sum(case when num_of_months <= 2 then summ_with_disc end) / count(distinct card) end) m2,
	round(case when max(num_of_months) > 2 then sum(case when num_of_months <= 3 then summ_with_disc end) / count(distinct card) end) m3,
	round(case when max(num_of_months) > 3 then sum(case when num_of_months <= 4 then summ_with_disc end) / count(distinct card) end) m4,
	round(case when max(num_of_months) > 4 then sum(case when num_of_months <= 5 then summ_with_disc end) / count(distinct card) end) m5,
	round(case when max(num_of_months) > 5 then sum(case when num_of_months <= 6 then summ_with_disc end) / count(distinct card) end) m6,
	round(case when max(num_of_months) > 6 then sum(case when num_of_months <= 7 then summ_with_disc end) / count(distinct card) end) m7,
	round(case when max(num_of_months) > 7 then sum(case when num_of_months <= 8 then summ_with_disc end) / count(distinct card) end) m8,
	round(case when max(num_of_months) > 8 then sum(case when num_of_months <= 9 then summ_with_disc end) / count(distinct card) end) m9,
	round(case when max(num_of_months) > 9 then sum(case when num_of_months <= 10 then summ_with_disc end) / count(distinct card) end) m10
from pre_data_2
group by cohort
order by cohort


