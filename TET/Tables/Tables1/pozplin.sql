CREATE TABLE [dbo].[pozplin] (
    [Subunitate]              CHAR (9)     NOT NULL,
    [Cont]                    VARCHAR (20) NULL,
    [Data]                    DATETIME     NOT NULL,
    [Numar]                   CHAR (10)    NOT NULL,
    [Plata_incasare]          CHAR (2)     NOT NULL,
    [Tert]                    CHAR (13)    NOT NULL,
    [Factura]                 CHAR (20)    NOT NULL,
    [Cont_corespondent]       VARCHAR (20) NULL,
    [Suma]                    FLOAT (53)   NOT NULL,
    [Valuta]                  CHAR (3)     NOT NULL,
    [Curs]                    FLOAT (53)   NOT NULL,
    [Suma_valuta]             FLOAT (53)   NOT NULL,
    [Curs_la_valuta_facturii] FLOAT (53)   NOT NULL,
    [TVA11]                   FLOAT (53)   NOT NULL,
    [TVA22]                   FLOAT (53)   NOT NULL,
    [Explicatii]              CHAR (50)    NOT NULL,
    [Loc_de_munca]            CHAR (9)     NOT NULL,
    [Comanda]                 CHAR (40)    NOT NULL,
    [Utilizator]              CHAR (10)    NOT NULL,
    [Data_operarii]           DATETIME     NOT NULL,
    [Ora_operarii]            CHAR (6)     NOT NULL,
    [Numar_pozitie]           INT          NOT NULL,
    [Cont_dif]                VARCHAR (20) NULL,
    [Suma_dif]                FLOAT (53)   NOT NULL,
    [Achit_fact]              FLOAT (53)   NOT NULL,
    [Jurnal]                  VARCHAR (20) NULL,
    [detalii]                 XML          NULL,
    [tip_tva]                 INT          NULL,
    [marca]                   VARCHAR (20) NULL,
    [decont]                  VARCHAR (20) NULL,
    [efect]                   VARCHAR (20) NULL,
    [idPozPlin]               INT          IDENTITY (1, 1) NOT NULL,
    [subtip]                  VARCHAR (2)  NULL,
    CONSTRAINT [pk_PozPlin] PRIMARY KEY CLUSTERED ([idPozPlin] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Principal]
    ON [dbo].[pozplin]([Subunitate] ASC, [Cont] ASC, [Data] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Tert_Factura]
    ON [dbo].[pozplin]([Subunitate] ASC, [Tert] ASC, [Factura] ASC);


GO
CREATE NONCLUSTERED INDEX [jurnal]
    ON [dbo].[pozplin]([Subunitate] ASC, [Cont] ASC, [Data] ASC, [Jurnal] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Tert_Efect]
    ON [dbo].[pozplin]([Subunitate] ASC, [Tert] ASC, [efect] ASC);


GO
--***
create trigger plinefect on pozplin for update,insert,delete as
begin
insert into efecte (Subunitate,Tip,Tert,Nr_efect,Cont,Data,Data_scadentei,Valoare,Valuta,Curs,Valoare_valuta,Decontat,
    Sold,Decontat_valuta,Sold_valuta,Loc_de_munca,Comanda,Data_decontarii,Explicatii)
	select a.subunitate, (case when isnull(a.subtip,'')='IY' then 'P' else (case a.plata_incasare when 'IS' then 'P' when 'PS' then 'I' else left(a.plata_incasare,1) end) end), 
	a.tert, a.efect,
    (case when isnull(c1.sold_credit, 0)=8 then a.cont else a.cont_corespondent end), 
	max(a.data), max(a.data), 0, max(a.valuta),
    max(a.curs),0,0,0,0,0, max(a.loc_de_munca), '', 
	max(case when isnull(c2.sold_credit, 0)=8 then a.data else convert(datetime,'01/01/1901') end), 
	isnull(nullif(max(a.detalii.value('(/row/@explicatii)[1]','varchar(100)')),''),left(max(a.explicatii),30)) 
    from inserted a 
	left outer join conturi c1 on c1.subunitate=a.subunitate and c1.cont=a.cont
	left outer join conturi c2 on c2.subunitate=a.subunitate and c2.cont=a.cont_corespondent
    where a.efect is not null and (isnull(c1.sold_credit, 0)=8 or isnull(c2.sold_credit, 0)=8) 
    and not exists (select 1 from efecte e where e.subunitate=a.subunitate and e.tip=(case when isnull(a.subtip,'')='IY' then 'P' else (case a.plata_incasare when 'IS' then 'P' when 'PS' then 'I' else left(a.plata_incasare,1) end) end) 
					and e.tert=a.tert and e.nr_efect=a.efect)
	group by a.subunitate, (case when isnull(a.subtip,'')='IY' then 'P' else (case a.plata_incasare when 'IS' then 'P' when 'PS' then 'I' else left(a.plata_incasare,1) end) end), a.tert, a.efect, (case when isnull(c1.sold_credit, 0)=8 then a.cont else a.cont_corespondent end)

declare @valoare float,@valoarev float,@decontat float,@decontatv float,@datadec datetime,@dataef datetime,@datascad datetime
declare @csub char(9),@ctip char(2),@ctert char(13),@cnr varchar(20),@semn int,@suma float,
             @sumadec float,@sumadif float,@valuta char(3),@curs float,@ddata datetime,@ddatasc datetime,@sumaachv float,@subtip varchar(2)
declare @gsub char(9), @gtip char(1), @gtert char(13),@gnr varchar(20),@gfetch int

declare tmp cursor for
select subunitate, plata_incasare, tert, efect as numar,1,(case when plata_incasare in ('IS','PS') then -1 else 1 end)*suma,0,0, valuta,curs,achit_fact, isnull(detalii.value('(/row/@dataefect)[1]','datetime'),data),isnull(detalii.value('(/row/@datascad)[1]','datetime'),data),isnull(subtip,'')
from inserted where efect is not null and (inserted.cont in (select cont from conturi where subunitate=inserted.subunitate and sold_credit=8)) 
union all
select subunitate, plata_incasare, tert, efect as numar,1,0,(case when plata_incasare in ('IS','PS') then -1 else 1 end)*suma,suma_dif, valuta,curs,0,data,data,isnull(subtip,'')
from inserted where efect is not null and (inserted.cont_corespondent in (select cont from conturi where subunitate=inserted.subunitate and sold_credit=8)) 
union all
select subunitate, plata_incasare, tert, efect as numar,-1, (case when plata_incasare in ('IS','PS') then -1 else 1 end)*suma,0,0, valuta,curs,achit_fact,data,data,isnull(subtip,'') 
from deleted where efect is not null and (deleted.cont in (select cont from conturi where subunitate=deleted.subunitate and sold_credit=8)) 
union all
select subunitate, plata_incasare, tert, efect as numar,-1,0,(case when plata_incasare in ('IS','PS') then -1 else 1 end)*suma,suma_dif, valuta,curs,0,data,data,isnull(subtip,'') 
from deleted where efect is not null and (deleted.cont_corespondent in (select cont from conturi where subunitate=deleted.subunitate and sold_credit=8)) 
order by subunitate, plata_incasare, tert, numar

open tmp
fetch next from tmp into @csub,@ctip,@ctert, @cnr, @semn,@suma,@sumadec,@sumadif,@valuta,@curs,@sumaachv,@ddata,@ddatasc,@subtip
set @gsub=@csub
set @gtip=(case when @subtip='IY' then 'P' else (case @ctip when 'IS' then 'P' when 'PS' then 'I' else left(@ctip,1) end) end)
set @gtert=@ctert
set @gnr=@cnr
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Valoarev=0
	set @Decontat=0
	set @Decontatv=0
	set @datadec=''
	set @dataef=''
	set @Datascad=''
	while @gsub=@csub and @gtip=(case when @subtip='IY' then 'P' else (case @ctip when 'IS' then 'P' when 'PS' then 'I' else left(@ctip,1) end) end) and @gtert=@ctert and @gnr=@cnr and @gfetch=0
	begin
		set @valoare=@valoare+(@suma-@sumadif)*@semn
		set @decontat=@decontat+@sumadec*@semn
		if @valuta<>'' set @valoarev=@valoarev+@sumaachv*@semn
		if @valuta<>'' set @decontatv=@decontatv+@sumaachv*@semn
		if @semn=1 and @ctip not in ('PF','IB') set @datadec=@ddata
		if @semn=1 and @ctip in ('PF','IB') set @dataef=@ddata
		if @semn=1 and @ctip in ('PF','IB') set @datascad=@ddatasc 
		fetch next from tmp into @csub,@ctip, @ctert, @cnr, @semn,@suma, @sumadec,@sumadif,@valuta,@curs,@sumaachv,@ddata,@ddatasc,@subtip
		set @gfetch=@@fetch_status
	end
	update efecte set valoare=valoare+@valoare, decontat=decontat+@decontat, sold=sold+@valoare-@decontat,
		valoare_valuta=valoare_valuta+@valoarev, data_decontarii=@datadec, 
		data=(case when @dataef='' then data else @dataef end), data_scadentei=(case when @datascad='' then data_scadentei else @datascad end), 
		decontat_valuta=decontat_valuta+@decontatv, sold_valuta=sold_valuta+@valoarev-@decontatv 
		where subunitate=@gsub and tip=@gtip and tert=@gtert and nr_efect=@gnr
	/*delete from efecte where subunitate=@gsub and tip=@gtip and tert=@gtert and nr_efect=@gnr 
		and valoare=0 and decontat=0 and valoare_valuta=0 and decontat_valuta=0*/
	set @gtert=@ctert
	set @gsub=@csub
	set @gnr=@cnr
	set @gtip=(case when @subtip='IY' then 'P' else (case @ctip when 'IS' then 'P' when 'PS' then 'I' else left(@ctip,1) end) end)
end

close tmp
deallocate tmp
end

GO
--***
create trigger plinfac on pozplin for update,insert,delete as 
begin
	declare @Ignor4428Avans int
    set @Ignor4428Avans=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='NEEXAV'),0)

	insert into facturi select subunitate,max(loc_de_munca), (case when plata_incasare in ('IB','IR','PS') then 0x46 else 0x54 end), 
	factura,tert,max(data),max(data),0,0,0,max(valuta),max(curs),0,0,0,max(cont_corespondent),0,0,max(comanda),max(data) 
	from inserted where plata_incasare in ('PF','IB','PR','IR','PS','IS') and factura not in (select factura from facturi where 
	subunitate=inserted.subunitate and tert=inserted.tert and tip=(case when inserted.plata_incasare in ('IB','IR','PS') 
	then 0x46 else 0x54 end))
	group by subunitate,plata_incasare,tert,factura

