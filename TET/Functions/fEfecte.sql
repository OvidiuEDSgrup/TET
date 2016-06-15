--***
create function  fEfecte (@dDataJos datetime, @dDataSus datetime, @cTipEf char(1), @cTert char(13), @cEfect varchar(20), @cCont varchar(40), @cLM char(9), @cComanda char(40), @parXML xml=null)
returns @docef table
(
 subunitate char(9), 
 tip_efect char(1),
 tert char(13),
 efect varchar(20),
 tip_document char(2),
 numar_document char(8),
 data datetime,
 in_perioada char(1),
 cont varchar(40),
 cont_corespondent varchar(40),
 valoare float,
 achitat float,
 valuta char(3),
 curs float,
 valoare_valuta float,
 achitat_valuta float,
 data_scadentei datetime,
 factura char(20),
 explicatii char(50),
 numar_pozitie int,
 loc_de_munca char(9),
 comanda char(40), 
 data_efect datetime
)

as begin

declare @Sb char(9), @dDataImpl datetime, @nAnImpl int, @nLunaImpl int, @sesiune varchar(50), @q_cuFltLocmStilVechi bit, @locmV varchar(20)
set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), 1901)
set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), 1)
set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnImpl-1901, '01/01/1901'))
select @sesiune=@parXML.value('(row/@sesiune)[1]','varchar(50)')

if @dDataJos is null set @dDataJos = '01/01/1901'
if @dDataSus is null set @dDataSus = '12/31/2999'
select @q_cuFltLocmStilVechi=0, @locmV=rtrim(@clm)
if exists (select 1 from par where Tip_parametru='GE' and Parametru='FLTTRTLM' and Val_logica=1) -- o factura are un singur loc de munca si anume cel din tabela [facturi]
begin
	set @cLM='%' -- se vor aduce datele nefiltrate pe loc de munca, filtrarea se va face ulterior
	select @q_cuFltLocmStilVechi=1
end


	/**	Pregatire filtrare pe proprietati utilizatori*/
declare @userASiS varchar(10), @lista_gestiuni bit, @fltLmUt int
set @userASiS=dbo.fIaUtilizator(@sesiune)
declare @LmUtiliz table(valoare varchar(200))
insert into @LmUtiliz (valoare)
select cod from lmfiltrare where utilizator=@userASiS
set	@fltLmUt=isnull((select count(1) from @LmUtiliz),0)
if @userASiS=''
	set @fltLmUt=0

insert @docef

select a.Subunitate, a.tip as tip_efect, a.Tert, a.Nr_efect, 'SI' as tip_document, '' as numar_document, a.data,
(case when a.data between @dDataJos and @dDataSus then '2' else '1' end) as in_perioada, 
a.Cont, '' as cont_corespondent, 
round(convert(decimal(17,5), a.valoare), 2) as valoare, round(convert(decimal(17,5), a.decontat), 2) as achitat, 
a.valuta, a.curs, round(convert(decimal(17,5), a.valoare_valuta), 2) as valoare_valuta, round(convert(decimal(17,5), a.decontat_valuta), 2) as achitat_valuta, 
a.data_scadentei, '' as factura, a.Explicatii, 0 as numar_pozitie, a.loc_de_munca,a.comanda,a.data
from efimpl a 
where a.Subunitate=@Sb 
and (isnull(@cTipEf,'')='' or a.tip=@cTipEf) and (isnull(@cTert,'')='' or a.Tert=@cTert) and (isnull(@cEfect,'')='' or a.nr_efect=@cEfect) 
and (isnull(@cCont,'')='' or a.cont like RTrim(@cCont)+'%') and (isnull(@cLM,'')='' or a.Loc_de_munca like RTrim(@cLM)+'%') and (isnull(@cComanda,'')='' or a.comanda=@cComanda)
and (@fltLmUt=0 or exists (select 1 from @LmUtiliz pr where pr.valoare=a.loc_de_munca))

union all 

