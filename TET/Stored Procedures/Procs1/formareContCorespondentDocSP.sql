--*/
CREATE PROCEDURE formareContCorespondentDocSP --@sesiune varchar(50), @parXML xml OUTPUT 
AS
begin try

	if OBJECT_ID('tempdb..#documente') is null
		create table #documente(tip varchar(2),numar varchar(20),data datetime,gestiune varchar(13),gestiune_primitoare varchar(20),tert varchar(13),factura varchar(20),
		data_facturii datetime,data_scadentei datetime,loc_de_munca varchar(13),numar_pozitie int,cod varchar(20),barcod varchar(20),codcodi varchar(50),cantitate float,pret_valuta float,pret_vanzare float,
		tip_tva int,zilescadenta int,facturanesosita int,aviznefacturat int,cod_intrare varchar(20),codiPrim varchar(20),pret_cu_amanuntul float,cota_tva int,tva_deductibil decimal(12,2),
		tva_valuta float,comanda varchar(20),indbug varchar(20),pret_de_stoc float,pret_amanunt_predator float,valuta varchar(3),curs float,locatie varchar(20),[contract] varchar(20),
		lot varchar(20),data_expirarii datetime,discount decimal(12,3),punctlivrare varchar(13),numar_dvi varchar(20),categ_pret int,
		cont_de_stoc varchar(20),cont_corespondent varchar(20),cont_intermediar varchar(20),cont_factura varchar(20),cont_venituri varchar(20),
		tva_neexigibil decimal(5,2),idJurnalContract int,idPozContract int,stare int,jurnal varchar(20),detalii xml,detalii_antet xml,subtip varchar(2),tip_miscare varchar(1),
		cumulat float,nrordmin int,nrordmax int,tvaunit float,nrpe int,nrpozmax int,updatabile int,cerecumulare int,idlinie int,idIntrareFirma int,idIntrare int,ptUpdate int,idpozdoc int,pid int,tva_deductibil_i decimal(12,2), idPtAntet int,colet varchar(20),
		codgs1 varchar(1000),nrp int identity)
	
	/*Creeam o tabela temporara pentru gestiuni de Transfer - utila mai ales la PV*/
	if OBJECT_ID('tempdb..#gesttransfer') is null
	begin
		create table #gesttransfer(gestiune varchar(20),gestiune_transfer varchar(20),nrordine int)
		exec creeazaGestiuniTransfer
	end

	update d set cont_intermediar=rtrim(g.Cont_contabil_specific)
	from #documente d
		inner join gestiuni g on d.gestiune_primitoare=g.cod_gestiune and g.Cont_contabil_specific!='' and g.Tip_gestiune='A'
		inner join nomencl n on n.Cod=d.cod
	where d.tip='AC' and isnull(d.cont_intermediar,'')<>rtrim(g.Cont_contabil_specific)
		and n.Tip not in ('R','S')

	
	update d set gestiune_primitoare=gt.gestiune, gestiune=gt.gestiune_transfer 
	from #documente d
		inner join gestiuni g on g.Subunitate='1' and g.cod_gestiune=d.gestiune and g.Cont_contabil_specific!='' and g.Tip_gestiune='A'
		inner join #gesttransfer gt on gt.gestiune=d.gestiune
		inner join nomencl n on n.Cod=d.cod
	where d.tip IN ('AP','AC') and d.cantitate<0
		and isnull(gt.gestiune_transfer,'')<>'' and gt.nrordine=1
		and n.Tip not in ('R','S')
		
	
	update d set cont_intermediar=rtrim(g.Cont_contabil_specific), cont_de_stoc=RTRIM(g1.Cont_contabil_specific)
	from #documente d
		inner join gestiuni g on g.Subunitate='1' and g.cod_gestiune=d.gestiune_primitoare and g.Cont_contabil_specific!='' and g.Tip_gestiune='A'
		inner join gestiuni g1 on g1.Subunitate='1' and g1.Cod_gestiune=d.gestiune and g1.Cont_contabil_specific!='' and g1.Tip_gestiune<>'A'
		inner join nomencl n on n.Cod=d.cod
	where d.tip IN ('AP','AC') and d.cantitate<0
		and (isnull(d.cont_intermediar,'')<>rtrim(g.Cont_contabil_specific) or isnull(d.cont_de_stoc,'')<>rtrim(g1.Cont_contabil_specific))
		and n.Tip not in ('R','S')
	
	
	update d set cont_intermediar='',gestiune_primitoare='378.0'
	from #documente d
		left join gestiuni g on d.gestiune_primitoare=g.cod_gestiune and g.Tip_gestiune='A' --and g.Cont_contabil_specific!='' 
		inner join nomencl n on n.Cod=d.cod
	where d.tip='AP' and d.cantitate>0 and isnull(gestiune_primitoare,'')<>'378.0'
		and n.Tip not in ('R','S')
		
	declare @ContNesositAviz varchar(40)
	select @ContNesositAviz=isnull(nullif((case when parametru='CTCLAVRT' then val_alfanumerica else @ContNesositAviz end),''),'418')
	from par where tip_parametru='GE' and parametru in ('CTFURECNE','CTCLAVRT')
	
	update d set
		cont_factura=cf.cont_factura
		,cont_corespondent=cc.cont_corespondent
		,cont_intermediar=ci.cont_intermediar
		,cont_venituri=rtrim(dbo.contVenitAP(isnull(d.gestiune,''),isnull(d.cod,''),d.cont_de_stoc,ci.cont_intermediar))
	from #documente d
		inner join nomencl n on n.Cod=d.cod
		inner join terti t on d.tert=t.tert
		left outer join infotert it on d.tert=it.tert and it.identificator=substring(d.numar_DVI,14,5)
		cross apply (select 
			cont_factura=(case when d.aviznefacturat=1 then @ContNesositAviz when substring(d.numar_DVI, 14, 5)!='' then it.cont_in_banca3 else t.cont_ca_beneficiar end)
			) cf
		cross apply (select 
			cont_corespondent=(CASE WHEN n.Tip='S' THEN cf.cont_factura ELSE dbo.contCorespAP(isnull(d.gestiune,''),isnull(d.cod,''),d.cont_de_stoc,isnull(d.loc_de_munca,''))END)
			) cc
		cross apply (select 
			cont_intermediar=rtrim(dbo.contIntermAP(isnull(d.gestiune,''),isnull(d.cod,''),d.cont_de_stoc,d.cont_corespondent))
			) ci
	where d.tip IN ('AP','AS') --and d.cantitate<0
		and n.Tip in ('S') and nullif(d.cont_corespondent,'') is null
	
END TRY

BEGIN CATCH
	--if @@trancount>0 and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'formareContCorespondentDocSP')
	--		ROLLBACK TRAN formareContCorespondentDocSP
	
	declare @mesaj varchar(1000)
	SET @mesaj = ERROR_MESSAGE()+' (formareContCorespondentDocSP)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
