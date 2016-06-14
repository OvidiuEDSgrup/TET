--/*
drop view yso_vIaStoclim 
go
create view yso_vIaStoclim as 
select Subunitate=rtrim(sl.Subunitate)
	, Tip_gestiune=rtrim(sl.Tip_gestiune), Cod_gestiune=rtrim(sl.Cod_gestiune), Den_gestiune=rtrim(g.Denumire_gestiune)
	, Cod=rtrim(sl.Cod), Den_cod=RTRIM(n.Denumire)
	, Data=CONVERT(char(10),sl.data,126)
	, Stoc_min=convert(decimal(12,3),sl.Stoc_min)
	, Stoc_max=convert(decimal(12,3),sl.Stoc_max)
	, Pret=CONVERT(decimal(15,5),sl.pret)
	, Locatie=RTRIM(Locatie)
from Stoclim sl 
	inner join nomencl n on n.Cod=sl.Cod
	inner join gestiuni g on g.Subunitate=sl.Subunitate and g.Tip_gestiune=sl.Tip_gestiune and g.Cod_gestiune=sl.Cod_gestiune
where sl.data<'2999-01-01'
go
drop proc yso_xIaStoclim 
go
create proc yso_xIaStoclim as
select * from yso_vIaStoclim
go
--*/
--/*
if exists (select * from sysobjects where name ='yso_xImportStoclim')
drop procedure yso_xImportStoclim
go
create procedure yso_xImportStoclim as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try--*/declare @tabela varchar(255)='stoclim', @fisier nvarchar(4000)='\\10.0.0.10\import\testimport.xlsx' 
/*
	select Subunitate=isnull(Subunitate,'')
	, Tip_gestiune=isnull(Tip_gestiune,''),Cod_gestiune=isnull(Cod_gestiune,''),Den_gestiune=isnull(Den_gestiune,'')
	, Cod=isnull(Cod,''), Den_cod=isnull(Den_cod,'')
	, Data=isnull(data,'')
	, Stoc_min=isnull(Stoc_min,'')
	, Stoc_max=isnull(Stoc_max,'')
	, Pret=isnull(pret,'')
	, Locatie=isnull(Locatie,'')
	,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport
*/
	select distinct /*Subunitate,Tip_gestiune,*/Cod_gestiune,Cod,Stoc_min,Stoc_max
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select			/*Subunitate,Tip_gestiune,*/Cod_gestiune,Cod,Stoc_min,Stoc_max
	from yso_vIaStoclim
go
--/*
if exists (select * from sysobjects where name ='yso_xScriuStoclim')
drop procedure yso_xScriuStoclim
go
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
go
--*/

 --exec yso_xScriuTabela 'Stoclim','\\10.0.0.10\import\testimport.xlsx'