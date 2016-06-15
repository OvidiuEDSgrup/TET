--***
create procedure [dbo].[wIaPozCheltuieli] @sesiune varchar(50), @parXML xml  
as    
  
declare @tip varchar(2), @tipDoc varchar(2), @numar varchar(20), @data datetime
--  
select 
 @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
 @tipDoc=ISNULL(@parXML.value('(/row/@tipDoc)[1]', 'varchar(2)'), ''),  
 @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),  
 @numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), '')
--
--
--Pozdoc
if @tipDoc in ('AE','AP','CM')
begin
select 
@tip as subtip,
RTRIM(n.denumire) as ex,
rtrim(d.cont_corespondent) as cont,
convert(decimal(15,2), d.Cantitate*d.pret_de_stoc) as suma,
rtrim(d.Loc_de_munca) as lm,
RTRIM(lm.Denumire) as denlm,
rtrim(d.Comanda) as comanda,
RTRIM(comenzi.Descriere) as dencomanda,
(case when rtrim(d.barcod)<>'' then rtrim(d.barcod) else rtrim(c.Articol_de_calculatie) end) as articol,
--
rtrim(d.tip) as tipDoc, 
rtrim(d.Numar) as numar, 
convert(char(10),d.data,101) as data, 
RTRIM(d.cod_intrare) as CI,                                    -- CI = CI
convert(char(10),d.numar_pozitie) as numar_pozitie 
from pozdoc d
left outer join conturi c on c.cont=d.cont_corespondent  
left outer join nomencl n on n.Cod=d.Cod 
left outer join lm on lm.Cod=d.Loc_de_munca
left outer join comenzi on comenzi.Comanda=d.Comanda
where d.Tip=@tipDoc
and d.numar=@numar 
and d.data=@data 
order by d.Numar_pozitie  
for xml raw
end
--
--
if @tipDoc in ('AI','AS','RM','RS')
begin
select  
@tip as subtip,
RTRIM(n.denumire) as ex,
rtrim(d.cont_de_stoc) as cont,
convert(decimal(15,2), d.Cantitate*d.pret_de_stoc) as suma,
rtrim(d.Loc_de_munca) as lm,
RTRIM(lm.Denumire) as denlm,
rtrim(d.Comanda) as comanda,
RTRIM(comenzi.Descriere) as dencomanda,
(case when rtrim(d.barcod)<>'' then rtrim(d.barcod) else rtrim(c.Articol_de_calculatie) end) as articol,
rtrim(d.tip) as tipDoc, 
rtrim(d.Numar) as numar, 
convert(char(10),d.data,101) as data, 
RTRIM(d.cod_intrare) as CI,                                    -- CI = CI
convert(char(10),d.numar_pozitie) as numar_pozitie
from pozdoc d
left outer join conturi c on c.cont=d.cont_de_stoc  
left outer join nomencl n on n.Cod=d.Cod 
left outer join lm on lm.Cod=d.Loc_de_munca
left outer join comenzi on comenzi.Comanda=d.Comanda
where d.Tip=@tipDoc
and d.numar=@numar 
and d.data=@data 
order by d.Numar_pozitie  
for xml raw
end
--
--
--Pozplin
if @tipDoc='PI'
begin
select  
@tip as subtip,
RTRIM(d.explicatii) as ex,
rtrim(d.cont_corespondent) as cont,
convert(decimal(15,2), d.suma) as suma,
rtrim(d.Loc_de_munca) as lm,
RTRIM(lm.Denumire) as denlm,
rtrim(d.Comanda) as comanda,
RTRIM(comenzi.Descriere) as dencomanda,
(case when rtrim(d.factura)<>'' then rtrim(d.factura) else rtrim(c.Articol_de_calculatie) end) as articol,
'PI' as tipDoc, 
rtrim(d.cont) as numar, 
convert(char(10),d.data,101) as data, 
RTRIM(d.numar) as CI,                                           --CI = numar pozitie
convert(char(10),d.numar_pozitie) as numar_pozitie
from pozplin d
left outer join conturi c on c.cont=d.cont_corespondent 
left outer join lm on lm.Cod=d.Loc_de_munca
left outer join comenzi on comenzi.Comanda=d.Comanda
where d.PLATA_INCASARE='PD' and 
d.cont=@numar 
and d.data=@data 
order by d.Numar_pozitie  
for xml raw
end
--
--Pozadoc
if @tipDoc in ('FF')
begin
select  
@tip as subtip,
RTRIM(d.explicatii) as ex,
rtrim(d.cont_deb) as cont,
convert(decimal(15,2), d.suma) as suma,
rtrim(d.Loc_munca) as lm,
RTRIM(lm.Denumire) as denlm,
rtrim(d.Comanda) as comanda,
RTRIM(comenzi.Descriere) as dencomanda,
(case when rtrim(d.Factura_stinga)<>'' then rtrim(d.Factura_stinga) else rtrim(c.Articol_de_calculatie) end) as articol,
rtrim(d.tip) as tipDoc, 
rtrim(d.Numar_document) as numar, 
convert(char(10),d.data,101) as data, 
RTRIM(d.factura_dreapta) as CI,                                    -- CI = factura_dreapta
convert(char(10),d.numar_pozitie) as numar_pozitie
from pozadoc d
left outer join conturi c on c.cont=d.cont_deb 
left outer join lm on lm.Cod=d.Loc_munca
left outer join comenzi on comenzi.Comanda=d.Comanda
where d.Tip=@tipDoc
and d.numar_document=@numar 
and d.data=@data 
order by d.Numar_pozitie  
for xml raw
end
--Pozncon
if @tipDoc in ('NC')
begin
select  
@tip as subtip,
RTRIM(d.explicatii) as ex,
rtrim(d.cont_debitor) as cont,
convert(decimal(15,2), d.suma) as suma,
rtrim(d.Loc_munca) as lm,
RTRIM(lm.Denumire) as denlm,
rtrim(d.Comanda) as comanda,
RTRIM(comenzi.Descriere) as dencomanda,
--rtrim(c.Articol_de_calculatie) as articol,
(case when rtrim(d.tert)<>'' then rtrim(d.tert) else rtrim(c.Articol_de_calculatie) end) as articol,
rtrim(d.tip) as tipDoc, 
rtrim(d.Numar) as numar, 
convert(char(10),d.data,101) as data, 
'' as CI,                                   
convert(char(10),d.nr_pozitie) as numar_pozitie
from pozncon d
left outer join conturi c on c.cont=d.cont_debitor 
left outer join lm on lm.Cod=d.Loc_munca
left outer join comenzi on comenzi.Comanda=d.Comanda
where d.Tip=@tipDoc
and d.numar=@numar 
and d.data=@data 
order by d.Nr_pozitie  
for xml raw
end
