-- Это решение работает для postgresql/greenplum (используются оконнные функции)
WITH intervals AS (    
      SELECT
            post_id, views, likes, shares,
            min(dttm) AS min_dttm, max(dttm) AS max_dttm, min(rn) AS min_rn, max(rn) AS max_rn     
      FROM (
            SELECT
                  ps.*,
                  row_number() OVER (PARTITION BY post_id ORDER BY dttm ASC) AS rn
            FROM public.post_stats ps
      ) psn
      GROUP BY post_id, views, likes, shares
)
SELECT
      i.post_id, i.views, i.likes, i.shares,
      i.min_dttm AS effective_from,
      COALESCE(i2.min_dttm, '9999-12-31 23:59:59'::timestamp) AS effective_to
FROM intervals i
LEFT JOIN intervals i2
      ON i.post_id = i2.post_id AND i.max_rn + 1 = i2.min_rn
ORDER BY i.post_id, i.min_rn
;
