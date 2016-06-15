--***
create procedure [dbo].[wIaFisamf] @sesiune varchar(30), @parXML XML
as
declare @sub varchar(9), @nrinv varchar(13), @cautare varchar(100)--,@iDoc int

exec luare_date_par 'GE','SUBPRO',1,0,@sub OUTPUT
set @nrinv = @parXML.value('(/row/@nrinv)[1]','varchar(13)')
--set @cautare = @parXML.value('(/row/@_cautare)[1]','varchar(100)')

SELECT f.felul_operatiei+'-'+(case f.felul_operatiei when '1' then 'Date lunare' when '2' then 
'Date implem.' when '3' then 'Intrare' when '4' then 'Modificare' when '5' then 'Iesire' 
when '6' then 'Transfer intern' when '7' then 'Conservare' when '8' then 'Iesire din conserv.' 
when '9' then 'Inchiriere' when 'A' then 'Valori istorice' else ' ' end) as tip, 
convert(char(10),f.Data_lunii_operatiei,101) as datal, 
convert(decimal(12,2), (case when f.Felul_operatiei in ('A','1') then f.amortizare_lunara 
else 0 end)) as amlun, convert(decimal(12,2),(case when f.Felul_operatiei in 
('A','1','2','3','5') then f.valoare_amortizata else 0 end)) as valam,
convert(decimal(12,2),f.valoare_de_inventar) as valinv,
(case when f.Felul_operatiei in ('A','1') then f.Numar_de_luni_pana_la_am_int else 0 end) as nrluni,
rtrim(f.loc_de_munca) as lm, rtrim(f.gestiune) as gest, rtrim(left(f.comanda,20)) as com, 
isnull(substring(substring(f.comanda,21,20),1,2),'  ')+'.'
+isnull(substring(substring(f.comanda,21,20),3,2),'  ')+'.'
+isnull(substring(substring(f.comanda,21,20),5,2),'  ')+'.'
+isnull(substring(substring(f.comanda,21,20),7,2),'  ')+'.'
+isnull(substring(substring(f.comanda,21,20),9,2),'  ')+'.'
+isnull(substring(substring(f.comanda,21,20),11,2),'  ')+'.'
+isnull(substring(substring(f.comanda,21,20),13,2),'  ') as indbug, 
convert(decimal(12,2), f.cantitate) as cantitate
FROM fisamf f WHERE f.Subunitate = @sub and f.numar_de_inventar = @nrinv --and (isnull(@cautare,'')='' or f.loc_de_munca like '%'+@cautare+'%')
order by f.Data_lunii_operatiei desc, f.felul_operatiei desc
for xml raw
