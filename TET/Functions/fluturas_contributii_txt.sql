--***

/**	functie pt fluturas Tehnologica (mod text) tiparit pe hartie autocopiativa */
Create function [dbo].[fluturas_contributii_txt]()

returns @fluturas_contributii table
	(Marca_i char(6), C01 char(60), C02 char(60), C03 char(60), C04 char(60),
	C05 char(60), C06 char(60), C07 char(60), C08 char(60), C09 char(60), C10 char(60),
	R01 char(60), R02 char(60), R03 char(60), R04 char(60), R05 char(60), R06 char(60),
	R07 char(60), R08 char(60), R09 char(60), R10 char(60), R11 char(60), R12 char(60),
	R13 char(60), R14 char(60), R15 char(60), R16 char(60),R21 CHAR (60), R22 CHAR(60),
	ZileCOEfect char(6), ZileCMEfect char(6), NrPersIntr int)
as
begin
	declare @HostID char(8)
	set @HostID=(select convert(char(8), abs(convert(int, host_id()))))
--	set @HostID='1808'

	insert @fluturas_contributii
	SELECT a.Marca_i, isnull((select Text_i from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='CAS individual' and b.marca_p='C'),'') 
	as C01,

	isnull((select rtrim(Ore_procent_i)+space(11-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10),Valoare_i)))))
	+ltrim(rtrim(convert (char(10),Valoare_i))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='CAS individual' and b.marca_p='C'),'') 
	as C02,

	isnull((select Text_i from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='Somaj' and b.marca_p='C'),'') 
	as C03,

	isnull((select rtrim(Ore_procent_i)+space(11-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10),Valoare_i)))))
	+ltrim(rtrim(convert (char(10),Valoare_i))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='Somaj' and b.marca_p='C'),'') 
	as C04,

	isnull((select Text_i from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='Asigurare sanatate' and b.marca_p='C'),'') 
	as C05,

	isnull((select rtrim(Ore_procent_i)+space(11-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10),Valoare_i)))))
	+rtrim(convert (char(10),Valoare_i)) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='Asigurare sanatate' and b.marca_p='C'),'') 
	as C06,

	isnull((select Text_i from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='Impozit' and b.marca_p='C'),'') 
	as C07,

	isnull((select rtrim(Ore_procent_i)+space(11-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10),Valoare_i)))))
	+ltrim(rtrim(convert (char(10),Valoare_i))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='Impozit' and b.marca_p='C'),'') 
	as C08,

	isnull((select Text_i from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='Salar net' and b.marca_p='C'),'') 
	as C09,

	isnull((select rtrim(Ore_procent_i)+space(11-len(rtrim(Ore_procent_i)+ltrim(rtrim(convert(char(10),Valoare_i)))))
	+ltrim(rtrim(convert (char(10),Valoare_i))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='Salar net' and b.marca_p='C'),'') 
	as C10,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='IMPUTATII' and b.marca_p='R'),'') 
	as R01,

	isnull((select rtrim(max(Ore_procent_i))+space(15-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(round(Valoare_i,2)))))))
	+ltrim(rtrim(convert (char(10),sum(round(Valoare_i,2))))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='IMPUTATII' and b.marca_p='R'),'') 
	as R02,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='ABONAMENTE' and b.marca_p='R'),'') 
	as R03,

	isnull((select rtrim(max(Ore_procent_i))+space(11-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(Valoare_i))))))
	+ltrim(rtrim(convert (char(10),sum(Valoare_i)))) 
	from flutur b where	a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='ABONAMENTE' and b.marca_p='R'),'') 
	as R04,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='ANALIZE MEDICALE' and b.marca_p='R'),'') 
	as R05,

	isnull((select rtrim(max(Ore_procent_i))+space(11-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(Valoare_i))))))
	+ltrim(rtrim(convert (char(10),sum(Valoare_i)))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='ANALIZE MEDICALE' and b.marca_p='R'),'')
	as R06,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='PENSIE ALIMENTARA' and b.marca_p='R'),'') 
	as R07,

	isnull((select rtrim(max(Ore_procent_i))+space(11-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(Valoare_i))))))
	+ltrim(rtrim(convert (char(10),sum(Valoare_i)))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='PENSIE ALIMENTARA' and b.marca_p='R'),'') 
	as R08,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='ECHIPAMENT PROTECTIE' and b.marca_p='R'),'') 
	as R09,

	isnull((select rtrim(max(Ore_procent_i))+space(11-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(Valoare_i))))))
	+ltrim(rtrim(convert (char(10),sum(Valoare_i)))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='ECHIPAMENT PROTECTIE' and b.marca_p='R'),'') 
	as R10,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='ANGAJAMENT PLATA' and b.marca_p='R'),'') 
	as R11,
	
	isnull((select rtrim(max(Ore_procent_i))+space(11-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(Valoare_i))))))
	+ltrim(rtrim(convert (char(10),sum(Valoare_i)))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='ANGAJAMENT PLATA' and b.marca_p='R'),'')
	as R12,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='PENALIZARI SALARIU' and b.marca_p='R'),'') 
	as R13,

	isnull((select rtrim(max(Ore_procent_i))+space(11-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(Valoare_i))))))
	+ltrim(rtrim(convert (char(10),sum(Valoare_i)))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='PENALIZARI SALARIU' and b.marca_p='R'),'') 
	as R14,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='AVANS' and b.marca_p='R'),'') 
	as R15,

	isnull((select rtrim(max(Ore_procent_i))+space(11-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(Valoare_i))))))
	+ltrim(rtrim(convert (char(10),sum(Valoare_i)))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='AVANS' and b.marca_p='R'),'') 
	as R16,

	isnull((select max(b.Text_i) from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='RESTITUIRE SUME' and b.marca_p='R'),'') 
	as R21,

	isnull((select rtrim(max(Ore_procent_i))+space(11-len(rtrim(max(Ore_procent_i))+ltrim(rtrim(convert(char(10),sum(Valoare_i))))))
	+ltrim(rtrim(convert (char(10),sum(Valoare_i)))) 
	from flutur b where a.HostID=b.Hostid and a.marca_i=b.marca_i and b.Text_i='RESTITUIRE SUME' and b.marca_p='R'),'') 
	as R22,
	
	convert(char(6),isnull(round((select sum(ore_concediu_de_odihna/regim_de_lucru) from pontaj 
	where pontaj.marca=max(a.marca_i) and year(pontaj.data) = year(max(avnefac.data))),2),0)) as ZileCOefect,

	convert(char(6),round((select sum(ore_concediu_medical/regim_de_lucru) from pontaj 
	where pontaj.marca=max(a.marca_i) and pontaj.data between dbo.eom(dateadd(month,-11, max(avnefac.data))) and max(avnefac.data)),2)) as ZileCMefect,

	isnull((select count(1) from persintr b where a.marca_i=b.marca and b.data=max(avnefac.data) and b.Coef_ded<>0),'') as NrPersIntr

	FROM flutur a, avnefac 
	where a.HostID=@HostID and a.HostID=avnefac.Terminal
	GROUP BY a.HostID, a.marca_i

	return
end
