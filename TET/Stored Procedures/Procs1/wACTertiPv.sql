-- procedura apelata din PVria pt. autocomplete-ul cu terti
CREATE procedure wACTertiPv @sesiune varchar(50),@parXML XML
as
if exists(select * from sysobjects where name='wACTertiPvSP' and type='P')
	exec wACTertiPvSP @sesiune, @parXML
else      
begin
	set transaction isolation level read uncommitted
	declare @subunitate varchar(9), @searchText varchar(80), @userASiS varchar(10), @lista_clienti bit, @msgEroare varchar(500), @areFiltruLm int
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')

	set @searchText=REPLACE(@searchText, ' ', '%')
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	select @lista_clienti=0
	select @lista_clienti=1 
		from proprietati 
		where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CLIENT' and valoare<>''
	
	set @areFiltruLm=0
	-- nu filtrez - cine e in PV ar trebui sa vada soldul. proprietatea LOCMUNCA e folosita pentru asociere loc de munca la user.
	--set @areFiltruLm=dbo.f_areLMFiltru(@userASiS) 
	
	select top 100 rtrim(terti.tert) as cod, rtrim(max(terti.denumire)) as denumire, 
		(case when @areFiltruLm=0 then 
			'Sold ben.: ' + ltrim(convert(varchar(20), convert(money, sum(facturi.sold)), 1))+' '+ 'lei'
		 else '' end ) as info
	from ( select top 100 t.Tert, t.Denumire+ case when t.Cod_fiscal = t.Tert then '' else '('+t.Cod_fiscal+')' end as Denumire
			from terti t 
			left join (select cu.Valoare from proprietati cu where cu.tip='UTILIZATOR' and cu.cod=@userASiS and cu.cod_proprietate='CLIENT') cu on cu.valoare=t.tert 
			where t.Subunitate=@subunitate and
				(t.denumire+t.tert+t.Cod_fiscal like '%'+@searchText+'%')
				and (@lista_clienti=0 or cu.Valoare is not null)
			order by PATINDEX('%'+@searchText+'%', t.denumire+t.tert+t.Cod_fiscal)) terti 
	left join facturi on facturi.subunitate=@subunitate and facturi.tert=terti.tert and facturi.tip=0x46
	group by terti.tert
	order by patindex('%'+@searchText+'%',max(terti.Denumire)+terti.Tert), 2
	for xml raw
end
