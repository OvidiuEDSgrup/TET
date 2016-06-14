--/*
drop view yso_vIaTargetag 
go
create view yso_vIaTargetag as 
select Agent=rtrim(ta.Agent), Denumire_agent=rtrim(lm.Denumire)
	, Client=rtrim(ta.Client), Denumire_client=RTRIM(t.Denumire)
	, Grupa_produs=RTRIM(ta.Produs), Denumire_grupa=RTRIM(g.Denumire)
	, Pct_livr=rtrim(ta.UM)
	, Data_lunii=convert(varchar(10),ta.Data_lunii,101)
	, Cantitate_valoare=convert(decimal(15,2),ta.Comision_suplimentar)
	-- select *
from Targetag ta 
	left join lm on lm.Cod=ta.Agent
	left join terti t on t.tert=ta.Client
	left join grupe g on g.Grupa=ta.Produs
go
drop proc yso_xIaTargetag 
go
create proc yso_xIaTargetag as
select 
Agent
, Denumire_agent
, Client
, Denumire_client
, Pct_livr
, Grupa_produs
, Denumire_grupa
, Data_lunii
, Cantitate_valoare from yso_vIaTargetag
go
--*/
if exists (select * from sysobjects where name ='yso_xImportTargetag')
drop procedure yso_xImportTargetag
go
create procedure yso_xImportTargetag as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try

	select Agent=ISNULL(Agent,'')
		, Denumire_agent=RTRIM(Denumire_agent)
		, Client=RTRIM(Client)
		, Denumire_client=RTRIM(Denumire_client)
		, Grupa_produs=RTRIM(Grupa_produs)
		, Denumire_grupa=RTRIM(Denumire_grupa)
		, Data_lunii=RTRIM(Data_lunii)
		, Cantitate_valoare=RTRIM(Cantitate_valoare)
		,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport

	select distinct Agent
		, Client
		, Grupa_produs
		, Data_lunii
		, Cantitate_valoare 
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select	
		Agent
		, Client
		, Grupa_produs
		, Data_lunii
		, Cantitate_valoare 
	from yso_vIaTargetag
go
--/*
if exists (select * from sysobjects where name ='yso_xScriuTargetag')
drop procedure yso_xScriuTargetag
go
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
go
 --exec yso_xScriuTabela 'Targetag','d:\BAZEDATE\EXCEL\IMPORT\testimport.xlsx'