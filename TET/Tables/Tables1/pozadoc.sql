CREATE TABLE [dbo].[pozadoc] (
    [Subunitate]      CHAR (9)     NOT NULL,
    [Numar_document]  CHAR (8)     NOT NULL,
    [Data]            DATETIME     NOT NULL,
    [Tert]            CHAR (13)    NOT NULL,
    [Tip]             CHAR (2)     NOT NULL,
    [Factura_stinga]  CHAR (20)    NOT NULL,
    [Factura_dreapta] CHAR (20)    NOT NULL,
    [Cont_deb]        VARCHAR (20) NULL,
    [Cont_cred]       VARCHAR (20) NULL,
    [Suma]            FLOAT (53)   NOT NULL,
    [TVA11]           FLOAT (53)   NOT NULL,
    [TVA22]           FLOAT (53)   NOT NULL,
    [Utilizator]      CHAR (10)    NOT NULL,
    [Data_operarii]   DATETIME     NOT NULL,
    [Ora_operarii]    CHAR (6)     NOT NULL,
    [Numar_pozitie]   INT          NOT NULL,
    [Tert_beneficiar] CHAR (13)    NOT NULL,
    [Explicatii]      CHAR (50)    NOT NULL,
    [Valuta]          CHAR (3)     NOT NULL,
    [Curs]            FLOAT (53)   NOT NULL,
    [Suma_valuta]     FLOAT (53)   NOT NULL,
    [Cont_dif]        VARCHAR (20) NULL,
    [suma_dif]        FLOAT (53)   NOT NULL,
    [Loc_munca]       CHAR (9)     NOT NULL,
    [Comanda]         CHAR (40)    NOT NULL,
    [Data_fact]       DATETIME     NOT NULL,
    [Data_scad]       DATETIME     NOT NULL,
    [Stare]           SMALLINT     NOT NULL,
    [Achit_fact]      FLOAT (53)   NOT NULL,
    [Dif_TVA]         FLOAT (53)   NOT NULL,
    [Jurnal]          VARCHAR (20) NULL,
    [detalii]         XML          NULL,
    [idPozadoc]       INT          IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_idPozadoc] PRIMARY KEY NONCLUSTERED ([idPozadoc] ASC)
);




GO
CREATE UNIQUE CLUSTERED INDEX [Actualizare]
    ON [dbo].[pozadoc]([Subunitate] ASC, [Tip] ASC, [Numar_document] ASC, [Data] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Dreapta]
    ON [dbo].[pozadoc]([Subunitate] ASC, [Tert] ASC, [Factura_dreapta] ASC);


GO
CREATE NONCLUSTERED INDEX [Stanga]
    ON [dbo].[pozadoc]([Subunitate] ASC, [Tert] ASC, [Factura_stinga] ASC);


GO



GO
create trigger ScriuPozAdocDocDeContat on pozadoc for insert,update,delete
as
	insert into DocDeContat(subunitate,tip,numar,data)
		select iu.subunitate,iu.tip,iu.numar_document,iu.data
		from
			(select i.subunitate,i.tip,i.numar_document,i.data from inserted i
			union
			select u.subunitate,u.tip,u.numar_document,u.data from deleted u) iu
		left outer join DocDeContat dc on iu.subunitate=dc.subunitate and dc.tip=iu.tip and iu.numar_document=dc.numar and iu.data=dc.data
		where dc.subunitate is null --doar daca nu exista
		group by iu.subunitate,iu.tip,iu.numar_document,iu.data		

GO
--***
create trigger adocfacst on pozadoc for update,insert,delete as 
begin
insert into facturi select subunitate,max(loc_munca),(case when tip in ('CB','IF','FB') then 0x46 else 0x54 end),factura_stinga,tert,max(data_fact),max(data_scad),
0,0,0,max(valuta),max(curs),0,0,0,max(cont_deb),0,0,max(comanda),max(data_fact) 
from inserted ins where tip<>'FF' and factura_stinga not in (select factura from facturi where subunitate=ins.subunitate and tert=ins.tert and tip=(case when ins.tip in ('CB','IF','FB') then 0x46 else 0x54 end))
group by subunitate,(case when tip in ('CB','IF','FB') then 0x46 else 0x54 end),tert,factura_stinga

