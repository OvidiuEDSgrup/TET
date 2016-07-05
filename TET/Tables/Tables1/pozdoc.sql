CREATE TABLE [dbo].[pozdoc] (
    [Subunitate]            CHAR (9)     NOT NULL,
    [Tip]                   CHAR (2)     NOT NULL,
    [Numar]                 CHAR (8)     NOT NULL,
    [Cod]                   CHAR (20)    NOT NULL,
    [Data]                  DATETIME     NOT NULL,
    [Gestiune]              CHAR (9)     NOT NULL,
    [Cantitate]             FLOAT (53)   NOT NULL,
    [Pret_valuta]           FLOAT (53)   NOT NULL,
    [Pret_de_stoc]          FLOAT (53)   NOT NULL,
    [Adaos]                 REAL         NOT NULL,
    [Pret_vanzare]          FLOAT (53)   NOT NULL,
    [Pret_cu_amanuntul]     FLOAT (53)   NOT NULL,
    [TVA_deductibil]        FLOAT (53)   NOT NULL,
    [Cota_TVA]              REAL         NOT NULL,
    [Utilizator]            CHAR (10)    NOT NULL,
    [Data_operarii]         DATETIME     NOT NULL,
    [Ora_operarii]          CHAR (6)     NOT NULL,
    [Cod_intrare]           CHAR (20)    NOT NULL,
    [Cont_de_stoc]          VARCHAR (20) NULL,
    [Cont_corespondent]     VARCHAR (20) NULL,
    [TVA_neexigibil]        REAL         NOT NULL,
    [Pret_amanunt_predator] FLOAT (53)   NOT NULL,
    [Tip_miscare]           CHAR (1)     NOT NULL,
    [Locatie]               CHAR (30)    NOT NULL,
    [Data_expirarii]        DATETIME     NOT NULL,
    [Numar_pozitie]         INT          NOT NULL,
    [Loc_de_munca]          CHAR (9)     NOT NULL,
    [Comanda]               CHAR (40)    NOT NULL,
    [Barcod]                CHAR (30)    NOT NULL,
    [Cont_intermediar]      CHAR (13)    NOT NULL,
    [Cont_venituri]         CHAR (13)    NOT NULL,
    [Discount]              REAL         NOT NULL,
    [Tert]                  CHAR (13)    NOT NULL,
    [Factura]               CHAR (20)    NOT NULL,
    [Gestiune_primitoare]   CHAR (13)    NOT NULL,
    [Numar_DVI]             CHAR (25)    NOT NULL,
    [Stare]                 SMALLINT     NOT NULL,
    [Grupa]                 VARCHAR (20) NULL,
    [Cont_factura]          CHAR (13)    NOT NULL,
    [Valuta]                CHAR (3)     NOT NULL,
    [Curs]                  FLOAT (53)   NOT NULL,
    [Data_facturii]         DATETIME     NOT NULL,
    [Data_scadentei]        DATETIME     NOT NULL,
    [Procent_vama]          REAL         NOT NULL,
    [Suprataxe_vama]        FLOAT (53)   NOT NULL,
    [Accize_cumparare]      FLOAT (53)   NOT NULL,
    [Accize_datorate]       FLOAT (53)   NOT NULL,
    [Contract]              CHAR (20)    NOT NULL,
    [Jurnal]                VARCHAR (20) NULL,
    [detalii]               XML          NULL,
    [idPozDoc]              INT          IDENTITY (1, 1) NOT NULL,
    [subtip]                VARCHAR (2)  NULL,
    [idIntrareFirma]        INT          NULL,
    [idIntrare]             INT          NULL,
    [idIntrareTI]           INT          NULL,
    [colet]                 VARCHAR (20) NULL,
    [lot]                   VARCHAR (20) NULL,
    CONSTRAINT [PK_idpozdoc] PRIMARY KEY NONCLUSTERED ([idPozDoc] ASC)
);




GO
CREATE UNIQUE CLUSTERED INDEX [Pentru_culegere]
    ON [dbo].[pozdoc]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Terti]
    ON [dbo].[pozdoc]([Subunitate] ASC, [Tip] ASC, [Tert] ASC, [Factura] ASC);


GO
CREATE NONCLUSTERED INDEX [Balanta]
    ON [dbo].[pozdoc]([Subunitate] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Data] ASC, [Tip_miscare] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[pozdoc]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Gestiune] ASC, [Cod] ASC, [Cod_intrare] ASC, [Numar_pozitie] ASC, [Pret_vanzare] ASC);


GO
CREATE NONCLUSTERED INDEX [yso_cantitate]
    ON [dbo].[pozdoc]([Subunitate] ASC, [Tip] ASC, [Cod] ASC, [Contract] ASC, [Cantitate] ASC);


GO
CREATE NONCLUSTERED INDEX [yso_cod]
    ON [dbo].[pozdoc]([Tip] ASC, [Data] ASC)
    INCLUDE([Subunitate], [Numar], [Cod], [Cantitate], [Contract]);


GO
CREATE NONCLUSTERED INDEX [yso_tip]
    ON [dbo].[pozdoc]([Tip] ASC)
    INCLUDE([Subunitate], [Cod], [Data], [Gestiune], [Cantitate], [Pret_de_stoc], [Pret_vanzare], [Cod_intrare], [Loc_de_munca], [Cont_venituri], [Tert], [Accize_cumparare]);


GO
CREATE NONCLUSTERED INDEX [IX_idIntrareFirma]
    ON [dbo].[pozdoc]([idIntrareFirma] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_idIntrare]
    ON [dbo].[pozdoc]([idIntrare] ASC);


GO

