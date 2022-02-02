-- ЗАДАЧА:
-- С помощью одного SQL запроса вывести путь между двумя вершинами графа с минимальным весом. 
-- Если для двух путей совпадает вес, то вывести с минимальной длиной пути. 
-- Если совпадает и путь, и длина, то вывести первый попавшийся.

-- ПОДГОТОВИМ СТРУКТУРУ ДЛЯ ИСХОДНЫХ ДАННЫХ
create table graph (
	p1 smallint not null, p2 smallint not null, weight smallint not null
);

create unique index ui_graph on graph (least(p1, p2), greatest(p1, p2));

-- ЗАПОЛНИМ ИСХОДНЫМИ ДАННЫМИ И ПРОВЕРИМ
insert into graph (
	select * from 
		unnest(
			array[1, 2, 3, 4, 5, 7, 1, 7, 3, 3, 7],  -- колонка p1
			array[2, 3, 4, 5, 6, 6, 8, 11, 7, 9, 9], -- колонка p2
			array[1, 1, 5, 1, 1, 1, 1, 1, 10, 2, 2]  -- кононка weight
		) as t(p1, p2, weight)
);

select * from graph;

-- Какие вершины имеют связность?
select p1 as vertix from graph
union
select p2 as vertix from graph
order by vertix;

-- Сколько всего вершин?
select count(*) from (
	select p1 from graph union select p2 from graph 
) all_vertices;

----------------------------------------------------------
-- НАЙДЁМ ПУТИ С ПОМОЩЬЮ РЕКУРСИИ

-- ищем путь из вершины 2 (S) в вершину 7 (T)
-- итерация_1 - запоминаем вершину s 
with path(last_vertix, steps) as (
	values (2, array[2])
)
select * from path;

-- итерация_2 - определяем куда можно переместиться из S
with make_path(last_vertix, path_steps) as (
	values (2, array[2::smallint]) -- стартуем из вершины 2, начинаем строить путь в массиве
)
-- посмотрим куда можно переместиться из S
select 
	graph.p2 as last_vertix,
	p.path_steps || array[graph.p2] as path_steps
from graph, make_path p
where graph.p1 = p.last_vertix
-- граф неориентированный, т.е. нужно анализировать рёбра (p1 -> p2) и (p2 -> p1)
union
select 
	graph.p1 as last_vertix,
	p.path_steps || array[graph.p1] as path_steps
from graph, make_path p
where graph.p2 = p.last_vertix; 


-- теперь нужно избавиться от union, т.к. make_path нельзя будет вызывать в рекурсии дважды 
with make_path(last_vertix, path_steps) as (
	values (2, array[2::smallint])
)
select
	g.p2 as last_vertix,
	p.path_steps || array[g.p2] as path_steps
from 
	(select p1, p2, weight from graph
	union
	select p2, p1, weight from graph) as g,
	make_path p
where g.p1 = p.last_vertix;


-- теперь попробуем рекурсию
with recursive make_path(last_vertix, path_steps, iteration) as (
	values (2, array[2::smallint], 1)
	-- начинаем движение из вершины S
	union all
	select
		g.p2 as last_vertix,
		p.path_steps || array[g.p2],
		p.iteration + 1 -- счётчик итераций рекурсии
	from
		(select p1, p2, weight from graph
		union
		select p2, p1, weight from graph) as g,
		-- здесь учитываем, что граф неориентированный
		make_path p
	where g.p1 = p.last_vertix
		and p.iteration <= 
			(select count(*) from (
				select p1 from graph union select p2 from graph 
			) all_vertices)
		-- ограничим кол-во итераций, чтобы оно не превышало кол-во вершин в графе
)
select * from make_path;


-- Слишком много маршрутов, т.к. есть зацикливания. Уберём варианты с циклами
with recursive make_path(last_vertix, path_steps, iterations, path_length) as (
	-- начинаем движение из вершины S
	values (2, array[2::smallint], 1, 0) --<< ЗДЕСЬ ЗАДАТЬ НАЧАЛЬНУЮ ВЕРШИНУ
	union all
	select
		g.p2 as last_vertix,			
		p.path_steps || array[g.p2],	-- добавляем вершину в путь
		p.iterations + 1,              	-- счётчик итераций рекурсии
		p.path_length + g.weight		-- считаем длину пути
	from
		(select p1, p2, weight from graph
		union
		select p2, p1, weight from graph) as g,
		-- здесь учитываем, что граф неориентированный
		make_path p
	where g.p1 = p.last_vertix
		and p.iterations <= 
			(select count(*) from (
				select p1 from graph union select p2 from graph 
			) all_vertices)
		-- чтобы не уходить в бесконечную рекурсию: ограничим число итераций, не должно превышать число вершин в графе
		and not g.p2 = any(p.path_steps)
		-- убираем маршруты с повторением вершин (зацикливанием)
),
my_paths as (
	select path_steps, path_length, iterations 
	from make_path
	-- выбираем только маршруты, приводящие в вершину T
	where last_vertix = 11   --<< ЗДЕСЬ ЗАДАТЬ КОНЕЧНУЮ ВЕРШИНУ
	-- выбираем кратчайший путь
	order by path_length, iterations
)
select * 
from my_paths
limit 1
;