declare @val float,@valv float,@vtva float,@vtva9 float,@ach float,@achv float,@dataultachit datetime,@ct varchar(40),@csub char(9),@ctip char(2),@data datetime,@ctert char(13),@cfact char(20),
@semn int,@s float,@sv float,@sdif float,@tva11 float,@tva22 float,@vlt char(3),@curs float,@achf float,@dift float,@ds datetime,@TVAv float,
@gct varchar(40),@gsub char(9),@gtip char(2),@gt char(13),@gf char(20),@tipf binary,@gds datetime,@gfetch int,@gcurs float,@dataf datetime,@gdataf datetime, 
@lm char(9), @glm char(9), @comanda char(40), @gcomanda char(40)

declare tmp cursor for
select i.subunitate,i.tip,i.data,i.tert,i.factura_stinga as factura,1,i.suma,i.suma_valuta,(case when i.tip in ('CF','SF','CO') and left(i.cont_dif,1) in ('6','3') then -i.suma_dif else i.suma_dif end),
i.tva11,(case when i.tip in ('IF','FB') and i.stare in (1,2) then 0 else i.tva22 end),i.valuta,i.curs,i.achit_fact,i.dif_TVA,i.data_scad,
(case when i.tip='C3' or i.tip in ('IF','FB') and i.stare in (1,2) or i.tip in ('IF','SF') and isnumeric(i.tert_beneficiar)=0 then 0 when i.tip='FB' then i.dif_TVA else convert(float,i.tert_beneficiar) end),
i.cont_deb, i.data_fact, i.loc_munca, 
left(i.comanda,20)+isnull(nullif(i.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(nullif(cf.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(cc.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')))
from inserted i
left outer join conturi cf on i.tip='FB' and cf.subunitate = i.subunitate and cf.cont = i.cont_deb
left outer join conturi cc on i.tip='FB' and cc.subunitate = i.subunitate and cc.cont = i.cont_cred
where tip<>'FF'
union all
select subunitate,tip,data,tert,factura_stinga,-1,suma,suma_valuta,(case when tip in ('CF','SF','CO') and left(cont_dif,1) in ('6','3') then -suma_dif else suma_dif end),
tva11,(case when tip in ('IF','FB') and stare in (1,2) then 0 else tva22 end),valuta,curs,achit_fact,dif_TVA,data_scad,
(case when tip='C3' or tip in ('IF','FB') and stare in (1,2) or tip in ('IF','SF') and isnumeric(tert_beneficiar)=0 then 0 when tip='FB' then dif_TVA else convert(float,tert_beneficiar) end),
cont_deb, data_fact, loc_munca, comanda
from deleted where tip<>'FF'
order by subunitate,tip,tert,factura
open tmp
fetch next from tmp into @csub,@ctip,@data,@ctert,@cfact,@semn,@s,@sv,@sdif,@tva11,@tva22,@vlt,@curs,@achf,@dift,@ds,@TVAv,@ct,@dataf,@lm,@comanda
set @gsub=@csub
set @gt=@ctert
set @gf=@cfact
set @gtip=@ctip
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @val=0
set @valv=0
set @vtva=0
set @vtva9=0
set @ach=0
set @achv=0
set @dataultachit=''
set @gct=''
set @gds=@ds
set @gcurs=@curs
set @gdataf=''
set @glm=''
set @gcomanda=''
while @gsub=@csub and @cTip=@gTip and @gt=@ctert and @gf=@cfact and @gfetch=0
begin
	if @ctip in ('CB','IF','FB') set @tipf=0x46 else set @tipf=0x54
	if @ctip='CO' or @ctip='C3' begin
		set @ach=@ach+@s*@semn+@semn*@sdif
		if @vlt<>'' set @achv=@achv+@semn*@sv
	end
	if @ctip='CF' 
		if @vlt='' set @ach=@ach+@s*@semn
		else begin
		set @ach=@ach+@s*@semn+@semn*@sdif
		set @achv=@achv+@achf*@semn
		end
	if @ctip='CB' begin
		if @vlt='' 
			set @ach=@ach-@s*@semn
		else begin
		set @ach=@ach-@s*@semn
		set @achv=@achv-@sv*@semn
		end
		if @semn=1 set @gds=@ds
	end
	if @ctip='SF' begin
		set @ach=@ach+@s*@semn+@semn*@tva22-@semn*@dift
		if @vlt<>'' 
		begin
		set @ach=@ach+@sdif*@semn
		set @achv=@achv+@semn*(@achf+@TVAv)
		set @achv=@achv-(case when @tva22<>0 then @semn*(@dift/@tva22)*@TVAv else 0 end)
		end
	end
	if @ctip='IF' begin
		set @val=@val+@s*@semn
		set @vtva=@vtva+(case when @tva11 in (9,11) then 0 else @tva22 end)*@semn
		set @vtva9=@vtva9+(case when @tva11 in (9,11) then @tva22 else 0 end)*@semn
		if @vlt<>'' 
			set @valv=@valv+@sv*@semn
		if @vlt<>'' 
			set @valv=@valv+@TVAv*@semn
		if @semn=1 set @gds=@ds
	end
	if @ctip='FB' begin
		set @val=@val+@semn*@s
		set @valv=@valv+@semn*@sv+@semn*@TVAv
		set @vtva=@vtva+(case when @tva11 in (9,11) then 0 else @tva22 end)*@semn
		set @vtva9=@vtva9+(case when @tva11 in (9,11) then @tva22 else 0 end)*@semn
		if @semn=1 set @gds=@ds
		if @semn=1 set @gcurs=@curs
	end
	if @semn=1 and @ctip in ('CO','CF','CB','SF') set @dataultachit=@data
	if @semn=1 and @ctip in ('CB','IF','FB') set @gct=@ct
	if @semn=1 set @gdataf=(case when @gdataf<='01/01/1901' or @dataf<@gdataf then @dataf else @gdataf end)
	if @semn=1 set @glm=(case when @lm<>'' then @lm else @glm end)
	if @semn=1 set @gcomanda=(case when @comanda<>'' then @comanda else @gcomanda end)
	fetch next from tmp into @csub,@ctip,@data,@ctert,@cfact,@semn,@s,@sv,@sdif,@tva11,@tva22,@vlt,@curs,@achf,@dift,@ds,@TVAv,@ct,@dataf,@lm,@comanda
	set @gfetch=@@fetch_status
end
update facturi set valoare=valoare+@val,tva_22=tva_22+@vtva,tva_11=tva_11+@vtva9,achitat=achitat+@ach,
sold=sold+@val+@vtva+@vtva9-@ach,data_ultimei_achitari=@dataultachit,
cont_de_tert=(case when @gct='' then cont_de_tert else @gct end),
data_scadentei=(case when @gtip in ('IF','FB'/*,'CB'*/) then @gds else data_scadentei end),
data=(case when @gdataf>'01/01/1901' and @gdataf<data then @gdataf else data end),
loc_de_munca=(case when loc_de_munca='' or @gdataf>'01/01/1901' and (@gdataf<data or @gdataf=data and (loc_de_munca='' or @gtip in ('IF','FB'))) and @glm<>'' then @glm else loc_de_munca end),
comanda=(case when comanda='' or @gdataf>'01/01/1901' and (@gdataf<data or @gdataf=data and (Comanda='' or @gtip in ('IF','FB'))) and @gcomanda<>'' then @gcomanda else comanda end)
where subunitate=@gsub and tip=@tipf and tert=@gt and factura=@gf

update facturi set valoare_valuta=valoare_valuta+@valv,achitat_valuta=achitat_valuta+@achv,
sold_valuta=sold_valuta+@valv-@achv,curs=(case when @gtip='FB' then @gcurs else curs end)
from terti t where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gt and facturi.factura=@gf 
and facturi.subunitate=t.subunitate and facturi.tert=t.tert and t.tert_extern=1
set @gt=@ctert
set @gsub=@csub
set @gf=@cfact
set @gtip=@ctip
end
close tmp
deallocate tmp
end

GO

create  trigger tr_ValidPozadoc on pozadoc for insert,update,delete NOT FOR REPLICATION as
begin try
	DECLARE 
		@errCt varchar(50), @msgErrCt varchar(500), @utilizator varchar(100)

	set @utilizator=dbo.fIaUtilizator(null)

	/* Validare loc de munca */
	if UPDATE(loc_munca) 
	begin
		create table #lm(utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm(utilizator,cod,data)
		select distinct @utilizator,loc_munca,data from inserted		
		exec validLM
	end

	/* Validare tert */
	if UPDATE(tert) 
	begin
		select DISTINCT tert cod into #terti 
		from inserted
		exec validTert
	end 

	/** Validare comanda */
	IF UPDATE(comanda)
	BEGIN
		select DISTINCT LEFT(comanda,20) comanda into #comenzi from INSERTED 
		exec validComanda		
	END

	/** Validare valuta si curs */
	IF UPDATE(valuta) or UPDATE(curs)
	BEGIN
		select DISTINCT tip, numar_document as numar, data, valuta, curs into #valute
			from INSERTED where valuta<>'' or curs<>0
		exec validValuta
	END

	/** Validare formule contabile + conturi in sine */
	IF UPDATE(cont_deb) OR UPDATE(cont_cred)
	BEGIN
		create table #formulecontabile (cont_credit varchar(40), cont_debit varchar(40), tip varchar(2), numar varchar(20), data datetime)
		insert into #formulecontabile(cont_credit, cont_debit, tip, numar, data)
		select cont_deb, cont_cred, tip, numar_document, Data from INSERTED
		exec validFormuleContabile
	END

	-- validare suma_de_tva fara cota_de_tva
	if exists (select 1 from inserted where TVA11=0 and abs(TVA22)>0.001)
		RAISERROR ('Documentul nu poate avea TVA fara a i se preciza Cota de TVA!', 16, 1)
		

	/** Validare luna inchisa contabil */
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
	set @mesaj =  ERROR_MESSAGE()+ ' (tr_ValidPozADoc)'
	raiserror ( @mesaj,16,1 )
end catch

GO
--***
/*Pentru creat antet alte documente*/
create trigger adocantet on pozadoc for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @docdef int--, @docdefie int
	set @docdef=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DOCDEF'),0)
	if (@docdef=1) set @docdef=1-isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DOCDEFIE'),0) 	
	--set @docdefie=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DOCDEFIE'),0)
	/**	sau :1=1 and :2=0	in expresia de mai jos*/
-------------
insert into adoc (Subunitate,Tip,Numar_document,Data,Tert,Numar_pozitii,Jurnal,Stare)
	select subunitate,tip,numar_document,data,max(tert),0,max (jurnal), max(case when stare=7 or @docdef=1 and stare=2 then stare else 0 end)
	from inserted where numar_document not in 
	(select numar_document from adoc where subunitate=inserted.subunitate 
	and tip=inserted.tip and data=inserted.data) 
	group by subunitate,tip,numar_document,data

/*Pentru calculul nr. de pozitii*/
declare @numar_poz int
declare @csub char(9),@ctip char(2),@cnr char(8),@cdata datetime,@semn int
declare @gsub char(9),@gtip char(2),@gnr char(8),@gdata datetime,@gfetch int

declare tmp cursor for
select subunitate,tip,numar_document,data,1
	from inserted union all
select subunitate,tip,numar_document,data,-1
	from deleted 
order by subunitate,tip,numar_document,data

open tmp
fetch next from tmp into @csub,@ctip,@cnr,@cdata,@semn
set @gsub=@csub
set @gtip=@ctip
set @gnr=@cnr
set @gdata=@cdata
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @numar_poz=0
	while @gsub=@csub and @gtip=@ctip and @gnr=@cnr and @gdata=@cdata and @gfetch=0
	begin
		set @numar_poz=@numar_poz+@semn
		fetch next from tmp into @csub,@ctip,@cnr,@cdata,@semn
		set @gfetch=@@fetch_status
	end
	update adoc set numar_pozitii=numar_pozitii+@numar_poz 
		where adoc.subunitate=@gsub and adoc.tip=@gtip and 
		adoc.numar_document=@gnr and adoc.data=@gdata
	set @gsub=@csub
	set @gtip=@ctip
	set @gnr=@cnr
	set @gdata=@cdata
end

close tmp
deallocate tmp
end

GO
--***
create trigger adocfacdr on pozadoc for update,insert,delete as 
begin

/*	Validare "unicitate" factura (pe tert, tip, data), numar */
IF UPDATE (factura_dreapta)
begin
	SELECT distinct tert, factura_dreapta factura, data data, 'F' tip 
	INTO #facturi
	from Inserted where tip in ('SF')


	exec validFactura
end

insert into facturi select subunitate,max(loc_munca),(case when tip in ('CF','SF','FF') then 0x54 else 0x46 end),factura_dreapta,(case when tip='C3' then tert_beneficiar else tert end),max(data_fact),max(data_scad),
0,0,0,max(valuta),max(curs),0,0,0,max(cont_cred),0,0,max(comanda),max(data_fact) 
from inserted ins 
where tip<>'FB' and factura_dreapta not in (select factura from facturi where subunitate=ins.subunitate and tert=(case when ins.tip='C3' then ins.tert_beneficiar else ins.tert end) 
and tip=(case when ins.tip in ('CF','SF','FF') then 0x54 else 0x46 end))
group by subunitate,(case when tip in ('CF','SF','FF') then 0x54 else 0x46 end),factura_dreapta,(case when tip='C3' then tert_beneficiar else tert end)

declare @val float,@valv float,@vtva float,@vtva9 float,@ach float,@achv float,@dataultachit datetime,@ct varchar(40),@csub char(9),@ctip char(2),@data datetime,@ctert char(13),@cfact char(20),
@semn int,@s float,@sv float,@sdif float,@tva11 float,@tva22 float,@vlt char(3),@curs float,@achf float,@dift float,@ds datetime,@TVAv float,@diftvaval float,
@gct varchar(40),@gsub char(9),@gtip char(2),@gt char(13),@gf char(20),@tipf binary,@gds datetime,@gfetch int,@gvlt char(3),@gcurs float,
@dataf datetime, @gdataf datetime, @lm char(9), @glm char(9), @comanda char(40), @gcomanda char(40)

declare tmp cursor for
select i.subunitate,i.tip,i.data,(case when tip='C3' then i.tert_beneficiar else i.tert end) as tert,i.factura_dreapta as factura,1,i.suma,i.suma_valuta,
(case when i.tip in ('CB','IF') and left(i.cont_dif,1)='7' then -i.suma_dif else i.suma_dif end) as suma_dif,i.tva11,(case when i.tip in ('SF','FF') and i.stare=1 then 0 else i.tva22 end),
i.valuta,i.curs,i.achit_fact,i.dif_TVA,i.data_scad,
(case when i.tip='C3' or i.tip in ('FF','SF') and i.stare=1 or i.tip in ('SF','IF') and isnumeric(i.tert_beneficiar)=0 then 0 when i.tip='FF' then i.dif_TVA else convert(float,i.tert_beneficiar) end),
i.cont_cred, i.data_fact, i.loc_munca, 
left(i.comanda,20)+isnull(nullif(i.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(nullif(cf.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(cd.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')))
from inserted i
left outer join conturi cf on i.tip='FF' and cf.subunitate = i.subunitate and cf.cont = i.cont_cred
left outer join conturi cd on i.tip='FF' and cd.subunitate = i.subunitate and cd.cont = i.cont_deb
where i.tip<>'FB' 
union all
select subunitate,tip,data,(case when tip='C3' then tert_beneficiar else tert end),factura_dreapta,-1,suma,suma_valuta,
(case when tip in ('CB','IF') and left(cont_dif,1)='7' then -suma_dif else suma_dif end),tva11,(case when tip in ('SF','FF') and stare=1 then 0 else tva22 end),
valuta,curs,achit_fact,dif_TVA,data_scad,
(case when tip='C3' or tip in ('FF','SF') and stare=1 or tip in ('SF','IF') and isnumeric(tert_beneficiar)=0 then 0 when tip='FF' then dif_TVA else convert(float,tert_beneficiar) end),
cont_cred, data_fact, loc_munca, comanda
from deleted where tip<>'FB'
order by subunitate,tip,tert,factura
open tmp
fetch next from tmp into @csub,@ctip,@data,@ctert,@cfact,@semn,@s,@sv,@sdif,@tva11,@tva22,@vlt,@curs,@achf,@dift,@ds,@TVAv,@ct,@dataf,@lm,@comanda
set @gsub=@csub
set @gt=@ctert
set @gf=@cfact
set @gtip=@ctip
set @gfetch=@@fetch_status
while @gfetch=0
begin
set @val=0
set @valv=0
set @vtva=0
set @vtva9=0
set @ach=0
set @achv=0
set @dataultachit=''
set @gct=''
set @gds=@ds
set @gvlt=@vlt
set @gcurs=@curs
set @gdataf=''
set @glm=''
set @gcomanda=''
while @gsub=@csub and @cTip=@gTip and @gt=@ctert and @gf=@cfact and @gfetch=0
begin
	if @ctip in ('CF','SF','FF') set @tipf=0x54 else set @tipf=0x46
	if @ctip='CO' or @ctip='C3' begin
		set @ach=@ach+@s*@semn
		if @vlt<>'' 
			set @achv=@achv+@semn*@sv
	end
	if @ctip='CF' begin
		if @vlt='' set @ach=@ach-(@s-(case when @cfact in (select factura from factimpl where subunitate=@gsub and tert=@gt and tip=0X54) then @tva22 else 0 end))*@semn
		else
		begin
		set @ach=@ach-@s*@semn
		set @achv=@achv-@sv*@semn
		end
		if @semn=1 set @gds=@ds
	end
	if @ctip='CB' 
		if @vlt='' set @ach=@ach+@s*@semn
		else begin
		set @ach=@ach+@s*@semn+@semn*@sdif
		set @achv=@achv+@achf*@semn
		end
	if @ctip='SF' begin
		set @val=@val+@s*@semn
		set @vtva=@vtva+(case when @tva11 in (9,11) then 0 else @tva22 end)*@semn
		set @vtva9=@vtva9+(case when @tva11 in (9,11) then @tva22 else 0 end)*@semn
		if @vlt<>'' set @valv=@valv+@semn*(@sv+@TVAv)
		if @semn=1 set @gds=@ds
	end
	if @ctip='IF' begin
		set @ach=@ach+@s*@semn+@semn*@tva22-@semn*@dift
		if @vlt<>'' 
		begin
		set @ach=@ach+@sdif*@semn
		set @achv=@achv+@achf*@semn
		set @achv=@achv+@TVAv*@semn
		set @achv=@achv-(case when @tva22<>0 then @semn*(@dift/@tva22)*@TVAv else 0 end)
		end
	end
	if @ctip='FF' begin
		set @val=@val+@semn*@s
		set @valv=@valv+@semn*@sv+@semn*@TVAv
		set @vtva=@vtva+(case when @tva11 in (9,11) then 0 else @tva22 end)*@semn
		set @vtva9=@vtva9+(case when @tva11 in (9,11) then @tva22 else 0 end)*@semn
		if @semn=1 set @gds=@ds
		if @semn=1 and @vlt<>'' set @gcurs=@curs
	end
	if @semn=1 and @ctip in ('CO','CF','CB','IF') set @dataultachit=@data
	if @semn=1 and @ctip in ('CF','SF','FF') set @gct=@ct
	if @semn=1 set @gdataf=(case when @gdataf<='01/01/1901' or @dataf<@gdataf then @dataf else @gdataf end)
	if @semn=1 set @glm=(case when @lm<>'' then @lm else @glm end)
	if @semn=1 set @gcomanda=(case when @comanda<>'' then @comanda else @gcomanda end)
	fetch next from tmp into @csub,@ctip,@data,@ctert,@cfact,@semn,@s,@sv,@sdif,@tva11,@tva22,@vlt,@curs,@achf,@dift,@ds,@TVAv,@ct,@dataf,@lm,@comanda
	set @gfetch=@@fetch_status
end
update facturi set valoare=valoare+@val,tva_22=tva_22+@vtva,tva_11=tva_11+@vtva9,achitat=achitat+@ach,
sold=sold+@val+@vtva+@vtva9-@ach,data_ultimei_achitari=(case when @gtip in ('CB','CF','CO','C3') then @dataultachit else data_ultimei_achitari end),
cont_de_tert=(case when @gct='' then cont_de_tert else @gct end),
data_scadentei=(case when @gtip in ('SF','FF'/*,'CF'*/) then @gds else data_scadentei end),/*valuta='',curs=0,*/
data=(case when @gdataf>'01/01/1901' and @gdataf<data then @gdataf else data end),
loc_de_munca=(case when loc_de_munca='' or @gdataf>'01/01/1901' and (@gdataf<data or @gdataf=data and (loc_de_munca='' or @gtip in ('SF','FF'))) and @glm<>'' then @glm else loc_de_munca end),
comanda=(case when comanda='' or @gdataf>'01/01/1901' and (@gdataf<data or @gdataf=data and (Comanda='' or @gtip in ('SF','FF'))) and @gcomanda<>'' then @gcomanda else comanda end)
where subunitate=@gsub and tip=@tipf and tert=@gt and factura=@gf

update facturi set valoare_valuta=valoare_valuta+@valv,achitat_valuta=achitat_valuta+@achv,
sold_valuta=sold_valuta+@valv-@achv ,curs=(case when @gtip='FF' and @gvlt<>'' then @gcurs else curs end)  
from terti t where facturi.subunitate=@gsub and facturi.tip=@tipf and facturi.tert=@gt and facturi.factura=@gf 
and facturi.subunitate=t.subunitate and facturi.tert=t.tert and t.tert_extern=1 	

delete from facturi where @ctip='FF' and subunitate=@gsub and tip=@tipf and tert=@gt and factura=@gf 
and valoare=0 and tva_22=0 and tva_11=0 and achitat=0 and valoare_valuta=0 and achitat_valuta=0
set @gt=@ctert
set @gsub=@csub
set @gf=@cfact
set @gtip=@ctip
end
close tmp
deallocate tmp
end

GO
--***
create trigger pozadocsterg on pozadoc for update, delete /*with append*/ NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspa
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Data_operarii, Ora_operarii,
	Subunitate, Numar_document, Data, Tert, Tip, Factura_stinga, Factura_dreapta, Cont_deb, Cont_cred, Suma, TVA11,
	TVA22, Utilizator, Numar_pozitie, Tert_beneficiar, Explicatii, Valuta, Curs, Suma_valuta, Cont_dif, suma_dif, 
	Loc_munca, Comanda, Data_fact, Data_scad, Stare, Achit_fact, Dif_TVA, Jurnal
   from deleted