declare @valoare float,@valoarev float,@dataach datetime, @contf varchar(40)
declare @csub char(9),@ctip char(2),@ddata datetime,@ctert char(13),@cfactura char(20),@semn int,@suma float,
             @sumav float,@sumad float,@valuta char(3),@curs float,@achv float
declare @gsub char(9),@gtip char(2),@gtert char(13),@gfactura char(20),@tipf binary,@gvaluta char(3),@gcurs float, @gfetch int, @gcontf varchar(40)

declare tmp cursor for
select subunitate,plata_incasare,data,tert,factura, (case when plata_incasare in ('PS','IS') then -1 else 1 end), 
	suma-(case when @Ignor4428Avans=1 /*and left(Cont_corespondent,3) in ('409','419','451','232')*/ and plata_incasare in ('IB', 'PF') then TVA22 else 0 end),
suma_valuta,suma_dif,valuta,curs,achit_fact, Cont_corespondent
from inserted where plata_incasare in ('IB','PF','PR','IR','PS','IS') union all
select subunitate,plata_incasare,data,tert,factura, (case when plata_incasare in ('PS','IS') then 1 else -1 end), 
	suma-(case when @Ignor4428Avans=1 /*and left(Cont_corespondent,3) in ('409','419','451','232')*/ and plata_incasare in ('IB', 'PF') then TVA22 else 0 end),
