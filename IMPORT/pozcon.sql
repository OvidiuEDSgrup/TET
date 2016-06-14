--/*
DROP VIEW yso_vIaPozcon
GO
create view yso_vIaPozcon as
select	
		--rtrim(p.subunitate) as subunitate
		rtrim(p.tip) as tip
		, rtrim(p.tip) as subtip
		, CASE p.Tip WHEN 'BF' THEN 'Contract beneficiar' WHEN 'BK' THEN 'Comanda livrare' 
			WHEN 'FA' THEN 'Contract furnizor' WHEN 'FC' THEN 'Comanda aprovizionare' ELSE '' END AS dentip
		, rtrim(p.contract) as numar
		,convert(datetime,convert(date,p.data)) as data
		,  rtrim(p.tert) as tert,
		isnull(rtrim(t.denumire), '') as dentert
		, rtrim(p.cod ) as cod, 
		rtrim(p.cod)+' - '+ rtrim(coalesce(n.denumire,g.denumire, '')) as dencod,  
		rtrim(coalesce(n.denumire,g.denumire, '')) as denumire,    
		rtrim(p.factura) as gestiune
		,isnull(rtrim(left(gest.denumire_gestiune, 30)), '') as dengestiune
		,  convert(decimal(17, 5), p.cantitate) as cantitate
		,  rtrim(isnull(p.valuta, '')) as valuta,  
		convert(varchar(10),p.termen,101) as termene
		, convert(decimal(14, 4), p.pret) as Tpret
		, convert(decimal(17, 5), p.cantitate) as Tcantitate
		, convert(decimal(17, 5), p.cant_realizata) as Tcant_realizata,  
		rtrim(isnull(n.um, '')) as um1, convert(decimal(17, 5), p.cantitate-(case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum1,    
		RTRIM(isnull(n.UM_1, '')) as um2, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_1, 0)) as coefconvum2,     
		convert(decimal(17, 5), (case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)) as cantitateum2,    
		RTRIM(isnull(n.UM_2, '')) as um3, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_2, 0)) as coefconvum3,     
		convert(decimal(17, 5), (case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum3,     
		convert(decimal(17, 5), p.pret) as pret, convert(decimal(10, 4), p.pret_promotional) as cant_transferata,     
		convert(decimal(12, 5), p.discount) as discount, 
		convert(decimal(12, 5), isnull(pe.pret, 0)) as discount2,
		convert(decimal(12, 5), isnull(pe.cantitate, 0)) as discount3,
		convert(decimal(5, 2), p.cota_tva) as cotatva,     
		rtrim(p.punct_livrare) as punctlivrare, rtrim(p.Mod_de_plata) as modplata,  
		'('+rtrim(p.mod_de_plata)+')'+rtrim(s.denumire) as denmodplata,           
		isnull(rtrim(gest.tip_gestiune), '') as tipgestiune,         
		convert(decimal(17, 5),p.cant_realizata) as cant_realizata,       
		convert(decimal(17, 5),p.cant_aprobata) as cant_aprobata, convert(varchar(10),p.termen,101) as termen_poz,       
		rtrim(p.Explicatii) as explicatii, p.numar_pozitie as numarpozitie, RTrim(ISNULL(pe.Explicatii, '')) as atp,    
		convert(char(10), isnull(pe.termen, '01/01/1901'), 101) as dataexpirarii,       
		rtrim(isnull(dp.Obiect, '')) as obiect, 
		rtrim(isnull(obiecteds.denumire, '')) as denobiect
		, rtrim(isnull(pe.punct_livrare, '')) as info2       
		,rtrim(isnull(pe2.explicatii, '')) as info4,    rtrim(isnull(pe2.punct_livrare, '')) as info5,      
		convert(char(10), isnull(dp.data1, '01/01/1901')) as info6, convert(char(10), isnull(dp.data2, '01/01/1901')) as info7,       
		convert(decimal(17, 5), isnull(dp.val1, 0)) as info8,  convert(decimal(17, 5), isnull(dp.val2, 0)) as info9,       
		convert(decimal(17, 5), isnull(dp1.val1, 0)) as info10,   convert(decimal(17, 5), isnull(dp1.val2, 0)) as info11,       
		rtrim(isnull(dp.observatii, '')) as info12,  rtrim(isnull(dp.info1, '')) as info13, rtrim(isnull(dp.info2, '')) as info14,       
		rtrim(isnull(dp1.observatii, '')) as info15,  rtrim(isnull(dp1.info1, '')) as info16,    
		rtrim(isnull(dp1.info2, '')) as info17,   
		convert(decimal(15,2),(p.cant_realizata)*p.pret) as Tfacturat 
from pozcon p      
left outer join nomencl n on (p.tip not in ('BF','FA') or p.Mod_de_plata='') and n.cod = p.Cod       
left outer join grupe g on p.Mod_de_plata='G' and g.Grupa=p.cod
left outer join surse s on s.Cod=p.Mod_de_plata      
left outer join terti t on t.subunitate = p.subunitate and t.tert = p.Tert      
left outer join gestiuni gest on gest.cod_gestiune = p.factura      
left outer join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=p.Tip and pe.Contract=p.Contract and pe.Tert=p.Tert and pe.Data=p.Data and pe.Cod=p.Cod      
left outer join pozcon pe2 on pe2.Subunitate='EXPAND2' and pe2.Tip=p.Tip and pe2.Contract=p.Contract and pe2.Tert=p.Tert and pe2.Data=p.Data and pe2.Cod=p.Cod      
left outer join detpozcon dp on dp.subunitate=p.subunitate and dp.tip=p.tip and dp.contract=p.contract and dp.tert=p.tert and dp.data=p.data and dp.numar_pozitie=p.numar_pozitie and dp.numar_ordine=0      
left outer join obiecteds on obiecteds.cod_obiect=dp.obiect      
left outer join detpozcon dp1 on dp1.subunitate=p.subunitate and dp1.tip=p.tip and dp1.contract=p.contract and dp1.tert=p.tert and dp1.data=p.data and dp1.numar_pozitie=p.numar_pozitie and dp1.numar_ordine=1           
where p.Subunitate='1' and p.tip='BF'
--order by p.Subunitate, p.Tip, p.Contract, p.Data, p.Tert, p.Cod, p.Numar_pozitie desc
go

drop procedure yso_xIaPozcon 
go
create procedure yso_xIaPozcon @tip char(2)=null as
select * from yso_vIaPozcon v
where ISNULL(@tip,'')='' or v.tip=@tip
go
--*/
if exists (select * from sysobjects where name ='yso_xScriuPozcon')
drop procedure yso_xScriuPozcon
go
create procedure yso_xScriuPozcon  @fisier nvarchar(4000) as
begin try -- scriu pozcon
	--declare @fisier nvarchar(4000) set @fisier='\\10.0.0.10\IMPORT\testimport.xlsx '
 	declare @eroareProc varchar(500),@txtSql nvarchar(max),@sursa varchar(max),@txtSelect varchar(max)
		,@txtParam nvarchar(max),@eroareXL varchar(500), @contor int, @parxml xml 
	
	if OBJECT_ID('tempdb..##importXlsIniTmp') is not null
		drop table ##importXlsIniTmp

	set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'
	set @sursa=REPLACE(@sursa,'@fisier',@fisier)
	set @txtSelect='Select * from [pozcon$]'
	set @txtSql=
	'select * into ##importXlsIniTmp
	from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
	,@sursa
	, @txtSelect) x '
	set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
	set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
	exec sp_executesql @txtSql
		
	if OBJECT_ID('tempdb..#importXlsTmp') is not null
		drop table #importXlsTmp

	select 
	tip=isnull(tip,''), subtip=isnull(subtip,''), dentip=isnull(dentip,''), numar=isnull(numar,''), data=isnull(data,'')
	, tert=isnull(tert,''), dentert=isnull(dentert,''), cod=isnull(cod,''), dencod=isnull(dencod,'')
	, denumire=isnull(denumire,''), gestiune=isnull(gestiune,''), dengestiune=isnull(dengestiune,'')
	, cantitate=isnull(cantitate,''), valuta=isnull(valuta,''), termene=isnull(termene,'')
	, Tpret=isnull(Tpret,''), Tcantitate=isnull(Tcantitate,''), Tcant_realizata=isnull(Tcant_realizata,'')
	, um1=isnull(um1,''), cantitateum1=isnull(cantitateum1,''), um2=isnull(um2,''), coefconvum2=isnull(coefconvum2,'')
	, cantitateum2=isnull(cantitateum2,''), um3=isnull(um3,''), coefconvum3=isnull(coefconvum3,'')
	, cantitateum3=isnull(cantitateum3,''), pret=isnull(pret,''), cant_transferata=isnull(cant_transferata,'')
	, discount=isnull(discount,''), discount2=isnull(discount2,''), discount3=isnull(discount3,'')
	, cotatva=isnull(cotatva,''), punctlivrare=isnull(punctlivrare,''), modplata=isnull(modplata,'')
	, denmodplata=isnull(denmodplata,''), tipgestiune=isnull(tipgestiune,''), cant_realizata=isnull(cant_realizata,'')
	, cant_aprobata=isnull(cant_aprobata,''), termen_poz=isnull(termen_poz,''), explicatii=isnull(explicatii,'')
	, numarpozitie=isnull(numarpozitie,''), atp=isnull(atp,''), dataexpirarii=isnull(dataexpirarii,'')
	, obiect=isnull(obiect,''), denobiect=isnull(denobiect,''), info2=isnull(info2,''), info4=isnull(info4,'')
	, info5=isnull(info5,''), info6=isnull(info6,''), info7=isnull(info7,''), info8=isnull(info8,''), info9=isnull(info9,'')
	, info10=isnull(info10,''), info11=isnull(info11,''), info12=isnull(info12,''), info13=isnull(info13,'')
	, info14=isnull(info14,''), info15=isnull(info15,''), info16=isnull(info16,''), info17=isnull(info17,'')
	, Tfacturat=isnull(Tfacturat,'')
	,_linieimport
	into #importXlsTmp
	from ##importXlsIniTmp where _linieimport is not null --and isnull(discount2,0)>0
	order by _linieimport

	if OBJECT_ID('tempdb..#importXlsDifTmp') is not null
		drop table #importXlsDifTmp

	select distinct tip, subtip, numar, data, tert, cod, gestiune
	, cantitate=convert(decimal(17,5),cantitate)
	, valuta--, termene
	, pret=convert(decimal(17,5),pret)
	, discount=convert(decimal(12,5),discount)
	, discount2=convert(decimal(12,5),discount2)
	, discount3=convert(decimal(12,5),discount3)
	, cotatva=convert(decimal(5,2),cotatva)
	, punctlivrare, modplata
	--, cant_aprobata=convert(decimal(17,5),cant_aprobata)
	, explicatii
	--, numarpozitie=convert(int,numarpozitie)
	, atp--, dataexpirarii, obiect, denobiect
	into #importXlsDifTmp
	from #importXlsTmp 
	except
	select			tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta--, termene
	, pret, discount, discount2, discount3, cotatva, punctlivrare, modplata
	--, cant_aprobata
	, explicatii--, numarpozitie
	, atp--, dataexpirarii, obiect, denobiect
	from yso_vIaPozcon where tip='BF'

	alter table #importXlsDifTmp add nrcrt int identity(1,1) not null
	create unique clustered index id on #importXlsDifTmp (nrcrt)
	--create nonclustered index preturi on #preturiXlsDifTmp (cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)

