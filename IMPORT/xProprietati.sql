--/*
drop view yso_vIaProprietati 
go
create view yso_vIaProprietati as 
select pr.Tip
	, pr.Cod
	, Denumire_cod=rtrim(coalesce(n.denumire,t.denumire,''))
	, pr.Cod_proprietate
	, pr.Valoare
	, pr.Valoare_tupla
	-- select *
from Proprietati pr 
	left join tipproprietati tp on tp.Tip=pr.Tip and tp.Cod_proprietate=pr.Cod_proprietate
	left join catproprietati cp on cp.Cod_proprietate=pr.Cod_proprietate
	left join nomencl n on pr.Tip='NOMENCL' and n.Cod=pr.Cod
	left join terti t on pr.Tip='TERT' and t.tert=pr.Cod
go
drop proc yso_xIaProprietati 
go
create proc yso_xIaProprietati @tip varchar(20)=null as
select 
	Tip
	,Cod
	,Denumire_cod
	,Cod_proprietate
	,Valoare
	--,Valoare_tupla
from yso_vIaProprietati v
where @tip is null or v.Tip=@tip
go
--*/
if exists (select * from sysobjects where name ='yso_xImportProprietati')
drop procedure yso_xImportProprietati
go
create procedure yso_xImportProprietati as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try

	select 	
		Cod=isnull(Cod,'')
		,Denumire_cod=isnull(Denumire_cod,'')
		,Cod_proprietate=isnull(Cod_proprietate,'')
		,Valoare=isnull(Valoare,'')
		,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport

	select distinct 
		Cod
		,Denumire_cod
		,Cod_proprietate
		,Valoare
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select	
		Cod
		,Denumire_cod
		,Cod_proprietate
		,Valoare
	from yso_vIaProprietati
go
--/*
if exists (select * from sysobjects where name ='yso_xScriuProprietati')
drop procedure yso_xScriuProprietati
go
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
go
 --exec yso_xScriuTabela 'Proprietati','d:\BAZEDATE\EXCEL\IMPORT\testimport.xlsx'