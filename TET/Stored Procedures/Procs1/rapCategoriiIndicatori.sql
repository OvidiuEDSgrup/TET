--***
create procedure rapCategoriiIndicatori (@calcul int, @categ char(9), @data_jos datetime, @data_sus datetime, @indicator varchar(20), @tip_coloana int
					, @element_1 varchar(20) = null, @element_2 varchar(20) = null, @cutotal bit=1)
as
/*
declare @calcul int, @categ char(9), @data_jos datetime, @data_sus datetime, @indicator varchar(20), @tip_coloana int
set @calcul=0 set @categ='FLO' set @data_jos='2008-1-1' set @data_sus='2009-10-30' set @indicator='FLO.T' set @tip_coloana=0

declare @q_calcul int, @q_categ char(9), @q_data_jos datetime, @q_data_sus datetime, @q_indicator varchar(20), @q_tip_coloana int
select @q_calcul=@calcul, @q_categ=@categ, @q_data_jos=@data_jos, @q_data_sus=@data_sus, @q_indicator=@indicator, @q_tip_coloana=@tip_coloana
--*/

if  object_id('tempdb..#ordineElement_1') is not null drop table #ordineElement_1
if  object_id('tempdb..#expval') is not null drop table #expval
if  object_id('tempdb..#de_numerotat') is not null drop table #de_numerotat
declare @separator varchar(20)
select @separator='->'
If @calcul = 1 begin 
exec dbo.CalcCategInd @pCateg=@categ,@pDataJos=@data_jos,@pDataSus=@data_sus,@lTipSold=0,@lFaraStergere=0 
end
	--> ordonarea elementelor (element_1 din expval)
select space(20-len(convert(varchar(20),ordine)))+convert(varchar(20),ordine) ordine, element_1 into #ordineElement_1 from fOrdineElement_1_TB(@categ)

/**	Se aranjeaza datele pentru a putea lua valori calculate si previzionate: */
	set transaction isolation level read uncommitted
create table #expval(cod_indicator varchar(20), valoare decimal(15,3), semn int, coloana varchar(50), ordonare varchar(50), ind_separator int, tip varchar(1))

insert into #expval(cod_indicator, valoare, semn, coloana, ordonare, ind_separator, tip)
select cod_indicator,sum(valoare) as valoare,0 as semn,
		rtrim(case @tip_coloana when 0 then convert(varchar(20),data,103) when 1 then v1.Element_1 when 2 then v1.Element_2 else v1.element_1 end) as coloana,
		rtrim(case @tip_coloana when 0 then convert(varchar(20),data,102) when 1 then max(o.ordine) when 2 then v1.Element_2 else max(o.ordine) end) as ordonare,
		charindex(@separator,v1.element_1) ind_separator,
		tip--, max(o.ordine) ordine_1
	from expval v1 
		inner join compcategorii c on c.cod_ind = v1.cod_indicator and c.cod_categ=@categ
		inner join #ordineElement_1 o on o.element_1=v1.Element_1
	where v1.data between @data_jos and @data_sus and (@element_1 is null or v1.element_1 like @element_1+'%')
		and (@element_2 is null or v1.element_2 like @element_2+'%')
	group by v1.cod_indicator, v1.tip, v1.data, v1.element_1, v1.element_2
union all -- mai jos "inventez" tipul de valori "D=Diferenta"
select cod_indicator,sum(valoare*(case tip when 'P' then 1 when 'E' then -1 else 0 end)) as valoare,
		(case max(tip) when 'P' then 1 else 0 end)+(case min(tip) when 'E' then -1 else 0 end) as semn,
		rtrim(case @tip_coloana when 0 then convert(varchar(20),data,103) when 1 then v1.Element_1 when 2 then v1.Element_2 else v1.element_1 end) as coloana,
		rtrim(case @tip_coloana when 0 then convert(varchar(20),data,102) when 1 then max(o.ordine) when 2 then v1.Element_2 else max(o.ordine) end) as ordonare,
		charindex(@separator,v1.element_1) ind_separator,
		'D' as tip--, max(o.ordine) ordine_1
	from expval v1 
		inner join compcategorii c on c.cod_ind = v1.cod_indicator and c.cod_categ=@categ 
		inner join #ordineElement_1 o on o.element_1=v1.Element_1
	where v1.data between @data_jos and @data_sus and (@element_1 is null or v1.element_1 like @element_1+'%')
		and (@element_2 is null or v1.element_2 like @element_2+'%')
	group by v1.cod_indicator, v1.data, v1.element_1, v1.element_2