create trigger docfac on pozdoc for update,insert,delete as
begin try
-------------	din tabela par (parametri trimis de Magic):
--(8)		[IF (FK,FL,2)],	[IF (FO,FP,2)], FV, GC, HA, [HM OR HL], HN, HO
	declare 
		@rotunj_n int, @rotunjr_n int, @timbrulit int, @stoehr int, @primariaTM int, @spgenisaVunicarm int, @docpesch_n int, @bloc_sold bit
	set @rotunj_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='ROTUNJ' and val_logica=1),2)
	set @rotunjr_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='ROTUNJR' and val_logica=1),2)
	set @bloc_sold=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='BLOCTERT'),0)
	set @timbrulit=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='TIMBRULIT'),0)
	--set @factbil=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='FACTBIL'),0)
	set @stoehr=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='STOEHR'),0)
	set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru='SP' and parametru='GENISA'),0)
		if (@spgenisaVunicarm=0) set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru='SP' and parametru='UNICARM'),0)
	set @primariaTM=isnull((select top 1 val_logica from par where tip_parametru='SP' and parametru='PRIMTIM'),0)
	set @docpesch_n=(case isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DOCPESCH'),0) when 1 then 0 else 1 end)
		if (@docpesch_n=0) set @docpesch_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='DOCPESCH'),0)
		--	sau "val_logica=0 or val_numerica=1" in loc de "@docpesch_n=1" mai jos

	delete from facturi where Subunitate in ('INTRASTAT','EXPAND')
	insert into facturi 
	select subunitate,max(loc_de_munca),(case when tip in ('AP','AS') then 0x46 else 0x54 end),factura,tert,
		max(data_facturii),max(data_scadentei),0,0,0,max(valuta),max(curs),0,0,0,max(cont_factura),0,0,max(comanda),max(data_facturii) 
	from inserted 
	where tip in ('RM','RP','RQ','RS','AP','AS') 
		and factura not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert and tip=(case when inserted.tip in ('AP','AS') then 0x46 else 0x54 end))
		and cont_factura<>'' 
		and Subunitate not in ('INTRASTAT','EXPAND')
	group by subunitate,(case when tip in ('AP','AS') then 0x46 else 0x54 end),tert,factura

	declare @Valoare float,@Tva float,@Tva9 float,@valoarev float,@contF varchar(40),@gvaluta char(3),@gcurs float,@glocm char(9),@gcom char(40)
	declare @csub char(9),@ctip char(2),@ctert char(13),@cfactura char(20),@semn int,@tvad float,@cant float,@valuta char(3),
		@curs float,@pstoc float,@pval float,@pvanz float,@cota float,@disc float,@cont varchar(40),@dvi char(8),
		@df datetime,@ds datetime,@LME float,@locm char(9),@com char(40),@TVAv float,@dfTVA int,@cuTVA int
	declare @gsub char(9),@gtip char(2),@gtert char(13),@gfactura char(20),@gdf datetime,@gds datetime,@tipf binary,@gfetch int

	declare tmp cursor for
	select i.subunitate,i.tip,i.tert,i.factura,1,i.tva_deductibil,i.cantitate,i.valuta,i.curs,i.pret_de_stoc,i.pret_valuta-(case when i.tip in ('RM','RS') and @timbrulit=1 and i.numar_dvi='' then i.accize_cumparare else 0 end),
		i.pret_vanzare,i.cota_tva,i.discount,
		i.cont_factura,i.numar_DVI,i.data_facturii,i.data_scadentei,i.suprataxe_vama,i.loc_de_munca,
	--	regula completare indicator bugetar (dupa prioritate): 1. pozdoc.substring(i.comanda,21,20) - compatibilitate in urma + Primaria TM, 
	--	apoi regula noua: 2.pozdoc.detalii/indicator, 3.cont_factura.detalii/indicator, 4.cont_corespondent.detalii/indicator (cont de stoc la receptii / cont venituri la avize)
		left(i.comanda,20)+(case when @primariaTM=0 or substring(i.comanda,21,20)='' 
			then isnull(nullif(i.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(nullif(cf.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),
				(case when i.tip in ('RM','RP','RQ','RS') then isnull(cs.detalii.value('(/row/@indicator)[1]','varchar(20)'),'') 
					when i.tip in ('AP','AS') then isnull(cv.detalii.value('(/row/@indicator)[1]','varchar(20)'),isnull(cs.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')) else '' end))) 
			else substring(i.comanda,21,20) end),
		(case when i.valuta<>'' and i.curs>0 then (case when isnumeric(i.grupa)=1 then convert(float,i.grupa) else convert(decimal(17,5),i.tva_deductibil/i.curs) end) else 0.0 end),i.procent_vama
	from inserted i
		left outer join conturi cs on i.tip in ('RM','RP','RQ','RS','AP','AS') and i.subunitate=cs.subunitate and i.cont_de_stoc=cs.cont
		left outer join conturi cv on i.tip in ('AP','AS') and i.subunitate=cv.subunitate and i.Cont_venituri=cv.cont
		left outer join conturi cf on i.subunitate=cf.subunitate and i.Cont_factura=cf.cont
	where i.tip in ('RM','RP','RQ','RS','AP','AS') and i.cont_factura<>'' 
	union all
	select subunitate,tip,tert,factura,-1,tva_deductibil,cantitate,valuta,curs,pret_de_stoc,pret_valuta-(case when tip in ('RM','RS') and @timbrulit=1 and numar_dvi='' then accize_cumparare else 0 end),
		pret_vanzare,cota_tva,discount,
		cont_factura,numar_DVI,data_facturii,data_scadentei,suprataxe_vama,loc_de_munca,comanda,
		(case when valuta<>'' and curs>0 then (case when isnumeric(grupa)=1 then convert(float,grupa) else convert(decimal(17,5),tva_deductibil/curs) end) else 0.0 end),procent_vama
	from deleted 
	where tip in ('RM','RP','RQ','RS','AP','AS') and cont_factura<>'' 
	order by subunitate,tip,tert,factura

	open tmp
	fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@tvad,@cant,@valuta,@curs,@pstoc,@pval,@pvanz,@cota,@disc,@cont,@dvi,@df,@ds,@LME,@locm,@com,@TVAv,@dfTVA
	set @gsub=@csub
	set @gtert=@ctert
	set @gfactura=@cfactura
	set @gtip=@ctip
	set @gfetch=@@fetch_status
	while @gfetch=0
	begin
		set @Valoare=0
		set @Tva=0
		set @Tva9=0
		set @valoarev=0
		set @ContF=@cont
		set @gvaluta=@valuta
		set @gcurs=@curs
		set @gdf=@df
		set @gds=@ds
		set @glocm=@locm
		set @gcom=@com
		while @gsub=@csub and @cTip=@gTip and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0
		begin
			if @ctip in ('RM','RP','RQ','RS')
			begin		
				set @tipf=0x54
				set @cuTVA=(case when (@ctip='RM' and @dvi<>'') or (@ctip='RM' and @dvi='' or @ctip in ('RP','RS')) and @dfTVA in (1) then 0 else 1 end)
				set @tva9=@tva9+(case when @cota in (9,11) then @semn*@cuTVA*@tvad else 0 end)
				set @tva=@tva+(case when @cota not in (9,11) then @semn*@cuTVA*@tvad else 0 end)
				set @disc=(case when abs(@disc+@cota*100/(@cota+100))<0.01 then convert(decimal(12,4),-@cota*100/(@cota+100)) 
					else convert(decimal(12,4),@disc) end)
				if @valuta='' 
					set @valoare=@valoare+@semn*round(convert(decimal(17,5),@cant*round(@pval*(1+@disc/100),5)),@rotunjr_n)
				else
				begin
					if @dvi='' set @valoare=@valoare+@semn*(case when @ctip='RP' then @pval else round(convert(decimal(17,5),@cant*round(convert(decimal(16,5),@pval*@curs*(1+@disc/100)),5)),@rotunjr_n) end)
					else set @valoare=@valoare+@semn*(case when @ctip='RP' then @pval when @ctip='RM' and @stoehr=1 and @df>='06/01/2003' then @pstoc*@cant else round(convert(decimal(17,5),@cant*round(convert(decimal(16,5),@pval*@curs),5)),@rotunjr_n) end)
					set @valoarev=@valoarev+@semn*round(convert(decimal(17,5),@cant*(case when @ctip='RP' then @pstoc else @pval end)*(1+(case when @ctip='RS' or @dvi='' then @disc else 0 end)/100)),2)
					set @valoarev=@valoarev+@semn*@cuTVA*@TVAv
				end
			end
			else begin
				set @tipf=0x46
				set @cuTVA=(case when @ctip in ('AP','AS') and @dfTVA in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or @ctip='AS') then 0 else 1 end)
				set @tva9=@tva9+(case when @cota in (9,11) then @semn*@cuTVA*@tvad else 0 end)
				set @tva=@tva+(case when @cota not in (9,11) then @semn*@cuTVA*@tvad else 0 end)
				set @valoare=@valoare+@semn*round(convert(decimal(17,5),@cant*@pvanz),@rotunj_n)
				if @valuta<>'' begin
					set @valoarev=@valoarev+@semn*round(convert(decimal(17,5),@cant*(@pval*(1-@disc/100)+@LME/1000))+(case when @curs>0 then @cuTVA*@tvad/@curs else 0 end),2)
				end
			end
			if @semn=1 set @contF=@cont
			if @semn=1 set @gvaluta=@valuta
			if @semn=1 set @gcurs=@curs
			if @semn=1 set @gdf=@df
			if @semn=1 set @gds=@ds
			if @semn=1 set @glocm=@locm
			if @semn=1 set @gcom=@com

			fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@tvad,@cant,@valuta,@curs,@pstoc,@pval,@pvanz,@cota,@disc,@cont,@dvi,@df,@ds,@LME,@locm,@com,@TVAv,@dfTVA
			set @gfetch=@@fetch_status
		end 
	
		/*	Validare limita sold beneficiari. Daca se lucreaza cu setarea GE, BLOCSOLD	*/	
		if @tipf=0x46 and @bloc_sold=1
		begin 
			IF OBJECT_ID('tempdb.dbo.#validSold') IS NOT NULL
				DROP TABLE #validSold	
				
			select @gtert tert, (@valoare+@tva+@tva9) valoare, 0 sold, 0 sold_max
			into #validSold

			exec validSoldTert		
		end

		/*	Validare "unicitate" factura (pe tert, tip, data), numar */
		IF ABS(@valoare)>=0.01 or ABS(@tva)>=0.01 or ABS(@tva9)>=0.01
		begin
			IF OBJECT_ID('tempdb.dbo.#facturi') IS NOT NULL
				DROP TABLE #facturi

			SELECT distinct tert, factura, data_facturii data, (case when tip in ('RM','RS','RP') then 'F' else 'B' end ) tip 
			INTO #facturi
			from Inserted where tip in ('RM','RS','RP','AP','AS') and subunitate<>'intrastat'

			exec validFactura
		end

		update facturi set valoare=valoare+@valoare,tva_22=tva_22+@tva,tva_11=tva_11+@tva9,
			sold=sold+@valoare+@tva+@tva9,
			valuta='',curs=0,
			cont_de_tert=@contF,loc_de_munca=@glocm,comanda=@gcom,
			data=(case when data<>@gdf then @gdf else data end),data_scadentei=(case when data_scadentei<>@gds then @gds else data_scadentei end)
		where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura

		update facturi set valoare_valuta=valoare_valuta+@valoarev,sold_valuta=sold_valuta+@valoarev,
			valuta=@gvaluta,curs=@gcurs 
		from terti where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura
			and facturi.subunitate=terti.subunitate and facturi.tert=terti.tert and terti.tert_extern=1 

		set @gtert=@ctert
		set @gsub=@csub
		set @gfactura=@cfactura
		set @gtip=@ctip
	end
	close tmp
	deallocate tmp
end try
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH

GO

create  trigger tr_ValidPozdoc on pozdoc for insert,update,delete NOT FOR REPLICATION as
begin try	
	DECLARE 
		@mesaj varchar(max),@userASiS varchar(50)

	set @userASiS=dbo.fIaUtilizator(null)


	/*
	IF EXISTS (select 1 from deleted d join LegaturiPozDoc p on d.idPozDoc in (p.idPozDoc1, p.idPozDoc2))
		RAISERROR('Pozitia documentului nu poate fi stearga sau modificata- este in legatura cu alte documente din baza de date (ex: promotii, stornari)!',16,1)
	*/
	/* Validare miscari valorice in raport cu cont atribuit stocuri */
	IF EXISTS (select 1 from inserted i JOIN Conturi c on i.cont_de_stoc=c.cont and i.tip_miscare='V' and c.sold_credit=3)
			RAISERROR ('Nu este permisa o miscare valorica pe un cont de stoc atribuit "Stocuri"', 16, 1)
	
	/*	Validare preturi pozitive. Exceptam de la validare prestarile. 	*/
	IF EXISTS (select 1 from inserted where tip not in ('RP','RZ') and (tip<>'RM' and ISNULL(Pret_vanzare,0.0)<0 or ISNULL(Pret_valuta,0.0)<0 or ISNULL(Pret_cu_amanuntul,0.0)<0 OR ISNULL(Pret_de_stoc,0.0)<0))
		RAISERROR ('Nu este permisa operarea cu preturi negative', 16, 1)

	/* Validare tert */
	if UPDATE(tert) 
	begin
		select DISTINCT tert cod into #terti 
		from inserted where tip in ('RM','RS','RP','AP','AS') and subunitate<>'intrastat'
		exec validTert
	end 

	/** Validare cod */
	if update(cod) 
	begin
		if object_id('tempdb..#nomencl') is not null drop table #nomencl
		create table #nomencl (Cod varchar(20), Data datetime)
		insert into #nomencl(Cod, Data)
		select distinct Cod, Data from inserted where subunitate<>'intrastat' and tip not in ('RP','RQ','RZ')
		exec validNomencl
		if object_id('tempdb..#nomencl') is not null drop table #nomencl
	end   

	/* Validare loc de munca */
	if UPDATE(loc_de_munca) 
	begin
		create table #lm(utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm(utilizator,cod,data)
		select distinct @userASiS,loc_de_munca,data from inserted where subunitate<>'intrastat'
		exec validLM
	end
	
	/** Validare comanda */
	IF UPDATE(comanda)
	BEGIN
		select DISTINCT left(comanda,20) comanda into #comenzi 
			from INSERTED where tip not in ('RP','RZ') and subunitate<>'intrastat'
		exec validComanda		
	END
	
	/** Validare valuta si curs */
	IF UPDATE(valuta) or UPDATE(curs)
	BEGIN
		select DISTINCT tip, numar, data, valuta, curs into #valute
			from INSERTED where valuta<>'' or curs<>0
		exec validValuta
	END

	/** Validare formule contabile (si implicit conturi) */
	IF UPDATE(cont_factura) OR UPDATE(cont_de_stoc) OR UPDATE(cont_venituri)
	BEGIN
		create table #formulecontabile (cont_debit varchar(40), cont_credit varchar(40), tip varchar(2), numar varchar(20), data datetime)
		insert into #formulecontabile(cont_debit, cont_credit, tip, numar, data)
		SELECT DISTINCT cont_de_stoc, cont_factura, tip, numar, Data from inserted where subunitate<>'intrastat' and Tip in ('RM','RS')
		UNION ALL
		SELECT DISTINCT cont_factura, cont_venituri, tip, numar, Data from inserted where subunitate<>'intrastat' and Tip in ('AP') and tip_miscare='E'
		UNION ALL
		SELECT DISTINCT cont_factura, cont_de_stoc, tip, numar, Data from inserted where subunitate<>'intrastat' and Tip in ('AP','AS') and tip_miscare='V'
		UNION ALL
		SELECT DISTINCT Cont_de_stoc, Cont_corespondent, tip, numar, Data from inserted where subunitate<>'intrastat' and tip_miscare='I' and Tip<>'RM' and tip not in ('AF','DF','PF') and cont_de_stoc not like '8%'
		UNION ALL
		SELECT DISTINCT Cont_corespondent, Cont_de_stoc, tip, numar, Data from inserted where subunitate<>'intrastat' and tip_miscare='E' and cont_intermediar='' and tip not in ('AF','DF','PF') and cont_de_stoc not like '8%'
		UNION ALL
		SELECT DISTINCT Cont_intermediar, Cont_de_stoc, tip, numar, Data from inserted where subunitate<>'intrastat' and tip_miscare='E' and cont_intermediar<>'' and tip not in ('AF','DF','PF') and cont_de_stoc not like '8%'
		UNION ALL
		SELECT DISTINCT Cont_corespondent, Cont_intermediar, tip, numar, Data from inserted where subunitate<>'intrastat' and tip_miscare='E' and cont_intermediar<>'' and tip not in ('AF','DF','PF')

		exec validFormuleContabile
	END
	

	/* 
		Daca exista inventar deschis nu se permite operarea de documente pe acea gestiune pe o data anterioare deschiderii inventarului    
		Daca inventarul este deschis pe o singura grupa, atunci sa se blocheze doar grupa respectiva
		Fiindca si "inchiderea" inventarului prespune generarea de documente in perioada "blocata" vom trece peste acestea la verificare
		identificandu-le prin atributul @idInventar din detalii, tabela pozdoc (se scrie dinspre procedura de inchidere)
	*/

	IF EXISTS (
			SELECT 1
			FROM AntetInventar at
			INNER JOIN inserted ins
				ON at.gestiune = ins.Gestiune
					AND ins.Data <= at.Data
					AND at.stare IN (0, 1)
					AND ins.detalii.value('(/row/@idInventar)[1]','int') IS NULL
			INNER JOIN nomencl n on n.Cod=ins.Cod and (n.Grupa=at.grupa or ISNULL(at.grupa,'')=''))
		--select * from inserted
		RAISERROR ('Pe aceasta gestiune exista un inventar in curs sau blocat temporar la o data anterioara datei introduse!', 16, 1)
		

	-- validare suma_de_tva fara cota_de_tva
	if exists (select 1 from inserted where tip in ('RM','RS','RP','AP','AS') and subunitate<>'intrastat' and Cota_TVA=0 and abs(TVA_deductibil)>0.001)
		RAISERROR ('Documentul nu poate avea TVA fara a i se preciza Cota de TVA!', 16, 1)
		


	/** Validare LUNA INCHISA STOCURI*/
	declare 
		@nlunastoc int, @nanulstoc int, @dDatastoc datetime
	set @nlunastoc= (select val_numerica from par where tip_parametru='GE' and parametru='LUNAINC')
	set @nanulstoc= (select val_numerica from par where tip_parametru='GE' and parametru='ANULINC')
	set @dDatastoc=dateadd(month,1,convert(datetime,str(@nLunastoc,2)+'/01/'+str(@nAnulstoc,4)))

	if (select count(*) from inserted where data<@dDatastoc and tip<>'MI')>0 or (select count(*) from deleted where data<@dDatastoc and tip<>'MI')>0
		RAISERROR ('Violare integritate date. Incercare de modificare luna inchisa stocuri ', 16, 1)

	/** Validare luna inchisa Contabilitate */
	create table #lunaconta (data datetime)
	insert into #lunaconta (data)
	select DISTINCT data from inserted where tip<>'MI'
	union all
	select DISTINCT data from deleted where tip<>'MI'
	exec validLunaInchisaConta

	/** Validare gestiune si/sau marca (daca se lucreaza cu proprietatea corespunzatoare) */
	if UPDATE(gestiune) OR UPDATE(gestiune_primitoare)
	begin
		declare 
			@ObInvPeLocM int, @ObInvPeGestiuni int
		exec luare_date_par 'GE','FOLLOCM', @ObInvPeLocM output, 0, ''
		exec luare_date_par 'GE','FOLGEST', @ObInvPeGestiuni output, 0, ''

		create table #gestiuni (cod varchar(20), primitoare bit, data datetime)
		create table #marci (marca varchar(20), data datetime)

		insert into #gestiuni (cod, primitoare, data)
		select
			gestiune, 0, data
		from inserted where subunitate<>'intrastat' and tip NOT IN ('PF','AF','CI') and Tip_miscare in ('I','E')
		UNION ALL
		select
			gestiune_primitoare, 1, data
		from inserted where subunitate<>'intrastat' and tip='TE'

		exec validGestiune


		insert into #marci(marca,data)
		select 
			gestiune, data
		from inserted where subunitate<>'intrastat' and tip in ('PF','AF','CI') and @ObInvPeLocM = 0 and @ObInvPeGestiuni = 0
		union all
		select
			gestiune_primitoare, data
		from INSERTED where subunitate<>'intrastat' and tip in ('PF','DF') and @ObInvPeLocM = 0 and @ObInvPeGestiuni = 0
				
		exec validMarca
	end

	/* validare indicator bugetar */ 
	if exists (select 1 from sysobjects where [type]='P' and [name]='validIndicatorBugetar') 
		and exists (select 1 from par where tip_parametru='GE' and parametru='BUGETARI' and Val_logica=1)
	Begin
		select DISTINCT detalii.value('(/row/@indicator)[1]','varchar(20)') indbug
		into #indbug 
		from inserted
			where isnull(detalii.value('(/row/@indicator)[1]','varchar(20)'),'')<>''
		exec validIndicatorBugetar
	End

	/** Validare document definitiv varianta noua, este descrisa pe Docs functionarea cu acest tip de validare doc. definitiv  */
	IF EXISTS (select 1	from 
		(select stare,tip, numar, data,RANK() over (PARTITION by tip, numar, data order BY data_operatii desc, idJurnal desc) rn  from JurnalDocumente) JD JOIN StariDocumente sd on sd.TipDocument=jd.tip and sd.stare=jd.stare JOIN 
		(select * from INSERTED union all select * from deleted ) ins on ins.Subunitate='1' and ins.tip=jd.tip and ins.numar=jd.numar and ins.data=JD.data and jd.rn=1 and sd.modificabil=0)
			raiserror('N:Documentul este intr-o stare care nu permite modificarea!',16,1)

	/** LEGACY- tratare din vechiul si batranul docdefinitiv a la Mircea */
	Declare 
		@lDrepModif int, @documente varchar(1000), @msgErr varchar(1000), @se_lucreaza_docdef bit
	
	/* Daca se lucreaza cu documente definitive, parametrul DOCDEF */
	select @se_lucreaza_docdef= val_logica from par where tip_parametru='GE' and Parametru='DOCDEF'
	IF ISNULL(@se_lucreaza_docdef,0)=1
	begin
		set @documente=''

		set @lDrepModif = (case 
			when isnull((Select val_numerica from par where tip_parametru = 'MP' and parametru = convert(char(8),abs(convert(int,host_id())))),0)<>0 then isnull((Select val_numerica from par where tip_parametru = 'MP' and parametru = convert(char(8),abs(convert(int,host_id())))),0) 
			when isnull((Select val_numerica from par where tip_parametru = 'MF' and parametru = convert(char(8),abs(convert(int,host_id())))),0)<>0 then isnull((Select val_numerica from par where tip_parametru = 'MF' and parametru = convert(char(8),abs(convert(int,host_id())))),0)
			else isnull((Select max(convert(int, val_logica)) from par where tip_parametru='DD' and parametru = convert(char(8),abs(convert(int,host_id())))),0) end)

		if left(cast(CONTEXT_INFO() as varchar),22)='modificaredocdefinitiv'
			set @lDrepModif=1
		if left(cast(CONTEXT_INFO() as varchar),19)='anularedocdefinitiv'
			set @lDrepModif=1	
		if left(cast(CONTEXT_INFO() as varchar),17)='specificebugetari'--lucru prin 482 cu doc definitive,scriere indicator bugetar pe doc definitive
			set @lDrepModif=1		
		if left(cast(CONTEXT_INFO() as varchar),24)='modificaredocdefinitivMF'
			set @lDrepModif=2
		if left(cast(CONTEXT_INFO() as varchar),24)='modificaredocdefinitivMP'
			set @lDrepModif=4

		select @documente=
			(case when @documente='' then d.tip+rtrim(d.numar)+'-'+convert(char(10),d.data,103) else 
				@documente+','+d.tip+rtrim(d.numar)+'-'+convert(char(10),d.data,103) end) 
				from deleted d 
			left outer join inserted i on d.subunitate=i.subunitate and d.tip=i.tip and d.numar=i.numar and d.data=i.data where d.stare in (2,6,7) 
			and not (d.stare=2 and isnull(i.stare, 0)=6) -- stornarea documentelor definitive
			and not (d.stare=7 and isnull(i.stare, 0)=3) -- trecerea din stare validat inapoi in stare Operat
			and (d.jurnal='MPX' and @lDrepModif<>4 or d.jurnal='MFX' and @lDrepModif<>2 or d.jurnal<>'MFX' and d.jurnal<>'MPX' and @lDrepModif<>1) 
	
		if @documente<>''
		begin
			set @msgErr='Violare integritate date. Incercare de modificare document definitiv'+char(13)+left(@documente,900)
			RAISERROR (@msgErr, 16, 1)
		end
	end

	/*	Apelare procedura specifica de validare, daca exista. */
	if exists (select 1 from sysobjects where [type]='P' and [name]='validPozdocSP') 
	Begin
		select * into #validPozdocSP 
		from inserted where tip in ('RM','RS','RP','AP','AS')
		exec validPozdocSP
	end
end try
begin catch	
	set @mesaj = ERROR_MESSAGE() +' (tr_ValidPozdoc)'
	raiserror(@mesaj, 16, 1)
end catch

GO
EXECUTE sp_settriggerorder @triggername = N'[dbo].[tr_ValidPozdoc]', @order = N'last', @stmttype = N'insert';


GO
-- pentru depozit fara pret mediu
create trigger docstoc on pozdoc for insert,update,delete as
begin try
-------------	din tabela par (parametri trimis de Magic):
	--[FW OR FV],DL,FQ,HU,HT,[IF (FR=1,'=','>')],CW
	declare 
		@timbruVaccize int, @stcust35 int, @stcust8 int, @mediup_l int, @medpexfol int, @urmcant2 int, @gestexceptiemediup_l int, @l_stocuri_codgestiune int, 
		@l_stocuri_locatie int, @gestexceptiemediup int, @prestte int  
	set @timbruVaccize=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='TIMBRULIT'),0)
		if (@timbruVaccize=0) set @timbruVaccize=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='ACCIZE'),0)
	set @stcust35=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='STCUST35'),0)
	set @stcust8=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='STCUST8'),0)
	set @urmcant2=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='URMCANT2'),0)
	set @gestexceptiemediup_l=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='MEDIUP'),0)
	set @l_stocuri_codgestiune=isnull((select top 1 syscolumns.length from syscolumns,sysobjects where sysobjects.name='stocuri' and 
											sysobjects.id=syscolumns.id and syscolumns.name='cod_gestiune'),0)
	set @l_stocuri_locatie=isnull((select top 1 syscolumns.length from syscolumns,sysobjects where sysobjects.name='stocuri' and 
											sysobjects.id=syscolumns.id and syscolumns.name='locatie'),0)
	set @gestexceptiemediup=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='MEDIUP'),0)
	set @prestte=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='PRESTTE'),0)
	-- LuciM: am unificat, deoarece expresia originala era (@mediup_l=0 or @medpexfol=1)
	set @mediup_l=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='MEDIUP'),0)
	set @medpexfol=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='MEDPEXFOL'),0)
	if @medpexfol=1 -- Ghita: daca execptie folosinta e ca si cum nu s-ar lucra cu pret mediu
		set @mediup_l=0
