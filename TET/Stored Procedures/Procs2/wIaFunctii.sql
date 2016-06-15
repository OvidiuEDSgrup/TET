--***
Create procedure wIaFunctii @sesiune varchar(50), @parXML xml
as
declare @filtruDenumire varchar(30), @filtruCOR varchar(100), @filtruDomeniu varchar(100), @areDetalii bit
set @filtruDenumire = isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),'')
set @filtruCOR = isnull(@parXML.value('(/row/@COR)[1]','varchar(100)'),'')
set @filtruDomeniu = isnull(@parXML.value('(/row/@filtruDomeniu)[1]','varchar(100)'),'')

if OBJECT_ID('tempdb..#wFunctii') is not null drop table #wFunctii

select top 100 rtrim(f.cod_functie) as cod, rtrim(f.denumire) as denumire, rtrim(f.nivel_de_studii) as nivelstudii, rtrim(isnull(e.val_inf,'')) as codcor, 
rtrim(isnull(fc.denumire,'')) as denumirecor, rtrim(isnull(p1.Valoare,'')) as descriere, rtrim(isnull(p2.Valoare,'')) as scop, 
rtrim(isnull(p3.Valoare,'')) as studii, rtrim(isnull(p4.Valoare,'')) as experienta, rtrim(isnull(p5.Valoare,'')) as id_domeniu, rtrim(isnull(d.Denumire,'')) as dendomeniu
into #wFunctii
from functii f
	left outer join extinfop e on e.Marca=f.Cod_functie and e.Cod_inf='#CODCOR' 
	left outer join functii_cor fc on e.Val_inf=fc.Cod_functie 
	left outer join proprietati p1 on p1.Tip='FUNCTII' and p1.Cod=f.Cod_functie and p1.Cod_proprietate='DESCRIERE' and p1.Valoare<>''
	left outer join proprietati p2 on p2.Tip='FUNCTII' and p2.Cod=f.Cod_functie and p2.Cod_proprietate='SCOP' and p2.Valoare<>''	
	left outer join proprietati p3 on p3.Tip='FUNCTII' and p3.Cod=f.Cod_functie and p3.Cod_proprietate='STUDII' and p3.Valoare<>''
	left outer join proprietati p4 on p4.Tip='FUNCTII' and p4.Cod=f.Cod_functie and p4.Cod_proprietate='EXPERIENTA' and p4.Valoare<>''	
	left outer join proprietati p5 on p5.Tip='FUNCTII' and p5.Cod=f.Cod_functie and p5.Cod_proprietate='DOMENIU' and p5.Valoare<>''	
	left outer join RU_domenii d on d.ID_domeniu=p5.Valoare
where rtrim(f.denumire) like '%'+@filtruDenumire+'%' 
	and (rtrim(isnull(fc.Cod_functie,'')) like '%'+@filtruCOR+'%' or rtrim(isnull(fc.Denumire,'')) like '%'+@filtruCOR+'%') 
	and (rtrim(isnull(p5.Valoare,'')) like '%'+@filtruDomeniu+'%' or rtrim(isnull(d.Denumire,'')) like '%'+@filtruDomeniu+'%')
order by f.cod_functie, f.denumire

if exists (SELECT 1 FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'terti' AND sc.NAME = 'detalii')
begin
	set @areDetalii = 1

	alter table #wFunctii ADD detalii XML
	
	update #wFunctii set detalii= f.detalii
	from functii f 
	where f.Cod_functie=#wFunctii.cod
END
ELSE
	SET @areDetalii = 0

select @areDetalii as areDetaliiXml
for xml raw,root('Mesaje')

select *
from #wFunctii
for xml raw
