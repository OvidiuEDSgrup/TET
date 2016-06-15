create procedure fisa_bugetara (@datajos datetime,@datasus datetime, @document varchar(20)=null, @cont_db varchar(20)=null, @cont_cd varchar(20)=null, @valuta varchar(3)=null, @cont varchar(20)=null, @art_alin varchar(20)=null, @cap_sub varchar(20)=null, @ind_bug varchar(20)=null, @jurnal varchar(20)=null, @ordonare int=null, @locm varchar(20)=null)
as
begin
declare @subunitate varchar(9), @ceva_37 bit
if @ordonare is null set @ordonare=0 -- 1=pe data, 0=pe indicatori
set @ceva_37=1
select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='subpro'

	/**	Pregatire filtrare pe proprietati utilizatori*/
declare @eLmUtiliz int
declare @LmUtiliz table(valoare varchar(200), cod_proprietate varchar(20))
insert into @LmUtiliz(valoare, cod_proprietate)
select valoare, cod_proprietate from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

select subunitate,tip_document,numar_document,data,cont_debitor,cont_creditor,suma,valuta,curs,suma_valuta,explicatii,utilizator,data_operarii,ora_operarii,numar_pozitie,loc_de_munca,right(Comanda,20) as Comanda,Jurnal
into #pozincon from pozincon where Subunitate=@subunitate and Data between @datajos and @datasus and ((@cont is null or Cont_debitor like rtrim(@cont)+'%') or (@cont is null or Cont_creditor like rtrim(@cont)+'%')) and (@document is null or Numar_document=@document) and (@cont_db is null or Cont_debitor like rtrim(@cont_db)+'%') and (@cont_cd is null or Cont_creditor like rtrim(@cont_cd)+'%') and (@valuta is null or valuta=@valuta) and (@art_alin is null or rtrim(substring(right(Comanda,20),9,4)) like rtrim(@art_alin)+'%') and (@cap_sub is null or rtrim(left(right(Comanda,20),6)) like rtrim(@cap_sub)+'%') and (@ind_bug is null or right(comanda,20) like rtrim(@ind_bug)+'%') and (@jurnal is null or jurnal=@jurnal)
			and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=Loc_de_munca))
			and (@locm is null or Loc_de_munca like @locm+'%')