suma_valuta,suma_dif,valuta,curs, achit_fact, Cont_corespondent
from deleted where plata_incasare in ('IB','PF','PR','IR','PS','IS')
order by subunitate,plata_incasare,tert,factura

open tmp
fetch next from tmp into @csub,@ctip,@ddata,@ctert,@cfactura,@semn,@suma,@sumav,@sumad,@valuta,@curs,@achv,@contf
set @gsub=@csub
set @gtert=@ctert
set @gfactura=@cfactura
set @gtip=@ctip
set @gvaluta=@valuta
set @gcurs=@curs
set @gcontf=@contf
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Valoarev=0
	set @DataAch=''
	while @gsub=@csub and @cTip=@gTip and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0
	begin
		if @ctip='PF' or @ctip='PR' or @ctip='IS'
			set @tipf=0x54
		else
			set @tipf=0x46
		if @valuta='' 
			set @valoare=@valoare+@suma*@semn
		else 
			begin
				set @valoare=@valoare+(@suma-@Sumad)*@semn
				set @valoarev=@valoarev+@achv*@semn
			end
		if @semn=1 set @dataach=@ddata
		fetch next from tmp
		    into @csub,@ctip,@ddata,@ctert,@cfactura,@semn,@suma,@sumav,@sumad,@valuta,@curs,@achv,@contf
		set @gfetch=@@fetch_status
	end
	update facturi set achitat=achitat+@valoare, sold=sold-@valoare, data_ultimei_achitari=@dataach, cont_de_tert=@gcontf /*,valuta='',curs=0*/
	where subunitate=@gsub and tip=@tipf and tert=@gtert and factura=@gfactura

	update facturi set /*valuta=@gvaluta,curs=@gcurs,*/
		achitat_valuta=achitat_valuta+@valoarev, sold_valuta=sold_valuta-@valoarev  
	from terti where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gtert and facturi.factura=@gfactura
			and facturi.subunitate=terti.subunitate and facturi.tert=terti.tert and terti.tert_extern=1 
	/*delete from facturi where subunitate=@gsub and tip=@tipf and tert=@gtert and factura=@gfactura 
		and valoare=0 and tva_22=0 and tva_11=0 and achitat=0 and valoare_valuta=0 and achitat_valuta=0
	if @tipf=0x54
		update terti set sold_ca_furnizor=sold_ca_furnizor-@valoare where tert=@gtert
	else
		update terti set sold_ca_beneficiar=sold_ca_beneficiar-@valoare where tert=@gtert*/
	set @gtert=@ctert
	set @gsub=@csub
	set @gfactura=@cfactura
	set @gtip=@ctip
	set @gvaluta=@valuta
	set @gcurs=@curs
	set @gcontf=@contf
