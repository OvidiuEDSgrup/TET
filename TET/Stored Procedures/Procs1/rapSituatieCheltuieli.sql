	--***
create procedure rapSituatieCheltuieli @sesiune varchar(50)=null, @datajos datetime, @datasus datetime, @cont varchar(100), @art_calc varchar(100), @locm varchar(100),
		@comanda varchar(100), @grcom varchar(100), @tip_document nvarchar(100)
as
/*
exec rapSituatieCheltuieli @datajos='2014-12-01', @datasus='2014-12-31', @cont=null, @art_calc=null, @locm=null,
		@comanda=null, @grcom=null, @tip_document=null

*/
declare @Sub char(9)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output

--> pregatire auto-filtrare pe loc de munca	
	declare @utilizator varchar(20), @eLmUtiliz int
	exec wiautilizator @sesiune=@sesiune, @utilizator=@utilizator output
	select @eLmUtiliz=0
	select @eLmUtiliz=1 from lmfiltrare where utilizator=@utilizator

	declare @LmUtiliz table(valoare varchar(200))
	insert into @LmUtiliz(valoare)
	select cod from lmfiltrare where utilizator=@utilizator

select c.Articol_de_calculatie as Articol_de_calculatie,p.cont_debitor,c.Denumire_cont as Denumire_cont,
		p.tip_document,p.numar_document,p.data,p.suma as suma,p.explicatii,p.loc_de_munca,p.comanda
	into #cheltuieli
	from pozincon p 
	left join conturi c on c.subunitate=p.Subunitate and p.cont_debitor=c.cont
	left join pozcom g on g.Subunitate='GR' and g.comanda=p.comanda
where
	p.Subunitate=@Sub
	and p.data between @datajos and @datasus 
	and p.cont_debitor like '6%' 
	and (@cont is null or p.cont_debitor like @cont+'%') 
	and (@art_calc is null or c.Articol_de_calculatie=@art_calc)-- or Tip_document in ('CM','RS','AI','PD','NC'))
	and (@comanda is null or p.comanda=@comanda) 
	and (@grcom is null or g.cod_produs=@grcom)
	and (@tip_document is null or p.tip_document=@tip_document)
	and (@locm is null or p.loc_de_munca like @locm+'%')
	and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=p.loc_de_munca))
	and not exists	(select 1 from proprietati pr where pr.tip='LM' and pr.cod_proprietate='NUSITCHELTUIELI' and pr.valoare=1 and pr.cod=p.Loc_de_munca)
--group by p.cont_debitor,p.tip_document,p.numar_document,p.data,p.Explicatii,p.loc_de_munca,p.comanda
order by c.articol_de_calculatie, p.cont_debitor,p.tip_document, p.numar_document, p.data

if exists (select 1 from pozincondet where Subunitate=@Sub and data between @datajos and @datasus)
begin

	select isnull(p.articol,c.Articol_de_calculatie) as Articol_de_calculatie, p.cont_debitor,c.Denumire_cont as Denumire_cont,
		p.tip_document,p.numar_document,p.data,p.suma as suma,p.explicatii,p.loc_de_munca,p.comanda 
	into #chdet
	from pozincondet p
		left join conturi c on c.subunitate=p.Subunitate and p.cont_debitor=c.cont
		left join pozcom g on g.Subunitate='GR' and g.comanda=p.comanda
	where p.Subunitate=@Sub
		and p.data between @datajos and @datasus 
		and p.cont_debitor like '6%' 
		and (@cont is null or p.cont_debitor like @cont+'%') 
		and (@art_calc is null or c.Articol_de_calculatie=@art_calc)-- or Tip_document in ('CM','RS','AI','PD','NC'))
		and (@comanda is null or p.comanda=@comanda) 
		and (@grcom is null or g.cod_produs=@grcom)
		and (@tip_document is null or p.tip_document=@tip_document)
		and (@locm is null or p.loc_de_munca like @locm+'%')
		and (@eLmUtiliz=0 or exists(select 1 from @lmutiliz l where l.valoare=p.loc_de_munca))
		and not exists	(select 1 from proprietati pr where pr.tip='LM' and pr.cod_proprietate='NUSITCHELTUIELI' and pr.valoare=1 and pr.cod=p.Loc_de_munca)

	delete from #cheltuieli 
		where exists (select 1 from #chdet c where c.tip_document=#cheltuieli.tip_document and c.numar_document=#cheltuieli.numar_document and c.data=#cheltuieli.data and substring(c.Loc_de_munca,1,1)=substring(#cheltuieli.Loc_de_munca,1,1))
	insert into #cheltuieli select * from #chdet
	drop table #chdet
end

select a.denumire as den_artcalc, c.Articol_de_calculatie, rtrim(c.cont_debitor) cont_debitor, c.Denumire_cont, c.tip_document, c.numar_document, c.data, 
		c.suma, c.explicatii, c.loc_de_munca, c.comanda, lm.denumire, o.descriere --c.denumire, c.descriere
 from #cheltuieli c 
		left join artcalc a on a.articol_de_calculatie=c.Articol_de_calculatie
		left join lm on lm.cod=c.loc_de_munca
		left join comenzi o on o.subunitate='1' and o.comanda=c.comanda
	where (@art_calc is null or c.Articol_de_calculatie=@art_calc)
	order by c.Articol_de_calculatie

if object_id('tempdb..#cheltuieli') is not null drop table #cheltuieli
/*,N'@datajos datetime,@datasus datetime,@cont nvarchar(3),@art_calc nvarchar(3),@locm nvarchar(3),@comanda nvarchar(3),@grcom nvarchar(3),@tip_document nvarchar(2)',
@datajos='2014-03-11 00:00:00',@datasus='2014-04-11 00:00:00',@cont=N'ar3',@art_calc=N'ar1',@locm=N'ar2',@comanda=N'ar4',@grcom=N'ar5',@tip_document=N'AI'
*/
