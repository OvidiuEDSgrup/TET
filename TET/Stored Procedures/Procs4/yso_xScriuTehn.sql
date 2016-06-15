create procedure yso_xScriuTehn @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as
declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)	
begin try
	update v
	set Cod_tehn=t.Cod_tehn, Denumire=t.Denumire, Tip_tehn=t.Tip_tehn
	from tehn v inner join ##importXlsDifTmp t on v.Cod_tehn=t.Cod_tehn
	where t._nrdif=@_nrdif
	if (@@ROWCOUNT=0)
		insert tehn
		(Cod_tehn, Denumire, Tip_tehn, Utilizator, Data_operarii, Ora_operarii, Data1, Data2, Alfa1, Alfa2, Alfa3, Alfa4, Alfa5, Val1, Val2, Val3, Val4, Val5)
		select
		Cod_tehn, Denumire, Tip_tehn, 'IMPORT', GETDATE(), '', '', '', '', '', '', '', '', '', '', '', '', ''
		from ##importXlsDifTmp t
		where t._nrdif=@_nrdif
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp d
		on d.Cod_tehn=t.Cod_tehn and d.Denumire=t.Denumire and d.Tip_tehn=t.Tip_tehn
	where d._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