-------------
declare @GestPM char(200)
exec luare_date_par 'GE', 'MEDIUP', 0, 0, @GestPM output
set @GestPM=','+RTrim(@GestPM)+','

-- intrari/iesiri
 insert into stocuri (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1,idIntrareFirma,idIntrare)
	select a.subunitate,c.tip_gestiune,left(a.gestiune,@l_stocuri_codgestiune),a.cod,min(a.data),a.cod_intrare,max(a.pret_de_stoc),0,0,0,'01/01/1901',0,
	max(a.cont_de_stoc),max(a.data_expirarii),0,max(case when a.tip='AI' and a.discount=1 then 1 else 0 end),
	max(a.tva_neexigibil),max(case when c.tip_gestiune='A' and tip_miscare='I' then a.pret_cu_amanuntul 
	when c.tip_gestiune='A' and tip_miscare='E' then a.pret_amanunt_predator else a.accize_cumparare end),
	'',isnull(max(a.pret_amanunt_predator),0),'','','','',max(coalesce(nullif(a.lot, ''), nullif(s.lot, ''), '')),0,0,0,0,0,0,'','01/01/1901',max(a.idPozDoc),max(a.idPozDoc)
	from inserted a
	inner join gestiuni c on a.Subunitate=c.Subunitate and a.Gestiune=c.Cod_gestiune
	left outer join stocuri s on s.subunitate=a.subunitate and s.tip_gestiune=c.tip_gestiune and s.cod_gestiune=left(a.gestiune,@l_stocuri_codgestiune) and s.cod_intrare=a.cod_intrare and s.cod=a.cod
	where (@gestexceptiemediup_l=0 or 
			(@gestexceptiemediup=1 and charindex(','+rtrim(a.gestiune)+',',@GestPM)=0 or @gestexceptiemediup<>1 and charindex(','+rtrim(a.gestiune)+',',@GestPM)>0)
			or c.tip_gestiune='A') and a.tip not in ('PF','CI','AF')
		and c.tip_gestiune not in ('V','I')
		and a.tip_miscare in ('I','E') and s.Cod_intrare is null 
	group by a.subunitate,c.tip_gestiune,left(a.gestiune,@l_stocuri_codgestiune),a.cod,a.cod_intrare
 -- intrari TI
 insert into stocuri 
	(Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1,idIntrareFirma,idIntrare)
	select a.subunitate,c.tip_gestiune,left(a.gestiune_primitoare,@l_stocuri_codgestiune),a.cod,min(a.data),
	(case when a.grupa='' then a.cod_intrare else a.grupa end),max(a.pret_de_stoc),0,0,0,
	max(a.data),0,max(a.cont_corespondent),max(a.data_expirarii),0,max(case when a.discount=1 or
	left(a.cont_de_stoc,3)='408' then 1 else 0 end),max(a.tva_neexigibil),max(a.pret_cu_amanuntul),'',
	isnull(max(a.pret_amanunt_predator),0),'','','','','',0,0,0,0,0,0,'','01/01/1901',max(s.idIntrareFirma),max(a.idPozDoc)
	from inserted a
	inner join gestiuni c on a.subunitate=c.subunitate and a.gestiune_primitoare=c.cod_gestiune and c.tip_gestiune not in ('V','I')
	left outer join stocuri s on a.subunitate=s.subunitate and a.gestiune=s.cod_gestiune and a.cod=s.cod and a.cod_intrare=s.cod_intrare
	where (@gestexceptiemediup_l=0 or 
		(@gestexceptiemediup=1 and charindex(','+rtrim(a.gestiune_primitoare)+',',@GestPM)=0 or @gestexceptiemediup<>1 and charindex(','+rtrim(a.gestiune_primitoare)+',',@GestPM)>0)
				or c.tip_gestiune='A') and a.tip='TE' 
		and not exists (select cod_intrare from stocuri where subunitate=a.subunitate and tip_gestiune=c.tip_gestiune
		and cod_gestiune=left(a.gestiune_primitoare,@l_stocuri_codgestiune)
		and cod_intrare=(case when a.grupa='' then a.cod_intrare else a.grupa end) and cod=a.cod)
	group by a.subunitate,c.tip_gestiune,left(a.gestiune_primitoare,@l_stocuri_codgestiune),a.cod,
	(case when a.grupa='' then a.cod_intrare else a.grupa end)
-- folosinta
insert into stocuri (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1,idIntrareFirma,idIntrare)
	select a.subunitate,'F',left(a.gestiune,@l_stocuri_codgestiune),a.cod,max(a.data),a.cod_intrare,max(a.pret_de_stoc),0,0,0,max(a.data),0,
	max(a.cont_de_stoc),max(a.data_expirarii),0,0,0,0,max(locatie),0, '', '', '', '', max(isnull(a.lot, '')), 0, 0, 0, 0, 0, 0, '', '01/01/1901',max(a.idPozDoc),max(a.idPozDoc)
	from inserted a 
	where a.tip in ('PF','CI','AF') and not exists (select cod_intrare from stocuri where subunitate=a.subunitate
		and tip_gestiune='F' and cod_gestiune=left(a.gestiune,@l_stocuri_codgestiune) and cod=a.cod and cod_intrare=a.cod_intrare)
	group by a.subunitate,left(a.gestiune,@l_stocuri_codgestiune),a.cod,a.cod_intrare
-- intrari folosinta pe marca_primitoare
insert into stocuri (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1,idIntrareFirma,idIntrare)
	select a.subunitate,'F',left(a.gestiune_primitoare,@l_stocuri_codgestiune),a.cod,max(a.data),(case when a.grupa<>'' then a.grupa else a.cod_intrare end),max(a.pret_de_stoc),0,0,0,
	max(a.data),0,max(a.cont_corespondent),max(a.data_expirarii),0,0,0,0,max(a.locatie),0, '', '', '', '', max(coalesce(nullif(a.lot, ''), nullif(s.lot, ''), '')), 0, 0, 0, 0, 0, 0, '', '01/01/1901',max(a.idIntrareFirma),max(a.idPozDoc)
	from inserted a 
	left outer join stocuri s on a.subunitate=s.subunitate and s.Tip_gestiune='F' and a.gestiune=s.cod_gestiune and a.cod=s.cod and a.cod_intrare=s.cod_intrare
	where a.tip in ('DF','PF')
		and not exists (select cod_intrare from stocuri where subunitate=a.subunitate and tip_gestiune='F'
			and cod_gestiune=left(a.gestiune_primitoare,@l_stocuri_codgestiune) and cod_intrare=(case when a.grupa<>'' then a.grupa else a.cod_intrare end) and cod=a.cod)
	group by a.subunitate,left(a.gestiune_primitoare,@l_stocuri_codgestiune),a.cod,(case when a.grupa<>'' then a.grupa else a.cod_intrare end)
