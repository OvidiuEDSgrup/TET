--***
Create procedure wIaSporuri @sesiune varchar(50), @parXML xml
as  
declare @_cautare varchar(100), @tip varchar(2), @marca char(6), @userASiS varchar(10), 
@LunaInch int, @AnulInch int, @DataInch datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=(case when dbo.iauParN('PS','LUNA-INCH')=0 then 1 else dbo.iauParN('PS','LUNA-INCH') end)
set @AnulInch=(case when dbo.iauParN('PS','ANUL-INCH')=0 then 1901 else dbo.iauParN('PS','ANUL-INCH') end)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

select @tip=xA.row.value('@tip', 'varchar(2)'), @marca=xA.row.value('@marca', 'varchar(6)') from @parXML.nodes('row') as xA(row) 
select @_cautare=@parXML.value('(/row/@_cautare)[1]', 'varchar(100)')

select 'SP' as tip, 'SP' as subtip, 'Sporuri' as densubtip, 
rtrim(p.marca) as marca, rtrim(p.Nume) as densalariat, 
convert(decimal(10),p.salar_de_incadrare) as salinc,convert(decimal(10),p.salar_de_baza) as salbaza,
convert(decimal(10,2),p.Spor_vechime) as spvech, convert(decimal(10,2),p.Spor_de_noapte) as spnoapte,
convert(decimal(10,2),p.Spor_sistematic_peste_program) as spprogr, convert(decimal(10,2),p.Spor_de_functie_suplimentara) as spsupl, 
convert(decimal(10,2),p.Spor_specific) as spspec, convert(decimal(10,2),p.Indemnizatia_de_conducere) as spindc, 
convert(decimal(10,2),p.Spor_conditii_1) as sp1, convert(decimal(10,2),p.Spor_conditii_2) as sp2, 
convert(decimal(10,2),p.Spor_conditii_3) as sp3, convert(decimal(10,2),p.Spor_conditii_4) as sp4, 
convert(decimal(10,2),p.Spor_conditii_5) as sp5, convert(decimal(10,2),p.Spor_conditii_6) as sp6, 
convert(decimal(10,2),i.Spor_cond_7) as sp7, 
'#000000' as culoare, 0 as _nemodificabil
from personal as p
left outer join infoPers i on i.Marca=p.Marca
where p.Marca=@marca 
for xml raw

select * from personal
