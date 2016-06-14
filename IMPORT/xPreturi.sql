--/*
drop view yso_vIaPreturi
go
create view yso_vIaPreturi as 
select rtrim(cod_produs) as cod,
	RTRIM(n.denumire) as dencod,
	rtrim(cp.Categorie) as catpret,
	rtrim(cp.Denumire) as 'dencategpret',
	rtrim(p.tip_pret) as tippret,
	dtp.denumire as dentippret,
	convert(char(10),data_inferioara,101) as data_inferioara,
	convert(char(10),data_superioara,101) as data_superioara,
	convert(decimal(12,3),p.Pret_vanzare) as pret_vanzare,
	convert(decimal(12,3),p.Pret_cu_amanuntul) as pret_cu_amanuntul
from preturi p
	inner join categpret cp on p.UM=cp.Categorie
	inner join dbo.fTipPret() dtp on p.tip_pret=dtp.tipPret
	left join dbo.nomencl n on n.Cod=p.Cod_produs
	--left outer join fPropUtiliz() fp on cod_proprietate='CATEGPRET' and categorie=fp.valoare
--where p.Cod_produs=@cod
	--and rtrim(cp.Denumire) like @cautare
	--and (@lista_categpret=0 OR fp.valoare is not null)
--order by convert(char(10),data_inferioara,101) desc
go
drop proc yso_xIaPreturi 
go
create proc yso_xIaPreturi @tip varchar(20)=null as
select 
	cod
	,dencod
	,catpret
	,dencategpret
	,tippret
	,dentippret
	,data_inferioara
	,data_superioara
	,pret_vanzare
	,pret_cu_amanuntul
from yso_vIaPreturi v
go
if exists (select * from sysobjects where name ='yso_xScriuPreturi')
drop procedure yso_xScriuPreturi
go
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
go
 --exec yso_xScriuTabela 'Preturi','d:\BAZEDATE\EXCEL\IMPORT\testimport.xlsx'