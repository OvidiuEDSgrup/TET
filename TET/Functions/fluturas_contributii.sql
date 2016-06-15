--***

/**	functie pt fluturas Colas (sau fluturas 1/pagina in format xml */

Create function fluturas_contributii() 
returns @fluturas_contributii table
	(Marca_i char(6), C01 char(60), C02 char(60), C03 char(60), C04 char(60), C05 char(60), C06 char(60), C07 char(60), C08 char(60), C09 char(60), C10 char(60), 
	C11 char(60), C12 char(60), C13 char(60), C14 char(60), C15 char(60), C16 char(60), C17 char(60), C18 char(60), C19 char(60), C20 char(60), 
	R01 char(60), R02 char(60), R03 char(60), R04 char(60), R05 char(60), R06 char(60), R07 char(60), R08 char(60), R09 char(60), R10 char(60), 
	R11 char(60), R12 char(60), R13 char(60), R14 char(60), R15 char(60), R16 char(60), R17 char(60), R18 char(60), R19 char(60), R20 char(60))
as
begin
	declare @HostID varchar(10)
--	set @HostID=(select convert(char(8), abs(convert(int, host_id()))))
	set @HostID=dbo.fIaUtilizator(null)
	
	insert @fluturas_contributii
	SELECT a.Marca_i, isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='C'),'') as C01, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='C'),'') as C02, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='C'),'') as C03, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='C'),'') as C04, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='C'),'') as C05, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	rtrim(convert (char(10),Valoare_i)) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='C'),'') as C06, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='C'),'') as C07, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='C'),'') as C08, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='C'),'') as C09, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='C'),'') as C10, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='C'),'') as C11, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='C'),'') as C12, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='C'),'') as C13, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='C'),'') as C14, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='C'),'') as C15, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='C'),'') as C16, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='C'),'') as C17, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='C'),'') as C18, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='C'),'') as C19, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='C'),'') as C20, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='R'),'') as R01, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=1 and b.marca_p='R'),'') as R02, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='R'),'') as R03, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=2 and b.marca_p='R'),'') as R04, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='R'),'') as R05, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=3 and b.marca_p='R'),'') as R06, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='R'),'') as R07, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=4 and b.marca_p='R'),'') as R08, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='R'),'') as R09, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=5 and b.marca_p='R'),'') as R10, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='R'),'') as R11, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=6 and b.marca_p='R'),'') as R12, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='R'),'') as R13, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=7 and b.marca_p='R'),'') as R14, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='R'),'') as R15, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=8 and b.marca_p='R'),'') as R16, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='R'),'') as R17, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=9 and b.marca_p='R'),'') as R18, 
	isnull((select Text_i from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='R'),'') as R19, 
	isnull((select rtrim(Ore_procent_i)+space(25-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10), Valoare_i)))))+
	ltrim(rtrim(convert (char(10),Valoare_i))) from flutur b where a.HostID=b.HostID and a.marca_i=b.marca_i and b.nr_linie=10 and b.marca_p='R'),'') as R20 
	FROM flutur a
	where a.HostID=@HostID
	GROUP BY a.HostID, a.marca_i

	return
end
