--***
create procedure wIaPozitiiDecontari (@sesiune varchar(50), @parXML xml)
as
declare @eroare varchar(500)
set @eroare=''
begin try
	declare 
		@cautare varchar(40),
		@datajos datetime, @datasus datetime, @locm varchar(20), @comanda varchar(50), @tip_filtrare varchar(100), @tab_apelare varchar(10), @sub varchar(9)
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output       
	select	
		@datasus=dbo.eom(@parxml.value('(row/@data)[1]','datetime'))
		/*@datajos=@parxml.value('(row/@datajos)[1]','datetime'),
		@datasus=@parxml.value('(row/@datasus)[1]','datetime'),*/
		,@locm=isnull(@parxml.value('(row/@lm)[1]','varchar(20)'),'')--+'%'
		,@comanda=isnull(@parxml.value('(row/@comanda)[1]','varchar(50)'),'%')
		--,@tipDoc=isnull(@parxml.value('(row/@tipDoc)[1]','varchar(20)'),'%')
		,@cautare = @parXML.value('(/row/@_cautare)[1]', 'varchar(40)')
		,@tab_apelare = isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(40)'),'CU')

	if isnull(@cautare,'')<>'' and charindex('=',@cautare)>1
	begin
		set @tip_filtrare=left(@cautare,charindex('=',@cautare)-1)
		set @cautare=substring(@cautare,charindex('=',@cautare)+1,len(@cautare)-charindex('=',@cautare)+1)
	end

	if isnull(@tip_filtrare,'') not in ('L','C','T','P','A')
		set @cautare=null

	select @tip_filtrare,@cautare

	declare @utilizator varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator
	select @datajos=dbo.bom(@datasus)
	
	select --top 100
		convert(varchar(20),data,101) data	, rtrim(lm_sup) lm_sup, rtrim(comanda_sup) comanda_sup, rtrim(art_sup) art_sup
		,rtrim(lm_inf) lm, rtrim(q.comanda_inf) comanda
		,convert(decimal(20,3),cantitate) cantitate
		,convert(decimal(20,3),valoare) valoare, parcurs, tip, numar
		,convert(decimal(20,3),valoare*cantitate) val_cost
		,(case when art_sup='T' then art_inf else art_sup end) as art
		,rtrim(lm.Denumire) as denlm_sup
		,rtrim(c.Descriere) as dencomanda_sup
		,rtrim(a.Denumire) as denart
		, case when q.parcurs=0 then '#FF0000' else null end as culoare
	from costsql q 
			left join lm on q.LM_sup=lm.Cod
			left join comenzi c on q.COMANDA_SUP=c.Comanda and c.Subunitate=@sub
			left join artcalc a on (case when q.art_sup='T' then q.art_inf else q.art_sup end)=a.Articol_de_calculatie
	where data between @datajos and @datasus
		--and q.ART_INF not in ('P','R','N')
		and (LM_INF like @locm)
		and (comanda_inf like @comanda)
		and (isnull(@cautare,'')='' 
			or( @tip_filtrare='L' and ((rtrim(lm.denumire) like '%'+@cautare+'%') or rtrim(lm_sup) like @cautare+'%'))
			or( @tip_filtrare='C' and (rtrim(c.descriere) like '%'+@cautare+'%') or rtrim(q.comanda_sup) like @cautare+'%')
			or( @tip_filtrare='T' and rtrim(tip) like @cautare)
			or( @tip_filtrare='P' and rtrim(parcurs) like @cautare)
			or( @tip_filtrare='A' and (case when art_sup='T' then art_inf else art_sup end) like @cautare))
	order by lm_inf, comanda_inf
	for xml raw
end try
begin catch
	set @eroare='wIaPozitiiDecontari:'+char(10)+error_message()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