select a.Subunitate, (case when isnull(a.subtip,'')='IY' then 'P' else (case a.plata_incasare when 'IS' then 'P' when 'PS' then 'I' else left(a.plata_incasare,1) end) end) as tip_efect, a.Tert, a.efect as efect, 
a.plata_incasare as tip_document, left(a.numar,8) as numar_document, a.data, (case when a.data between @dDataJos and @dDataSus then '2' else '1' end) as in_perioada, 
a.Cont, a.Cont_corespondent, 
(case when a.plata_incasare in ('IS','PS') then -1 else 1 end)*round(convert(decimal(17,5), a.Suma), 2) as valoare, 0 as achitat, 
a.valuta, a.curs, (case when a.plata_incasare in ('IS','PS') then -1 else 1 end)*round(convert(decimal(17,5), a.Suma_valuta), 2) as valoare_valuta, 0 as achitat_valuta, 
isnull(a.detalii.value('(/row/@datascad)[1]','datetime'), a.data) as data_scadentei, a.Factura, a.Explicatii, a.numar_pozitie, a.loc_de_munca,a.comanda, isnull(a.detalii.value('(/row/@dataefect)[1]','datetime'), a.data) as data_efect
from pozplin a 
left outer join conturi c on a.Subunitate=c.Subunitate and a.Cont=c.Cont 
where a.Subunitate=@Sb and isnull(c.Sold_credit,0)=8 and a.data between @dDataImpl and @dDataSus 
and (isnull(@cTipEf,'')='' or (case when isnull(a.subtip,'')='IY' then 'P' else (case a.plata_incasare when 'IS' then 'P' when 'PS' then 'I' else left(a.plata_incasare,1) end) end)=@cTipEf) and (isnull(@cTert,'')='' or a.Tert=@cTert) 
and (isnull(@cEfect,'')='' or a.efect=@cEfect) 
and (isnull(@cCont,'')='' or a.cont like RTrim(@cCont)+'%') and (isnull(@cLM,'')='' or a.Loc_de_munca like RTrim(@cLM)+'%') and (isnull(@cComanda,'')='' or a.comanda=@cComanda) 
and (@fltLmUt=0 or exists (select 1 from @LmUtiliz pr where pr.valoare=a.loc_de_munca))

union all 

select a.Subunitate, (case when isnull(a.subtip,'')='IY' then 'P' else (case a.plata_incasare when 'IS' then 'P' when 'PS' then 'I' else left(a.plata_incasare,1) end) end) as tip_efect, a.Tert, 
a.efect, a.plata_incasare as tip_document, left(a.numar,8) as numar_document, a.data,
(case when a.data between @dDataJos and @dDataSus then '2' else '1' end) as in_perioada, 
a.Cont_corespondent, a.Cont, 
0 as valoare, (case when a.plata_incasare in ('IS','PS') then -1 else 1 end)*round(convert(decimal(17,5), a.Suma), 2) as achitat, 
a.valuta, a.curs, 
0 as valoare_valuta, (case when a.plata_incasare in ('IS','PS') then -1 else 1 end)*round(convert(decimal(17,5), a.achit_fact), 2) as achitat_valuta, 
isnull(e.Data_scadentei, '01/01/1901'), a.Factura, isnull(e.explicatii,a.Explicatii), a.numar_pozitie, isnull(e.loc_de_munca, a.loc_de_munca), isnull (e.Comanda, a.comanda), isnull(e.data, '01/01/1901')
from pozplin a 
left outer join conturi c on a.Subunitate=c.Subunitate and a.Cont_corespondent=c.Cont 
left outer join efecte e on a.Subunitate=e.Subunitate and a.tert=e.tert and a.efect=e.Nr_efect and e.tip = (case when isnull(a.subtip,'')='IY' then 'P' else (case a.plata_incasare when 'IS' then 'P' when 'PS' then 'I' else left(a.plata_incasare,1) end) end)
where a.Subunitate=@Sb and isnull(c.Sold_credit,0)=8 and a.data between @dDataImpl and @dDataSus
and (isnull(@cTipEf,'')='' or (case when isnull(a.subtip,'')='IY' then 'P' else (case a.plata_incasare when 'IS' then 'P' when 'PS' then 'I' else left(a.plata_incasare,1) end) end)=@cTipEf) 
and (isnull(@cTert,'')='' or a.Tert=@cTert) and (isnull(@cEfect,'')='' or a.efect=@cEfect) 
and (isnull(@cCont,'')='' or a.cont_corespondent like RTrim(@cCont)+'%') and (isnull(@cLM,'')='' or a.Loc_de_munca like RTrim(@cLM)+'%') and (isnull(@cComanda,'')='' or a.comanda=@cComanda) 
and (@fltLmUt=0 or exists (select 1 from @LmUtiliz pr where pr.valoare=a.loc_de_munca))



if @q_cuFltLocmStilVechi=1
begin
	delete ft
		from @docef ft 
		left outer join facturi f on f.subunitate=ft.subunitate and f.tert=ft.tert and f.factura=ft.factura and ft.tip_efect=(case when f.tip=0x54 then 'P' else 'I' end)
		where (f.loc_de_munca is not null and f.loc_de_munca not like rtrim(@locmV)+'%')
			 or (f.Loc_de_munca is null and ft.loc_de_munca not like rtrim(@locmV)+'%')

end


return 
end
