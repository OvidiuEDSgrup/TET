CREATE PROCEDURE formChitantaSP @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100) OUTPUT     
AS    
begin try     
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
declare @tip varchar(2),@numar varchar(20),@data datetime,@subunitate varchar(9),@debug int,@cont varchar(20),@userASiS varchar(200)
	, @idpozplin int
	
 EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

 /** Filtre **/    
 set @cont=@parXML.value('(/*/@cont)[1]', 'varchar(20)')    
 SET @tip=@parXML.value('(/*/row/@tip)[1]', 'varchar(2)')    
 SET @numar=@parXML.value('(/*/row/@numar)[1]', 'varchar(20)')    
 SET @data= @parXML.value('(/*/row/@data)[1]', 'datetime')    
 SET @idPozPlin = isnull(@idPozPlin,@parXML.value('(/row/row/@idPozPlin)[1]','int'))
 
 if @tip is null --Pentru date din MOBILE
 begin
	 select top 1 @cont=valoare from proprietati where tip='UTILIZATOR' and Cod_proprietate='CONTPLIN' and cod=@userASiS
	 SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')    
	 SET @numar=@parXML.value('(/*/@numar)[1]', 'varchar(20)')    
	 SET @data= @parXML.value('(/*/@data)[1]', 'datetime')    
 end   
    
 /* Alte **/    
 set @debug=0    
 EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT    

select 
f.Tert,f.Factura,convert(char(10),f.data,103) as data,
(case when abs(sum(p.Suma)-max(f.Valoare+f.TVA_11+f.TVA_22))>0.01 then 'partial' else 'integral' end)
	as integralsaupartial
into #fmic
FROM pozplin p
left outer join facturi f on f.Tip=0x46 and f.Tert=p.Tert and f.Factura=p.Factura
WHERE p.Subunitate=@subunitate and p.Plata_incasare='IB' and p.Cont=@cont
and p.Data=@data and p.Numar=@numar 
group by f.Tert,f.Factura,f.Data

declare @textReprezentand varchar(8000)
set @textReprezentand=''

select @textReprezentand=@textReprezentand+','+rtrim(f.factura)+'-'+RTRIM(f.data)+'-'+RTRIM(f.integralsaupartial)
from #fmic f
if @@ROWCOUNT=1
	set @textReprezentand='c.v. factura:'+substring(@textReprezentand,2,8000)
else
	set @textReprezentand='c.v. facturi:'+substring(@textReprezentand,2,8000)

/*
SELECT 1 as NRCRT,
@numar as numar,
convert(CHAR(10),@data,103) as data,    
t.denumire as denTert,    
rtrim(t.localitate)+' '+rtrim(t.adresa) as locAdresa,     
isnull((select max(banca3) from infotert where subunitate='1' and tert=t.tert and identificator=''), '') as CodJ,    
rtrim(t.cod_fiscal) as cod_fiscal,    
 convert(char(15),convert(money,round(sum(p.suma),2)),1) as suma,    
 dbo.Nr2Text(sum(p.suma)) as sumalitere,     
@textReprezentand as reprezentand
into #selectMare    
FROM pozplin p,terti t,#fmic f     
WHERE p.Subunitate=@subunitate and p.Plata_incasare='IB' and p.Cont=@cont
and p.Data=@data and p.Numar=@numar and p.Tert=t.tert and f.Tert=p.Tert and f.Factura=p.Factura 
GROUP BY p.Subunitate,p.Plata_incasare,p.Numar,p.Data,t.Denumire,t.Adresa,t.Localitate,t.Tert,t.Cod_fiscal
  
*/
 
select rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='NUME'),'')) as [FIRMA],
 rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='JUDET'),'')) as [JUDF],
 rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='ADRESA'),'')) as [ADRESAF],
 rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='CONTBC'),'')) as [CONTF],
 rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='BANCA'),'')) as [BANCAF],
 rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='CODFISC'),'')) as [CUIF],
 rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='ORDREG'),'')) as [JF],
 rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='CAPITALS'),'')) as [CAPSOC],
 rtrim(max(t.denumire)) as [TERT],
 rtrim(max(t.adresa)) as [ADRESA],
 rtrim((select lm.Denumire from lm  where max(p.loc_de_munca)= lm.Cod)) as [PUNCTLUCRU],
 rtrim(max(p.numar)) as [NRCHIT],
 rtrim(convert(char(10),p.data,103)) as [DATACHIT],
 rtrim(convert(char(15),convert(money,round(sum(p.suma),2)),1)) as [SUMA],
 rtrim(dbo.nr2text(round(sum(p.suma),2))) as [TRANSFORM],
 '' as [CE],
 --rtrim(rtrim(p.factura)+' din '+convert(CHAR(10),(select top 1 f.data from facturi f where f.subunitate=p.subunitate and f.tert=p.tert and f.factura=p.factura),103)) 
 @textReprezentand as [FACTURA],
 rtrim(MAX(t.LOCALITATE)) as [LOCALIT],
 rtrim(max(t.JUDET)) as [JUDETBEN],
 rtrim(MAX(t.COD_FISCAL)) as [CUIBEN],
 rtrim((select max(BANCA3)  from INFOTERT WHERE p.TERT=INFOTERT.TERT AND INFOTERT.SUBUNITATE='1' and infotert.identificator='')) as [JBEN]
 into #selectMare
FROM terti t,POZplin p,#fmic f 
WHERE p.Subunitate=@subunitate and p.Plata_incasare='IB' and p.Cont=@cont and p.Data=@data and p.Numar=@numar 
and p.Tert=t.tert and f.Tert=p.Tert and f.Factura=p.Factura 
GROUP BY p.subunitate,p.numar,p.data,p.Plata_incasare,p.tert--,p.loc_de_munca
    
declare @cTextSelect nvarchar(max),@mesaj varchar(8000)    
    
 SET @cTextSelect = '    
 SELECT *    
 into ' + @numeTabelTemp + '    
 from #selectMare    
 ORDER BY datachit,nrchit    
 '    
    
 EXEC sp_executesql @statement = @cTextSelect    
    
IF @debug = 1    
 BEGIN    
  SET @cTextSelect = 'select * from ' + @numeTabelTemp    
  EXEC sp_executesql @statement = @cTextSelect    
 END    
end try    
begin catch    
 set @mesaj=ERROR_MESSAGE()+ ' (formChitantaSP)'    
 raiserror(@mesaj, 11, 1)    
end catch    
return