--***

/**	functie pt fluturas 1/pagina in format xml */

Create function fluturas_venituri() 
returns @fluturas_venituri table
	(Marca_i char(6), V01 char(60), V02 char(60), V03 char(60), V04 char(60), V05 char(60), V06 char(60), V07 char(60), V08 char(60), V09 char(60), V10 char(60), 
	V11 char(60), V12 char(60), V13 char(60), V14 char(60), V15 char(60), V16 char(60), V17 char(60), V18 char(60), V19 char(60), V20 char(60), 
	V21 char(60), V22 char(60), V23 char(60), V24 char(60), V25 char(60), V26 char(60), V27 char(60), V28 char(60), V29 char(60), V30 char(60), 
	V31 char(60), V32 char(60))
as
begin
	declare @HostID varchar(10)
--	set @HostID=(select convert(char(8), abs(convert(int, host_id()))))
	set @HostID=dbo.fIaUtilizator(null)
	
	insert @fluturas_venituri
	SELECT a.Marca_i, isnull((select Marca_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='V'),'') as V01, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='V'),'') as V02, 
	'' as C03, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='V'),'') as V04, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='V'),'') as V05, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='V'),'') as V06, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='V'),'') as V07, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='V'),'') as V08, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='V'),'') as V09, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='V'),'') as V10, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='V'),'') as V11, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='V'),'') as V12, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='V'),'') as V13, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='V'),'') as V14, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='V'),'') as V15, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='V'),'') as V16, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='V'),'') as V17, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='V'),'') as V18, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='V'),'') as V19, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='V'),'') as V20, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='V'),'') as V21, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='V'),'') as V22, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=11 and b.marca_p='V'),'') as V23, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=11 and b.marca_p='V'),'') as V24, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=12 and b.marca_p='V'),'') as V25, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=12 and b.marca_p='V'),'') as V26, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=13 and b.marca_p='V'),'') as V27, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=13 and b.marca_p='V'),'') as V28, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=14 and b.marca_p='V'),'') as V29, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=14 and b.marca_p='V'),'') as V30, 
	isnull((select Text_i from flutur b where a.marca_i=b.marca_i and b.nr_linie=15 and b.marca_p='V'),'') as V31, 
	isnull((select rtrim(Ore_procent_i)+space(30-len(rtrim(Ore_procent_i)+rtrim(convert(char(10), Valoare_i))))+rtrim(convert (char(10),Valoare_i)) 
		from flutur b where a.marca_i=b.marca_i and b.nr_linie=15 and b.marca_p='V'),'') as V32
	FROM flutur a
	where a.HostID=@HostID
	GROUP BY a.HostID, a.marca_i

	return
end
