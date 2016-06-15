create procedure yso_xScriuTehnpoz @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as
declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)	
begin try	
	update v
	set subtip=t.Tip_resursa, Specific=t.Consum_specific
	from tehnpoz v inner join ##importXlsDifTmp t on v.Cod_tehn=t.Cod_tehn and v.Tip=t.Tip and v.Cod=t.Cod and v.Nr=t.Nr and v.Loc_munca=''
	where t._nrdif=@_nrdif
	if (@@ROWCOUNT=0)
		insert tehnpoz
		(Cod_tehn, Tip, Cod, Cod_operatie, Nr, Subtip, Supr, Coef_consum, Randament, Specific, Cod_inlocuit, Loc_munca, Obs, Utilaj, Timp_preg, Timp_util, Categ_salar, Norma_timp, Tarif_unitar, Lungime, Latime, Inaltime, Comanda, Alfa1, Alfa2, Alfa3, Alfa4, Alfa5, Val1, Val2, Val3, Val4, Val5)
		select
		Cod_tehn, Tip, Cod, '', Nr, Tip_resursa, '', '', '', Consum_specific, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''
		from ##importXlsDifTmp t
		where t._nrdif=@_nrdif
	if (select top 1 cod from ##importXlsDifTmp t where t._nrdif=@_nrdif) in ('08028100','96635040')
		print 'debug-stop'
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp d
		on d.Cod_tehn=t.Cod_tehn and d.Tip=t.Tip and d.Cod=t.Cod  
			and d.Nr=t.Nr and d.Tip_resursa=t.Tip_resursa and d.Consum_specific=t.Consum_specific
	where d._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
