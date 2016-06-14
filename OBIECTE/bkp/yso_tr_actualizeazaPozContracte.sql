
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
BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	
	merge into pozcontracte as ct
		using (select actiune=(case when i.tip is null then 'DEL' when d.tip is null then 'INS' else 'UPD' end)
					,Subunitate=isnull(i.Subunitate,d.Subunitate),Tip=isnull(i.Tip,d.Tip),Contract=isnull(i.Contract,d.Contract)
					,Tert=isnull(i.Tert,d.Tert),Punct_livrare=isnull(i.Punct_livrare,d.Punct_livrare),Data=isnull(i.Data,d.Data)
					,Cod=isnull(i.Cod,d.Cod),Cantitate=isnull(i.Cantitate,d.Cantitate),Pret=isnull(i.Pret,d.Pret),Pret_promotional=isnull(i.Pret_promotional,d.Pret_promotional)
					,Discount=isnull(i.Discount,d.Discount),Termen=isnull(i.Termen,d.Termen),Factura=isnull(i.Factura,d.Factura),Cant_disponibila=isnull(i.Cant_disponibila,d.Cant_disponibila)
					,Cant_aprobata=isnull(i.Cant_aprobata,d.Cant_aprobata),Cant_realizata=isnull(i.Cant_realizata,d.Cant_realizata),Valuta=isnull(i.Valuta,d.Valuta),Cota_TVA=isnull(i.Cota_TVA,d.Cota_TVA),Suma_TVA=isnull(i.Suma_TVA,d.Suma_TVA),Mod_de_plata=isnull(i.Mod_de_plata,d.Mod_de_plata),UM=isnull(i.UM,d.UM),Zi_scadenta_din_luna=isnull(i.Zi_scadenta_din_luna,d.Zi_scadenta_din_luna),Explicatii=isnull(i.Explicatii,d.Explicatii),Numar_pozitie=isnull(i.Numar_pozitie,d.Numar_pozitie),Utilizator=isnull(i.Utilizator,d.Utilizator),Data_operarii=isnull(i.Data_operarii,d.Data_operarii),Ora_operarii=isnull(i.Ora_operarii,d.Ora_operarii),idPozCon=isnull(i.idPozCon,d.idPozCon),detalii=isnull(i.detalii,d.detalii)
			from inserted i full join deleted d on d.subunitate=i.subunitate and d.tip=i.tip and d.contract=i.contract --and d.tert=i.tert and d.Data=i.Data
				--left join contracte c on c.tip=(case isnull(i.Tip,d.Tip) when 'BK' then 'CB' when 'FC' then 'CF' end)
				--	and c.numar=isnull(i.Contract_coresp,d.Contract_coresp) and c.tert=isnull(i.Tert,d.Tert)
			where isnull(i.Tip,d.Tip) in ('BF','BK','FA','FC')
			) as cn 
			on cn.tip=ct.tip and cn.numar=ct.numar --and cn.data=ct.data and cn.tert=ct.tert
		when matched and cn.actiune='DEL' then 
			delete 
		when matched then 
			update SET data=cn.data,tert=cn.tert,punct_livrare=nullif(cn.punct_livrare,''),gestiune=cn.gestiune,gestiune_primitoare=nullif(cn.cod_dobanda,''),loc_de_munca=cn.loc_de_munca,valuta=cn.valuta,curs=cn.curs,valabilitate=(case when cn.termen not in ('1900-01-01','1901-01-01',cn.data) then cn.termen end),explicatii=cn.explicatii,idContractCorespondent=null,detalii=cn.detalii,AWB=null
		--when not matched by target then
		when not matched by target then
			insert (tip,numar,data,tert,punct_livrare,gestiune,gestiune_primitoare,loc_de_munca,valuta,curs,valabilitate,explicatii,idContractCorespondent,detalii,AWB)
			values (tip,numar,data,tert,nullif(punct_livrare,''),gestiune,nullif(cod_dobanda,''),loc_de_munca,valuta,curs,(case when cn.termen not in ('1900-01-01','1901-01-01',cn.data) then cn.termen end),explicatii,null,detalii,null)
		;--output INSERTED.*,$action,DELETED.*;
		
--	select numar=isnull(i.Numar,d.Numar), data=isnull(i.Data,d.data), numar_pozitie=isnull(i.Numar_pozitie,d.numar_pozitie)
--		, cantitate=coalesce(i.Cantitate,d.cantitate), stare=coalesce(i.Stare*10,-10)
--	into #NAmodStare 
--	from inserted i full join deleted d on d.Numar=i.Numar and d.Data=i.Data and d.Numar_pozitie=i.Numar_pozitie 
--	where (coalesce(d.Stare*10,-15)<>coalesce(i.Stare*10,-10) or isnull(d.Cantitate,0)<>isnull(i.Cantitate,0))

--	create table #RNmodStare (idContract int not null)
--/*
--	select p.idContract,*, --*/ update p set
--		starePoz=n.stare
--	output inserted.idcontract into #RNmodStare 
--	from PozContracte p join Contracte c on c.idContract=p.idContract
--		join #NAmodStare n on n.Numar=c.numar and n.Data=c.data and n.Numar_pozitie=p.idPozContract
--	where isnull(p.starePoz,-15)<>n.Stare or p.cantitate<>n.Cantitate
	
--	declare @p xml
--	set @p=(select distinct r.idContract from #RNmodStare r for xml raw, root('Date'), type)
--	exec updateStareSetContracte null,@p	
	
--	select numar=isnull(i.Numar,d.Numar), data=isnull(i.Data,d.data), numar_pozitie=isnull(i.Numar_pozitie,d.numar_pozitie)
--		, cantitate=coalesce(i.Cantitate,d.cantitate)
--		, termen=coalesce(i.termen,d.termen), explicatii=coalesce(i.explicatii,d.explicatii)
--	into #NAmodDate 
--	from inserted i left join deleted d on d.Numar=i.Numar and d.Data=i.Data and d.Numar_pozitie=i.Numar_pozitie 
--	where (coalesce(d.termen,'')<>coalesce(i.termen,'') or isnull(d.explicatii,'')<>isnull(i.explicatii,''))

--	create table #RNmodDate (idContract int not null)
--/*
--	select p.idContract,*, --*/ update p set
--		termen=n.termen, explicatii=n.explicatii
--	output inserted.idcontract into #RNmodDate 
--	from PozContracte p join Contracte c on c.idContract=p.idContract
--		join #NAmodDate n on n.Numar=c.numar and n.Data=c.data and n.Numar_pozitie=p.idPozContract
--	where isnull(p.termen,'')<>isnull(n.termen,'') or isnull(p.explicatii,'')<>isnull(n.explicatii,'')
	
	
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH 