-- custodie pe terti
insert into stocuri (Subunitate,Tip_gestiune,Cod_gestiune,Cod,Data,Cod_intrare,Pret,Stoc_initial,Intrari,Iesiri,Data_ultimei_iesiri,
	Stoc,Cont,Data_expirarii,Stoc_ce_se_calculeaza,Are_documente_in_perioada,TVA_neexigibil,Pret_cu_amanuntul,Locatie,Pret_vanzare,
	Loc_de_munca,Comanda,Contract,Furnizor,Lot,Stoc_initial_UM2,Intrari_UM2,Iesiri_UM2,Stoc_UM2,Stoc2_ce_se_calculeaza,Val1,Alfa1,Data1)
	select a.subunitate,'T',left(a.tert,@l_stocuri_codgestiune),a.cod,max(a.data),a.cod_intrare,max(a.pret_de_stoc),0,0,0,max(a.data),
	0,max(a.cont_corespondent),max(a.data_expirarii),0,0,max(a.tva_neexigibil),max(a.pret_cu_amanuntul),max(locatie),
	isnull(max(a.pret_amanunt_predator),0), '', '', '', '', '', 0, 0, 0, 0, 0, 0, '', '01/01/1901'
	from inserted a, gestiuni b 
	where a.tip in ('AP','AI') and (@stcust35=1 and left(a.cont_corespondent,2)='35' or @stcust8=1 and left(a.cont_corespondent,1)='8')
	and a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and b.tip_gestiune not in ('V', 'I')
	and not exists (select cod_intrare from stocuri where subunitate=a.subunitate and tip_gestiune='T' and cod_gestiune=left(a.tert,@l_stocuri_codgestiune)
	and cod_intrare=a.cod_intrare and cod=a.cod) and a.tip_miscare in ('I','E')
	group by a.subunitate,left(a.tert,@l_stocuri_codgestiune),a.cod,a.cod_intrare

declare @intrari float,@iesiri float,@int2 float,@ies2 float,@pret float,@pretam float,@TVAn float,@pretv float
declare @csub char(9),@ddat datetime,@cgest char(20),@ccod char(20),@ccodi char(13),@npret float,@npretam float,@nTVAn float,@ddataexp datetime,
	@ncant float,@ncant2 float,@tipm char(1),@tipg char(1),@loc char(30),@npretv float,@semn int,@intrare int,@ccontstoc varchar(40),@locm char(9),@com char(40),
	@cntr char(20),@furn char(13),@lot char(20)
declare @gsub char(9),@gtipg char(1),@ggest char(20),@gcod char(20),@gcodi char(13),@gloc char(30),@gfetch int,@gctstoc varchar(40),@gdata datetime,@ggdat datetime,
	@ddataulties datetime,@gdataexp datetime,@glocm char(9),@gcom char(40),@gcntr char(20),@gfurn char(13),@glot char(20),@tip varchar(2),@numar varchar(20),@numar_pozitie int

declare @pretE float,@contE varchar(40)-->variabile necesare verificare necorelatii iesiri
declare @crsDocStoc cursor
set @crsDocStoc = cursor local fast_forward for
select a.subunitate as sub,a.tip as tip,a.numar as numar,a.numar_pozitie as numar_pozitie, c.tip_gestiune,data,gestiune,cod,cod_intrare,pret_de_stoc,
	(case when @timbruVaccize=1 then accize_cumparare else (case when tip_miscare='E' then pret_amanunt_predator else pret_cu_amanuntul end) end),cantitate,
	ISNULL(a.detalii.value('(/*/@_cantitate2)[1]','float'),(case when tip='RM' and numar_DVI<>'' then accize_datorate else suprataxe_vama end)),tip_miscare,locatie,pret_amanunt_predator,TVA_neexigibil,1 as semn,
	data_expirarii,a.cont_de_stoc,'',comanda,(case when tip='TE' then factura when tip in ('AP','AC','PP') then contract else '' end),
	(case tip when 'RM' then tert when 'AI' then cont_venituri else '' end),(case when tip in ('RM','PP','AI') and isnull(lot,'')<>'' then isnull(lot,'') when tip='RM' then cont_corespondent when tip in ('PP','AI') then grupa else '' end)
from inserted a,gestiuni c where a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and (@gestexceptiemediup_l=0 or 
	(@gestexceptiemediup=1 and charindex(','+rtrim(gestiune)+',',@GestPM)=0 or @gestexceptiemediup<>1 and charindex(','+rtrim(gestiune)+',',@GestPM)>0) 
		or c.tip_gestiune='A') and tip not in ('PF','CI','AF') and tip_miscare in ('I','E') and c.tip_gestiune not in ('V','I')
union all
select a.subunitate,a.tip,a.numar as numar,a.numar_pozitie as numar_pozitie,c.tip_gestiune,a.data,gestiune_primitoare,a.cod,(case when grupa<>'' then grupa else a.cod_intrare end),
	(case when @prestte=1 and accize_datorate <> 0 then accize_datorate else pret_de_stoc end),a.pret_cu_amanuntul,cantitate,ISNULL(a.detalii.value('(/*/@_cantitate2)[1]','float'),suprataxe_vama),'I',a.locatie,
	pret_amanunt_predator,a.TVA_neexigibil,1,a.data_expirarii,a.cont_corespondent,'',a.comanda,factura,isnull(s.furnizor,''),isnull(s.lot,'')
from inserted a
inner join gestiuni c on a.subunitate=c.subunitate and a.gestiune_primitoare=c.cod_gestiune
inner join gestiuni b on a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune
left outer join stocuri s on a.subunitate=s.subunitate and s.tip_gestiune=b.tip_gestiune and s.cod_gestiune=a.gestiune and s.cod=a.cod and s.cod_intrare=a.cod_intrare
where a.tip='TE' and (@gestexceptiemediup_l=0 or 
	(@gestexceptiemediup=1 and charindex(','+rtrim(gestiune_primitoare)+',',@GestPM)=0 or @gestexceptiemediup<>1 and charindex(','+rtrim(gestiune_primitoare)+',',@GestPM)>0)
	or c.tip_gestiune='A') and c.tip_gestiune not in ('V','I')
union all
select subunitate, tip as tip,numar as numar,numar_pozitie as numar_pozitie, 'F' as tipg, data, gestiune, cod, cod_intrare, 
	pret_de_stoc, (case when @timbruVaccize=1 then accize_cumparare else (case when  tip_miscare='E' then pret_amanunt_predator else pret_cu_amanuntul end) end), cantitate, 0, 
	tip_miscare, locatie, pret_amanunt_predator, TVA_neexigibil, 1, data_expirarii, cont_de_stoc,loc_de_munca,comanda,'','',''
from inserted where @mediup_l=0 and tip in ('PF','CI','AF') and tip_miscare in ('I','E')
union all
select subunitate,tip as tip,numar as numar,numar_pozitie as numar_pozitie, 'F',data,gestiune_primitoare,cod,(case when grupa<>'' then grupa else cod_intrare end),
	(case when tip='DF' and procent_vama<>0 then round(pret_de_stoc*(1-procent_vama/100),4) else pret_de_stoc end), pret_cu_amanuntul,cantitate,0,
	'I',locatie,pret_amanunt_predator,TVA_neexigibil,1,data_expirarii, cont_corespondent,isnull(detalii.value('(/*/@lmprim)[1]','varchar(20)'),loc_de_munca),comanda,'','',''
from inserted where @mediup_l=0 and tip in ('DF','PF')
union all
select a.subunitate,a.tip as tip,a.numar as numar,a.numar_pozitie as numar_pozitie, 'T',data,tert,cod,cod_intrare,pret_de_stoc,0,cantitate,0, 
	(case when tip_miscare='E' then 'I' else 'E' end), locatie, 0, 0, 1, data_expirarii, a.cont_corespondent, loc_de_munca, comanda,'','',''
from inserted a, gestiuni b where tip in ('AP','AI') and tip_miscare<>'V' and (@stcust35=1 and left(cont_corespondent,2)='35' or @stcust8=1 and left(cont_corespondent,1)='8') 
	and a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and b.tip_gestiune not in ('V', 'I')
union all
select a.subunitate,a.tip,a.numar as numar,a.numar_pozitie as numar_pozitie,c.tip_gestiune,data,gestiune,cod,cod_intrare,pret_de_stoc,
	(case when @timbruVaccize=1 then accize_cumparare else (case when tip_miscare='E' then pret_amanunt_predator else pret_cu_amanuntul end) end),cantitate,
	ISNULL(a.detalii.value('(/*/@_cantitate2)[1]','float'),(case when tip='RM' and numar_DVI<>'' then accize_datorate else suprataxe_vama end)),tip_miscare,locatie,pret_amanunt_predator,TVA_neexigibil,-1,data_expirarii,'','',comanda,
	(case when tip='TE' then factura when tip in ('AP','AC','PP') then contract else '' end),(case tip when 'RM' then tert when 'AI' then cont_venituri else '' end),
	(case when tip in ('RM','PP','AI') and isnull(lot,'')<>'' then isnull(lot,'') when tip='RM' then cont_corespondent when tip in ('PP','AI') then grupa else '' end)
from deleted a,gestiuni c where a.subunitate=c.subunitate and a.gestiune=c.cod_gestiune and (@gestexceptiemediup_l=0 or 
	(@gestexceptiemediup=1 and charindex(','+rtrim(gestiune)+',',@GestPM)=0 or @gestexceptiemediup<>1 and charindex(','+rtrim(gestiune)+',',@GestPM)>0)
	or c.tip_gestiune='A') and tip not in ('PF','CI','AF') and tip_miscare in ('I','E') and c.tip_gestiune not in ('V','I')
union all
select a.subunitate,a.tip,a.numar as numar,a.numar_pozitie as numar_pozitie,c.tip_gestiune,data,gestiune_primitoare,cod,(case when grupa<>'' then grupa else cod_intrare end),pret_de_stoc,pret_cu_amanuntul,cantitate,ISNULL(a.detalii.value('(/*/@_cantitate2)[1]','float'),suprataxe_vama),'I',
	locatie,pret_amanunt_predator,TVA_neexigibil,-1,data_expirarii,'','',comanda,factura,'',''
from deleted a,gestiuni c where a.subunitate=c.subunitate and a.gestiune_primitoare=c.cod_gestiune and (@gestexceptiemediup_l=0 or
	(@gestexceptiemediup=1 and charindex(','+rtrim(gestiune_primitoare)+',',@GestPM)=0 or @gestexceptiemediup<>1 and charindex(','+rtrim(gestiune_primitoare)+',',@GestPM)>0)
	or c.tip_gestiune='A') and tip='TE' and c.tip_gestiune not in ('V','I')
union all
select subunitate, tip as tip,numar as numar,numar_pozitie as numar_pozitie, 'F' as tipg, data, gestiune, cod, cod_intrare, 
	pret_de_stoc, (case when @timbruVaccize=1 then accize_cumparare else (case when  tip_miscare='E' then pret_amanunt_predator else pret_cu_amanuntul end) end), cantitate, 0, 
	tip_miscare, locatie, pret_amanunt_predator, TVA_neexigibil, -1, data_expirarii, cont_de_stoc,loc_de_munca,comanda,'','',''
from deleted where @mediup_l=0 and tip in ('PF','CI','AF') and tip_miscare in ('I','E')
union all
select subunitate,tip as tip,numar as numar,numar_pozitie as numar_pozitie, 'F',data,gestiune_primitoare,cod,(case when grupa<>'' then grupa else cod_intrare end),
	(case when tip='DF' and procent_vama<>0 then round(pret_de_stoc*(1-procent_vama/100),4) else pret_de_stoc end), pret_cu_amanuntul,cantitate,0,
	'I',locatie,pret_amanunt_predator,TVA_neexigibil,-1,data_expirarii, cont_corespondent,loc_de_munca,comanda,'','',''
from deleted where @mediup_l=0 and tip in ('DF','PF')
union all
select a.subunitate,a.tip as tip,a.numar as numar,a.numar_pozitie as numar_pozitie, 'T',data,tert,cod,cod_intrare,pret_de_stoc,0,cantitate,0, 
	(case when tip_miscare='E' then 'I' else 'E' end), locatie, 0, 0, -1, data_expirarii, a.cont_corespondent, loc_de_munca, comanda,'','',''
from deleted a, gestiuni b where tip in ('AP','AI') and tip_miscare<>'V' and (@stcust35=1 and left(cont_corespondent,2)='35' or @stcust8=1 and left(cont_corespondent,1)='8') 
	and a.subunitate=b.subunitate and a.gestiune=b.cod_gestiune and b.tip_gestiune not in ('V', 'I')
order by sub,gestiune,cod,cod_intrare,semn

declare
	@uNumar varchar(20), @uTip varchar(2), @uData datetime, @uNumarPozitie int, @uTipM char(1), @uCant float , @uCant2 float 
