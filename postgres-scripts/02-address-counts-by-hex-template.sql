
DROP TABLE IF EXISTS hex.{0};
CREATE TABLE hex.{0} (
  x integer NOT NULL,
  y integer NOT NULL,
  count_2010 integer NOT NULL,
  count_2016 integer NOT NULL,
  difference integer NOT NULL,
  percent integer NOT NULL,
  geom geometry(Polygon,4326)
) WITH (OIDS=FALSE);
ALTER TABLE hex.{0} OWNER TO postgres;

INSERT INTO hex.{0}
SELECT CASE WHEN left(hex_pid, 1) = '-' THEN split_part(hex_pid, '-', 2)::integer * -1 ELSE split_part(hex_pid, '-', 1)::integer END AS x,
       CASE WHEN left(hex_pid, 1) = '-' THEN split_part(hex_pid, '-', 3)::integer * -1 ELSE split_part(hex_pid, '-', 2)::integer * -1 END AS y,
       count_2010,
       count_2016,
       count_2016 - count_2010 AS difference,
       CASE WHEN count_2010 > 0 THEN (count_2016::float / count_2010::float * 100.0)::integer - 100 ELSE count_2016 * 100.0 END AS percent,
       null::geometry(polygon,4326) AS geom
  FROM (
         SELECT hex_pid_{1} AS hex_pid,
         SUM(CASE WHEN year_added <= 2010 THEN 1 ELSE 0 END) AS count_2010,
         Count(*) AS count_2016
         FROM public.address_hexes
         GROUP BY hex_pid_{1}
  ) AS sqt
  WHERE count_2016 - count_2010 > {3};

  
UPDATE hex.{0} SET geom = get_hex_by_coords({2}, x, y);

ALTER TABLE hex.{0} ADD CONSTRAINT {0}_pk PRIMARY KEY (x, y);
CREATE INDEX {0}_geom_idx ON hex.{0} USING gist(geom);
ALTER TABLE hex.{0} CLUSTER ON {0}_geom_idx;
