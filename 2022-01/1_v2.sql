-- нагенерим тестовых данных:
-- пусть будет 10 постов, данные за 1 год с дискретностью в 1 день
CREATE TABLE public.test_data AS 
WITH series AS ( 
	SELECT 
		s.*,
		CASE 
			WHEN s.rnd < 0.5 THEN 0
			WHEN s.rnd BETWEEN 0.5 AND 0.9 THEN 1
			ELSE -1
		END AS delta_likes,
		CASE 
			WHEN s.rnd < 0.7 THEN 0
			WHEN s.rnd BETWEEN 0.7 AND 0.9 THEN 1
			ELSE -1
		END AS delta_shares,
		CASE 
			WHEN s.rnd < 0.3 THEN 0
			ELSE 1
		END AS delta_views
	FROM (
		SELECT 
			p.post_id, t.dttm, 
			random() AS rnd
		FROM generate_series('2021-01-01 00:00:00'::timestamp, '2022-01-01 00:00:00'::timestamp, INTERVAL '1 day') AS t (dttm)
		CROSS JOIN generate_series(1, 10) AS p (post_id)
	) AS s
)
SELECT 
	s.post_id, s.dttm,
	GREATEST(
		sum(delta_likes) OVER (PARTITION BY post_id ORDER BY dttm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
		0
	) AS likes,
	GREATEST(
		sum(delta_shares) OVER (PARTITION BY post_id ORDER BY dttm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
		0
	) AS shares,
	GREATEST(
		sum(delta_views) OVER (PARTITION BY post_id ORDER BY dttm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
		0
	) AS views
FROM series s
--ORDER BY post_id, dttm
;

-- преобразование в scd2
SELECT 
	ch.post_id, ch.likes, ch.shares, ch.views,
	ch.dttm AS eff_from,
	COALESCE(LEAD(ch.dttm) OVER (PARTITION BY post_id ORDER BY dttm), '9999-12-31 00:00:00') AS eff_to
FROM (
	SELECT 
		t.*,
		(COALESCE(LAG(likes) OVER (PARTITION BY post_id ORDER BY dttm), -1) != likes 
			OR COALESCE(LAG(shares) OVER (PARTITION BY post_id ORDER BY dttm), -1) != shares
			OR COALESCE(LAG(views) OVER (PARTITION BY post_id ORDER BY dttm), -1) != views
		) AS attrs_changed
	FROM public.test_data t
) ch
WHERE attrs_changed 
ORDER BY post_id, dttm
;