Select rtrim(Comanda) as art_bugetar, Suma as Incasari, convert(float, 0) as plati, convert(float, 0) as restituiri, 
convert(float, 0) as cheltuieli, convert(float, 0) as venituri, Tip_document, Numar_document, Data, month(data) as Luna, Cont_debitor, Cont_creditor, Explicatii, 
rtrim(substring(Comanda,5,2)) as Subcapitol, rtrim(substring(Comanda,7,2)) as Titlu, 
rtrim(substring(Comanda,9,2)) as Articol, rtrim(substring(Comanda,11,2)) as Aliniat,
(case when @ordonare=1 then Data else convert(datetime, convert(char(10), getdate(), 101), 101) end) as Ordonare_data,
(case when @ordonare=1 then rtrim(substring(Comanda,9,4)) else rtrim(substring(comanda,1,4)) end) as Ordonare 
from #pozincon 
where exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='COPLREB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_debitor),len(val_alfanumerica))) 
and ((select val_logica from par where tip_parametru='GE' and left(parametru,7)='PLCHELT')=1 
or not exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='CONTCHB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_creditor),len(val_alfanumerica))) 
)
and (charindex('XW',explicatii)>0 or cont_debitor not like '231%' and cont_debitor not like '13%' and cont_debitor not like '220%' and cont_debitor not like '4621%') and suma<>0
and not (tip_document='PI' and cont_debitor like '4281.%' and exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='COPLREB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_creditor),len(val_alfanumerica))))
union all
Select Comanda, 0, Suma as Plati, 0, 0, 0, Tip_document, Numar_document, Data, month(data) as Luna, Cont_debitor, Cont_creditor, Explicatii, 
rtrim(substring(Comanda,5,2)) as Subcapitol, rtrim(substring(Comanda,7,2)) as Titlu, 
rtrim(substring(Comanda,9,2)) as Articol, rtrim(substring(Comanda,11,2)) as Aliniat, 
(case when @ordonare=1 then Data else convert(datetime, convert(char(10), getdate(), 101), 101) end) as Ordonare_data,
(case when @ordonare=1 then rtrim(substring(Comanda,9,4)) else rtrim(substring(comanda,1,4)) end) as Ordonare
from #pozincon 
where 
exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='COPLREB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_creditor),len(val_alfanumerica))) 
and not (tip_document='NC' and (cont_debitor like '410%' or cont_debitor like '462%' or cont_creditor like '462%' or cont_creditor like '4281.%')) and suma<>0 and left(cont_debitor,3) not in ('472','476','481','482')
union all
Select Comanda, 0, 0, Suma as Restituiri, 0, 0, Tip_document, Numar_document, Data, month(data) as Luna, Cont_debitor, Cont_creditor, Explicatii,
rtrim(substring(Comanda,5,2)) as Subcapitol, rtrim(substring(Comanda,7,2)) as Titlu, 
rtrim(substring(Comanda,9,2)) as Articol, rtrim(substring(Comanda,11,2)) as Aliniat, 
(case when @ordonare=1 then Data else convert(datetime, convert(char(10), getdate(), 101), 101) end) as Ordonare_data,
(case when @ordonare=1 then rtrim(substring(Comanda,9,4)) else rtrim(substring(comanda,1,4)) end) as Ordonare
from #pozincon 
where exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='COPLREB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_creditor),len(val_alfanumerica))) 
and (1=0 and suma<0)
union all
Select Comanda, 0, 0, 0, 
(case when exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='CONTCHB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_debitor),len(val_alfanumerica))) 
or left(cont_debitor,3) in ('401','472','476','481','482') or left(cont_debitor, 1)='6' then Suma else 0 end) as Cheltuieli, 
(case when exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='CONTCHB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_debitor),len(val_alfanumerica))) 
or left(cont_debitor,3) in ('401','472','476','481','482') or left(cont_debitor, 1)='6' then 0 when @ceva_37=1 then Suma else 0 end) as Venituri, Tip_document, Numar_document, Data, month(data) as Luna,  Cont_debitor, Cont_creditor, Explicatii, 
rtrim(substring(Comanda,5,2)) as Subcapitol, rtrim(substring(Comanda,7,2)) as Titlu, 
rtrim(substring(Comanda,9,2)) as Articol, rtrim(substring(Comanda,11,2)) as Aliniat, 
(case when @ordonare=1 then Data else convert(datetime, convert(char(10), getdate(), 101), 101) end) as Ordonare_data, 
(case when @ordonare=1 then rtrim(substring(Comanda,9,4)) else rtrim(substring(Comanda,1,4)) end) as Ordonare
from #pozincon 
where (exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='CONTCHB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_debitor),len(val_alfanumerica))) 
	 or exists (select 1 from par where tip_parametru='GE' and left(parametru,7)='CONTCHB' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_creditor),len(val_alfanumerica))) 
or left(cont_debitor,3) in ('472','476','481','482') or left(cont_debitor, 1)='6') and not (cont_debitor like '231%' and cont_creditor like '700%')
union all
Select Comanda, 0, 0, 0, 0, Suma as Venituri , Tip_document, Numar_document, Data, month(data) as Luna,  Cont_debitor, Cont_creditor, Explicatii, 
rtrim(substring(Comanda,5,2)) as Subcapitol, rtrim(substring(Comanda,7,2)) as Titlu, rtrim(substring(Comanda,9,2)) as Articol, rtrim(substring(Comanda,11,2)) as Aliniat, 
(case when @ordonare=1 then Data else convert(datetime, convert(char(10), getdate(), 101), 101) end) as Ordonare_data, 
(case when @ordonare=1 then rtrim(substring(Comanda,9,4)) else rtrim(substring(Comanda,1,4)) end) as Ordonare
from #pozincon 
where exists (select 1 from par where tip_parametru='GE' and left(parametru,8)='COVENBUG' and rtrim(val_alfanumerica)<>'' and rtrim(val_alfanumerica)=left(rtrim(Cont_creditor),len(val_alfanumerica))) 
and not (cont_creditor like '461%')
order by Ordonare_data, Ordonare, Subcapitol, Titlu, Articol, Aliniat

drop table #pozincon
end