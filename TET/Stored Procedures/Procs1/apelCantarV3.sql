--***
CREATE proc [dbo].[apelCantarV3] @sesiune varchar(50), @parxml xml
as
begin
	set transaction isolation level READ UNCOMMITTED

	declare @gestutiliz varchar(20),@categoriepret int,@utilizator varchar(100)	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
print @utilizator
	set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and 
		cod_proprietate='GESTPV' and cod=@utilizator),'')
	set @categoriePret=isnull((select valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz and Valoare<>''),'201')
print @gestutiliz
print @categoriepret
	select max(cod_de_bare) as cb,cod_produs as cod
	into #codbares
	from codbare
	where cod_produs in (select n.cod
		from nomencl n where n.um='KG')
	group by cod_produs
   
	if exists (select 1 from tempdb..sysobjects where name like '##ptCantar')
		drop table ##ptCantar
		
   select cb.cb as codbare,cb.cb as codbare1,ltrim(str(p.Pret_cu_amanuntul,6,2)) as pret,
	rtrim(n.denumire) as denumire,0 as c1,0 as c2,'11/5/2013' as datae,0 as c3,'00000' as c4,0 as c5
   into ##ptCantar
   from lactag..nomencl n
   inner join #codbares cb on cb.cod=n.cod
   inner join  
   		(select RANK() over (partition by p.cod_produs order by p.tip_pret desc,p.data_inferioara desc) as nrank, p.Cod_produs,p.Pret_cu_amanuntul
			from preturi p
			inner join nomencl n on p.Cod_produs=n.Cod
			where p.um=@categoriepret
			and ((p.tip_pret=1 and GETDATE()>=p.Data_inferioara)
				or (p.tip_pret=2 and GETDATE() between p.Data_inferioara and p.data_superioara))) p 
  
   on n.Cod=p.Cod_produs and p.nrank=1
   where UM='kg'
   
end
