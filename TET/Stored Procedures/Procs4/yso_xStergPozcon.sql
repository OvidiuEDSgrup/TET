create procedure yso_xStergPozcon @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as

declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)

begin try
/*
	set @parxml=(select fara_luare_date=1
					,tip, subtip, numar, data, tert,
			(select *
				,isnull((select TOP 1 1 from pozcon v 
					where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data 
						and v.cod=t.cod),0) as [update] 
				from ##importXlsDifTmp t 
				where t._nrdif=tt._nrdif for xml raw,type)
		from ##importXlsDifTmp tt 
			where tt._nrdif=@_nrdif for xml raw)
	if @parxml is not null
		exec wScriuPozcon @sesiune=null,@parxml=@parxml
*/
	delete v
	from pozcon v 
		inner join ##importXlsDifTmp t
			on v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data and v.cod=t.cod
	where t._nrdif=@_nrdif 
	
	delete v
	from con v 
		inner join ##importXlsDifTmp t
			on v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data 
		outer apply (select top 1 cod from pozcon p 
			where  v.Tip=p.tip and v.Contract=p.Contract and v.Tert=p.tert and v.Data=p.data) p
	where t._nrdif=@_nrdif 
		and p.Cod is null
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp d
		on d.tip=t.tip and d.subtip=t.subtip and d.numar=t.numar and d.data=t.data and d.tert=t.tert and d.cod=t.cod and d.pret=t.pret 
	where d._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