end

close tmp
deallocate tmp
end

GO

create trigger tr_ValidPozPlin on pozplin for insert, update,delete NOT FOR REPLICATION as
declare 
	@errCt varchar(50), @msgErrCt varchar(500), @utilizator varchar(100)
begin try
	
	set @utilizator=dbo.fIaUtilizator(null)

	/**	Validare operare pe acelasi cont, cont neatribuit: ex. dec. 542=542 	*/
	IF EXISTS (select 1 from INSERTED i JOIN Conturi cc on cc.Cont=i.Cont JOIN Conturi cct on cct.Cont=i.Cont_corespondent and i.Cont=i.Cont_corespondent and cc.Sold_credit=cct.Sold_credit 
		and cc.Sold_credit<>0 and i.cont not like '8%')
		RAISERROR('Nu este permisa operarea pe acelasi cont (cont = cont corespondent)!',16,1)

	/** Validare formule contabile + conturi in sine */
	IF UPDATE(cont) OR UPDATE(cont_corespondent)
	BEGIN
		create table #formulecontabile (cont_debit varchar(40), cont_credit varchar(40), tip varchar(2), numar varchar(20), data datetime)
		insert into #formulecontabile(cont_debit, cont_credit, tip, numar, data)
		select cont, cont_corespondent, plata_incasare, numar, data from INSERTED where left(plata_incasare,1)='I'
		union all
		select cont_corespondent, cont, plata_incasare, numar,  data from INSERTED where left(plata_incasare,1)='P'
		exec validFormuleContabile
	END

	/** Validare tert  */
	if UPDATE(tert) 
	begin
		select DISTINCT tert cod into #terti 
		from inserted where plata_incasare in ('PF','PR','PS','IB','IR','IS','PC') 
			or (plata_incasare='IC' and tert<>'') 
			or (plata_incasare in ('PD','ID') and cont_corespondent in (select cont from conturi where Sold_credit='8'))
		exec validTert
	end 
	/** Validare marca - de facut!!!!!!!!!  */


	/* Validare loc de munca */
	if UPDATE(loc_de_munca) 
	begin
		create table #lm(utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm(utilizator,cod,data)
		select distinct @utilizator,loc_de_munca,data from inserted		
		exec validLM
	end

	/** Validare comanda */
	IF UPDATE(comanda)
	BEGIN
		select DISTINCT left(comanda,20) comanda into #comenzi 
			from INSERTED 
		exec validComanda		
	END

	/** Validare valuta si curs */
	IF UPDATE(valuta) or UPDATE(curs)
	BEGIN
		select DISTINCT plata_incasare tip, numar, data, valuta, curs into #valute
			from INSERTED where valuta<>'' or curs<>0
		exec validValuta
	END

	/** Validare luna inchisa Contabilitate */
	create table #lunaconta (data datetime)
	insert into #lunaconta (data)
	select DISTINCT data from inserted
	union all
	select DISTINCT data from deleted
	exec validLunaInchisaConta

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

