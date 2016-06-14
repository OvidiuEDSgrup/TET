--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--***  
create procedure [dbo].[wIaPozCon] @sesiune varchar(50), @parXML xml      
as      
      
declare @iDoc int, @lCuTermene int, @TermPeSurse int,@doc xml,@tip varchar(2), @sub char(9),@numar char(20),@tert char(20),@numere_pozitii varchar(max),      
  @data datetime, @cautare varchar(100), @Periodicitate int  
   
select @lCuTermene=Val_logica from par where tip_parametru='UC' and parametru='TERMCNTR'      
set @TermPeSurse=isnull((select top 1 Val_logica from par where tip_parametru='UC' and parametru='POZSURSE'),0)  
set @Periodicitate=isnull((select top 1 Val_logica from par where tip_parametru='UC' and parametru='PERIODCON'),0)  
  
select  @sub=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),        
  @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),        
  @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),        
  @numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),    
  @tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), ''),    
  @numere_pozitii=ISNULL(@parXML.value('(/row/@numerepozitii)[1]', 'varchar(20)'), ''),  
  @cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(100)'), '')  
     
set @cautare='%'+replace(@cautare,' ','%')+'%'    
IF OBJECT_ID('tempdb..#termene') IS NOT NULL  
  drop table #termene  
select max(te.subunitate) as subunitate, max(te.tert) as tert, max(te.data) as data, max(te.explicatii) as explicatii, max(te.data2) as data2, max(te.termen) as termen,  
      max(te.cod) as cod, max(te.contract) as contract,  
      max(case when month(te.termen)=1 then te.cantitate else 0 end) as Tianuarie,  
      max(case when month(te.termen)=2 then te.cantitate else 0 end) as Tfebruarie,  
      max(case when month(te.termen)=3 then te.cantitate else 0 end) as Tmartie,  
      max(case when month(te.termen)=4 then te.cantitate else 0 end) as Taprilie,  
      max(case when month(te.termen)=5 then te.cantitate else 0 end) as Tmai,  
      max(case when month(te.termen)=6 then te.cantitate else 0 end) as Tiunie,  
      max(case when month(te.termen)=7 then te.cantitate else 0 end) as Tiulie,  
      max(case when month(te.termen)=8 then te.cantitate else 0 end)as Taugust,  
      max(case when month(te.termen)=9 then te.cantitate  else 0 end) as Tseptembrie,  
      max(case when month(te.termen)=10 then te.cantitate else 0 end) as Toctombrie,  
      max(case when month(te.termen)=11 then te.cantitate else 0 end) as Tnoiembrie,  
      max(case when month(te.termen)=12 then te.cantitate else 0 end) as Tdecembrie  
     into #termene from termene te   
     where  te.Subunitate=@sub and te.tip=@tip and   
       te.Contract=@numar and te.Data=@data and te.tert=@tert  
       group by te.cod  
       order by te.cod  
         
  
