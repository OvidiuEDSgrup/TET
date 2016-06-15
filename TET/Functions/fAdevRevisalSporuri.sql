--***
/**	functie pt. returnare date privind sporurile pe contract */
Create function fAdevRevisalSporuri() 
returns @AdevRevisalSporuri table 
	(NrCurent int identity(1,1), Marca char(6), DenumireSpor char(100), ValoareSpor decimal(10), TipSpor char(2), 
	Nr_contract char(20), Data_contract datetime)
As
Begin
--	variabila pentru generare suspendari contracte (CFS, Ingrijire copil, poate si absente nemotivate) 
--	din datele lunare - conalte, conmed, etc.
	declare @HostID char(10), @Marca char(6), @DataJ datetime, @DataS datetime, @RevisalSuspDinDL int
	set @HostID=isnull((select convert(char(8),abs(convert(int,host_id())))),'')
--	Set @HostID='2640'
	set @Marca=isnull((select Numar from avnefac where AVNEFAC.TERMINAL=@HostID and tip='AD'),'')
	select @DataJ='01/01/1901'
	set @DataS=dbo.eom(isnull((select Data from avnefac where AVNEFAC.TERMINAL=@HostID and tip='AD'),'01/01/1901'))
	
	set @RevisalSuspDinDL=dbo.iauParL('PS','REVSUSPDL')

	insert into @AdevRevisalSporuri
	select a.Marca, (case when a.TipSpor='TipSporAngajator' then a.CodSpor else c.Descriere end), 
	ValoareSpor, (case when IsProcent='true' then 'Da' else 'Nu' end),
	i.Nr_contract, isnull((select max(data_inf) from extinfop e where e.marca=a.marca and e.cod_inf='DATAINCH'),'01/01/1901')
	from fRevisalSporuri(@DataJ, @DataS, @Marca) a
 		left outer join infopers i on i.marca=a.marca
		left outer join CatalogRevisal c on c.TipCatalog='TipSporPredefinit' and c.Cod=a.CodSpor

--	inlocuiesc caracterele speciale intrucat da eroare la deschidere document rezultat
	update @AdevRevisalSporuri set DenumireSpor=REPLACE(DenumireSpor,'�','i')
	update @AdevRevisalSporuri set DenumireSpor=REPLACE(DenumireSpor,'�','a')
	update @AdevRevisalSporuri set DenumireSpor=REPLACE(DenumireSpor,'�','a')
	update @AdevRevisalSporuri set DenumireSpor=REPLACE(DenumireSpor,'?','a')

	return
End

/*
	select * from dbo.fAdevRevisalSporuri () 
*/