end try 
begin catch
	ROLLBACK TRANSACTION
	declare 
		@mesaj varchar(max)
	set @mesaj= ERROR_MESSAGE() + ' (tr_validPozPlin)'
	raiserror ( @mesaj,16,1 )
end catch

GO
--***
/*Pentru creat antet plati / incasari*/
create trigger plinantet on pozplin for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @docdef int
	set @docdef=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DOCDEF'),0)
-------------
declare @decgrluna int
set @decgrluna = isnull((select val_logica from par where tip_parametru='GE' and parametru='DECONTCT9'), 0)

insert into plin (Subunitate,Cont,Data,Numar,Valuta,Curs,Total_plati,Total_incasari,Ziua,Numar_pozitii,Jurnal,stare)
	select inserted.subunitate,inserted.cont,(case when @decgrluna=1 and max(conturi.sold_credit)='9' then dbo.eom(data) else data end),
	'',max(valuta),max(curs),0,0,max(day (data)),0,
	jurnal, (case when @docdef=1 and right(max(utilizator),1)='2' then 2 else 0 end) 
         from inserted,conturi 
	where inserted.cont=conturi.cont and inserted.subunitate=conturi.subunitate 
	and inserted.cont not in (select cont from plin where subunitate=inserted.subunitate and 
	data=(case when @decgrluna=1 and conturi.sold_credit='9' then dbo.eom(inserted.data) else inserted.data end) and jurnal=inserted.jurnal) 
	group by inserted.subunitate,inserted.cont,data,jurnal

