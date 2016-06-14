
if exists (select * from sysobjects where name ='yso_xScriuPozcon')
drop procedure yso_xScriuPozcon
go
create procedure yso_xScriuPozcon @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as

declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)

begin try
	set @parxml=(select tip, subtip, numar, data, tert,
			(select tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta, pret
				, discount
				, info1=discount2, info3=discount3, cotatva, punctlivrare, modplata, explicatii
				, atp
				,isnull((select TOP 1 1 from pozcon v 
					where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data 
						and v.cod=t.cod),0) as [update] 
				from ##importXlsDifTmp t 
				where t._nrdif=tt._nrdif for xml raw,type)
		from ##importXlsDifTmp tt 
			where tt._nrdif=@_nrdif for xml raw)
	if @parxml is not null
		exec wScriuPozcon @sesiune=null,@parxml=@parxml
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)
	select '','','S',HOST_ID(),'Erori import linie pozcon',@eroareProc
	
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from #importXlsTmp t inner join #importXlsDifTmp d
		on d.tip=t.tip and d.subtip=t.subtip and d.numar=t.numar and d.data=t.data and d.tert=t.tert and d.cod=t.cod 
			and d.gestiune=t.gestiune and d.cantitate=t.cantitate and d.valuta=t.valuta 
			and d.pret=t.pret and d.discount=t.discount and d.discount2=t.discount2 
			and d.discount3=t.discount3 and d.cotatva=t.cotatva and d.punctlivrare=t.punctlivrare and d.modplata=t.modplata 
			and d.explicatii=t.explicatii 
			and d.atp=t.atp 
	where d._nrdif=@_nrdif
end catch
