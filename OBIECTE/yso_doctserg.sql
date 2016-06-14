/****** Object:  Trigger [dbo].[pozdocsterg]    Script Date: 06/08/2012 14:09:55 ******/
drop trigger [dbo].[yso_docsterg]
GO

CREATE trigger [dbo].[yso_docsterg] on [dbo].[doc] for update, delete NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into yso_syssd
select top 1 host_id() [Host_id],host_name () [Host_name], @Aplicatia Aplicatia, getdate() Data_stergerii, @Utilizator Stergator  
,Subunitate
,Tip
,Numar
,Cod_gestiune
,Data
,Cod_tert
,Factura
,Contractul
,Loc_munca
,Comanda
,Gestiune_primitoare
,Valuta
,Curs
,Valoare
,Tva_11
,Tva_22
,Valoare_valuta
,Cota_TVA
,Discount_p
,Discount_suma
,Pro_forma
,Tip_miscare
,Numar_DVI
,Cont_factura
,Data_facturii
,Data_scadentei
,Jurnal
,Numar_pozitii
,Stare
,detalii
from deleted d

declare @log xml=(
	SELECT 
		  r.session_id, 
		  r.blocking_session_id, 
		  s.program_name, 
		  s.host_name, 
		  t.objectid, 
		  o.name,
		  t.text

	FROM
		  sys.dm_exec_requests r
		  INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
		  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
		  left join sys.objects o on o.object_id=t.objectid

	WHERE
		  s.is_user_process = 1
	for xml raw
      )

GO

