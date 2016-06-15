--***
create procedure wIaDeclaratieIntrastat @sesiune varchar(50), @parXML xml 
as  
begin try
	declare @sub char(9), @tip char(2), @data datetime, @datajos datetime, @datasus datetime, @flux varchar(10), 
		@userASiS varchar(20), @eroare xml, @mesaj varchar(254)
	
	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS output

	select @data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ISNULL(@parXML.value('(/row/@datalunii)[1]', 'datetime'), '01/01/1901')), 
		@flux = ISNULL(@parXML.value('(/row/@flux)[1]', 'varchar(10)'), 'I')

	select @datajos=dbo.bom(@data), @datasus=dbo.eom(@data)

/*
	if object_id('tempdb.dbo.#declintrastat') is not null drop table #declintrastat
	create table #declintrastat (nr_ord int, cod_NC8 varchar(20), val_facturata float, val_statistica float, masa_neta float, UM2 varchar(20), cant_UM2 float, 
		natura_tranzactie_a varchar(20), natura_tranzactie_b varchar(20), cond_livrare varchar(20), mod_transport varchar(20), tara_tert varchar(20), tara_origine varchar(20), dencodv varchar(80))

	insert into #declintrastat
	*/
	if object_id('tempdb.dbo.#intrastat') is not null drop table #intrastat
	if object_id('tempdb..#intrastat') is null
	begin
		create table #intrastat (nr_ord int)
		exec rapDeclaratieIntrastat_tabela
	end
	
	exec rapDeclaratieIntrastat @datajos=@datajos, @datasus=@datasus, @flux=@flux, @tipdecl='N'

	select 'DI' as subtip, nr_ord as nrord, cod_NC8 as codvama, dencodv as dencodvama, convert(decimal(12,2),val_facturata) as valfacturata, convert(decimal(12,2),val_statistica) as valstatistica, 
		convert(decimal(12,2),masa_neta) as masaneta, um2, convert(decimal(12,2),cant_UM2) as cantum2, natura_tranzactie_a as nattranza, natura_tranzactie_b as nattranzb, 
		cond_livrare as condlivr, 
		'('+mod_transport+') '+(case when mod_transport='1' then 'maritim' when mod_transport='2' then 'feroviar' when mod_transport='3' then 'rutier' when mod_transport='4' then 'aerian' 
		when mod_transport='5' then 'postal' when mod_transport='7' then 'instal. fixe' when mod_transport='8' then 'naval interior' when mod_transport='9' then 'propulsie proprie' else '' end) as modtransp, 
		tara_tert as taratert, tara_origine as taraorigine, cif_partener, 1 as _nemodificabil 
	from #intrastat
	for xml raw
end try	

begin catch
	set @mesaj = '(wIaDeclaratieIntrastat) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
