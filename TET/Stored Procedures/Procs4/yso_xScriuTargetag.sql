create procedure yso_xScriuTargetag @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as
declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)	
begin try	
	update v
	set v.Comision_suplimentar=t.Cantitate_valoare
	from Targetag v inner join ##importXlsDifTmp t on v.Agent=t.Agent and v.Client=t.Client and v.Produs=t.Grupa_produs
		and v.Data_lunii=t.Data_lunii --and v.Pct_livr=t.Pct_livr
	where t._nrdif=@_nrdif
	if (@@ROWCOUNT=0)
		insert Targetag
			(Agent
			, Client
			, UM
			, Produs
			, Data_lunii
			, Comision_suplimentar)
		select
			Agent
			, Client
			, ''
			, Grupa_produs
			, Data_lunii
			, Cantitate_valoare 
		from ##importXlsDifTmp t
		where t._nrdif=@_nrdif
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp v
		on v.Agent=t.Agent and v.Client=t.Client and v.Grupa_produs=t.Grupa_produs
	where v._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
