--***
create function fDeconturiCen  
(@dDataJos datetime, @dDataSus datetime, @cMarca char(13), @cDecont varchar(40),  
@GrMarca int, @GrDec int, @cCont varchar(40), @PtRulaj int, @PtFisa int)  

returns @dec table  
(  
Subunitate char(9),  
Tip char(2),  
Marca char(6),  
Decont varchar(40),  
Cont varchar(40),  
Data datetime,  
Data_scadentei datetime,  
Valoare float,  
Valuta char(3),  
Curs float,  
Valoare_valuta float,  
Decontat float,  
Sold float,  
Decontat_valuta float,  
Sold_valuta float,  
Loc_de_munca char(9),  
Comanda char(40), 
Data_ultimei_decontari datetime,  
Explicatii char(50)  
)  
as  
begin  
  
declare @docdec table  
 (subunitate char(9),marca char(6),decont varchar(40), tip_document char(2), numar_document varchar(20), data datetime, in_perioada char(1),   
 valoare float, achitat float, cont varchar(40), cont_coresp varchar(40), fel char(1), valuta char(3), curs float,   
 valoare_valuta float, achitat_valuta float, tert char(13), factura char(20), explicatii char(50), numar_pozitie int,   
 loc_de_munca char(9), comanda char(40), data_scadentei datetime, cantitate float, debit_credit char(1),  
 grp varchar(100),ordine varchar(50),ordine_valuta varchar(50),  
 dataDec datetime, valutaDec char(3), cursDec float)  

if @GrMarca is null set @GrMarca = 1  
if @GrDec is null set @GrDec = 1  
  
insert @docdec  
select subunitate,marca,decont,tip_document, numar_document, data, in_perioada, valoare, achitat, cont, cont_coresp, fel, valuta,   
curs, valoare_valuta, achitat_valuta, tert, factura, explicatii,numar_pozitie, loc_de_munca, comanda, data_scadentei, cantitate, debit_credit,   
subunitate+tip_document+marca+decont,  
(case when tip_document in ('PD') then '0' else '1' end)+convert(char(8),data,112)+str(numar_pozitie),  
(case when valuta<>'' and curs<>0 then '2' when valuta<>'' then '1' else '0' end)+(case when tip_document in ('PD') then '1' else '0' end)+convert(char(8),data,112)+str(numar_pozitie),  
'01/01/2999','', 0  
from dbo.fDeconturi (@dDataJos, @dDataSus, @cMarca, @cDecont, @cCont, @PtRulaj, @PtFisa, null)   
  
update @docdec  
set   
dataDec=(case when d.ordine=d1.ordine then d.data else d.dataDec end),   
valutaDec=(case when d.ordine_valuta=d1.ordine_valuta then d.valuta else d.valutaDec end),   
cursDec=(case when d.ordine_valuta=d1.ordine_valuta then d.curs else d.cursDec end)  
from @docdec d, (select d2.grp, min(d2.ordine) as ordine, max(d2.ordine_valuta) as ordine_valuta from @docdec d2 group by d2.grp) d1  
where d.grp=d1.grp and (d.ordine=d1.ordine or d.ordine_valuta=d1.ordine_valuta)  

insert @dec  
select  
subunitate, 'T' /*tip_document*/,
max(case when @GrMarca=1 then marca else '' end),
max(case when @GrDec=1 then decont else '' end),  
min(cont),min(dataDec), min(data_scadentei),  
sum(round(convert(decimal(17,5), valoare), 2)),
max(valutaDec),max(cursDec),sum(round(convert(decimal(17,5), valoare_valuta), 2)),
sum(round(convert(decimal(17,5), achitat), 2)),  
sum(round(convert(decimal(17,5), valoare), 2)-round(convert(decimal(17,5), achitat), 2)),  
sum(round(convert(decimal(17,5), achitat_valuta), 2)),   
sum(round(convert(decimal(17,5), valoare_valuta), 2)-round(convert(decimal(17,5), achitat_valuta), 2)),
max(loc_de_munca),max(comanda), max(data), 
max(explicatii)
from @docdec  
group by subunitate, /*tip_document,*/  
(case when @GrDec=1 then decont else '' end),  
(case when @GrMarca=1 then marca else '' end)  
 
return  
end
