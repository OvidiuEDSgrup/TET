/****** Object:  Trigger [dbo].[pozdocsterg]    Script Date: 06/08/2012 14:09:55 ******/
drop trigger [dbo].yso_bpsterg
GO

CREATE trigger [dbo].yso_bpsterg on [dbo].bp for update, delete NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into yso_syssbp
select host_id() [Host_id],host_name () [Host_name], @Aplicatia Aplicatia, getdate() Data_stergerii, @Utilizator Stergator  
, Casa_de_marcat,	Factura_chitanta,	Numar_bon,	Numar_linie,	Data,	Ora,	Tip,	Vinzator,	Client
,	Cod_citit_de_la_tastatura,	CodPLU,	Cod_produs,	Categorie,	UM,	Cantitate,	Cota_TVA,	Tva,	Pret,	Total,	Retur
,	Inregistrare_valida,	Operat,	Numar_document_incasare,	Data_documentului,	Loc_de_munca,	Discount,	IdAntetBon
,	IdPozitie,	lm_real,	Comanda_asis,	Contract
,	Gestiune
--into yso_syssbp
from deleted 

--declare @log xml=(
--	SELECT 
--		  r.session_id, 
--		  r.blocking_session_id, 
--		  s.program_name, 
--		  s.host_name, 
--		  t.objectid, 
--		  o.name,
--		  t.text

--	FROM
--		  sys.dm_exec_requests r
--		  INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
--		  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
--		  left join sys.objects o on o.object_id=t.objectid

--	WHERE
--		  s.is_user_process = 1
--	for xml raw
--      )
--      return

GO