--set @doc=(      
select rtrim(te.subunitate) as subunitate, convert(varchar(10),te.termen,103) as codsisursa, te.cantitate as Taugust,  
		rtrim(p.cod)+' - '+ rtrim(isnull(left(n.denumire,30), '')) as dencod, rtrim(p.cod) as cod,  
		convert(decimal(17, 5), te.cantitate) as Tcantitate, convert(varchar(10),te.data,101) as Tdata,  
		convert(varchar(10),te.termen,101) as Ttermen,  
		isnull((select convert(decimal(15,2),convert(decimal(15,2),achitat)/(select count (*) from termene where subunitate=@sub and explicatii=f.factura and data2=f.data))   
		from facturi f where f.subunitate=@sub and f.tip='F' and f.tert=@tert and f.Factura=te.Explicatii and data=te.Data2),0) as Tachitat,  
		convert(decimal(15,2),(te.cant_realizata*te.pret))as Tfacturat,  
		convert(varchar(10),te.Data1,101) as termen, convert(varchar(10),te.termen,101) as termene,    
		convert(varchar(10),te.data1,101) as Tdata1,  convert(decimal(14, 4), te.pret) as Tpret,  
		rtrim(p.Explicatii) as explicatii, convert(int,p.numar_pozitie) as numarpozitie,     
		(convert(decimal(17, 5), te.cant_realizata)) as Tcant_realizata,rtrim(isnull(n.um, '')) as um1,  
		(case when te.cant_realizata>0 then '#808080' else '#08088A' end )as culoare,  
		convert(decimal(17, 5), p.cantitate-(case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum1,    
		RTRIM(isnull(n.UM_1, '')) as um2, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_1, 0)) as coefconvum2,     
		convert(decimal(17, 5), (case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else  
		0 end))/n.Coeficient_conversie_1) else 0 end)) as cantitateum2,  RTRIM(isnull(n.UM_2, '')) as um3, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_2, 0)) as coefconvum3,     
		convert(decimal(17, 5), (case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum3,     
		convert(decimal(17, 5), p.pret) as pret,   
		convert(decimal(17, 5), p.pret_promotional) as cant_transferata,     
		convert(decimal(10, 5), p.discount) as discount,  
		convert(decimal(5, 2), p.cota_tva) as cotatva,    
		rtrim(p.punct_livrare) as punctlivrare,   
		rtrim(te.tert) as Ttert, rtrim(te.Contract) as Tcontract,     
		rtrim(p.Mod_de_plata) as modplata,'('+rtrim(p.mod_de_plata)+')'+rtrim(s.denumire) as denmodplata,'TE' as subtip   
 into #tmptermen  
 from TERMENE te   
 inner join  pozcon p on te.subunitate=p.subunitate and te.contract=p.contract and te.tert=p.tert and te.data=p.data   
 left outer join nomencl n on n.cod = p.Cod    
 left outer join surse s on s.Cod=p.Mod_de_plata         
 where	p.Subunitate=@sub and p.Tip=@tip and p.Contract=@numar and p.Data=@data  
		and (te.Cod=(case when @TermPeSurse=0  then p.cod else ltrim(str(p.numar_pozitie)) end) or  
		te.Cod=(case when @TermPeSurse=1  then ltrim(str(p.numar_pozitie))else  p.cod end) )  
 order by(case when te.Cantitate is null then p.numar_pozitie else '' end),       
		(case when te.Cantitate is null then null else       
		(case when @TermPeSurse=0 then '' else isnull(rtrim(p.Mod_de_plata),'')+' '+isnull(rtrim(left(s.Denumire,50)),'') end)      
		+' - '+rtrim(isnull(p.cod,'')) +' - '+rtrim(isnull(left(n.denumire,30), ''))       
		+' ('+convert(varchar(17),convert(decimal(17, 5), isnull(p.cantitate,'')))+' '+rtrim(isnull(n.um, ''))+')'  end),       
		te.Termen  
              
select	rtrim(p.subunitate) as subunitate, rtrim(p.tip) as tip, rtrim(p.tip) as subtip, rtrim(p.contract) as numar,       
		p.data as data, rtrim(p.cod ) as cod, rtrim(p.cod)+' - '+ rtrim(isnull(left(n.denumire,30), '')) as dencod,      
		rtrim(p.factura) as gestiune,  convert(decimal(17, 5), p.cantitate) as cantitate,  rtrim(isnull(p.valuta, '')) as valuta,  
		convert(varchar(10),p.termen,101) as termene, convert(decimal(14, 4), p.pret) as Tpret,  rtrim(p.tert) as tert,
		convert(decimal(17, 5), p.cantitate) as Tcantitate, convert(decimal(17, 5), p.cant_realizata) as Tcant_realizata,  
		rtrim(isnull(n.um, '')) as um1, convert(decimal(17, 5), p.cantitate-(case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then fl
oor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum1,    
		RTRIM(isnull(n.UM_1, '')) as um2, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_1, 0)) as coefconvum2,     
		convert(decimal(17, 5), (case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) el
se 0 end))/n.Coeficient_conversie_1) else 0 end)) as cantitateum2,    
		RTRIM(isnull(n.UM_2, '')) as um3, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_2, 0)) as coefconvum3,     
		convert(decimal(17, 5), (case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum3,     
		convert(decimal(17, 5), p.pret) as pret, convert(decimal(10, 4), p.pret_promotional) as cant_transferata,     
		convert(decimal(10, 5), p.discount) as discount, convert(decimal(5, 2), p.cota_tva) as cotatva,     
		rtrim(p.punct_livrare) as punctlivrare,  rtrim(p.Mod_de_plata) as modplata,  '('+rtrim(p.mod_de_plata)+')'+rtrim(s.denumire) as denmodplata,  
		rtrim(isnull(n.denumire, ''))+(case when @TermPeSurse=1 then ' - ('+isnull(rtrim(p.Mod_de_plata),'')+')'+isnull(RTRIM(s.Denumire),'') else '' end) as denumire,       
		isnull(rtrim(left(gest.denumire_gestiune, 30)), '') as dengestiune,  isnull(rtrim(gest.tip_gestiune), '') as tipgestiune,       
		isnull(rtrim(t.denumire), '') as dentert,  convert(decimal(17, 5),p.cant_realizata) as cant_realizata,       
		convert(decimal(17, 5),p.cant_aprobata) as cant_aprobata, convert(varchar(10),p.termen,101) as termen_poz,       
		rtrim(p.Explicatii) as explicatii, p.numar_pozitie as numarpozitie, RTrim(ISNULL(pe.Explicatii, '')) as lot,    
		convert(char(10), isnull(pe.termen, '01/01/1901'), 101) as dataexpirarii,       
		rtrim(isnull(dp.Obiect, '')) as obiect, rtrim(isnull(obiecteds.denumire, '')) as denobiect,      
		isnull(pe.pret, 0) as info1, rtrim(isnull(pe.punct_livrare, '')) as info2, isnull(pe.cantitate, 0) as info3,       
		rtrim(isnull(pe2.explicatii, '')) as info4,    rtrim(isnull(pe2.punct_livrare, '')) as info5,      
		convert(char(10), isnull(dp.data1, '01/01/1901')) as info6, convert(char(10), isnull(dp.data2, '01/01/1901')) as info7,       
		convert(decimal(17, 5), isnull(dp.val1, 0)) as info8,  convert(decimal(17, 5), isnull(dp.val2, 0)) as info9,       
		convert(decimal(17, 5), isnull(dp1.val1, 0)) as info10,   convert(decimal(17, 5), isnull(dp1.val2, 0)) as info11,       
		rtrim(isnull(dp.observatii, '')) as info12,  rtrim(isnull(dp.info1, '')) as info13, rtrim(isnull(dp.info2, '')) as info14,       
		rtrim(isnull(dp1.observatii, '')) as info15,  rtrim(isnull(dp1.info1, '')) as info16,    
		rtrim(isnull(dp1.info2, '')) as info17,  convert(decimal(17, 5),tr.Tianuarie) as Tianuarie,  
		convert(decimal(17, 5),tr.Tfebruarie) as Tfebruarie,  convert(decimal(17, 5),tr.Tmartie) as Tmartie,  
		convert(decimal(17, 5),tr.Taprilie) as Taprilie,  convert(decimal(17, 5),tr.Tmai) as Tmai,  
		convert(decimal(17, 5),tr.Tiunie) as Tiunie,  convert(decimal(17, 5),tr.Tiulie) as Tiulie,  convert(decimal(17, 5),tr.Taugust) as Taugust,  
		convert(decimal(17, 5),tr.Tseptembrie) as Tseptembrie,  convert(decimal(17, 5),tr.Toctombrie) as Toctombrie,  
		convert(decimal(17, 5),tr.Tnoiembrie) as Tnoiembrie,  convert(decimal(17, 5),tr.Tdecembrie) as Tdecembrie,  
		isnull((select convert(decimal(15,2),achitat) from facturi f where f.subunitate=@sub and f.tip='F' and f.tert=tr.tert and  f.tert=@tert and f.Factura=tr.Explicatii and data=tr.Data2),0)   
						as Tachitat,  
		convert(decimal(15,2),(p.cant_realizata)*p.pret) as Tfacturat,  
		rtrim(p.cod)+' - '+ rtrim(isnull(left(n.denumire,100), ''))+char(10)+(case when @TermPeSurse=1 then ' - ('+isnull(rtrim(p.Mod_de_plata),'')+')'+isnull(RTRIM(s.Denumire),'') else '' end) as codsisursa  
into #tmppozcon  
from pozcon p      
left outer join nomencl n on n.cod = p.Cod       
left outer join surse s on s.Cod=p.Mod_de_plata      
left outer join terti t on t.subunitate = p.subunitate and t.tert = p.Tert      
left outer join gestiuni gest on gest.cod_gestiune = p.factura      
left outer join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=p.Tip and pe.Contract=p.Contract and pe.Tert=p.Tert and pe.Data=p.Data and pe.Cod=p.Cod      
left outer join pozcon pe2 on pe2.Subunitate='EXPAND2' and pe2.Tip=p.Tip and pe2.Contract=p.Contract and pe2.Tert=p.Tert and pe2.Data=p.Data and pe2.Cod=p.Cod      
left outer join detpozcon dp on dp.subunitate=p.subunitate and dp.tip=p.tip and dp.contract=p.contract and dp.tert=p.tert and dp.data=p.data and dp.numar_pozitie=p.numar_pozitie and dp.numar_ordine=0      
left outer join obiecteds on obiecteds.cod_obiect=dp.obiect      
left outer join detpozcon dp1 on dp1.subunitate=p.subunitate and dp1.tip=p.tip and dp1.contract=p.contract and dp1.tert=p.tert and dp1.data=p.data and dp1.numar_pozitie=p.numar_pozitie and dp1.numar_ordine=1      
left outer join #termene tr  
on tr.subunitate=p.subunitate and tr.contract=p.contract and tr.Data=p.data and tr.tert=p.tert and  
  tr.Subunitate=@sub and tr.Contract=@numar and tr.Data=@data and   
  tr.Cod=(case when @TermPeSurse=0  then p.cod else ltrim(str(p.numar_pozitie)) end)   
where p.subunitate=@sub and p.tip=@tip and p.contract=@numar and ltrim(p.tert)=@tert and p.data=@data   
 and (p.cod like @cautare or @cautare='')  
 and (isnull(@numere_pozitii, '')='' or charindex(';' + ltrim(str(p.numar_pozitie)) + ';', ';' + @numere_pozitii + ';')>0)      
order by p.Numar_pozitie desc   
  
declare @areDetalii int  
if exists(select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='pozcon' and sc.name='detalii')  
begin  
 set @areDetalii=1  
 alter table #tmppozcon add detalii xml  
 update #tmppozcon set #tmppozcon.detalii=pozcon.detalii  
 from pozcon where #tmppozcon.subunitate=pozcon.subunitate and #tmppozcon.tip=pozcon.tip and   
     #tmppozcon.data=pozcon.data and #tmppozcon.numar=pozcon.contract  
end  
else  
 set @areDetalii=0  

set @doc=(select *,(select * from #tmptermen ter where ter.subunitate=pz.subunitate and ter.Tcontract=pz.numar and   
            ter.Tdata=pz.data and ter.cod=pz.cod for xml raw, type) from #tmppozcon pz  
for xml raw
, root('Ierarhie')
)  
select @areDetalii as areDetaliiXml for xml raw, root ('Mesaje')      
select @doc for xml path('Date')      

