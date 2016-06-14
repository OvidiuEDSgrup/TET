declare @utilizator char(10),@contract VARCHAR(20), @data DATETIME, @furnizor CHAR(13), 
	@termenJos datetime, @termenSus datetime,@filtruTermen int, @gestiune char(9)
	
set @utilizator=dbo.fIaUtilizator(null)
select *
from pozaprov p inner join comaprovtmp c on c.Cod=p.Cod and c.Furnizor=p.Furnizor
where contract=@contract and data=@data AND Tip='BK' and c.utilizator=@utilizator

select * from comaprovtmp
exec luare_date_par 'UC', 'NRCNTFC', 0, 0, @contract output
select * from par where par.Tip_parametru='UC' and par.Parametru='NRCNTFC'

select * from par where par.Tip_parametru='GA' and par.Parametru=@utilizator
20555        06/03/201206/03/2012   .            101      101                             0                                                                                                             

SELECT *
		---ISNULL((SELECT SUM(Cant_comandata) FROM pozaprov WHERE pozaprov.Contract=pozcon.Contract 
		--	AND pozaprov.Data=pozcon.Data AND pozaprov.Furnizor=pozcon.Tert and pozaprov.cod=pozcon.cod AND pozaprov.tip='BK' 
		--	AND pozaprov.Comanda_livrare<>'' AND pozaprov.Cant_comandata>=0.001),0) AS Cant_libera
	FROM pozcon INNER JOIN con ON con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and con.data=pozcon.data 
		and con.tert=pozcon.tert and con.contract=pozcon.contract
	WHERE  pozcon.subunitate='1' AND pozcon.tip='FC'
		AND NOT EXISTS (SELECT 1 FROM pozcon p WHERE p.subunitate=pozcon.subunitate and p.tip=pozcon.tip 
		and p.contract=pozcon.contract and p.data=pozcon.data and p.tert=pozcon.tert and ABS(pozcon.cant_realizata)>=0.001)
		
exec ProcGenFC 'OVIDIU'

select * from nomencl n where n.Cod='50-MB20             '

select distinct furnizor from nomencl n where n.Furnizor not in (select t.tert from terti t)