/*Pentru calculul valorilor*/
declare @total_plati float, @total_incasari float, @numar_poz int
declare @csub char(9),@ctip char(2),@ccont varchar(40),@cdata datetime,@cjurnal char (3),@semn int,@suma float
declare @gsub char(9),@gcont varchar(40),@gdata datetime,@gjurnal char (3),@gfetch int

declare tmp cursor for
select subunitate,plata_incasare,cont,data,jurnal,1,suma 
	from inserted union all
select subunitate,plata_incasare,cont,data,jurnal,-1,suma
	from deleted 
order by subunitate,cont,data,jurnal,plata_incasare

open tmp
fetch next from tmp into @csub,@ctip,@ccont,@cdata,@cjurnal,@semn,@suma
set @gsub=@csub
set @gcont=@ccont
set @gdata=@cdata
set @gjurnal=@cjurnal
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @total_plati=0
	set @total_incasari=0
	set @numar_poz=0
	while @gsub=@csub and @gcont=@ccont and @gdata=@cdata and @gjurnal=@cjurnal and @gfetch=0
	begin
		set @numar_poz=@numar_poz+@semn
		if left(@ctip,1)='P' 
			set @total_plati=@total_plati+@semn*@suma
		if left(@ctip,1)='I'
			set @total_incasari=@total_incasari+@semn*@suma
		fetch next from tmp into @csub,@ctip,@ccont,@cdata,@cjurnal,@semn,@suma
		set @gfetch=@@fetch_status
	end
	update plin set total_plati=total_plati+@total_plati, 
		total_incasari=total_incasari+@total_incasari,
		numar_pozitii=numar_pozitii+@numar_poz 
		where plin.subunitate=@gsub and plin.cont=@gcont and plin.data=@gdata and plin.jurnal=@gjurnal

	delete from plin where subunitate = @gsub and data = @gdata and cont=@gcont
			and total_incasari=0 and total_plati = 0 and numar_pozitii = 0
	set @gsub=@csub
	set @gcont=@ccont
	set @gdata=@cdata
	set @gjurnal=@cjurnal
end

close tmp
deallocate tmp
end

GO
--***
create trigger pozplinsterg on pozplin for update, delete /*with append*/ NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspp
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator,
	Data_operarii, Ora_operarii,
	Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, Cont_corespondent, Suma, Valuta, Curs, 
	Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, Explicatii, Loc_de_munca, Comanda, Utilizator, 
	Numar_pozitie, Cont_dif, Suma_dif, Achit_fact, Jurnal
   from deleted

GO
--***
create trigger plindec on pozplin for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @decrest1 int, @decrest2 int, @decmarct int, @primariaTM int
	set @decrest1=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DECREST'),0)-1
	set @decrest2=@decrest1+1
	set @decmarct=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DECMARCT'),0)
	set @primariaTM=isnull((select top 1 val_logica from par where tip_parametru='SP' and parametru='PRIMTIM'),0)
-------------
insert into deconturi select a.subunitate,'T', a.marca, (case when @decmarct=0 then a.decont else a.cont end), a.cont, max(a.data), max(a.data), 0, max(valuta), max(curs), 
	0,0,0,0,0, max(loc_de_munca), max(comanda), max(a.data), left(max(explicatii),30) 
from inserted a 
where a.decont is not null and a.cont in (select cont from conturi where subunitate=a.subunitate and sold_credit=9) 
	and (case when @decmarct=0 then a.decont else a.cont end) not in (select decont from deconturi where subunitate=a.subunitate and marca=a.marca and tip='T')
group by a.subunitate,a.marca,(case when @decmarct=0 then a.decont else a.cont end),a.cont

insert into deconturi select a.subunitate,'T', a.marca, (case when @decmarct=0 then a.decont else a.cont_corespondent end), a.cont_corespondent, max(a.data),max(a.data),0,max(valuta),max(curs),
	0,0,0,0,0, max(loc_de_munca), max(comanda),max(a.data), left(max(explicatii),30) 
