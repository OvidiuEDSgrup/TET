--***
Create procedure wIaRegistruSalariati @sesiune varchar(50), @parXML xml
as  
declare @_cautare varchar(100), @tip varchar(2), @marca char(6), @userASiS varchar(10), 
@LunaInch int, @AnulInch int, @DataInch datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=(case when dbo.iauParN('PS','LUNA-INCH')=0 then 1 else dbo.iauParN('PS','LUNA-INCH') end)
set @AnulInch=(case when dbo.iauParN('PS','ANUL-INCH')=0 then 1901 else dbo.iauParN('PS','ANUL-INCH') end)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))

select @tip=xA.row.value('@tip', 'varchar(2)'), @marca=xA.row.value('@marca', 'varchar(6)') from @parXML.nodes('row') as xA(row) 
select @_cautare=@parXML.value('(/row/@_cautare)[1]', 'varchar(100)')

select 'RE' as tip, 'RE' as subtip, 'Registru electronic' as densubtip, 
rtrim(p.marca) as marca, rtrim(p.Nume) as densalariat, rtrim(isnull(fc.Denumire,'')) as dencor, 
rtrim(isnull(e2.val_inf,'')) as nrscarnet, rtrim(isnull(e3.val_inf,'')) as tipactident, rtrim(isnull(e4.val_inf,'')) as cetatenie, 
rtrim(isnull(e5.val_inf,'')) as idnationalitate, rtrim(isnull(e6.val_inf,'')) as nationalitate, rtrim(isnull(t.denumire,'')) as dennationalitate, 
rtrim(isnull(e7.val_inf,'')) as permismunca, rtrim(isnull(e8.val_inf,'')) as mentiuni, 
rtrim(isnull(e9.val_inf,'')) as localitate, rtrim(isnull(l.oras,'')) as denlocalitate, 
convert(char(10),isnull(e1.Data_inf,p.Data_angajarii_in_unitate),101) as datainchcntr, 
rtrim(isnull(e.val_inf,'')) as nrcntritm, convert(char(10),isnull(e.Data_inf,'01/01/1901'),101) as datacntritm, 
rtrim(isnull(e10.val_inf,'')) as temeiincet, rtrim(isnull(e11.val_inf,'')) as texttemei, rtrim(isnull(e12.val_inf,'')) as detaliicntr, 
rtrim(isnull(e13.val_inf,'')) as motivmodif, convert(char(10),isnull(e13.data_inf,'01/01/1901'),101) as datamodif,  
rtrim(isnull(e14.val_inf,'')) as explmodif, convert(char(10),isnull(e15.Data_inf,getdate()),101) as datavalid, 
'#000000' as culoare, 0 as _nemodificabil
from personal as p
left outer join functii f on f.Cod_functie=p.Cod_functie
left outer join extinfop cc on cc.Cod_inf='#CODCOR' and f.Cod_functie=cc.Marca
left outer join functii_cor fc on cc.Val_inf=fc.Numar_curent
left outer join extinfop e on e.marca=p.marca and e.Cod_inf='CNTRITM'
left outer join extinfop e1 on e1.marca=p.marca and e1.Cod_inf='DATAINCH'
left outer join extinfop e2 on e2.marca=p.marca and e2.Cod_inf='NRSCARNET' and e2.Data_inf='01/01/1901'
left outer join extinfop e3 on e3.marca=p.marca and e3.Cod_inf='TIPACTIDENT' and e3.Data_inf='01/01/1901'
left outer join extinfop e4 on e4.marca=p.marca and e4.Cod_inf='CETATENIE' and e4.Data_inf='01/01/1901'
left outer join extinfop e5 on e5.marca=p.marca and e5.Cod_inf='NATIONALITATE' and e5.Data_inf='01/01/1901'
left outer join extinfop e6 on e6.marca=p.marca and e6.Cod_inf='CODNATIONAL' and e6.Data_inf='01/01/1901'
left outer join Tari t on t.cod_tara=e6.Val_inf
left outer join extinfop e7 on e7.marca=p.marca and e7.Cod_inf='PERMISMUNCA' and e7.Data_inf='01/01/1901'
left outer join extinfop e8 on e8.marca=p.marca and e8.Cod_inf='MENTIUNI' and e8.Data_inf='01/01/1901'
left outer join extinfop e9 on e9.marca=p.marca and e9.Cod_inf='CODSIRUTA' and e9.Data_inf='01/01/1901'
left outer join Localitati l on l.cod_oras=e9.Val_inf
left outer join extinfop e10 on e10.marca=p.marca and e10.Cod_inf='TEMEIINCET' and e10
.Data_inf='01/01/1901'
left outer join extinfop e11 on e11.marca=p.marca and e11.Cod_inf='TXTTEMEIINCET' and e11.Data_inf='01/01/1901'
left outer join extinfop e12 on e12.marca=p.marca and e12.Cod_inf='CONTRDET' and e12.Data_inf='01/01/1901'
left outer join extinfop e13 on e13.marca=p.marca and e13.Cod_inf='MMODIFCNTR'
left outer join extinfop e14 on e14.marca=p.marca and e14.Cod_inf='MODIFEXPL' and e14.Data_inf='01/01/1901'
left outer join extinfop e15 on e15.marca=p.marca and e15.Cod_inf='DATAVALID'
where p.Marca=@marca 
for xml raw