open @crsDocStoc
fetch next from @crsDocStoc into @csub,@tip,@numar,@numar_pozitie,@tipg,@ddat,@cgest,@ccod,@ccodi,@npret,@npretam,@ncant,@ncant2,@tipm,@loc,@npretv,@nTVAn,@semn,@ddataexp,@ccontstoc,@locm,@com,@cntr,@furn,@lot
set @gsub=@csub
set @gtipg=@tipg
set @ggest=@cgest
set @gcod=@ccod
set @gcodi=@ccodi
set @ggdat=@ddat
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Intrari=0
	set @Iesiri=0
	set @int2=0
	set @ies2=0
	set @pret=@npret
	set @pretam=@npretam
	set @TVAn=@nTVAn
	set @gloc=''
	set @glocm=''
	set @gcom=''
	set @gcntr=''
	set @gfurn=''
	set @glot=''
	set @pretv=@npretv
	set @intrare=0
	set @gctstoc=''
	set @ddataulties='01/01/1901'
	set @gdata='01/01/1901'
	set @gdataexp='01/01/1901'
	set @ggdat=@ddat
	while @gsub=@csub and @gtipg=@tipg and @ggest=@cgest and @gcod=@ccod and @gcodi=@ccodi
		and @gfetch=0
	begin
		if @tipm='I' and @semn=1 set @intrare=1
		if (@gdata='01/01/1901' or @ddat<@gdata) and @intrare=1 set @gdata=@ddat
		if (@gdataexp='01/01/1901' or @ddataexp<@gdataexp) and @intrare=1 set @gdataexp=@ddataexp
		if @tipm='I' set @intrari=@intrari+@semn*@ncant
		if @tipm='E' set @iesiri=@iesiri+@semn*@ncant
		if @urmcant2=1 
		begin
			if @tipm='I' set @int2=@int2+@semn*@ncant2
			if @tipm='E' set @ies2=@ies2+@semn*@ncant2
		end
		set @pret=@npret
		set @pretam=@npretam
		set @TVAn=@nTVAn
		set @ggdat=@ddat
		
		--necesare (?) pentru validari documente de iesire
		if @tipm='E' --and @semn=1
		begin
			--set @pretE=@npret
			set @contE=@ccontstoc
		end	
		
		if @gloc='' and @intrare=1 and @ncant>0 set @gloc=@loc
		if @tipg='F' and @glocm='' and @tipm='I' and @semn=1 and @ncant>0 set @glocm=@locm
		if @gcom='' and @intrare=1 and @ncant>0 set @gcom=@com
		if @gcntr='' and @intrare=1 and @ncant>0 set @gcntr=@cntr
		if @gfurn='' and @intrare=1 and @ncant>0 set @gfurn=@furn
		if @glot='' and @intrare=1 and @ncant>0 set @glot=@lot
		if @intrare=1 and @ddat<=@gdata set @gctstoc=@ccontstoc
		if @tipm='E' and @semn=1 and @ddataulties<@ddat set @ddataulties=@ddat
		if @intrare=1 set @pretv=@npretv
		
		select
			@uNumar=@numar, @uData =@ddat, @uNumarPozitie=@numar_pozitie, @uTip=@tip, @uTipM=@tipm, @uCant=@ncant, @uCant2=@ncant2

		fetch next from @crsDocStoc into @csub,@tip,@numar,@numar_pozitie,@tipg,@ddat,@cgest,@ccod,@ccodi,@npret,@npretam,
			@ncant,@ncant2,@tipm,@loc,@npretv,@nTVAn,@semn,@ddataexp,@ccontstoc,@locm,@com,@cntr,@furn,@lot
		set @gfetch=@@fetch_status
	end
	
	--validare stoc negativ
	declare @cod_gestiune varchar(13),@cantitate float,@cantitate2 float
	set @cod_gestiune=left(@ggest,@l_stocuri_codgestiune)
	set @cantitate=@intrari-@iesiri
	set @cantitate2=@int2-@ies2
	if 1=1 or ((SELECT trigger_nestlevel() ) < 2 )
	begin
		if exists (select * from sysobjects where name ='validareStocNegativ')
			EXEC validareStocNegativ @Subunitate=@gsub,@Tip_gestiune=@gtipg,@Cod_gestiune=@cod_gestiune,@Cod=@gcod,
				@Cod_intrare=@gcodi,@Cantitate=@cantitate, 
				@Tip=@uTip,@Numar=@uNumar,@Data=@uData,@numar_pozitie=@uNumarPozitie,@tipm=@uTipM
			if exists (select * from sysobjects where name ='validareStocNegativSP')
				EXEC validareStocNegativSP @Subunitate=@gsub,@Tip_gestiune=@gtipg,@Cod_gestiune=@cod_gestiune,@Cod=@gcod,
				@Cod_intrare=@gcodi,@Cantitate=@cantitate, 
				@Tip=@uTip,@Numar=@uNumar,@Data=@uData,@numar_pozitie=@uNumarPozitie,@tipm=@uTipM	
		end

	--validare/propagare corelatii pret si cont
	if (select count(1) from inserted)>0 and (1=1 or ((SELECT trigger_nestlevel() ) < 2 ))-->se apeleaza numai pentru pozitiile din insert
		--and (UPDATE(pret_de_stoc) or UPDATE(cont_de_stoc) or UPDATE(cont_corespondent) and @tip='TE')
	begin
		if exists (select * from sysobjects where name ='validareNecorelatiiStocuri')
		begin
			declare @pretValidare float, @contValidare varchar(40)-->variabile necesare pentru validare necorelatii
			set @pretValidare= @pret -- (case when @uTipM='I' then @pret else @pretE end )
			set @contValidare= (case when @uTipM='I' then @gctstoc else @contE end )
			exec validareNecorelatiiStocuri @Subunitate=@gsub,@Tip=@uTip,@Numar=@uNumar,@Data=@uData,@numar_pozitie=@uNumarPozitie,
				@Tip_miscare=@uTipM,@Cantitate=@ncant,@Gest=@ggest,@Cod=@gcod,@Cod_intrare=@gcodi,@Tip_gest=@gtipg,
				@Pret_stoc= @pretValidare, @Cont_stoc=@contValidare
			if exists (select * from sysobjects where name ='validareNecorelatiiStocuriSP')
				exec validareNecorelatiiStocuriSP @Subunitate=@gsub,@Tip=@uTip,@Numar=@uNumar,@Data=@uData,@numar_pozitie=@uNumarPozitie,
					@Tip_miscare=@uTipM,@Cantitate=@ncant,@Gest=@ggest,@Cod=@gcod,@Cod_intrare=@gcodi,@Tip_gest=@gtipg,
					@Pret_stoc= @pretValidare, @Cont_stoc=@contValidare,@cantitate2=@uCant2
		end
	end
	
	update stocuri set intrari=intrari+@intrari,iesiri=iesiri+@iesiri,
		stoc=stoc+@intrari-@iesiri,
		intrari_UM2=intrari_UM2+@int2,iesiri_UM2=iesiri_UM2+@ies2,stoc_UM2=stoc_UM2+@int2-@ies2,
		pret=(case when stoc_initial=0 and @intrare=1 then @pret else pret end),
		locatie=(case when @gloc<>'' then left(@gloc,@l_stocuri_locatie) else locatie end),
		loc_de_munca=(case when @glocm<>'' then @glocm else loc_de_munca end),
		comanda=(case when @gcom<>'' then @gcom else comanda end),
		contract=(case when @gcntr<>'' then @gcntr else contract end),
		furnizor=(case when @gfurn<>'' then @gfurn else furnizor end),
		lot=(case when @glot<>'' then @glot else lot end),
		data_ultimei_iesiri=(case when data_ultimei_iesiri>@ddataulties then data_ultimei_iesiri else @ddataulties end),
		pret_cu_amanuntul=(case when stoc_initial=0 and @intrare=1 then @pretam else pret_cu_amanuntul end),
		TVA_neexigibil=(case when stoc_initial=0 and @intrare=1 then @TVAn else TVA_neexigibil end),
		pret_vanzare=isnull((case when stoc_initial=0 and @intrare=1 then @pretv else pret_vanzare end),0),
		data_expirarii=(case when @gdataexp>'01/01/1901' and @gdataexp>data_expirarii then @gdataexp else data_expirarii end),
		cont=(case when @gctstoc<>'' and @gdata<=data then @gctstoc else cont end),
		data=(case when @intrare=1 and @intrari>0 /*and @ggdat<data*/ then @ggdat else data end)
	where subunitate=@gsub and tip_gestiune=@gtipg and cod_gestiune=left(@ggest,@l_stocuri_codgestiune) and cod=@gcod and cod_intrare=@gcodi
		
	delete stocuri
		where abs(Stoc)<0.001 and abs(intrari)<0.001 and abs(Iesiri)<0.001 AND subunitate=@gsub and tip_gestiune=@gtipg and cod_gestiune=left(@ggest,@l_stocuri_codgestiune) and cod=@gcod and cod_intrare=@gcodi 
			/*Nu trebuie pusa aceasta conditie. Daca modific la o pozitie codul de intrare, stocul ei va ramane perpetuu chiar daca este cu zero*/
			--and not exists (select 1 from pozdoc where pozdoc.idPozdoc=stocuri.idIntrare)
	set @gsub=@csub
	set @gtipg=@tipg
	set @ggest=@cgest
	set @gcod=@ccod
	set @gcodi=@ccodi
	set @ggdat=@ddat
	end
		
end try
begin catch
	IF @@TRANCOUNT>0
		ROLLBACK TRANSACTION
	declare @mesaj varchar(max)
	set @mesaj = ERROR_MESSAGE() +' (docstoc)'
	raiserror(@mesaj, 11, 1)
end catch

GO
--***
create trigger docMfix on pozdoc for update, insert/*, delete*/ as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @ifn int
	set @ifn=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='IFN'),0)
-------------
/*delete from Mfix 
      where subunitate+numar_de_inventar in (select a.subunitate+a.cod_intrare from deleted a, nomencl b 
      where a.tip_miscare='I'  and a.cod=b.cod and b.tip='F')*/
	insert into Mfix (Subunitate, Numar_de_inventar, Denumire, Serie, Tip_amortizare, Cod_de_clasificare, Data_punerii_in_functiune)
	select a.subunitate, a.cod_intrare, left(b.denumire,(select y.length from syscolumns y, sysobjects z where y.id=z.id and y.name='denumire' and z.name='mfix')), left(a.loc_de_munca,(select w.length from syscolumns w, sysobjects x where w.id=x.id and w.name='serie' and x.name='mfix')), (case when b.stoc_limita=0 then '2' else left(convert(char(5),b.stoc_limita),1) end), b.furnizor, a.data 
	from inserted a, nomencl b 
	WHERE not (@ifn=1 and left(a.cont_de_stoc, 2)='43')
	and left(a.cont_de_stoc,2)<>'23' and a.tip_miscare='I' and a.cod=b.cod and b.tip='F' and a.cod_intrare not in (select numar_de_inventar from Mfix where subunitate=a.subunitate) 
end

GO
--***
create trigger realizpozprod on dbo.pozdoc for insert, update, delete not for replication as
begin
declare @cSb char(9), @cComProd char(20), @cCod char(20), @nCantPredare float, 
	@cComLivr char(20), @dLivr datetime, @cBenef char(13), @nCantComandata float, @nCantRealizata float, 
	@nCantDescarc float
set @cSb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
-- cantitate PP => realizata pozprod
declare tmpcmdpred cursor for
select isnull(i.comanda, d.comanda) as comanda, isnull(i.cod, d.cod) as cod, 
sum(isnull(i.cantitate, 0))-sum(isnull(d.cantitate, 0)) as diferenta 
from inserted i full outer join deleted d 
	on i.subunitate=d.subunitate and i.tip=d.tip and i.numar=d.numar and i.data=d.data and i.numar_pozitie=d.numar_pozitie 
		and i.cod=d.cod and i.comanda=d.comanda
where isnull(i.subunitate, d.subunitate)=@cSb and isnull(i.tip, d.tip)='PP' and isnull(i.comanda, d.comanda)<>''
group by isnull(i.comanda, d.comanda), isnull(i.cod, d.cod)
having abs(sum(isnull(i.cantitate, 0))-sum(isnull(d.cantitate, 0))) >= 0.001
open tmpcmdpred
fetch next from tmpcmdpred into @cComProd, @cCod, @nCantPredare
while @@fetch_status = 0
begin
	declare tmppozprod cursor for
	select comanda_livrare, data_comenzii, beneficiar, cantitate_comandata, cantitate_realizata
	from pozprod 
	where comanda=@cComProd and cod=@cCod
	order by datediff(day, getdate(), data_comenzii) * sign(@nCantPredare), 
		(case when sign(@nCantPredare)>0 then comanda_livrare else '' end) ASC,
		(case when sign(@nCantPredare)<0 then comanda_livrare else '' end) DESC
	open tmppozprod
	fetch next from tmppozprod into @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantRealizata
	while @@fetch_status = 0 and abs(@nCantPredare) >= 0.001
	begin
		if @nCantPredare > 0 
			set @nCantDescarc = (case when @nCantComandata - @nCantRealizata < @nCantPredare then @nCantComandata - @nCantRealizata else @nCantPredare end)
		else 
			set @nCantDescarc = (case when @nCantRealizata < abs(@nCantPredare) then (-1) * @nCantRealizata else @nCantPredare end)
		
		set @nCantPredare = @nCantPredare - @nCantDescarc
		update pozprod set cantitate_realizata = cantitate_realizata + @nCantDescarc
		where comanda=@cComProd and cod=@cCod and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
		fetch next from tmppozprod into @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantRealizata
	end
	close tmppozprod
	deallocate tmppozprod
	fetch next from tmpcmdpred into @cComProd, @cCod, @nCantPredare
end
close tmpcmdpred
deallocate tmpcmdpred

end

GO
create trigger tr_docdefinitiv on dbo.pozdoc for insert,update,delete NOT FOR REPLICATION as
begin try
	declare 
		@mesaj varchar(max),  @stare_doc int

		select TOP 1
			@stare_doc= jd.stare
		from JurnalDocumente JD
		JOIN (select * from INSERTED union all select * from deleted )ins on ins.Subunitate='1' and ins.tip=jd.tip and ins.numar=jd.numar and ins.data=JD.data
		order by jd.data_operatii desc
		
		if @stare_doc=1
			raiserror('Documentul este definitiv: nu permite modificarea!(tr_docdefinitiv)',16,1)

