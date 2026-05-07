-- cek data fact ispu

select  *from fact_ispu fi ;

--cek data dim stastiun

select  *from dim_stasiun;

-- digunakan untuk melihat data yang sudah di input berhasil

--cek tipe data

select column_name, data_type
from information_schema.columns
where table_name = 'fact_ispu';

-- menganalisis tipe data yang akan digunaka pada data base fact_ispu

-- drop null

	
delete from fact_ispu 
	where pm10 is null 
	or pm25 is null 
	or TRIM(pm25) = '';

-- membersikan data yang null atau kosong agar perhitungan rata rata 
-- tidak bias


-- cek hasil drop

select COUNT(*)
from fact_ispu
where pm10 is null 
   or pm25 is null 
   or TRIM(pm25) = '';


--memastikan tidak ada data kosong atau null

--CTE moving average (7,14,30 hari)

with clean as (
	select 
	ds.nama_stasiun,
	fi.tanggal,
	fi.pm10,
	fi.pm25,
	fi.co,
	fi.o3,
	fi.categori
	from fact_ispu fi 
	join dim_stasiun ds 
		on fi.stasiun_id = ds.stasiun_id
	where fi.pm10 is not null
)

select 
	nama_stasiun,
	tanggal,
	pm10,
-- avg 7 hari
	avg(pm10) over(
		partition by nama_stasiun
		order by tanggal
		rows between 6 preceding and current row
	) as ma_7hari,
-- avg 14 hari
	avg(pm10) over(
		partition by nama_stasiun
		order by tanggal
		rows between 13 preceding and current row
	) as ma_14hari,
-- avg 30 hari
	avg(pm10) over(
		partition by nama_stasiun
		order by tanggal
		rows between 29 preceding and current row
	) as ma_30hari
from clean;

-- digunakan untuk moving average pm10 (7,14, dan30 hari) perstasiun untuk melihat 
-- tren polusi jangka pendek dan panjang setelah melakukan CTE pengabungan data yang
-- dibutuhkan serta memastikan data valid dianalisis

-- CTE avg pm10 perbulan per stasiun

with avg_bulan as (
   select
        ds.nama_stasiun, fi.tanggal,
        avg(fi.pm10) as avg_pm10
    from fact_ispu fi 
    join dim_stasiun ds 
        on fi.stasiun_id = ds.stasiun_id
    where fi.tanggal::date 
          between '2024-09-01' and '2025-02-28'
      and fi.pm10 is not null
    group by  
        ds.nama_stasiun,fi.tanggal
)

select *
	from avg_bulan
	order by avg_pm10;


-- CTE pm10 tertinggi 6 bulan data terakhir

with avg_bulan as (
	select 
	ds.nama_stasiun,
	avg (fi.pm10) as avg_pm10
	from fact_ispu fi 
	join dim_stasiun ds 
		on fi.stasiun_id = ds.stasiun_id
	where fi.tanggal between '2024-09-01' and '2025-02-28'
	and fi.pm10 is not null
	group by ds.nama_stasiun
	)
select *
	from avg_bulan
	order by avg_pm10 desc
	limit 5;

-- CTE pm10 terendah 6 bulan data terakhir

with avg_bulan as (
	select 
	ds.nama_stasiun,
	avg (fi.pm10) as avg_pm10
	from fact_ispu fi 
	join dim_stasiun ds 
		on fi.stasiun_id = ds.stasiun_id
	where fi.tanggal between '2024-09-01' and '2025-02-28'
	and fi.pm10 is not null
	group by ds.nama_stasiun
	)
select *
	from avg_bulan
	order by avg_pm10 asc
	limit 5;