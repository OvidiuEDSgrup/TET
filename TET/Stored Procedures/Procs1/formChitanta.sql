CREATE PROCEDURE formChitanta @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100) OUTPUT     
AS    
begin try     
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
declare @tip varchar(2),@numar varchar(20),@data datetime,@subunitate varchar(9),@debug int,@cont varchar(20),@userASiS varchar(200)
 EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

 /** Filtre **/    
 set @cont=@parXML.value('(/*/@cont)[1]', 'varchar(20)')    
 SET @tip=@parXML.value('(/*/row/@tip)[1]', 'varchar(2)')    
 SET @numar=@parXML.value('(/*/row/@numar)[1]', 'varchar(20)')    
 SET @data= @parXML.value('(/*/row/@data)[1]', 'datetime')    
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
   
    
declare @cTextSelect nvarchar(max),@mesaj varchar(8000)    
    
 SET @cTextSelect = '    
 SELECT *    
 into ' + @numeTabelTemp + '    
 from #selectMare    
 ORDER BY data,numar    
 '    
    
 EXEC sp_executesql @statement = @cTextSelect    
    
IF @debug = 1    
 BEGIN    
  SET @cTextSelect = 'select * from ' + @numeTabelTemp    
  EXEC sp_executesql @statement = @cTextSelect    
 END    
end try    
begin catch    
 set @mesaj=ERROR_MESSAGE()+ ' (formChitanta)'    
 raiserror(@mesaj, 11, 1)    
end catch    
return