/**		coloana = denumire/grupare pe coloane;		ordonare = ordinea in care se iau datele */

;with x as (
select Cod_Categ, Cod_Ind, Rand, parinte from compcategorii 
		where rtrim(cod_categ)=rtrim(@categ) and (rtrim(cod_ind)=rtrim(@indicator) or @indicator is null) union all
select c.Cod_Categ, c.Cod_Ind, c.Rand, c.Parinte from compcategorii c, x 
		where x.cod_ind=c.parinte and @indicator is not null
)
select i.cod_indicator,
			max(case when isnull(i.Descriere_expresie,'')<>'' then rtrim(i.Descriere_expresie) 
				when i.denumire_indicator!='' then rtrim(i.cod_indicator)+' - '+rtrim(i.denumire_indicator) else i.cod_indicator end) as descriere_expresie,
			c.cod_categ, max(cat.denumire_categ) as denumire_categ,c.rand,sum(cast(isnull(v1.valoare,0) as decimal(15,2))) as valoare,
			max(case when @tip_coloana<>20 then v1.coloana else (case when v1.ind_separator>0 then left(v1.coloana,v1.ind_separator-1) else v1.coloana end) end) coloana,
			max(case when @tip_coloana<>20 then '' else (case when v1.ind_separator>0 then substring(v1.coloana,v1.ind_separator+len(@separator),100) else '' end) end) coloana2,
			--v1.coloana,
			isnull(v1.tip,null) as tip,
			sum(v1.semn) as semn,max(c.parinte) as cod_parinte, min(v1.ordonare) ordonare,--, max(v1.ordine_1) ordine_1
			coloana as element_1
	into #de_numerotat
from indicatori i 
	inner join x c on c.cod_ind = i.cod_indicator
	inner join categorii cat on cat.cod_categ = c.cod_categ
	left outer join #expval v1 on i.cod_indicator = v1.cod_indicator --and v1.data between @data_jos and @data_sus
where c.rand<>0
group by i.cod_indicator,c.cod_categ,c.rand,v1.coloana,v1.tip
union all		/**	ultima coloana e de totaluri: */
select i.cod_indicator,
			max(case when isnull(i.Descriere_expresie,'')<>'' then rtrim(i.Descriere_expresie) 
				when i.denumire_indicator!='' then rtrim(i.cod_indicator)+' - '+rtrim(i.denumire_indicator) else i.cod_indicator end) as descriere_expresie,
			@categ cod_categ, max(cat.denumire_categ) as denumire_categ,c.rand,sum(cast(isnull(v1.valoare,0) as decimal(15,2))) as valoare,
			'<|Total|>', '', isnull(v1.tip,null) as tip,
			sum(v1.semn) as semn,max(c.parinte) as cod_parinte, 'ZZZZZZ' ordonare,--, max(v1.ordine_1) ordine_1
			''
from indicatori i 
	inner join x c on c.cod_ind = i.cod_indicator and @cutotal=1
	inner join categorii cat on cat.cod_categ = c.cod_categ
	left outer join #expval v1 on i.cod_indicator = v1.cod_indicator --and v1.data between @data_jos and @data_sus
where c.rand<>0
group by i.cod_indicator, c.rand,v1.tip
order by ordonare

declare @minrand int
select @minrand=min(d.rand)-1 from #de_numerotat d

select cod_indicator, descriere_expresie, cod_categ, denumire_categ, rand, valoare, coloana, coloana2, tip, semn, cod_parinte, ordonare, element_1
	from #de_numerotat d union all
select 'Ordine', '------------------------Ordine element------------------------', max(cod_categ), max(denumire_categ), @minrand,
		max(c.ordine), max(coloana), max(coloana2), max(tip), min(semn), null, max(ordonare), d.element_1		
	from #de_numerotat d left join fOrdineElement_1_TB(@categ) c on d.element_1=c.element_1
	where @tip_coloana not in (0,2)
group by d.element_1--, d.tip--*/
order by ordonare, rand

if  object_id('tempdb..#de_numerotat') is not null drop table #de_numerotat
if  object_id('tempdb..#ordineElement_1') is not null drop table #ordineElement_1
if  object_id('tempdb..#expval') is not null drop table #expval
