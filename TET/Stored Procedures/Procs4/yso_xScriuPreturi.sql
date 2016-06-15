create procedure yso_xScriuPreturi @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as
declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)	
begin try	
	set @parxml=(select t.cod as cod
		,rtrim(t.cod) as o_cod
		, rtrim(t.catpret) as catpret
		, rtrim(t.catpret) as o_categorie
		, rtrim(t.tippret) as tippret
		, rtrim(t.tippret) as o_tippret
		, convert(varchar(10),data_inferioara,126) as data_inferioara 
		, convert(varchar(10),data_inferioara,126) as o_data_inferioara
		, convert(decimal(12,3),t.pret_vanzare) as pret_vanzare
		, convert(decimal(12,3),t.pret_cu_amanuntul) as pret_cu_amanuntul
		,isnull((select TOP 1 1 from yso_vIaPreturi v 
			where v.cod=t.cod and v.catpret=t.catpret and v.tippret=t.tippret and v.data_inferioara=t.data_inferioara),0) 
		as [update] 
		from ##importXlsDifTmp t 
		where t._nrdif=@_nrdif for xml raw,root('row'))
		--if isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),@parXML.value('(/row/row/@cod)[1]','varchar(20)'))
		--	='AA9H0KPRM'
		--	print 'stop'
	--set @parXML.modify('delete /*[2]')
	--if @parxml.value('(/row/row/@cod)[1]','varchar(20)')='537d6302'
		--select @parxml
	set @parXML.modify('insert /row/row/@cod[1]  into /row[1]')
	if @parxml is not null
		exec wScriuPreturiNomenclator @sesiune=null,@parxml=@parxml
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp v
		on v.cod=t.cod and v.catpret=t.catpret and v.tippret=t.tippret and v.data_inferioara=t.data_inferioara
	where v._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
