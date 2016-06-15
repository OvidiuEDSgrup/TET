--***
create procedure [dbo].[wOPCalcCost] @sesiune varchar(50), @parXML xml 
as 

declare @data datetime,@dataj datetime,@datas datetime, @lm varchar(9) 
set @data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')
set @lm=@parXML.value('(/parametri/@lm)[1]', 'varchar(9)')

set @dataj=dbo.BOM(@data)
set @datas=dbo.EOM(@data)

begin try
	if @lm='' -- configurat in macheta sa ceara un loc de munca, dar neintrodus
		raiserror('Eroare: este obligatorie selectarea unei sectii!', 16, 1) 
   	
	if object_id('tempdb..#lm_filtrare_calcul') is not null 
		drop table #lm_filtrare_calcul
	create table #lm_filtrare_calcul (lm varchar(9))
	insert #lm_filtrare_calcul select @lm -- pun valoarea de filtrare intr-o tabela, pentru a fi folosita in proceduri specifice 

	exec calcCost @dataj, @datas, @lm 
    declare @totalinc float,@totalrep float
    
    select @totalinc=SUM(CANTITATE*VALOARE) 
		from COSTTMP 
		where LM_SUP='' and COMANDA_SUP='' and ART_SUP in ('P','R','S','A','N')
			and COMANDA_SUP not in (select comanda from comenzi where Tip_comanda='D')
			and (@lm is null or lm_inf like @lm+'%')
	
	select @totalrep=SUM(cantitate*valoare) 
		from COSTTMP 
		where PARCURS=1
			and (@lm is null or lm_inf like @lm+'%')

   	if object_id('tempdb..#lm_filtrare_calcul') is not null 
		drop table #lm_filtrare_calcul
	
	if exists (select 1 from sys.sysobjects where name = 'wJurnalizareOperatie' and type = 'P')
		exec wJurnalizareOperatie @sesiune = @sesiune, @parXML = @parXML, @obiectSql = 'wOPCalcCost'

	if exists(select * from COSTTMP where PARCURS=0)
		select 'Exista bucle de cheltuieli in repartizarea costurilor' as textMesaj for xml raw, root('Mesaje')
	else if Abs(@totalinc-@totalrep)>1
		select 'Cheltuielile incarcate ('+ltrim(str(@totalinc,17,2))+') nu sunt egale cu cheltuielile repartizate ('+ltrim(str(@totalrep,17,2))+')' as textMesaj for xml raw, root('Mesaje')
	else    
		select 'Calcul efectuat cu succes' as textMesaj for xml raw, root('Mesaje')

end try 
begin catch 
	declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