end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
--***
CREATE trigger pozdocsterg on pozdoc for update, delete NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspd
select host_id(),host_name (), @Aplicatia, getdate(), @Utilizator, 
data_operarii, ora_operarii,
Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare,
Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Cod_intrare, Cont_de_stoc, Cont_corespondent, 
TVA_neexigibil,	Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, 
Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
Accize_cumparare, Accize_datorate, Contract, Jurnal
from deleted

GO
--***
create  trigger yso_tr_ValidPozdoc on pozdoc for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN
-- Ghita, 27.04.2012: acest trigger ar trebui sa se raporteze doar la cataloage, nu si la tabelele sinteza (acestea se actualizeaza prin triggere si nu se stie daca inainte sau dupa verificare)
begin try	
	declare @grupa varchar(13), @cod varchar(20), @discmax float, @msgerr varchar(250), @discount float, @dencod varchar(250)

--/*sp
	if update(discount) --Verificam discounturile
	begin
		select top 1 @cod=i.Cod, @discount=i.discount, @grupa=n.Grupa, @dencod=n.Denumire
		from inserted i 
			LEFT JOIN doc d on d.Subunitate=i.Subunitate and d.Tip=i.Tip and d.Numar=i.Numar and d.Data=i.Data
			left join nomencl n on i.cod=n.cod 
		where i.Subunitate='1' and i.Tip in ('AP','AC','AS') 
			and i.Discount>--/*dbo.valoare_minima(
			isnull((select top 1 CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',','')) else null end 
				from proprietati pr where pr.Valoare<>'' and pr.Cod<>'' and tip='GRUPA' and cod_proprietate='DISCMAX' 
					and n.Grupa like RTRIM(pr.Cod)+'%'
				order by pr.cod desc, pr.Valoare desc),0.001) --*/
			/*isnull((select top 1 p.Discount 
				from pozcon p where p.Subunitate= '1' AND p.tip= 'BF' AND p.Contract=i.Contract
					AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' 
				order by p.Cod desc, p.Discount desc),0.00)*/
		
		if @cod is not null
		begin
			set @msgerr='Eroare operare (pozcon.yso_tr_ValidPozdoc): Discountul de '+rtrim(convert(decimal(7,2),@discount))
				+' depaseste maximul '--de '+rtrim(convert(decimal(7,2),@discmax))
				+' admis pe grupa '+rtrim(@grupa)+' a articolului ('+rtrim(@cod)+') '+RTRIM(@dencod)+'!'
			raiserror(@msgerr,16,1)
		end
	end   	
	
	if exists (select top (1) 1 from inserted i join nomencl n on n.Cod = i.Cod
		where i.Subunitate='1' and i.Tip in ('AP','AC','AS') and n.Tip not in ('R', 'S') and i.Cantitate <= -0.001)
	begin
		declare @potStorna tinyint
		set @potStorna = COALESCE((SELECT TOP (1) val_logica FROM par P WHERE P.Tip_parametru = 'CG' AND P.Parametru = 'POTSTORNA'), 1)
		/*
		select top 1 @cod=i.Cod, @discount=i.discount, @grupa=n.Grupa, @dencod=n.Denumire
		from inserted i 
			LEFT JOIN doc d on d.Subunitate=i.Subunitate and d.Tip=i.Tip and d.Numar=i.Numar and d.Data=i.Data
			left join nomencl n on i.cod=n.cod 
		where i.Subunitate='1' and i.Tip in ('AP','AC','AS') 
			and i.Cantitate <= -0.001
		*/
		if @potStorna = 0
		begin
			set @msgerr='Eroare operare: In acest moment NU se pot efectua stornari! Cereti autorizare de la supervizorul aplicatiei. (pozcon.yso_tr_ValidPozdoc)'
			raiserror(@msgerr,16,1)
		end
	end 	
--sp*/	
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
--***
create trigger docfacav on pozdoc for update,insert,delete as
begin
--avansuri avize/receptii
-------------	din tabela par (parametri trimis de Magic):
	declare @spgenisaVunicarm int, @docpesch_n int, @neexav int, @neexdocff int, @conturidocff varchar(200)
	set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru='SP' and parametru='GENISA'),0)
		if (@spgenisaVunicarm=0) set @spgenisaVunicarm=isnull((select top 1 val_logica from par where tip_parametru='SP' and parametru='UNICARM'),0)
	set @docpesch_n=(case isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DOCPESCH'),0) when 1 then 0 else 1 end)
		if (@docpesch_n=0) set @docpesch_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='DOCPESCH'),0)
		--	sau "val_logica=0 or val_numerica=1" in loc de "@docpesch_n=1" mai jos
	set @neexav=(case isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='NEEXAV'),0) when 1 then 0 else 1 end)
	set @neexdocff=(case isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='NEEXDOCFF'),0) when 1 then 0 else 1 end)
	set @conturidocff=isnull((select top 1 val_alfanumerica from par where tip_parametru='GE' and parametru='NEEXDOCFF'),'408,418')
-------------
insert into facturi select subunitate,max(loc_de_munca),(case when left(tip,1)='A' then 0x46 else 0x54 end),
(case when cod_intrare='' then 'AVANS' else cod_intrare end),tert,max(data_facturii),max(data_scadentei),0,0,0,max(valuta),max(curs),0,0,0,max(cont_de_stoc),0,0,max(comanda),
max(data) from inserted where tip in ('AP','AS','RM','RS') and (case when cod_intrare='' then 'AVANS' else cod_intrare end) not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert and tip=(case when left(inserted.tip,1)='A' then 0x46 else 0x54 end))
and cont_de_stoc in (select cont from conturi where sold_credit=(case when left(tip,1)='A' then 2 else 1 end)) 
group by subunitate,(case when left(tip,1)='A' then 0x46 else 0x54 end),tert,(case when cod_intrare='' then 'AVANS' else cod_intrare end) 

declare @contF varchar(40),@gvaluta char(3),@gcurs float,@glocm char(9),@gcom char(40)
declare @csub char(9),@ctip char(2),@ctert char(13),@cfactura char(20),@semn int,@ccant float,@gcant float,@valuta char(3),
	@curs float,@cont varchar(40),@df datetime,@ds datetime,@locm char(9),@com char(40),@ach float,@achv float,
	@achitat float,@achitatv float
declare @gsub char(9),@gtip char(2),@gtert char(13),@gfactura char(20),@gdf datetime,@gds datetime,@tipf binary,@gfetch int

declare tmp cursor for
select subunitate,tip,tert,(case when cod_intrare='' then 'AVANS' else cod_intrare end) as facturaav,1,valuta,curs,cont_de_stoc,data_facturii,data_scadentei,loc_de_munca,comanda,
-- avize
(case when left(tip,1)='A' then round(convert(decimal(17,5),cantitate*pret_vanzare),2)
-- TVA avans
	+(case when @neexav=0 and charindex(left(Cont_de_stoc,3),@conturidocff)=0 or @neexdocff=0 and charindex(left(Cont_de_stoc,3),@conturidocff)<>0 then 0 else 1 end)
		*(case when procent_vama in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or tip='AS') then 0 else 1 end)*tva_deductibil 
-- receptii
else round(convert(decimal(17,5),cantitate*round(convert(decimal(18,5),pret_valuta*(case when valuta<>'' then curs else 1 end)),5)),2)
-- TVA avans
	+round(convert(decimal(17,5),(case when @neexav=0 and charindex(left(Cont_de_stoc,3),@conturidocff)=0 or @neexdocff=0 and charindex(left(Cont_de_stoc,3),@conturidocff)<>0 then 0 else 1 end)
		*(case when tip='RM' and left(numar_dvi,13)='' and procent_vama=1 then 0 else 1 end)*tva_deductibil),2) end)
+isnull(detalii.value('(/row/@_difcursav)[1]','float'),0) as ach,
-- sume in valuta
(case when valuta<>'' and curs>0 then (case when left(tip,1)='A' then round(convert(decimal(17,5),cantitate*pret_valuta*(1-discount/100)),2)
	+round(convert(decimal(17,5),(case when @neexav=0 and charindex(left(Cont_de_stoc,3),@conturidocff)=0 or @neexdocff=0 and charindex(left(Cont_de_stoc,3),@conturidocff)<>0 then 0 else 1 end)
		*(case when procent_vama in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or tip='AS') then 0 else 1 end)*tva_deductibil/curs),2) 
 else round(convert(decimal(17,5),cantitate*pret_valuta),2)
	+round(convert(decimal(17,5),(case when @neexav=0 and charindex(left(Cont_de_stoc,3),@conturidocff)=0 or @neexdocff=0 and charindex(left(Cont_de_stoc,3),@conturidocff)<>0 then 0 else 1 end)
		*(case when tip='RM' and left(numar_dvi,13)='' and procent_vama=1 then 0 else 1 end)*tva_deductibil/curs),2) end) 
 else 0 end) as achv,Cantitate
from inserted where tip in ('AP','AS','RM','RS') and cont_de_stoc in (select cont from conturi where sold_credit=(case when left(tip,1)='A' then 2 else 1 end)) 
union all
select subunitate,tip,tert,(case when cod_intrare='' then 'AVANS' else cod_intrare end) as facturaav,-1,valuta,curs,cont_de_stoc,data_facturii,data_scadentei,loc_de_munca,comanda,
(case when left(tip,1)='A' then round(convert(decimal(17,5),cantitate*pret_vanzare),2)
 +(case when @neexav=0 and charindex(left(Cont_de_stoc,3),@conturidocff)=0 or @neexdocff=0 and charindex(left(Cont_de_stoc,3),@conturidocff)<>0 then 0 else 1 end)
  *(case when procent_vama in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or tip='AS') then 0 else 1 end)*tva_deductibil 
 else round(convert(decimal(17,5),cantitate*round(convert(decimal(18,5),pret_valuta*(case when valuta<>'' then curs else 1 end)),5)),2)
 +round(convert(decimal(17,5),(case when @neexav=0 and charindex(left(Cont_de_stoc,3),@conturidocff)=0 or @neexdocff=0 and charindex(left(Cont_de_stoc,3),@conturidocff)<>0 then 0 else 1 end)
  *(case when tip='RM' and left(numar_dvi,13)='' and procent_vama=1 then 0 else 1 end)*tva_deductibil),2) end)
+isnull(detalii.value('(/row/@_difcursav)[1]','float'),0) as ach,
(case when valuta<>'' and curs>0 then (case when left(tip,1)='A' then round(convert(decimal(17,5),cantitate*pret_valuta*(1-discount/100)),2)
 +round(convert(decimal(17,5),(case when @neexav=0 and charindex(left(Cont_de_stoc,3),@conturidocff)=0 or @neexdocff=0 and charindex(left(Cont_de_stoc,3),@conturidocff)<>0 then 0 else 1 end)
  *(case when procent_vama in (1,2) and @spgenisaVunicarm=0 and (@docpesch_n=1 or tip='AS') then 0 else 1 end)*tva_deductibil/curs),2) 
 else round(convert(decimal(17,5),cantitate*pret_valuta),2)
  +round(convert(decimal(17,5),(case when @neexav=0 and charindex(left(Cont_de_stoc,3),@conturidocff)=0 or @neexdocff=0 and charindex(left(Cont_de_stoc,3),@conturidocff)<>0 then 0 else 1 end)
   *(case when tip='RM' and left(numar_dvi,13)='' and procent_vama=1 then 0 else 1 end)*tva_deductibil/curs),2) end) 
else 0 end) as achv,Cantitate
from deleted where tip in ('AP','AS','RM','RS') and cont_de_stoc in (select cont from conturi where sold_credit=(case when left(tip,1)='A' then 2 else 1 end)) 
order by subunitate,tip,tert,facturaav

open tmp
fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@valuta,@curs,@cont,@df,@ds,@locm,@com,@ach,@achv,@ccant
set @gsub=@csub
set @gtert=@ctert
set @gfactura=@cfactura
set @gtip=@ctip
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @Achitat=0
set @AchitatV=0
set @ContF=@cont
set @gvaluta=@valuta
set @gcurs=@curs
set @gdf=@df
set @gds=@ds
set @glocm=@locm
set @gcom=@com
set @gcant=@ccant
while @gsub=@csub and @cTip=@gTip and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0
begin
	if @ctip in ('RM','RP','RQ','RS')
	begin		
		set @tipf=0x54
		set @Achitat=@Achitat+@semn*@ach
		if @valuta<>'' 
			set @achitatv=@achitatv+@semn*@achv
	end
	else begin
		set @tipf=0x46
		set @Achitat=@Achitat+@semn*@ach
		if @valuta<>''
			set @achitatv=@achitatv+@semn*@achv
	end
	if @semn=1 set @contF=@cont
	if @semn=1 set @gvaluta=@valuta
	if @semn=1 set @gcurs=@curs
	if @semn=1 set @gdf=@df
	if @semn=1 set @gds=@ds
	if @semn=1 set @glocm=@locm
	if @semn=1 set @gcom=@com
	if @semn=1 set @gcant=@ccant

fetch next from tmp into @csub,@ctip,@ctert,@cfactura,@semn,@valuta,@curs,@cont,@df,@ds,@locm,@com,@ach,@achv,@ccant
set @gfetch=@@fetch_status
end
update facturi set achitat=achitat+@achitat,sold=sold-@achitat,
	valuta='',curs=(case when @gcant>0 then 0 else curs end),	--sa nu modifice cursul daca sunt cantitati negative (acestea provin din stornare avans si nu trebuie sa afecteze cursul din facturi)
	cont_de_tert=@contF,loc_de_munca=@glocm,comanda=@gcom,
	data=(case when data>@gdf then @gdf else data end),data_scadentei=(case when data_scadentei>@gds then @gds else data_scadentei end)
