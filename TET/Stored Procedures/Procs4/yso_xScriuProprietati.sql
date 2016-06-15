create procedure yso_xScriuProprietati @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as
declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)	
begin try	
	update v
	set v.Valoare=t.Valoare
	from Proprietati v inner join ##importXlsDifTmp t 
		on v.Tip=t.Tip and v.Cod_proprietate=t.Cod_proprietate and v.Cod=t.cod
	where t._nrdif=@_nrdif
	if (@@ROWCOUNT=0)
		insert Proprietati
			(Tip
			,Cod
			,Cod_proprietate
			,Valoare
			,Valoare_tupla)
		select
			Tip
			,Cod
			,Cod_proprietate
			,Valoare
			,''
		from ##importXlsDifTmp t
		where t._nrdif=@_nrdif
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp v
		on v.Tip=t.Tip and v.Cod_proprietate=t.Cod_proprietate and v.Cod=t.cod
	where v._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
