--***
create procedure wIaPozitiiCosturi (@sesiune varchar(50), @parXML xml)
as
declare @eroare varchar(500)
set @eroare=''
begin try
	declare 
		@cautare varchar(40),
		@datajos datetime, @datasus datetime, @locm varchar(20), @comanda varchar(50), @tip_filtrare varchar(100), @sub varchar(9)
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	select	
		@datasus=dbo.eom(@parxml.value('(row/@data)[1]','datetime')),
		/*@datajos=@parxml.value('(row/@datajos)[1]','datetime'),
		@datasus=@parxml.value('(row/@datasus)[1]','datetime'),*/
		@locm=isnull(@parxml.value('(row/@lm)[1]','varchar(20)'),'')--+'%'
		,@comanda=isnull(@parxml.value('(row/@comanda)[1]','varchar(50)'),'%'),
		--,@tipDoc=isnull(@parxml.value('(row/@tipDoc)[1]','varchar(20)'),'%')
		@cautare = @parXML.value('(/row/@_cautare)[1]', 'varchar(40)')

	if isnull(@cautare,'')<>'' and charindex('=',@cautare)>1
	begin
		set @tip_filtrare=left(@cautare,charindex('=',@cautare)-1)
		set @cautare=substring(@cautare,charindex('=',@cautare)+1,len(@cautare)-charindex('=',@cautare)+1)
	end

	if isnull(@tip_filtrare,'') not in ('L','C','T','P','A')
		set @cautare=null

	declare @utilizator varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator
	select @datajos=dbo.bom(@datasus)
	
	select --top 100
		convert(varchar(20),data,101) data	--, lm_sup, comanda_sup, art_sup
			,rtrim(lm_inf) lm, rtrim(q.comanda_inf) comanda
			,convert(decimal(20,3),cantitate) cantitate
			,convert(decimal(20,3),valoare) valoare, parcurs, tip, numar
			,(case when art_sup='T' then art_inf else art_sup end) as art
			,convert(decimal(20,3),valoare*cantitate) val_cost
			,rtrim(lm.Denumire) as denlm
			,rtrim(c.Descriere) as dencomanda
			,rtrim(a.Denumire) as denart
			, case when q.parcurs=0 then '#FF0000' else null end as culoare
	from costsql q 
			left join lm on q.LM_INF=lm.Cod
			left join comenzi c on q.COMANDA_INF=c.Comanda and c.subunitate=@sub
			left join artcalc a on (case when q.art_sup='T' then q.art_inf else q.art_sup end)=a.Articol_de_calculatie
	where data between @datajos and @datasus
		and q.art_sup not in ('P','R','N')
		and (lm_sup like @locm)
		and (comanda_sup like @comanda)
		and (isnull(@cautare,'')='' 
			or( @tip_filtrare='L' and ((rtrim(lm.denumire) like '%'+@cautare+'%') or rtrim(lm_inf) like @cautare+'%'))
			or( @tip_filtrare='C' and (rtrim(c.descriere) like '%'+@cautare+'%') or rtrim(q.comanda_inf) like @cautare+'%')
			or( @tip_filtrare='T' and rtrim(tip) like @cautare)
			or( @tip_filtrare='P' and rtrim(parcurs)=@cautare)
			or( @tip_filtrare='A' and (case when art_sup='T' then art_inf else art_sup end) like @cautare)
			)
	order by lm_inf, comanda_inf
	for xml raw
end try
begin catch
	set @eroare='wIaPozitiiCosturi:'+char(10)+error_message()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
