create procedure yso_xScriuStoclim @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as
declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)	
begin try	
	delete v
	--update v set Stoc_min=t.stoc_min, Stoc_max=t.stoc_max
	from Stoclim v inner join ##importXlsDifTmp t 
		on v.Cod_gestiune=t.Cod_gestiune 
			and v.Cod=t.cod and v.data<'2999-01-01'
			/*v.Subunitate=t.subunitate and v.Tip_gestiune=t.Tip_gestiune and v.Data=t.data*/
	where t._nrdif=@_nrdif
	
	insert Stoclim (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Stoc_min,Stoc_max,Pret,Locatie)
	select p.Val_alfanumerica,g.Tip_gestiune,t.Cod_gestiune,t.Cod,GETDATE(),t.Stoc_min,t.Stoc_max,0,''
	from ##importXlsDifTmp t
		left join par p on p.Tip_parametru='GE' and p.Parametru='SUBPRO' 
		left join gestiuni g on g.Subunitate=p.Val_alfanumerica and g.Cod_gestiune=t.Cod_gestiune
	where t._nrdif=@_nrdif
	if (select top 1 cod from ##importXlsDifTmp t where t._nrdif=@_nrdif) in ('08028100','96635040')
		print 'debug-stop'
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp v
		on /*v.Subunitate=t.subunitate and v.Tip_gestiune=t.Tip_gestiune and */v.Cod_gestiune=t.Cod_gestiune 
			and v.Cod=t.cod --and v.Data=t.data
	where v._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
