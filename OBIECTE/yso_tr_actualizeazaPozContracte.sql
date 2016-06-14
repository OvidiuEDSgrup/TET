
--BF --> CB
--BK --> CL
--FA --> CF
--FC --> CA

if exists (select * from sysobjects where name ='yso_tr_actualizeazaPozContracte' and xtype='TR')
	drop trigger yso_tr_actualizeazaPozContracte
go
--***
create trigger yso_tr_actualizeazaPozContracte on pozcon after insert,update,delete
as
--if TRIGGER_NESTLEVEL()>2
--	return
BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	
	set identity_insert pozcontracte on	
	merge into pozcontracte as ct
		using (select actiune=(case when i.idPozCon is null then 'DEL' when d.idPozCon is null then 'INS' else 'UPD' end)
					,c.idCon
					,Subunitate=isnull(i.Subunitate,d.Subunitate)
					,Tip=(case isnull(i.Tip,d.Tip) when 'BF' then 'CB' when 'BK' then 'CL' when 'FA' then 'CF' when 'FC' then 'CA' end)
					,Numar=isnull(i.Contract,d.Contract)
					,Tert=isnull(i.Tert,d.Tert),Punct_livrare=isnull(i.Punct_livrare,d.Punct_livrare),Data=isnull(i.Data,d.Data)
					,Cod=isnull(i.Cod,d.Cod),Cantitate=isnull(i.Cantitate,d.Cantitate),Pret=isnull(i.Pret,d.Pret),Pret_promotional=isnull(i.Pret_promotional,d.Pret_promotional)
					,Discount=isnull(i.Discount,d.Discount),Termen=isnull(i.Termen,d.Termen),Factura=isnull(i.Factura,d.Factura),Cant_disponibila=isnull(i.Cant_disponibila,d.Cant_disponibila)
					,Cant_aprobata=isnull(i.Cant_aprobata,d.Cant_aprobata),Cant_realizata=isnull(i.Cant_realizata,d.Cant_realizata),Valuta=isnull(i.Valuta,d.Valuta),Cota_TVA=isnull(i.Cota_TVA,d.Cota_TVA),Suma_TVA=isnull(i.Suma_TVA,d.Suma_TVA),Mod_de_plata=isnull(i.Mod_de_plata,d.Mod_de_plata),UM=isnull(i.UM,d.UM),Zi_scadenta_din_luna=isnull(i.Zi_scadenta_din_luna,d.Zi_scadenta_din_luna),Explicatii=isnull(i.Explicatii,d.Explicatii),Numar_pozitie=isnull(i.Numar_pozitie,d.Numar_pozitie),Utilizator=isnull(i.Utilizator,d.Utilizator),Data_operarii=isnull(i.Data_operarii,d.Data_operarii),Ora_operarii=isnull(i.Ora_operarii,d.Ora_operarii),detalii=isnull(i.detalii,d.detalii)
					,idPozCon=isnull(i.idPozCon,d.idPozCon)
			from inserted i full join deleted d on d.idPozCon=i.idPozCon--d.subunitate=i.subunitate and d.tip=i.tip and d.contract=i.contract and d.tert=i.tert and d.Data=i.Data and d.Cod=i.Cod and d.Numar_pozitie=i.Numar_pozitie
				inner join con c on c.subunitate=isnull(i.Subunitate,d.Subunitate) and c.Tip=isnull(i.Tip,d.Tip) and c.contract=isnull(i.Contract,d.Contract)
					and c.Tert=isnull(i.Tert,d.Tert) and c.Data=isnull(i.Data,d.Data)
				inner join contracte t on t.idcontract=c.idcon
			where isnull(i.Tip,d.Tip) in ('BF','BK','FA','FC')
			) as cn 
			on cn.idPozCon=ct.idPozContract 
		when matched and cn.actiune='DEL' then 
			delete 
		when matched then 
			update SET idContract=cn.idCon,cantitate=cn.cant_aprobata,pret=cn.pret,discount=cn.discount
				,termen=(case when cn.termen not in ('1900-01-01','1901-01-01',cn.data) then cn.termen end)
				,periodicitate=null,explicatii=cn.explicatii,detalii=cn.detalii,cod_specific=null,idPozLansare=null,subtip=cn.tip
		--when not matched by target then
		when not matched by target then
			insert (idPozContract,idContract,cod,grupa,cantitate,pret,discount,termen,periodicitate,explicatii,detalii,cod_specific,idPozLansare,subtip)
			values (idPozCon,idCon,cod,cod,cant_aprobata,pret,discount,(case when cn.termen not in ('1900-01-01','1901-01-01',cn.data) then cn.termen end)
				,null,explicatii,detalii,null,null,cn.tip)
		;set identity_insert pozcontracte off
	
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH 
