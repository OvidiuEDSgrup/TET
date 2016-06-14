
--BF --> CB
--BK --> CL
--FA --> CF
--FC --> CA

if exists (select * from sysobjects where name ='yso_tr_actualizeazaContracte' and xtype='TR')
	drop trigger yso_tr_actualizeazaContracte
go
--***
create trigger yso_tr_actualizeazaContracte on con after insert,update,delete
as
--if TRIGGER_NESTLEVEL()>2
	--return
BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	set identity_insert contracte on	
	merge into contracte as ct
		using (select actiune=(case when i.idCon is null then 'DEL' when d.idCon is null then 'INS' else 'UPD' end)
					,idCon=isnull(i.idCon,d.idCon),Subunitate=isnull(i.Subunitate,d.Subunitate)
					,Tip=(case isnull(i.Tip,d.Tip) when 'BF' then 'CB' when 'BK' then 'CL' when 'FA' then 'CF' when 'FC' then 'CA' end)
					,Data=isnull(i.Data,d.Data),numar=isnull(i.Contract,d.Contract),Tert=isnull(i.Tert,d.Tert)
					,Punct_livrare=isnull(i.Punct_livrare,d.Punct_livrare),Stare=isnull(i.Stare,d.Stare),Loc_de_munca=isnull(i.Loc_de_munca,d.Loc_de_munca),Gestiune=isnull(i.Gestiune,d.Gestiune),Termen=isnull(i.Termen,d.Termen),Scadenta=isnull(i.Scadenta,d.Scadenta),Discount=isnull(i.Discount,d.Discount),Valuta=isnull(i.Valuta,d.Valuta),Curs=isnull(i.Curs,d.Curs),Mod_plata=isnull(i.Mod_plata,d.Mod_plata),Mod_ambalare=isnull(i.Mod_ambalare,d.Mod_ambalare),Factura=isnull(i.Factura,d.Factura),Total_contractat=isnull(i.Total_contractat,d.Total_contractat),Total_TVA=isnull(i.Total_TVA,d.Total_TVA)
					,Contract_coresp=isnull(i.Contract_coresp,d.Contract_coresp),Mod_penalizare=isnull(i.Mod_penalizare,d.Mod_penalizare),Procent_penalizare=isnull(i.Procent_penalizare,d.Procent_penalizare),Procent_avans=isnull(i.Procent_avans,d.Procent_avans),Avans=isnull(i.Avans,d.Avans),Nr_rate=isnull(i.Nr_rate,d.Nr_rate),Val_reziduala=isnull(i.Val_reziduala,d.Val_reziduala),Sold_initial=isnull(i.Sold_initial,d.Sold_initial),Cod_dobanda=isnull(i.Cod_dobanda,d.Cod_dobanda),Dobanda=isnull(i.Dobanda,d.Dobanda),Incasat=isnull(i.Incasat,d.Incasat),Responsabil=isnull(i.Responsabil,d.Responsabil),Responsabil_tert=isnull(i.Responsabil_tert,d.Responsabil_tert),Explicatii=isnull(i.Explicatii,d.Explicatii),Data_rezilierii=isnull(i.Data_rezilierii,d.Data_rezilierii)
					,detalii=isnull(i.detalii,d.detalii)
			from inserted i full join deleted d on d.idCon=i.idCon
			where isnull(i.Tip,d.Tip) in ('BF','BK','FA','FC')
			) as cn 
			on cn.idCon=ct.idContract
		when matched and cn.actiune='DEL' then 
			delete 
		when matched then 
			update SET tip=cn.tip, numar=cn.numar
				,data=cn.data,tert=nullif(cn.tert,''),punct_livrare=nullif(cn.punct_livrare,''),gestiune=nullif(cn.gestiune,''),gestiune_primitoare=nullif(cn.cod_dobanda,''),loc_de_munca=nullif(cn.loc_de_munca,''),valuta=cn.valuta,curs=cn.curs,valabilitate=(case when cn.termen>cn.data then cn.termen end),explicatii=cn.explicatii,idContractCorespondent=null,AWB=null
				,detalii=(select Subunitate=rtrim(nullif(cn.Subunitate,'')),Stare=rtrim(nullif(cn.Stare,''))
						,Scadenta=nullif(cn.Scadenta,0),Discount=convert(decimal(12,2),nullif(cn.Discount,0))
						,Mod_plata=rtrim(nullif(cn.Mod_plata,'')),Mod_ambalare=rtrim(nullif(cn.Mod_ambalare,''))
						,Factura=rtrim(nullif(cn.Factura,'')),Total_contractat=convert(decimal(15,2),nullif(cn.Total_contractat,0))
						,Total_TVA=convert(decimal(15,2),nullif(cn.Total_TVA,0))
						,Contract_coresp=rtrim(nullif(cn.Contract_coresp,'')),Mod_penalizare=rtrim(nullif(cn.Mod_penalizare,''))
						,Procent_penalizare=convert(decimal(12,2),nullif(cn.Procent_penalizare,0))
						,Procent_avans=convert(decimal(12,2),nullif(cn.Procent_avans,0))
						,Avans=convert(decimal(15,2),nullif(cn.Avans,0))
						,Nr_rate=nullif(cn.Nr_rate,0),Val_reziduala=convert(decimal(15,2),nullif(cn.Val_reziduala,0))
						,Sold_initial=convert(decimal(15,2),nullif(cn.Sold_initial,0)),Cod_dobanda=rtrim(nullif(cn.Cod_dobanda,''))
						,Dobanda=convert(decimal(12,2),nullif(cn.Dobanda,0)),Incasat=convert(decimal(15,2),nullif(cn.Incasat,0))
						,Responsabil=rtrim(nullif(cn.Responsabil,'')),Responsabil_tert=rtrim(nullif(cn.Responsabil_tert,''))
						,Data_rezilierii=convert(varchar(10),nullif(cn.Data_rezilierii,'01/01/1900'),101)
					for xml raw, type)
		when not matched by target then
			insert (idContract,tip,numar,data,tert,punct_livrare,gestiune,gestiune_primitoare,loc_de_munca,valuta,curs,valabilitate,explicatii,idContractCorespondent,AWB,detalii)
			values (idCon,tip,numar,data,nullif(tert,''),nullif(punct_livrare,''),nullif(gestiune,''),nullif(cod_dobanda,''),nullif(loc_de_munca,''),valuta,curs,(case when cn.termen>cn.data then cn.termen end),explicatii,null,null
				,(select Subunitate=rtrim(nullif(cn.Subunitate,'')),Stare=rtrim(nullif(cn.Stare,''))
						,Scadenta=nullif(cn.Scadenta,0),Discount=convert(decimal(12,2),nullif(cn.Discount,0))
						,Mod_plata=rtrim(nullif(cn.Mod_plata,'')),Mod_ambalare=rtrim(nullif(cn.Mod_ambalare,''))
						,Factura=rtrim(nullif(cn.Factura,'')),Total_contractat=convert(decimal(15,2),nullif(cn.Total_contractat,0))
						,Total_TVA=convert(decimal(15,2),nullif(cn.Total_TVA,0))
						,Contract_coresp=rtrim(nullif(cn.Contract_coresp,'')),Mod_penalizare=rtrim(nullif(cn.Mod_penalizare,''))
						,Procent_penalizare=convert(decimal(12,2),nullif(cn.Procent_penalizare,0))
						,Procent_avans=convert(decimal(12,2),nullif(cn.Procent_avans,0))
						,Avans=convert(decimal(15,2),nullif(cn.Avans,0))
						,Nr_rate=nullif(cn.Nr_rate,0),Val_reziduala=convert(decimal(15,2),nullif(cn.Val_reziduala,0))
						,Sold_initial=convert(decimal(15,2),nullif(cn.Sold_initial,0)),Cod_dobanda=rtrim(nullif(cn.Cod_dobanda,''))
						,Dobanda=convert(decimal(12,2),nullif(cn.Dobanda,0)),Incasat=convert(decimal(15,2),nullif(cn.Incasat,0))
						,Responsabil=rtrim(nullif(cn.Responsabil,'')),Responsabil_tert=rtrim(nullif(cn.Responsabil_tert,''))
						,Data_rezilierii=convert(varchar(10),nullif(cn.Data_rezilierii,'01/01/1900'),101)
					for xml raw, type))
		;set identity_insert contracte off	

		INSERT INTO JurnalContracte (idContract, data, stare, explicatii, detalii, utilizator)
			--OUTPUT inserted.idJurnal, inserted.idContract INTO #jurnalIntrodus(idJurnal, idContract)
		select idCon, GETDATE() data, ISNULL(c.stare,-900), rtrim(s.denumire) explicatii, detalii, isnull(nullif(dbo.fIaUtilizator(null),''),SUSER_NAME())
		from (select i.idCon, i.stare
				,tip=(case i.Tip when 'BF' then 'CB' when 'BK' then 'CL' when 'FA' then 'CF' when 'FC' then 'CA' end)
			from inserted i left join deleted d on d.idCon=i.idCon
			where coalesce(i.Stare,-900)<>coalesce(d.Stare,-900) ) c 
			join StariContracte s on s.tipContract=c.tip and s.stare=c.stare
			outer apply (select top 1 stare from JurnalContracte j where j.idContract=c.idCon 
				order by j.data desc, j.idJurnal desc) j
		where isnull(j.stare,-900)<>isnull(c.stare,-900)
		
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH 