where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura

update facturi set achitat_valuta=achitat_valuta+@achitatv,sold_valuta=sold_valuta-@achitatv,
	valuta=@gvaluta,curs=(case when @gcant>0 then @gcurs else curs end)
from terti where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura
	and facturi.subunitate=terti.subunitate and facturi.tert=terti.tert and terti.tert_extern=1 

set @gtert=@ctert
set @gsub=@csub
set @gfactura=@cfactura
set @gtip=@ctip
end
close tmp
deallocate tmp
end

GO
--***
/*Pentru completare cant. realizata*/
create trigger doccontr on dbo.pozdoc for update,insert,delete NOT FOR REPLICATION as
begin
-------------	din tabela par (parametri trimis de Magic):
declare @rezstoc int, @multicdbk int, @pozsurse int
set @rezstoc=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='REZSTOC'),0)
set @multicdbk=isnull((select top 1 val_logica from par where tip_parametru='UC' and parametru='MULTICDBK'),0)
set @pozsurse=isnull((select top 1 val_logica from par where tip_parametru='UC' and parametru='POZSURSE'),0)
-------------
declare @realizat float
declare @csub char(9),@ccod char(20), @barcod char(8), @ctip char(2),@ccontr char(20),@ctert char(13),@cgest char(9),@semn int,@cant float,@ctipcontr char(1),@ccodi char(13),@clocatie char(20),@pret float
declare @gsub char(9),@gcod char(20),@gbarcod char(8), @gtip char(2),@gcontr char(20),@gtert char(13),@ggest char(9),@gcodi char(13), @glocatie char(20),@gid int,@gpret float,@gfetch int
declare @cGestPrim char(9), @gGestPrim char(9)

declare tmpCo cursor for
select subunitate,cod,barcod, tip,contract,tert,1,cantitate,(case when left(tip,1)='R' then 'F' else 'B' end),
(case when @rezstoc=1 then gestiune else '' end) as gest,(case when @rezstoc=1 and left(tip,1)='A' then cod_intrare else '' end) as codi,locatie,
pret_valuta
from inserted where tip in ('AC','AP','AS','RM','RS') and contract<>'' 
union all
select subunitate,cod,barcod, tip,contract,tert,-1,cantitate,(case when left(tip,1)='R' then 'F' else 'B' end),
(case when @rezstoc=1 then gestiune else '' end),(case when @rezstoc=1 and left(tip,1)='A' then cod_intrare else '' end),locatie,
pret_valuta
from deleted where tip in ('AC','AP','AS','RM','RS') and contract<>''
order by subunitate,tip,contract/*,tert*/,cod,gest,locatie

open tmpCo
fetch next from tmpCo into @csub,@ccod,@barcod,@ctip,@ccontr,@ctert,@semn,@cant,@ctipcontr,@cgest,@ccodi,@clocatie,@pret
set @gsub=@csub
set @gtip=@ctip
set @gcontr=@ccontr
--set @gtert=@ctert
set @gcod=@ccod
set @gbarcod=(case when @pozsurse=1 and @ctipcontr='B' then @barcod else '' end)
set @ggest=@cgest
set @gcodi=@ccodi
set @gpret=(case when @multicdbk=1 and @ctipcontr='B' then @pret else 0 end)
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @realizat=0
	set @gid=0
	set @glocatie=@clocatie
	while @gsub=@csub and @gTip=@cTip and @gcontr=@ccontr --and @gtert=@ctert 
		and @gcod=@ccod and (@rezstoc=0 or @ggest=@cgest and @gcodi=@ccodi) 
		and @gpret=(case when @multicdbk=1 and @ctipcontr='B' then @pret else 0 end)
		and @gbarcod=(case when @pozsurse=1 and @ctipcontr='B' then @barcod else '' end)
		and @gfetch=0
	begin
		set @realizat=@realizat+@semn*@cant 
		if @semn=1 set @glocatie=@clocatie
		fetch next from tmpCo into @csub,@ccod,@barcod,@ctip,@ccontr,@ctert,@semn,@cant,@ctipcontr,@cgest,@ccodi,@clocatie,@pret
		set @gfetch=@@fetch_status
	end
	update pozcon set cant_realizata=cant_realizata+@realizat,@gid=1
		where subunitate=@gsub and left(tip,1)=@ctipcontr and contract=@gcontr --and tert=@gtert 
		and cod=@gcod 
		and (@rezstoc=0 or @rezstoc=1 and mod_de_plata=@ggest 
			and (left(@gtip,1)='A' or factura=@glocatie) and (left(@gtip,1)='R' or valuta=@gcodi) 
			and zi_scadenta_din_luna=0 and (left(@gtip,1)='R' or contract<>@glocatie))
		and ((@ctipcontr = 'B' and tip = 'BK') or (@ctipcontr = 'F' and tip = 'FC') or (@ctipcontr = 'B' and tip = 'BP'))
		and (@multicdbk=0 or @multicdbk=1 and (@ctipcontr<>'B' or abs(pret-@gpret)<=0.001))
		and (@pozsurse=0 or @pozsurse=1 and (@ctipcontr<>'B' or mod_de_plata=@gbarcod))

	/*cu rezervari de stocuri*/
	update pozcon set cant_realizata=cant_realizata+@realizat
		where @rezstoc=1 and @gid=0 and left(@gtip,1)='A' and subunitate=@gsub and tip='BF' and
		contract=@gcontr and /*tert=@gtert and */cod=@gcod and zi_scadenta_din_luna>0

	/* Modificare stare contract*/
--	update con set stare='6' 
	--	where subunitate=@gsub and left(tip,1)=@ctipcontr and contract=@gcontr /*and tert=@gtert*/
		--and tip<>'BF'

	set @gsub=@csub
	set @gtip=@ctip
	set @gcontr=@ccontr
	--set @gtert=@ctert
	set @gcod=@ccod
	set @gbarcod=(case when @pozsurse=1 and @ctipcontr='B' then @barcod else '' end)
	set @ggest=@cgest
	set @gcodi=@ccodi
	set @gpret=(case when @multicdbk=1 and @ctipcontr='B' then @pret else 0 end)
end

close tmpCo
deallocate tmpCo

-- realizat pe TE

declare tmpCo cursor for
select subunitate, (case when tip='AE' then '' when contract<>'' then contract else gestiune_primitoare end) as gestiune_primitoare, 
cod, (case when tip='AE' then grupa else factura end),  1, cantitate, Pret_vanzare
from inserted where (tip = 'TE' and factura <> '' or tip='AE' and grupa<>'')
union all
select subunitate, (case when tip='AE' then '' when contract<>'' then contract else gestiune_primitoare end) as gestiune_primitoare, 
cod, (case when tip='AE' then grupa else factura end), -1, cantitate, Pret_vanzare
from deleted where (tip = 'TE' and factura <> '' or tip='AE' and grupa<>'')

open tmpCo
fetch next from tmpCo into @csub, @cGestPrim, @ccod, @ccontr, @semn, @cant, @pret
set @gsub=@csub
set @gGestPrim=@cGestPrim
set @gcod=@ccod
set @gcontr=@ccontr
set @gpret=(case when @multicdbk=1 then @pret else 0 end)
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @realizat=0
	while @gsub=@csub and @gGestPrim=@cGestPrim and @gcontr=@ccontr and @gcod=@ccod 
		and @gpret=(case when @multicdbk=1 then @pret else 0 end) and @gfetch=0
	begin
		set @realizat=@realizat+@semn*@cant 
		fetch next from tmpCo into @csub, @cGestPrim, @ccod, @ccontr, @semn, @cant, @pret
		set @gfetch=@@fetch_status
	end
	update pozcon 
	set pret_promotional=p.pret_promotional+@realizat
	from pozcon p 
	left outer join gestiuni g on p.punct_livrare<>'' and p.subunitate=g.subunitate and p.punct_livrare=g.cod_gestiune
	where p.subunitate=@gsub and p.tip='BK' and p.contract=@gcontr and p.cod=@gcod
	and (@gGestPrim='' or p.punct_livrare = @gGestPrim)
	and (@multicdbk=0 or abs(pret-@gpret)<=0.01)

	set @gsub=@csub
	set @gGestPrim=@cGestPrim
	set @gcod=@ccod
	set @gcontr=@ccontr
	set @gpret=(case when @multicdbk=1 then @pret else 0 end)
end

close tmpCo
deallocate tmpCo
end

GO
--***
/*Pentru creat antet document*/
create trigger docantet on pozdoc for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	--HE, [IF (FK,FL,2)],[IF (FO,FP,2)],[GB OR 'TRUE'LOG],FM,HH
	declare @datapcons int, @rotunj_n int, @rotunjr_n int, @dve int, @accimp int , @comppret int, @urmc2 int, @scriuValDoc int  
	set @datapcons=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DATAPCONS'),0)
	set @rotunj_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='ROTUNJ' and val_logica=1),2)
	set @rotunjr_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='ROTUNJR' and val_logica=1),2)
	--set @dve=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DVE'),0)	/**	anulat in Magic (cu 'OR True')*/
	set @accimp=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='ACCIMP'),0)
	set @comppret=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='COMPPRET'),0)
	set @urmc2=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='URMCANT2'),0)
	set @scriuValDoc=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='VANTETDOC'),0)
-------------
insert into doc 
	(Subunitate, Tip, Numar, Cod_gestiune, Data, Cod_tert, Factura, Contractul, Loc_munca, Comanda, Gestiune_primitoare, Valuta, Curs, Valoare, Tva_11, Tva_22, Valoare_valuta, 
	Cota_TVA, Discount_p, Discount_suma, Pro_forma, Tip_miscare, Numar_DVI, Cont_factura, Data_facturii, Data_scadentei, Jurnal, Numar_pozitii, Stare)
	select subunitate,tip,numar,max(gestiune),max(data),max(tert),max(factura),max(contract),max(loc_de_munca),max(comanda),
	max(case when tip in ('AP','AS') then rtrim(substring(numar_dvi,14,5)) when tip='AE' then grupa else left(gestiune_primitoare,40) end), max(valuta),max(curs),0,0,0,0,
	max(case when tip='RM' and numar_DVI<>'' then 0 else Procent_vama end), max(discount), max(accize_cumparare),0,min(tip_miscare), 
	max(case when --@dve=1 and 
		tip in ('AP','AS') then barcod when tip in ('RM','RS') then rtrim(left(numar_dvi,13)) else '' end),
	max(cont_factura),max(data_facturii),max(data_scadentei),max(jurnal),0,max(stare)
	from inserted where numar not in
	(select numar from doc where subunitate=inserted.subunitate and 
	((tip='CM' and @datapcons=1 and data between dateadd(day, 1-day(inserted.data), inserted.data) and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(inserted.data), inserted.data)))) 
	or data=inserted.data) and tip=inserted.tip) 
	group by subunitate, tip, numar, (case when tip='CM' and @datapcons=1 then getdate() else data end)

/*Pentru calculul valorilor*/
declare @Valoare float, @Tva float, @Tva9 float, @valoarev float, @numar_poz int, @gfact char(20), @gdf datetime, @gds datetime
declare @csub char(9),@ctip char(2),@cnumar char(20),@cdata datetime,@ctert char(13),@semn int,@cant float,@valuta char(3),@curs float, 
	@pstoc float,@pval float,@pvanz float,@cota float,@tvad float,@numar_dvi char (8), @fact char(20), @df datetime, 
	@ds datetime, @disc float, @LME float, @ct4428 char(13), @gct4428 char(13), @gprim varchar(40), @ggprim varchar(40), @stare int, @clm char(9), @ccom char(40), @ccont_fact varchar(40), @ctip_tva smallint, @cgest char(9) 
declare @gsub char(9),@gtip char(2),@gnumar char(20),@gdata datetime,@gtert char(13),@gvaluta char(3),@gcurs float,@gfetch int, @gstare int, @gRetur int, @glm char(9), @gcom char(40), @gcont_fact varchar(40), @gtip_tva smallint, @ggest char(9)

declare tmp cursor for
select subunitate,tip,numar,data,tert,1,cantitate,valuta,curs,pret_de_stoc,pret_valuta,pret_vanzare,
cota_tva,tva_deductibil, numar_dvi,factura,data_facturii, data_scadentei, discount, suprataxe_vama, 
grupa, cont_venituri, stare, loc_de_munca, comanda, cont_factura, procent_vama, gestiune 
from inserted union all
select subunitate,tip,numar,data,tert,-1,cantitate,valuta,curs,pret_de_stoc,pret_valuta,pret_vanzare,
cota_tva,tva_deductibil, numar_dvi,factura,data_facturii, data_scadentei, discount, suprataxe_vama, 
grupa, cont_venituri, stare, loc_de_munca, comanda, cont_factura, procent_vama, gestiune
from deleted 
order by subunitate,tip,numar,data

open tmp
fetch next from tmp into @csub,@ctip,@cnumar,@cdata,@ctert,@semn,@cant,@valuta,@curs,
	@pstoc,@pval,@pvanz,@cota,@tvad,@numar_dvi,@fact,@df,@ds, @disc, @LME, @ct4428, @gprim, @stare, 
	@clm, @ccom, @ccont_fact,@ctip_tva, @cgest 