/*	
select * from #importXlsTmp 
select tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta
	, pret
	, discount, discount2, discount3, cotatva, punctlivrare, modplata
	, explicatii
	, atp
	,(select TOP 1 1 from pozcon v 
							where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data)
from #importXlsDifTmp t
where numar='RO22547417EU  '
select * from pozcon v 
							where v.Tip='bf' and v.Contract='RO22547417EU  ' 
							and v.Tert='RO22547418'-- and v.Data=t.data

select tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta, pret
	, discount, discount2, discount3, cotatva, punctlivrare, modplata, explicatii
	, atp
from yso_vIaPozcon where numar='RO22547417EU  '

*/
	declare @randuri int
	select @randuri=MAX(nrcrt) from #importXlsDifTmp

	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp
		
	select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj 
	into #mesajeASiSTmp from mesajeASiS
	
	if OBJECT_ID('tempdb..#importXlsErrTmp') is not null
		drop table #importXlsErrTmp
		
	select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #importXlsErrTmp from #importXlsTmp t 

	set @contor=1
	while @contor<=@randuri
	begin
		begin try
			set @parxml=(select tip, subtip, numar, data, tert, lm=i.Loc_munca, scadenta=i.Discount,
					(select tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta
						, pret=ISNULL(nullif(pret,0),1)
						, discount
						, info1=discount2, info3=discount3, cotatva, punctlivrare, modplata, explicatii
						, atp
						, Tpret=1
						,isnull((select TOP 1 1 from pozcon v 
							where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data 
								and v.cod=t.cod),0) as [update] 
						from #importXlsDifTmp t 
						where t.nrcrt=tt.nrcrt for xml raw,type)
				from #importXlsDifTmp tt left join infotert i on i.Subunitate='1' and i.Tert=tt.tert and i.Identificator=''
					where tt.nrcrt=@contor for xml raw)
			--if '0007001A'=@parXML.value('(/row/@cod)[1]','varchar(20)')
			--	print 'stop'
			if @parxml is not null
 				exec wScriuPozcon @sesiune=null,@parxml=@parxml
 		end try
 		begin catch
			set @eroareProc = ERROR_MESSAGE()
			begin try
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori import linie pozcon',@eroareProc
				
				insert #importXlsErrTmp
				select _linieimport, @eroareProc as _eroareimport from #importXlsTmp t inner join #importXlsDifTmp d
					on d.tip=t.tip and d.subtip=t.subtip and d.numar=t.numar and d.data=t.data and d.tert=t.tert and d.cod=t.cod 
						and d.gestiune=t.gestiune and d.cantitate=t.cantitate and d.valuta=t.valuta 
						and d.pret=t.pret and d.discount=t.discount and d.discount2=t.discount2 
						and d.discount3=t.discount3 and d.cotatva=t.cotatva and d.punctlivrare=t.punctlivrare and d.modplata=t.modplata 
						and d.explicatii=t.explicatii 
						and d.atp=t.atp 
				where d.nrcrt=@contor
			end try
			begin catch
				set @eroareXL = ERROR_MESSAGE()
				insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
				select '','','S',HOST_ID(),'Erori raportare erori in tabel',@eroareXL
			end catch
 		end catch
 	
 		set @contor=@contor+1
	end
	begin try
		set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'
		set @sursa=REPLACE(@sursa,'@fisier',@fisier)
		set @txtSelect='Select * from [pozcon$]'
		set @txtSql=
		'UPDATE x 
		SET _eroareimport = @eroareimport
		from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''
		,@sursa
		, @txtSelect) x '
		set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')
		set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')
		set @txtParam='@eroareimport varchar(500)'
		exec sp_executesql @txtSql, @txtParam, ''
		set @txtSql=REPLACE(@txtSql,'@eroareimport','e._eroareimport')
		set @txtSql=@txtSql+' inner join #importXlsErrTmp e on e._linieimport=x._linieimport'
		exec sp_executesql @txtSql
	end try
	begin catch
		set @eroareXL = ERROR_MESSAGE()
		insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
		select '','','S',HOST_ID(),'Erori raportare erori in excel',@eroareXL
	end catch
	
	insert mesajeASiS (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj, Data, Ora, Stare)
	select t.*,GETDATE(),'','' from 
		(select Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect
			, convert(varchar,count(*))+':'+Mesaj as Mesaj from #mesajeASiSTmp
		group by Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj) t
	
	if OBJECT_ID('tempdb..##importXlsIniTmp') is not null
		drop table ##importXlsIniTmp	

	if OBJECT_ID('tempdb..#importXlsTmp') is not null
		drop table #importXlsTmp
	
	
	if OBJECT_ID('tempdb..#importXlsDifTmp') is not null
		drop table #importXlsDifTmp
		
	if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null
		drop table #mesajeASiSTmp -- select * from #mesajeASiSTmp
		
	if OBJECT_ID('tempdb..#importXlsErrTmp') is not null
		drop table #importXlsErrTmp -- select * into testerrxls from #importXlsErrTmp
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = 'yso_xScriuPozcon: '+ ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)	
end catch
go
--exec yso_xScriuPozcon 'd:\BAZA_DATE_ASIS\EXCEL\IMPORT\testimport.xlsx'