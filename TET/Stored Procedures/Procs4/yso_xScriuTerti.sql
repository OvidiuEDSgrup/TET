create procedure yso_xScriuTerti @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as
declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)	
begin try	
	set @parxml=(select *
				,isnull((select TOP 1 1 from yso_vIaTerti v where v.tert=t.tert),0) as [update] 
				,faravalidare=1
			from ##importXlsDifTmp t 
			where t._nrdif=@_nrdif for xml raw)
		--if isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),@parXML.value('(/row/row/@cod)[1]','varchar(20)'))
		--	='AA9H0KPRM'
		--	print 'stop'
	if @parxml is not null
		exec wScriuTerti @sesiune=null,@parxml=@parxml
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport 
	from ##importXlsTmp t 
		inner join ##importXlsDifTmp v on v.tert=t.tert
	where v._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
