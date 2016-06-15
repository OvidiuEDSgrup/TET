--***
create procedure rapVerificareRepartizare (@sesiune varchar(50),
		@datajos datetime, @datasus datetime,
		@detaliat bit=1,
		@locm varchar(200)=null,
		@parXML xml = null)
as
begin
--set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @f_locm bit
	select @f_locm=(case when @locm is null then 0 else 1 end),
			@locm=@locm+'%'

	--> pregatire auto-filtrare pe loc de munca	
		declare @utilizator varchar(20), @eLmUtiliz int
		exec wiautilizator @sesiune=@sesiune, @utilizator=@utilizator output
		select @eLmUtiliz=0
		select @eLmUtiliz=1 from lmfiltrare where utilizator=@utilizator

		declare @LmUtiliz table(valoare varchar(200))
		insert into @LmUtiliz(valoare)
		select cod from lmfiltrare where utilizator=@utilizator
		
	select grupare, nivel, denumire, isnull(suma,0) as suma from
	(
		select 'I' as grupare,1 as nivel,'Cheltuieli incarcate' as denumire,sum(isnull(cantitate*valoare,0)) as suma
		from costsql
		where (lm_inf='' and art_sup='T' and (comanda_inf like '6%' OR comanda_inf like '8%') ) and data between @datajos and @datasus
			and (@f_locm=0 or lm_sup like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_sup))
	union all
		select 'I' as grupare,1 as nivel,'Semifabricate incarcate',sum(isnull(cantitate*valoare,0))
		from costsql
		where (lm_inf='' and comanda_inf like '711%' or tip='CX' ) and data between @datajos and @datasus
			and (@f_locm=0 or lm_sup like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_sup))
	union all
		select	'I' as grupare,2 as nivel,'Consum de semifabricate',sum(isnull(cantitate*valoare,0))
		from costsql
		where (lm_inf='' and comanda_inf like '711%' and art_inf='T' or tip='CX' ) and data between @datajos and @datasus
			and (@f_locm=0 or lm_sup like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_sup))
	union all
		select 'I' as grupare,2 as nivel,'Diferenta pret la semif.',sum(isnull(cantitate*valoare,0))
		from costsql
		where (lm_inf='' and comanda_inf like '711%' and art_inf<>'T' ) and data between @datajos and @datasus
			and (@f_locm=0 or lm_sup like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_sup))
	union all
		select 'I' as grupare,1 as nivel,'Neterminata incarcata',sum(isnull(cantitate*valoare,0))
		from costsql
		where (art_inf='N' and data=@datajos ) and data between @datajos and @datasus
			and (@f_locm=0 or lm_inf like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_inf))
	union all
		select 'R' as grupare,1 as nivel,'Cost productie terminata',sum(isnull(cantitate*valoare,0))
		from costsql
		where (lm_sup='' and comanda_sup='' and art_sup in ('P','R','A') ) and data between @datajos and @datasus
			and (@f_locm=0 or lm_inf like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_inf))
	union all
		select 'R' as grupare,2 as nivel,'Comenzi tip '+c.tip_comanda, sum(costsql.cantitate*costsql.valoare)--, max(p.cod_produs) as grupa, max(g.denumire_grupa) as nume_grupa
		from costsql left outer join comenzi c on comanda_inf=c.comanda
			left join pozcom p on p.comanda=c.comanda and p.subunitate='GR'
			left join grcom g on c.tip_comanda=g.tip_comanda and p.cod_produs=g.grupa
		where (lm_sup='' and comanda_sup='' and art_sup in ('P','R','A') ) and data between @datajos and @datasus 
			and isnull(c.tip_comanda,'') in ('P','R','A') and @detaliat='1'
			and (@f_locm=0 or lm_inf like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_inf))
		group by c.tip_comanda
	union all
		select 'R' as grupare,1 as nivel,'Cost semifabricate predate',sum(isnull(cantitate*valoare,0))
		from costsql
		where (lm_sup='' and comanda_sup='' and art_sup='S' ) and data between @datajos and @datasus
			and (@f_locm=0 or lm_inf like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_inf))
	union all
		select 'R' as grupare,1 as nivel,'Productie in curs',sum(isnull(cantitate*valoare,0))
		from costsql
		where (lm_sup='' and comanda_sup='' and art_sup='N' and data=@datasus ) and data between @datajos and @datasus
			and (@f_locm=0 or lm_inf like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_inf))
	union all
		select 'R' as grupare,1 as nivel,'Cost desfacere pe comenzi',sum(isnull(cantitate*valoare,0))
		from costsql
		where (comanda_sup in (select comanda from comenzi where tip_comanda='D')) and data between @datajos and @datasus
			and (@f_locm=0 or lm_inf like @locm)
			and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=lm_inf))
	) n

end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapVerificareRepartizare '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
