exec faInregistrariContabile
Tip:AE,Numar:10000416,Data:03/06/2014- Formula eronata: Cont debitor necompletat:  = 4427!

select * from webJurnalOperatii j where j.obiectSql like 'wscriupozdoc%' and CONVERT(nvarchar(max),j.parametruXML) like '%16292%'

delete pozdoc where tip='AP' and contract='16292' and data='2014-06-03'
exec wScriuDoc '','
<row tip="AE" numar="10000416" data="2014-06-03" numarpozitii="2">
  <row subtip="AE" data="2014-06-03" gestiune="101      " cod="020102402/26        " cantitate="1" lm="1SE_02   " contract="16292" explicatii="" />
</row>'

select p.TVA_deductibil,p.Numar_pozitie,* from sysspd p where p.Numar='10000416' and p.Tip='AE' and p.Numar_pozitie=2
order by p.Data_stergerii desc