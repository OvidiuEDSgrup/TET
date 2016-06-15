--***
create function  fDeconturi (@dDataJos datetime, @dDataSus datetime, @cMarca char(6), @cDecont varchar(40), @cCont varchar(40), @PtRulaj int, @PtFisa int, @parXML xml=null)
returns @docsal table
(
	subunitate char(9), 
	marca char(6), 
	decont varchar(40), 
	tip_document char(2), 
	numar_document char(20), 
	data datetime, 
	in_perioada char(1), 
	valoare float, 
	achitat float, 
	cont varchar(40), 
	cont_coresp varchar(40), 
	fel char(1), 
	valuta char(3), 
	curs float, 
	valoare_valuta float, 
	achitat_valuta float, 
	tert char(13),
	factura char(20),
	explicatii char(50), 
	numar_pozitie int, 
	loc_de_munca char(9), 
	comanda char(40), 
	data_scadentei datetime, 
	cantitate float, 
	debit_credit char(1)
)

--select * from dbo.fDeconturi ('2014-01-01', '2014-12-31', '1', null, null, 0, 0, '<row sesiune="A88CE8A5E02E7"/>')

as begin

declare @Sb char(9), @dDataImpl datetime, @nAnImpl int, @nLunaImpl int, @dDataJosDoc datetime, @DecRest int, @GrMarcaCont int, @RestitCaAchit int, @CuContVenDF int, @ContVenDF varchar(40), @sesiune varchar(50)
select @sesiune=@parXML.value('(row/@sesiune)[1]','varchar(50)')
set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), 1901)
set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), 1)
set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnImpl-1901, '01/01/1901'))
set @DecRest=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='DECREST'), 0)
set @GrMarcaCont=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='DECMARCT'), 0)
set @CuContVenDF=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='CTVENDF'), 0)
set @ContVenDF=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CTVENDF'), '')
if @dDataJos is null set @dDataJos = '01/01/1901'
if @dDataSus is null set @dDataSus = '12/31/2999'
if @PtRulaj is null set @PtRulaj = 0
if @PtFisa is null set @PtFisa = 0

set @RestitCaAchit = @DecRest + @PtFisa
if @RestitCaAchit > 1 set @RestitCaAchit = 1

if @PtRulaj = 1
	set @dDataJosDoc = @dDataJos
else
	set @dDataJosDoc = @dDataImpl
	
		/**	Pregatire filtrare pe proprietati utilizatori*/
declare @userASiS varchar(10)
select @userASiS=dbo.fIaUtilizator(@sesiune)

insert @docsal
select subunitate, left(marca, 6), rtrim(decont) as decont, 'SI' as tip_document, decont as numar_document, data, (case when data between @dDataJos and @dDataSus then '2' else '1' end) as in_perioada, 
valoare, decontat, cont, '' as cont_coresp, '1' as fel, valuta, curs, valoare_valuta, decontat_valuta, 
'' as tert, '' as factura, 'Sold initial' as explicatii, 0 as numar_pozitie, loc_de_munca, comanda, data_scadentei, 0 as cantitate, 'D' as debit_credit
from decimpl 
left join lmfiltrare pr on pr.cod=loc_de_munca and pr.utilizator=@userASiS
where subunitate=@Sb and tip='T' and @PtRulaj = 0 and data<=@dDataSus 
and (isnull(@cMarca, '')='' or marca=@cMarca) and (isnull(@cDecont, '')='' or decont=@cDecont) and (isnull(@cCont, '')='' or cont like rtrim(@cCont)+'%')
and (dbo.f_areLMFiltru(@userASiS)=0 or pr.utilizator=@userASiS)

