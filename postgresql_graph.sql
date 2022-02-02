-- ������:
-- � ������� ������ SQL ������� ������� ���� ����� ����� ��������� ����� � ����������� �����. 
-- ���� ��� ���� ����� ��������� ���, �� ������� � ����������� ������ ����. 
-- ���� ��������� � ����, � �����, �� ������� ������ ����������.

-- ���������� ��������� ��� �������� ������
create table graph (
	p1 smallint not null, p2 smallint not null, weight smallint not null
);

create unique index ui_graph on graph (least(p1, p2), greatest(p1, p2));

-- �������� ��������� ������� � ��������
insert into graph (
	select * from 
		unnest(
			array[1, 2, 3, 4, 5, 7, 1, 7, 3, 3, 7],  -- ������� p1
			array[2, 3, 4, 5, 6, 6, 8, 11, 7, 9, 9], -- ������� p2
			array[1, 1, 5, 1, 1, 1, 1, 1, 10, 2, 2]  -- ������� weight
		) as t(p1, p2, weight)
);

select * from graph;

-- ����� ������� ����� ���������?
select p1 as vertix from graph
union
select p2 as vertix from graph
order by vertix;

-- ������� ����� ������?
select count(*) from (
	select p1 from graph union select p2 from graph 
) all_vertices;

----------------------------------------------------------
-- ���Ĩ� ���� � ������� ��������

-- ���� ���� �� ������� 2 (S) � ������� 7 (T)
-- ��������_1 - ���������� ������� s 
with path(last_vertix, steps) as (
	values (2, array[2])
)
select * from path;

-- ��������_2 - ���������� ���� ����� ������������� �� S
with make_path(last_vertix, path_steps) as (
	values (2, array[2::smallint]) -- �������� �� ������� 2, �������� ������� ���� � �������
)
-- ��������� ���� ����� ������������� �� S
select 
	graph.p2 as last_vertix,
	p.path_steps || array[graph.p2] as path_steps
from graph, make_path p
where graph.p1 = p.last_vertix
-- ���� �����������������, �.�. ����� ������������� ���� (p1 -> p2) � (p2 -> p1)
union
select 
	graph.p1 as last_vertix,
	p.path_steps || array[graph.p1] as path_steps
from graph, make_path p
where graph.p2 = p.last_vertix; 


-- ������ ����� ���������� �� union, �.�. make_path ������ ����� �������� � �������� ������ 
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


-- ������ ��������� ��������
with recursive make_path(last_vertix, path_steps, iteration) as (
	values (2, array[2::smallint], 1)
	-- �������� �������� �� ������� S
	union all
	select
		g.p2 as last_vertix,
		p.path_steps || array[g.p2],
		p.iteration + 1 -- ������� �������� ��������
	from
		(select p1, p2, weight from graph
		union
		select p2, p1, weight from graph) as g,
		-- ����� ���������, ��� ���� �����������������
		make_path p
	where g.p1 = p.last_vertix
		and p.iteration <= 
			(select count(*) from (
				select p1 from graph union select p2 from graph 
			) all_vertices)
		-- ��������� ���-�� ��������, ����� ��� �� ��������� ���-�� ������ � �����
)
select * from make_path;


-- ������� ����� ���������, �.�. ���� ������������. ����� �������� � �������
with recursive make_path(last_vertix, path_steps, iterations, path_length) as (
	-- �������� �������� �� ������� S
	values (2, array[2::smallint], 1, 0) --<< ����� ������ ��������� �������
	union all
	select
		g.p2 as last_vertix,			
		p.path_steps || array[g.p2],	-- ��������� ������� � ����
		p.iterations + 1,              	-- ������� �������� ��������
		p.path_length + g.weight		-- ������� ����� ����
	from
		(select p1, p2, weight from graph
		union
		select p2, p1, weight from graph) as g,
		-- ����� ���������, ��� ���� �����������������
		make_path p
	where g.p1 = p.last_vertix
		and p.iterations <= 
			(select count(*) from (
				select p1 from graph union select p2 from graph 
			) all_vertices)
		-- ����� �� ������� � ����������� ��������: ��������� ����� ��������, �� ������ ��������� ����� ������ � �����
		and not g.p2 = any(p.path_steps)
		-- ������� �������� � ����������� ������ (�������������)
),
my_paths as (
	select path_steps, path_length, iterations 
	from make_path
	-- �������� ������ ��������, ���������� � ������� T
	where last_vertix = 11   --<< ����� ������ �������� �������
	-- �������� ���������� ����
	order by path_length, iterations
)
select * 
from my_paths
limit 1
;
