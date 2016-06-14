--/*
drop view yso_vIaTehnpoz 
go
create view yso_vIaTehnpoz as 
select tp.Cod_tehn, rtrim(t.Denumire) as Den_tehn
	, tp.Tip, CASE tp.Tip WHEN 'M' THEN 'Material' WHEN 'R' THEN 'Rezultat' ELSE 'Altele' END as Den_tip
	, tp.Cod, RTRIM(n.Denumire) as Den_cod
	, tp.Nr
	, rtrim(tp.Subtip) as Tip_resursa, CASE tp.Tip WHEN 'M' THEN 'Material' WHEN 'P' THEN 'Produs' ELSE 'Altele' END as Den_tip_resursa
	, tp.Specific as Consum_specific
from tehnpoz tp 
	inner join tehn t on t.Cod_tehn=tp.Cod_tehn
	inner join nomencl n on n.Cod=tp.Cod
go
drop proc yso_xIaTehnpoz 
go
create proc yso_xIaTehnpoz as
select * from yso_vIaTehnpoz
go
--*/
if exists (select * from sysobjects where name ='yso_xImportTehnpoz')
drop procedure yso_xImportTehnpoz
go
create procedure yso_xImportTehnpoz as --@tabela varchar(255), @fisier nvarchar(4000) as
--begin try
/*
	select isnull(Cod_tehn,'') as Cod_tehn, isnull(Den_tehn,'') as Den_tehn, isnull(Tip,'') as Tip, isnull(Den_tip,'') as Den_tip, isnull(Cod,'') as Cod, isnull(Den_cod,'') as Den_cod, isnull(Nr,'') as Nr, isnull(Tip_resursa,'') as Tip_resursa, isnull(Den_tip_resursa,'') as Den_tip_resursa, isnull(Consum_specific,'') as Consum_specific
	,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp
	order by _linieimport
*/
	select distinct Cod_tehn, Tip, Cod, Nr, Tip_resursa, Consum_specific
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select			Cod_tehn, Tip, Cod, Nr, Tip_resursa, Consum_specific
	from yso_vIaTehnpoz
go
--/*
if exists (select * from sysobjects where name ='yso_xScriuTehnpoz')
drop procedure yso_xScriuTehnpoz
go
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
go
 --exec yso_xScriuTabela 'tehnpoz','\\10.0.0.10\import\80_ASIS_import_pachete_20 august_2012_DC_test.xlsx'