union all 
select a.subunitate, left(a.marca, 6), (case when @GrMarcaCont=1 then a.cont_corespondent else rtrim(a.decont) end), a.plata_incasare, left(a.numar,20), a.data, 
(case when a.data between @dDataJos and @dDataSus then '2' else '1' end), 
(case when a.plata_incasare='ID' then (case when @RestitCaAchit=1 then 0 else -a.suma end) else a.suma end), (case when a.plata_incasare='ID' and @RestitCaAchit=1 then a.suma else 0 end), 
a.cont_corespondent, a.cont, '3', a.valuta, a.curs, 
(case when a.plata_incasare='ID' then (case when @RestitCaAchit=1 then 0 else -a.suma_valuta end) else a.suma_valuta end), (case when a.plata_incasare='ID' and @RestitCaAchit=1 then a.suma_valuta else 0 end), 
a.tert, a.factura, isnull(nullif(a.detalii.value('(/row/@explicatii)[1]','varchar(100)'),''),a.explicatii), a.numar_pozitie, a.loc_de_munca, a.comanda, 
isnull(a.detalii.value('(/row/@datascad)[1]','datetime'), a.data), 
isnull(a.detalii.value('(/row/@cantitate)[1]','decimal(12,2)'), 0) as cantitate, (case when a.plata_incasare='ID' and @RestitCaAchit=1 then 'C' else 'D' end)
from pozplin a
left outer join conturi c on a.subunitate=c.subunitate and a.cont_corespondent=c.cont
left join lmfiltrare pr on pr.cod=a.loc_de_munca and pr.utilizator=@userASiS
where a.subunitate=@Sb and isnull(c.sold_credit, 0) = 9 and a.data between @dDataJosDoc and @dDataSus
and (isnull(@cMarca, '')='' or a.marca=@cMarca) and (isnull(@cDecont, '')='' or (case when @GrMarcaCont=1 then a.cont_corespondent else a.decont end)=@cDecont) 
and (isnull(@cCont, '')='' or a.cont_corespondent like rtrim(@cCont)+'%')
and (dbo.f_areLMFiltru(@userASiS)=0 or pr.utilizator=@userASiS)

union all 
select a.subunitate, left(a.marca, 6), (case when @GrMarcaCont=1 then a.cont else rtrim(a.decont) end), a.plata_incasare, left(a.numar,20), a.data, 
(case when a.data between @dDataJos and @dDataSus then '2' else '1' end), 
(case when left(a.plata_incasare, 1)='I' then a.suma else 0 end), (case when left(a.plata_incasare, 1)='I' then 0 when left(a.plata_incasare, 1)='P' then 1 else -1 end)*a.suma, 
a.cont, a.cont_corespondent, '3', a.valuta, a.curs, 
(case when left(a.plata_incasare, 1)='I' then a.suma_valuta else 0 end), (case when left(a.plata_incasare, 1)='I' then 0 when left(a.plata_incasare, 1)='P' then 1 else -1 end)*a.suma_valuta, 
a.tert, a.factura, isnull(nullif(a.detalii.value('(/row/@explicatii)[1]','varchar(100)'),''),a.explicatii), a.numar_pozitie, a.loc_de_munca, a.comanda, 
isnull(a.detalii.value('(/row/@datascad)[1]','datetime'), a.data), 
isnull(a.detalii.value('(/row/@cantitate)[1]','decimal(12,2)'), 0) as cantitate, 'C'
from pozplin a
left outer join conturi c on a.subunitate=c.subunitate and a.cont=c.cont
left join lmfiltrare pr on pr.cod=a.loc_de_munca and pr.utilizator=@userASiS
where a.subunitate=@Sb and isnull(c.sold_credit, 0) = 9 and a.data between @dDataJosDoc and @dDataSus 
and (isnull(@cMarca, '')='' or a.marca=@cMarca) and (isnull(@cDecont, '')='' or (case when @GrMarcaCont=1 then a.cont else a.decont end)=@cDecont) 
and (isnull(@cCont, '')='' or a.cont like rtrim(@cCont)+'%')
and (dbo.f_areLMFiltru(@userASiS)=0 or pr.utilizator=@userASiS)

union all
select a.subunitate, left(a.gestiune_primitoare,6), a.tert, a.tip, a.numar, a.data, (case when a.data between @dDataJos and @dDataSus then '2' else '1' end), 
round(convert(decimal(15, 5), a.cantitate*a.pret_de_stoc*a.procent_vama/100*(1+a.cota_TVA/100)), 2), 0, 
a.cont_factura, (case when @CuContVenDF=1 then @ContVenDF else a.cont_de_stoc end), '2', 
a.valuta, a.curs, 0, 0, '', '', '', a.numar_pozitie, a.loc_de_munca, a.comanda, a.data, a.cantitate, 'D'
from pozdoc a
inner join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_factura
left join lmfiltrare pr on pr.cod=a.loc_de_munca and pr.utilizator=@userASiS
where a.subunitate=@Sb and a.tip='DF' and c.sold_credit=9 and a.tert<>'' and a.procent_vama<>0
and (isnull(@cMarca, '')='' or left(a.gestiune_primitoare, 6)=@cMarca) 
and (isnull(@cDecont, '')='' or a.tert=@cDecont) 
and (isnull(@cCont, '')='' or a.cont_factura like rtrim(@cCont)+'%')
and (dbo.f_areLMFiltru(@userASiS)=0 or pr.utilizator=@userASiS)
return 
end
