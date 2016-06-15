﻿--***
Create procedure wIaDateRevisal @sesiune varchar(50), @parXML xml
as  
declare @_cautare varchar(100), @tip varchar(2), @marca char(6), @userASiS varchar(10), 
@LunaInch int, @AnulInch int, @DataInch datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=(case when dbo.iauParN('PS','LUNA-INCH')=0 then 1 else dbo.iauParN('PS','LUNA-INCH') end)
set @AnulInch=(case when dbo.iauParN('PS','ANUL-INCH')=0 then 1901 else dbo.iauParN('PS','ANUL-INCH') end)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

select @tip=xA.row.value('@tip', 'varchar(2)'), @marca=xA.row.value('@marca', 'varchar(6)') from @parXML.nodes('row') as xA(row) 
select @_cautare=@parXML.value('(/row/@_cautare)[1]', 'varchar(100)')

select 'RV' as tip, 'RV' as subtip, 'Date revisal' as densubtip, 
	rtrim(p.marca) as marca, rtrim(p.Nume) as densalariat, rtrim(isnull(fc.Denumire,'')) as dencor, 
	rtrim(i.Nr_contract) as nrcontract, 
	rtrim(isnull(e2.val_inf,'')) as tipactident, rtrim(isnull(r2.Descriere,'')) as dentipactident, 
	rtrim(isnull(e3.val_inf,'')) as cetatenie, rtrim(isnull(r3.Descriere,'')) as dencetatenie, 
	rtrim(isnull(e4.val_inf,'')) as nationalitate, rtrim(isnull(r4.Descriere,'')) as dennationalitate, 
	rtrim(isnull(e5.val_inf,'')) as mentiuni, 
	rtrim(isnull(e6.val_inf,'')) as localitate, rtrim(isnull(l.oras,'')) as denlocalitate, 
	rtrim(isnull(e1.val_inf,'')) as tipcontract, rtrim(isnull(r1.descriere,'')) as dentipcontract, 
	rtrim(isnull(eds.val_inf,'')) as excepdatasf, rtrim(isnull(red.descriere,'')) as denexcepdatasf, 
	rtrim(isnull(e8.val_inf,'')) as repartizaretm, rtrim(isnull(r8.descriere,'')) as denreptm, 
	rtrim(isnull(e9.val_inf,'')) as intervalreptm, rtrim(isnull(r9.descriere,'')) as deninterval, 
	rtrim(isnull(e9.Procent,'')) as nroreint, 
	convert(char(10),isnull(e1.Data_inf,getdate()),101) as datainchcntr, 
	convert(char(10),p.Data_angajarii_in_unitate,101) as datainceput, 
	rtrim(isnull(e11.val_inf,'')) as temeiincet, rtrim(isnull(r11.descriere,'')) as dentemeiincet, 
	rtrim(isnull(e12.val_inf,'')) as texttemei, rtrim(isnull(e13.val_inf,'')) as detaliicntr, 
	convert(char(10),isnull(e14.data_inf,getdate()),101) as dataconsemn, 
	'#000000' as culoare, 0 as _nemodificabil
from personal as p
	left outer join infoPers i on i.Marca=p.Marca
	left outer join functii f on f.Cod_functie=p.Cod_functie
	left outer join extinfop cc on cc.Cod_inf='#CODCOR' and f.Cod_functie=cc.Marca
	left outer join functii_cor fc on cc.Val_inf=fc.Cod_functie
	left outer join extinfop e1 on e1.marca=p.marca and e1.Cod_inf='DATAINCH'
	left outer join CatalogRevisal r1 on r1.Cod=e1.Val_inf	
	left outer join extinfop e2 on e2.marca=p.marca and e2.Cod_inf='RTIPACTIDENT' and e2.Data_inf='01/01/1901'
	left outer join CatalogRevisal r2 on r2.TipCatalog='TipActIdentitate' and r2.Cod=e2.Val_inf
	left outer join extinfop e3 on e3.marca=p.marca and e3.Cod_inf='RCETATENIE' and e3.Data_inf='01/01/1901'
	left outer join CatalogRevisal r3 on r3.TipCatalog='Cetatenie' and r3.Cod=e3.Val_inf
	left outer join extinfop e4 on e4.marca=p.marca and e4.Cod_inf='RCODNATIONAL' and e4.Data_inf='01/01/1901'
	left outer join CatalogRevisal r4 on r4.TipCatalog='Nationalitate' and r4.Cod=e4.Val_inf
	left outer join extinfop e5 on e5.marca=p.marca and e5.Cod_inf='MENTIUNI' and e5.Data_inf='01/01/1901'
	left outer join extinfop e6 on e6.marca=p.marca and e6.Cod_inf='CODSIRUTA' and e6.Data_inf='01/01/1901'
	left outer join Localitati l on l.cod_oras=e6.Val_inf
	left outer join extinfop eds on eds.marca=p.marca and eds.Cod_inf='EXCEPDATASF' and eds.Data_inf='01/01/1901'
	left outer join CatalogRevisal red on red.TipCatalog='ExceptieDataSfarsit' and red.Cod=eds.Val_inf
	left outer join extinfop e8 on e8.marca=p.marca and e8.Cod_inf='REPTIMPMUNCA' and e8.Data_inf='01/01/1901'
	left outer join CatalogRevisal r8 on r8.TipCatalog='RepartizareTimpMunca' and r8.Cod=e8.Val_inf
	left outer join extinfop e9 on e9.marca=p.marca and e9.Cod_inf='TIPINTREPTM' and e9.Data_inf='01/01/1901'
	left outer join CatalogRevisal r9 on r9.TipCatalog='IntervalRTM' and r9.Cod=e9.Val_inf
	left outer join extinfop e11 on e11.marca=p.marca and e11.Cod_inf='RTEMEIINCET' and e11.Data_inf='01/01/1901'
	left outer join CatalogRevisal r11 on r11.TipCatalog='TemeiIncetare' and r11.Cod=e11.Val_inf
	left outer join extinfop e12 on e12.marca=p.marca and e12.Cod_inf='TXTTEMEIINCET' and e12.Data_inf='01/01/1901'
	left outer join extinfop e13 on e13.marca=p.marca and e13.Cod_inf='CONTRDET' and e13.Data_inf='01/01/1901'
	left outer join extinfop e14 on e14.marca=p.marca and e14.Cod_inf='MMODIFCNTR'
where p.Marca=@marca 
for xml raw
