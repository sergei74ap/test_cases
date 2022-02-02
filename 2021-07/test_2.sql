-- ПОДГОТОВКА
CREATE TABLE public.department (
	dep_id int4 NOT NULL,
	dep_name text NOT NULL,
	CONSTRAINT department_dep_name_key UNIQUE (dep_name),
	CONSTRAINT department_pkey PRIMARY KEY (dep_id)
);

CREATE TABLE public.employer (
	emp_id int4 NOT NULL,
	dep_id int4 NULL,
	emp_name text NOT NULL,
	"position" text NOT NULL,
	CONSTRAINT employer_emp_name_key UNIQUE (emp_name),
	CONSTRAINT employer_pkey PRIMARY KEY (emp_id)
);

CREATE TABLE public.salary (
	emp_id int4 NULL,
	"period" int4 NULL,
	amount int4 NULL
);


------------------------------------------------------------------------------------
-- ЗАДАНИЕ 2А
select 
	emp_name, 
	coalesce(dep_name, '-') as dep_name, 
	position, 
	amount 
from employer e
left join department d on e.dep_id = d.dep_id
left join salary s on e.emp_id = s.emp_id 
where period = 201905
order by emp_name;


-- ЗАДАНИЕ 2B
select e.emp_name,
 (select dep_name from department d where d.dep_id = e.dep_id) dep_name, e.position
from employer e;

select e.emp_name, d.dep_name, e.position
from employer e
left join department d
on d.dep_id = e.dep_id;


-- ЗАДАНИЕ 2С
-- ПОДГОТОВКА
select emp_name, coalesce(dep_name, '-'), position, sum(amount) 
from employer e
left join department d on e.dep_id = d.dep_id
left join salary s on e.emp_id = s.emp_id 
where period in (201901, 201902, 201903)
group by emp_name
order by emp_name;

-- ВАРИАНТ_1
with salary_1q as (
	select emp_id, sum(amount) as amount
	from salary
	where period in (201901, 201902, 201903)
	group by emp_id
)
select 
	emp_name, 
	coalesce(dep_name, '-') as dep_name, 
	position, 
	amount 
from employer e
left join department d on e.dep_id = d.dep_id
left join salary_1q s on e.emp_id = s.emp_id 
where amount > 2000
order by emp_name;

-- ВАРИАНТ_2
with salary_1q as (
	select emp_id, sum(amount) as amount
	from salary
	where period >= 201901 and period <= 201903
	group by emp_id
	having sum(amount) > 2000
)
select 
	emp_name, 
	coalesce(dep_name, '-') as dep_name, 
	position, 
	amount 
from employer e
left join department d on e.dep_id = d.dep_id
join salary_1q s on e.emp_id = s.emp_id 
order by amount desc;


-- ЗАДАНИЕ 2D
select 
	emp_name, 
	coalesce(dep_name, '') as dep_name, 
	position,
	period, 
	sum(amount) over (partition by e.emp_id order by period) as running_sum 
from employer e
left join department d on e.dep_id = d.dep_id
left join salary s on e.emp_id = s.emp_id
order by e.emp_id, period;