from inserted a 
where a.decont is not null and a.cont_corespondent in (select cont from conturi where subunitate=a.subunitate and sold_credit=9) 
	and (case when @decmarct=0 then a.decont else a.cont_corespondent end) not in (select decont from deconturi where subunitate=a.subunitate and marca=a.marca and tip='T')
group by a.subunitate,a.marca,(case when @decmarct=0 then a.decont else a.cont_corespondent end),a.cont_corespondent

declare @valoare float,@valoarev float,@decontat float,@decontatv float,@datadec datetime, @datascad datetime, @lm char(9), @com char(40), @ex char(30)
declare @csub char(9),@ctip char(2),@cmarca char(6),@cdecont varchar(20),@semn int,@suma float,@sumav float,@sumadec float,@sumadecv float,@valuta char(3),@curs float,@ddata datetime, @ddatascad datetime, 
	@sumarestv float, @glm char(9), @gcom char(40), @gex char(30)
declare @gsub char(9),@gmarca char(6),@gdecont varchar(20),@gfetch int

declare tmp cursor for
select i.subunitate,i.plata_incasare,i.marca, (case when @decmarct=0 then i.decont else i.cont end) as dec,1,0,0,i.suma,i.suma_valuta,i.valuta,i.curs,i.data,i.data,
	(case when i.plata_incasare in ('PD','PC') then i.suma_valuta else i.achit_fact end),i.loc_de_munca,
	--	regula completare indicator bugetar (dupa prioritate): 1. pozplin.substring(i.comanda,21,20) - compatibilitate in urma + Primaria TM, 
	--	apoi regula noua: 2.pozplin.detalii/indicator, 3.cont_antet.detalii/indicator, 4.cont_corespondent.detalii/indicator
	left(i.comanda,20)+(case when @primariaTM=0 or substring(i.comanda,21,20)='' 
		then rtrim(isnull(nullif(i.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(nullif(cc.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),'')))
		else substring(i.comanda,21,20) end) as comanda, 
	left(explicatii,30)
from inserted i 
left outer join conturi cc ON cc.subunitate = i.subunitate and cc.cont = i.cont_corespondent
where i.decont is not null and i.cont in (select cont from conturi where subunitate=i.subunitate and sold_credit=9) 
union all 
select i.subunitate,i.plata_incasare,i.marca, (case when @decmarct=0 then i.decont else i.cont_corespondent end), 1,i.suma,i.suma_valuta, 0,0, i.valuta,i.curs,i.data,
	isnull(i.detalii.value('(/row/@datascad)[1]','datetime'),i.data),0,i.loc_de_munca,
	left(i.comanda,20)+(case when @primariaTM=0 or substring(i.comanda,21,20)='' 
		then rtrim(isnull(nullif(i.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),'')) else substring(i.comanda,21,20) end) as comanda, 
	left(i.explicatii,30)
from inserted i 
where i.decont is not null and cont_corespondent in (select cont from conturi where subunitate=i.subunitate and sold_credit=9) 
union all 
select subunitate,plata_incasare,marca, (case when @decmarct=0 then decont else cont end),-1,0,0,suma,suma_valuta,valuta,curs,data,data,
	(case when plata_incasare in ('PD','PC') then suma_valuta else achit_fact end),loc_de_munca,comanda, left(explicatii,30) 
from deleted 
where decont is not null and cont in (select cont from conturi where subunitate=deleted.subunitate and sold_credit=9) 
union all 
select subunitate,plata_incasare,marca, (case when @decmarct=0 then decont else cont_corespondent end),-1,suma,suma_valuta,0,0,valuta,curs,data,data,0,  loc_de_munca,comanda, left(explicatii,30) 
from deleted 
where decont is not null and cont_corespondent in (select cont from conturi where subunitate=deleted.subunitate and sold_credit=9) 
order by subunitate,marca,dec

open tmp
fetch next from tmp into @csub,@ctip,@cmarca,@cdecont,@semn,@suma,@sumav,@sumadec,@sumadecv, @valuta,@curs,@ddata,@ddatascad, @sumarestv, @lm, @com, @ex
set @gsub=@csub
set @gmarca=@cmarca
set @gdecont=@cdecont
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Valoarev=0
	set @Decontat=0
	set @Decontatv=0
	set @Datadec=''
	set @Datascad=''
	set @glm=''
	set @gcom=''
	set @gex=''
	while @gsub=@csub and @gmarca=@cmarca and @gdecont=@cdecont and @gfetch=0
	begin
		set @valoare=@valoare+@suma*@semn*(case when @ctip='ID' then @decrest1 else 1 end)
			+(case when left(@ctip,1)='I' then @sumadec*@semn else 0 end)
		set @decontat=@decontat
			+@sumadec*@semn*(case when left(@ctip,1)='P' then 1 else 0 end)
			+@suma*@semn*(case when @ctip='ID' then @decrest2 else 0 end)
		if @valuta<>'' 
			set @valoarev=@valoarev
				+(case when @ctip='ID' then @decrest1 else 1 end)*@sumav*@semn
				+(case when left(@ctip,1)='I' then @decontatv*@semn else 0 end)
		if @valuta<>'' 
			set @decontatv=@decontatv
				+@sumav*@semn*(case when @ctip='ID' then @decrest2 else 0 end)
				+@sumarestv*@semn*(case when left(@ctip,1)='P' then 1 else 0 end)
		if @semn=1 and @suma=0 and @sumav=0 set @datadec=@ddata
		if @semn=1 and not(@suma=0 and @sumav=0) set @datascad=@ddatascad
		if @semn=1 and not(@suma=0 and @sumav=0) set @glm=@lm
		if @semn=1 and not(@suma=0 and @sumav=0) set @gcom=@com
		if @semn=1 and not(@suma=0 and @sumav=0) set @gex=@ex
		fetch next from tmp into @csub,@ctip,@cmarca,@cdecont,@semn,@suma,@sumav,@sumadec, 
			@sumadecv,@valuta,@curs,@ddata,@ddatascad,@sumarestv, @lm, @com, @ex
		set @gfetch=@@fetch_status
	end
	update deconturi set valoare=valoare+@valoare, decontat=decontat+@decontat, sold=sold+@valoare-@decontat,
		data_ultimei_decontari=(case when @datadec='' then data_ultimei_decontari else @datadec end), 
		valoare_valuta=valoare_valuta+@valoarev, 
		data_scadentei=(case when @datascad='' then data_scadentei else @datascad end),
		decontat_valuta=decontat_valuta+@decontatv, sold_valuta=sold_valuta+@valoarev-@decontatv, 
		loc_de_munca=(case when @glm='' then loc_de_munca else @glm end),
		comanda=(case when @gcom='' then comanda else @gcom end),
		explicatii=(case when @gex='' then explicatii else @gex end)
	where subunitate=@gsub and tip='T' and marca=@gmarca and decont=@gdecont
	delete from deconturi where subunitate=@gsub and tip='T' and marca=@gmarca and decont=@gdecont 
		and valoare=0 and decontat=0 and valoare_valuta=0 and decontat_valuta=0
	set @gmarca=@cmarca
	set @gsub=@csub
	set @gdecont=@cdecont
end

close tmp
deallocate tmp
end

GO
create trigger ScriuPozPlinDocDeContat on pozplin for insert,update,delete
as
	insert into DocDeContat(subunitate,tip,numar,data)
		select iu.subunitate,'PI',iu.cont,iu.data
		from
			(select i.subunitate,i.cont,i.data from inserted i
			union
			select u.subunitate,u.cont,u.data from deleted u) iu
		left outer join DocDeContat dc on iu.subunitate=dc.subunitate and dc.tip='PI' and iu.Cont=dc.numar and iu.data=dc.data
		where dc.subunitate is null --doar daca nu exista
		group by iu.subunitate,iu.cont,iu.data		
