--***
create function  fFacturiCen(@cFurnBenef char(1), @dDataJos datetime, @dDataSus datetime, @cTert char(13), @cFact char(20), @GrTert int, @GrFact int, @cContFact varchar(20), @nSoldMin float, @nSemnSold int, @parxml xml=null)
returns @fact table
(
subunitate char (9),
tip char(1),
factura char(20),
tert char(13),
data datetime,
data_scadentei datetime,
valoare float,
tva float,
achitat float,
sold float,
valuta char(3),
curs float,
valoare_valuta float,
achitat_valuta float,
sold_valuta float,
cont_factura varchar(20),
loc_de_munca varchar(13),
comanda char(40),
data_ultimei_achitari datetime,
achitat_interval float,
achitat_interval_plata float,
explicatii varchar(2000)
--,contract varchar(20)
--	primary key (subunitate, tip, factura, tert)	--> nu pare a imbunatati viteza; mai merita studiat?
)
as
begin

declare @docfac table
(furn_benef char(1),subunitate char(9),tert char(13),factura char(20),tip char(2),numar char(20),data datetime,valoare float,tva float,
 achitat float,valuta char(3),curs float,total_valuta float,achitat_valuta float,loc_de_munca char(13),comanda char(40),
 cont_de_tert varchar(20),fel int,cont_coresp varchar(20),explicatii char(50),numar_pozitie int,gestiune char(13),data_facturii datetime,
 data_scadentei datetime,nr_dvi char(13),pozitie int,
 grp varchar(100),ordine varchar(50),ordine_valuta varchar(50),
 dataFact datetime, dataScadFact datetime, valutaFact char(3), cursFact float, lmFact char(13), data_platii datetime
 --, contract varchar(20)
 )

if @GrTert is null set @GrTert = 1
if @GrFact is null set @GrFact = 1
declare @efecteAchitate bit
select @efecteAchitate=isnull(@parXML.value('(row/@efecteachitate)[1]','bit'),0)

insert @docfac(furn_benef, subunitate, tert, factura, tip, numar, data, valoare, tva, achitat, valuta, curs, total_valuta,
	achitat_valuta, loc_de_munca, comanda, cont_de_tert, fel, cont_coresp, explicatii, numar_pozitie, gestiune, data_facturii,
	data_scadentei, nr_dvi, pozitie, grp, ordine, ordine_valuta, dataFact, dataScadFact, valutaFact, cursFact, lmFact, data_platii--, contract
	)
select furn_benef,subunitate,tert,factura,tip,numar,data,valoare,tva
		,(case when abs(achitare_efect_in_curs)>0 and achitat>0 then 0 else achitat end) achitat--> daca se tine cont de achitarea efectelor, un efect neachitat determina ca factura sa fie considerata neachitata
		,valuta,curs,total_valuta,achitat_valuta,
loc_de_munca,comanda,cont_de_tert,fel,cont_coresp,explicatii,numar_pozitie,gestiune,data_facturii,data_scadentei,
nr_dvi,pozitie,
subunitate+furn_benef+tert+factura as grp,
(case when tip in ('SI','AP','AS','RM','RS','RP','RQ','SF','IF') then '0' when tip in ('FF','FB') then '1' else '2' end)
+convert(char(8),data,112)+str(numar_pozitie) as ordine,
(case when valuta<>'' and curs<>0 then '2' when valuta<>'' then '1' else '0' end)
	+(case when tip in ('SI','AP','AS','RM','RP','RQ','RS','SF','IF') then '1' when tip in ('FF','FB') then '2' else '0' end)
	+convert(char(8),data,112)+str(numar_pozitie) as ordine_valuta,
'01/01/2999', '01/01/2999', '', 0, '', data_platii--, contract
from dbo.fFacturi(@cFurnBenef, @dDataJos, @dDataSus, @cTert, @cFact, @cContFact, @nSoldMin, @nSemnSold, 0, null, @parxml)

-- data, data scadentei, valuta, curs, loc munca: se iau in functie de tip doc, data si numar pozitie
-- mai sus au fost initializate cu valori implicite 
-- mai jos se vor inlocui aceste valori pe pozitiile care dau valoare finala (ex. RM da locul de munca, indiferent de loc m. de pe PF)
update @docfac
set 
dataFact=(case when d.ordine=d1.ordine then d.data_facturii else d.dataFact end), 
dataScadFact=(case when d.ordine=d1.ordine then d.data_scadentei else d.dataScadFact end),
valutaFact=(case when d.ordine_valuta=d1.ordine_valuta then d.valuta else d.valutaFact end), 
cursFact=(case when d.ordine_valuta=d1.ordine_valuta then d.curs else d.cursFact end),
lmFact=(case when d.ordine=d1.ordine then d.loc_de_munca else d.lmFact end) 
from @docfac d, (select d2.grp, min(d2.ordine) as ordine, max(d2.ordine_valuta) as ordine_valuta from @docfac d2 group by d2.grp) d1
where d.grp=d1.grp and (d.ordine=d1.ordine or d.ordine_valuta=d1.ordine_valuta)

/*
update @docfac
set 
valutaFact=valuta, cursFact=curs
from @docfac d, (select d2.grp, max(d2.ordine_valuta) as ordine_valuta from @docfac d2 group by d2.grp) d1
where d.grp=d1.grp and d.ordine_valuta=d1.ordine_valuta
*/

insert @fact (
	subunitate,
	tip,
	factura,
	tert,
	data,
	data_scadentei,
	valoare,
	tva,
	achitat,
	sold,
	valuta,
	curs,
	valoare_valuta,
	achitat_valuta,
	sold_valuta,
	cont_factura,
	loc_de_munca,
	comanda,
	data_ultimei_achitari,
	achitat_interval,
	achitat_interval_plata,
	explicatii
	--,contract
	)
select
subunitate, furn_benef tip,
max(case when @GrFact=1 then factura else '' end) factura,
max(case when @GrTert=1 then tert else '' end) tert,
min(dataFact) data, min(dataScadFact) data_scadentei,
sum(round(convert(decimal(17,5), valoare), 2)) valoare,
sum(round(convert(decimal(17,5), tva), 2)) tva,
sum(round(convert(decimal(17,5), achitat), 2)) achitat,
sum(round(convert(decimal(17,5), valoare), 2)+round(convert(decimal(17,5), tva), 2)-round(convert(decimal(17,5), achitat), 2)) sold,
max(valutaFact) valuta, max(cursFact) curs,
sum(round(convert(decimal(17,5), total_valuta), 2)) valoare_valuta,
sum(round(convert(decimal(17,5), achitat_valuta), 2)) achitat_valuta,
sum(round(convert(decimal(17,5), total_valuta), 2)-round(convert(decimal(17,5), achitat_valuta), 2)) sold_valuta,
max(cont_de_tert) cont_factura, max(lmFact) loc_de_munca, max(comanda) comanda,
max(case when abs(achitat)>=0.01 or abs(achitat_valuta)>=0.01 then data else '01/01/1901' end) data_ultimei_achitari,
sum(round(convert(decimal(17,5), (case when data>=@dDataJos and data<=@ddatasus then achitat else 0 end)), 2)) achitat_interval ,
sum(round(convert(decimal(17,5), (case when isnull(data_platii,data)>=@dDataJos and isnull(data_platii,data)<=@ddatasus then achitat else 0 end)), 2)) achitat_interval_plata,
max(explicatii)
--,max(contract) contract
from @docfac
group by subunitate, furn_benef,
(case when @GrFact=1 then factura else '' end),
(case when @GrTert=1 then tert else '' end)

return
end