set @gsub=@csub
set @gtip=@ctip
set @gnumar=@cnumar
set @gdata=@cdata
set @gtert=@ctert
set @glm=@clm 
set @gcom=@ccom
set @gcont_fact=@ccont_fact
set @gtip_tva=@ctip_tva
set @ggest=@cgest
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Tva=0
	set @Tva9=0
	set @valoarev=0
	set @numar_poz=0
	set @gvaluta=@valuta
	set @gcurs=@curs
	set @gfact=@fact
	set @gdf=@df
	set @gds=@ds
	set @gct4428=@ct4428
	set @ggprim=@gprim
	set @gstare=0
	set @gRetur=0
	while @gsub=@csub and @gTip=@cTip and @gnumar=@cnumar and 
		((@gTip='CM' and @datapcons=1 and @cdata between dateadd(day, 1-day(@gdata), @gdata) 
		and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(@gdata), @gdata)))) 
		or @gdata=@cdata) and @gfetch=0
	begin
		set @gtert=@ctert
		set @glm=@clm 
		set @gcom=@ccom
		set @gcont_fact=@ccont_fact
		set @gtip_tva=@ctip_tva
		set @ggest=@cgest
		if @scriuValDoc=1
		begin
			set @numar_poz=@numar_poz+@semn
			set @tva=@tva+@semn*(case when (left(@ctip,1)='A'  
				or left(@ctip,1)='R') and @cota not in (9, 11) then @tvad else 0 end)
			set @tva9=@tva9+@semn*(case when (left(@ctip,1)='A'  
				or left(@ctip,1)='R') and @cota in (9,11) then @tvad else 0 end)
			set @valoare=@valoare+@semn*(case 
				when @ctip in ('AP','AC','AS') then round(convert(decimal(17,5),@cant*@pvanz),@rotunj_n) 
				when @ctip in ('RM','RS') then round(convert(decimal(17,5),@cant*@pstoc),@rotunjr_n) 
				else round(convert(decimal(17,5),@cant*@pstoc), 2) end)-
				@semn*(case when @ctip in ('RM','RS') and @ctip_tva=3 and abs(@cant*@pstoc)>=0.01 then @tvad else 0 end)
			if @valuta<>'' set @valoarev=@valoarev+round(convert(decimal(17,5),@semn*(case when @ctip in ('AP','AC','AS') 
				then round(convert(decimal(17,5),@pval*(1-@disc/100)+@comppret*@LME/1000)+(case when @curs>0 and @cant<>0 then @tvad/@curs/@cant else 0 end),5) 
				else @pval*(1+@disc/100)*(case when @ctip<>'RM' or @numar_dvi='' and @ctip_tva<>1 then 1+@cota/100 else 1 end) end)*@cant), 2) 
		End
		if @semn=1 set @gvaluta=@valuta
		if @semn=1 set @gcurs=@curs
		if @semn=1 set @gfact=@fact
		if @semn=1 set @gdf=@df
		if @semn=1 set @gds=@ds
		if @semn=1 and @ctip in ('AP','AS') set @gct4428=@ct4428
		if @semn=1 and @ctip in ('RM','RS') set @ggprim=@gprim
		if @semn=1 set @gstare=(case when @stare=2 or @gstare=2 then 2 when @stare>@gstare then @stare else @gstare end) 
		if @semn=1 and @LME=1 and @urmc2=0 and @comppret=0 and @ctip='AP' set @gRetur=1
		fetch next from tmp into @csub,@ctip,@cnumar,@cdata,@ctert,@semn,@cant,@valuta,@curs,@pstoc,@pval,
			@pvanz,@cota,@tvad,@numar_dvi,@fact,@df,@ds,@disc,@LME,@ct4428,@gprim, @stare, @clm, @ccom, @ccont_fact, @ctip_tva, @cgest
		set @gfetch=@@fetch_status
	end
	update doc set 
		valuta=@gvaluta, curs=@gcurs, factura=@gfact, data_facturii=@gdf, data_scadentei=@gds, 
		stare=(case when @gstare=6 or stare=6 then 6 when @gstare=2 or stare=2 then 2 when @gstare>stare then @gstare else stare end), 
		loc_munca=(case when loc_munca='' then @glm else Loc_munca end), comanda=(case when comanda='' then @gcom else comanda end)
		where doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and (doc.data=@gdata
			or @gTip='CM' and @datapcons=1 and doc.data between dateadd(day, 1-day(@gdata), @gdata) and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(@gdata), @gdata)))) 
	if @scriuValDoc=1
	begin
		update doc set valoare=valoare+@valoare, tva_22=tva_22+@tva, tva_11=tva_11+@tva9, valoare_valuta=valoare_valuta+@valoarev, numar_pozitii=numar_pozitii+@numar_poz
		where doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and (doc.data=@gdata
			or @gTip='CM' and @datapcons=1 and doc.data between dateadd(day, 1-day(@gdata), @gdata) and dateadd(day, -1, dateadd(month, 1, dateadd(day, 1-day(@gdata), @gdata)))) 
	end

	update doc set tip_miscare=(case when @gRetur=1 then 'R' else '8' end) 
		where (@gtip in ('AP','AS') and left(@gct4428,4)='4428' or @gtip='AP' and @gRetur=1)
		and doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and doc.data=@gdata
	update doc set gestiune_primitoare=@ggprim 
		where @gtip in ('RM','RS') and doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and doc.data=@gdata
	update doc set cod_tert=@gtert, loc_munca=@glm, comanda=@gcom, cont_factura=@gcont_fact, 
			cota_tva=(case when tip='RM' and numar_DVI<>'' then 0 else @gtip_tva end), cod_gestiune=@ggest 
		where @gtip in ('RM','AP') and doc.subunitate=@gsub and doc.tip=@gtip and doc.numar=@gnumar and doc.data=@gdata and stare=2
	/* update doc set numar_DVI='' where @gtip='RM' and doc.subunitate=@gsub and doc.tip=@gtip and
		doc.numar=@gnumar and doc.data=@gdata and @accimp=1 and cod_gestiune in (select cod_gestiune from
		gestiuni where tip_gestiune in ('A','V'))
	update doc set valoare_valuta=valoare_valuta+(case when dvi.valuta_CIF=@valuta then dvi.valoare_CIF else 0 end), 
		tva_22=tva_22+dvi.tva_CIF+dvi.tva_22+dvi.tva_comis, valoare=valoare+dvi.suma_suprataxe from dvi where 
		@ctip='RM' and @numar_dvi<>'' and doc.subunitate=@gsub and 
		doc.tip=@gtip and doc.numar=@gnumar and doc.data=@gdata and 
		doc.subunitate=dvi.subunitate and doc.numar= 
		dvi.numar_receptie and doc.numar_dvi=dvi.numar_dvi */
	set @gsub=@csub
	set @gtip=@ctip
	set @gnumar=@cnumar
	set @gdata=@cdata
	set @gtert=@ctert
	set @glm=@clm 
	set @gcom=@ccom
	set @gcont_fact=@ccont_fact
	set @gtip_tva=@ctip_tva
	set @ggest=@cgest
end

close tmp
deallocate tmp
end

GO
--***
create trigger docdec on pozdoc for insert, update, delete as
begin
insert deconturi
(Subunitate, Tip, Marca, Decont, Cont, Data, Data_scadentei, 
Valoare, Valuta, Curs, Valoare_valuta, Decontat, Sold, Decontat_valuta, Sold_valuta, 
Loc_de_munca, Comanda, Data_ultimei_decontari, Explicatii)
select a.subunitate, 'T', a.gestiune_primitoare, a.tert, max(a.cont_factura), max(a.data), max(a.data), 
0, max(a.valuta), max(a.curs), 0, 0, 0, 0, 0, 
max(a.loc_de_munca), max(a.comanda), '01/01/1901', ''
from inserted a
inner join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_factura
where a.tip='DF' and c.sold_credit=9 and a.tert<>'' and a.procent_vama<>0
and not exists (select 1 from deconturi d where d.subunitate=a.subunitate and d.tip='T' and d.marca=a.gestiune_primitoare and d.decont=a.tert)
group by a.subunitate, a.gestiune_primitoare, a.tert

declare @sub char(9), @marca char(6), @decont varchar(40), @valoare float, @lm char(9), @comanda char(40), @semn int, 
	@gsub char(9), @gmarca char(6), @gdecont varchar(40), @gvaloare float, @glm char(9), @gcomanda char(40), @nFetch int

declare tmpdocdec cursor for
select a.subunitate, a.gestiune_primitoare as marca, a.tert as decont, 
round(convert(decimal(15, 5), a.cantitate*a.pret_de_stoc*a.procent_vama/100*(1.00+a.cota_TVA/100.00)), 2) as valoare, 
a.loc_de_munca as loc_de_munca, a.comanda as comanda, 1 as semn
from inserted a
inner join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_factura
where a.tip='DF' and c.sold_credit=9 and a.tert<>'' and a.procent_vama<>0
union all 
select a.subunitate, a.gestiune_primitoare as marca, a.tert as decont, 
round(convert(decimal(15, 5), a.cantitate*a.pret_de_stoc*a.procent_vama/100*(1.00+a.cota_TVA/100.00)), 2) as valoare, 
a.loc_de_munca as loc_de_munca, a.comanda as comanda, -1 as semn
from deleted a
inner join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_factura
where a.tip='DF' and c.sold_credit=9 and a.tert<>'' and a.procent_vama<>0
order by 1, 2, 3

open tmpdocdec
fetch next from tmpdocdec into @sub, @marca, @decont, @valoare, @lm, @comanda, @semn
select @nFetch=@@fetch_status, @gsub=@sub, @gmarca=@marca, @gdecont=@decont
while @nFetch=0
begin
	select @gvaloare=0, @glm='', @gcomanda=''
	while @nFetch=0 and @gsub=@sub and @gmarca=@marca and @gdecont=@decont
	begin
		select @gvaloare=@gvaloare+@semn*@valoare, 
			@glm=(case when @semn=1 and @lm<>'' then @lm else @glm end), 
			@gcomanda=(case when @semn=1 and @comanda<>'' then @comanda else @gcomanda end)
		fetch next from tmpdocdec into @sub, @marca, @decont, @valoare, @lm, @comanda, @semn
		set @nFetch=@@fetch_status
	end
	
	update deconturi
	set valoare=valoare+@gvaloare, sold=sold+@gvaloare, 
		loc_de_munca=(case when @glm<>'' then @glm else loc_de_munca end), comanda=(case when @gcomanda<>'' then @gcomanda else comanda end)
	where subunitate=@gsub and tip='T' and marca=@gmarca and decont=@gdecont
end
close tmpdocdec
deallocate tmpdocdec
end

GO
create trigger ScriuPozDocInDocDeContat on pozdoc for insert,update,delete
as
	insert into DocDeContat(subunitate,tip,numar,data)
		select iu.subunitate,iu.tip,iu.numar,iu.data
		from
			(select i.subunitate,i.tip,i.numar,i.data from inserted i
			union
			select u.subunitate,u.tip,u.numar,u.data from deleted u) iu
		left outer join DocDeContat dc on iu.subunitate=dc.subunitate and iu.tip=dc.tip and iu.numar=dc.numar and iu.data=dc.data
		where dc.subunitate is null --doar daca nu exista
			and iu.tip not in ('RP','RZ') --RP-urile si RZ-urile nu se scriu niciodata.
		group by iu.subunitate,iu.tip,iu.numar,iu.data		

GO
--***
create trigger tr_RezervaLaIntrareInStoc on pozdoc after insert,update,delete
as
BEGIN TRY
if exists (select * from sysobjects where name ='RezervaLaIntrareInStoc')
begin
	declare @gestiuneRezervari varchar(20)
	EXEC luare_date_par 'GE', 'REZSTOCBK', 0, 0, @gestiuneRezervari OUTPUT

	select 'I' as tiplinie,i.data,i.cod,i.gestiune,sum(s.stoc) as cantitate
	into #tmpderezervat
	from inserted i
	inner join stocuri s on i.Gestiune=s.Cod_gestiune and i.cod=s.cod
	where i.Tip_miscare!='V' and not (i.tip='TE' and i.gestiune_primitoare=@gestiuneRezervari)  and ISNULL(i.detalii.value('(/row/@_nuRezervaStoc)[1]','int'),0)=0
	-- Aici ignoram si documentele care reprezinta valorificari de inventar. Ele sunt sit. exceptionale care nu dau efect in rez. automata
	and detalii.value('(/row/@idInventar)[1]','int') IS NULL
	group by i.data,i.cod,i.gestiune
	union all
	select 'I' as tiplinie,i.data,i.cod,i.Gestiune_primitoare,sum(s.stoc) as cantitate
	from inserted i
	inner join stocuri s on i.Gestiune_primitoare=s.Cod_gestiune and i.cod=s.cod
	where i.Tip_miscare!='V' and i.tip='TE' and i.gestiune_primitoare<>@gestiuneRezervari and ISNULL(i.detalii.value('(/row/@_nuRezervaStoc)[1]','int'),0)=0 
	-- Aici ignoram si documentele care reprezinta valorificari de inventar. Ele sunt sit. exceptionale care nu dau efect in rez. automata
	and detalii.value('(/row/@idInventar)[1]','int') IS NULL
	group by i.data,i.cod,i.Gestiune_primitoare


	if @@ROWCOUNT>0
		exec RezervaLaIntrareInStoc
end
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH

GO
--***
CREATE trigger yso_ins_pozdoc on dbo.pozdoc for insert NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspd
select host_id(),host_name (), @Aplicatia, getdate(), @Utilizator, 
data_operarii, ora_operarii,
Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare,
Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Cod_intrare, Cont_de_stoc, Cont_corespondent, 
TVA_neexigibil,	Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, 
Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
Accize_cumparare, Accize_datorate, Contract, Jurnal
from inserted
