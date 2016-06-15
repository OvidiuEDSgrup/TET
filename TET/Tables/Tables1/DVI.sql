CREATE TABLE [dbo].[DVI] (
    [Subunitate]          CHAR (9)     NOT NULL,
    [Numar_DVI]           CHAR (13)    NOT NULL,
    [Data_DVI]            DATETIME     NOT NULL,
    [Numar_receptie]      CHAR (8)     NOT NULL,
    [Data_receptiei]      DATETIME     NOT NULL,
    [Tert_receptie]       CHAR (13)    NOT NULL,
    [Valoare_fara_CIF]    FLOAT (53)   NOT NULL,
    [Factura_CIF]         CHAR (20)    NOT NULL,
    [Data_CIF]            DATETIME     NOT NULL,
    [Tert_CIF]            CHAR (13)    NOT NULL,
    [Cont_CIF]            VARCHAR (20) NULL,
    [Procent_CIF]         REAL         NOT NULL,
    [Valoare_CIF]         FLOAT (53)   NOT NULL,
    [Valuta_CIF]          CHAR (3)     NOT NULL,
    [Curs]                FLOAT (53)   NOT NULL,
    [Valoare_CIF_lei]     FLOAT (53)   NOT NULL,
    [TVA_CIF]             FLOAT (53)   NOT NULL,
    [Total_vama]          FLOAT (53)   NOT NULL,
    [Tert_vama]           CHAR (13)    NOT NULL,
    [Factura_vama]        CHAR (20)    NOT NULL,
    [Cont_vama]           VARCHAR (20) NULL,
    [Suma_vama]           FLOAT (53)   NOT NULL,
    [Cont_suprataxe]      VARCHAR (20) NULL,
    [Suma_suprataxe]      FLOAT (53)   NOT NULL,
    [TVA_22]              FLOAT (53)   NOT NULL,
    [TVA_11]              FLOAT (53)   NOT NULL,
    [Val_fara_comis]      FLOAT (53)   NOT NULL,
    [Tert_comis]          CHAR (13)    NOT NULL,
    [Factura_comis]       CHAR (20)    NOT NULL,
    [Data_comis]          DATETIME     NOT NULL,
    [Cont_comis]          VARCHAR (20) NULL,
    [Valoare_comis]       FLOAT (53)   NOT NULL,
    [TVA_comis]           FLOAT (53)   NOT NULL,
    [Valoare_intrare]     FLOAT (53)   NOT NULL,
    [Valoare_TVA]         FLOAT (53)   NOT NULL,
    [Valoare_accize]      FLOAT (53)   NOT NULL,
    [Cont_tert_vama]      VARCHAR (20) NULL,
    [Factura_TVA]         CHAR (20)    NOT NULL,
    [Cont_factura_TVA]    VARCHAR (20) NULL,
    [Cont_vama_suprataxe] VARCHAR (20) NULL,
    [Cont_com_vam]        VARCHAR (20) NULL,
    [Suma_com_vam]        FLOAT (53)   NOT NULL,
    [Dif_vama]            FLOAT (53)   NOT NULL,
    [Dif_com_vam]         FLOAT (53)   NOT NULL,
    [Utilizator]          CHAR (10)    NOT NULL,
    [Data_operarii]       DATETIME     NOT NULL,
    [Ora_operarii]        CHAR (6)     NOT NULL,
    [detalii]             XML          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Receptie]
    ON [dbo].[DVI]([Subunitate] ASC, [Numar_receptie] ASC, [Numar_DVI] ASC, [Data_DVI] ASC);


GO
CREATE NONCLUSTERED INDEX [DVI]
    ON [dbo].[DVI]([Subunitate] ASC, [Numar_DVI] ASC);


GO
--***
create trigger DVIfac on DVI for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @accimp int, @contfv int
	set @accimp=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='ACCIMP'),0)
	set @contfv=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='CONTFV'),0)
-------------
  /*Inserare pentru factura CIF*/
insert into facturi select subunitate,'',0x54,factura_CIF,tert_CIF,max(data_CIF),max(isnull(nullif(nullif(data_comis,''),'01/01/1901'),data_cif)), 0,0,0,max(valuta_CIF), max(curs), 0,0,0, max(cont_CIF),0,0,'',max(data_CIF) 
from inserted where tert_CIF<>'' and factura_CIF not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert_CIF and tip=0x54)
group by subunitate,tert_CIF,factura_CIF
  /*Inserare pentru factura vama*/
insert into facturi select subunitate,'',0x54,factura_vama,tert_vama,max(data_receptiei),max(substring(tert_comis,4,2)+'/'+left(tert_comis,2)+'/'+substring(tert_comis,7,4)), 0,0,0,'', 0,0,0,0, max(case when @contfv=0 or cont_tert_vama='' then cont_vama else cont_tert_vama end), 0,0,'',max(data_receptiei) 
from inserted where tert_vama<>'' and factura_vama not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert_vama and tip=0x54) and factura_comis in ('','D')
group by subunitate,tert_vama,factura_vama
  /*Inserare pentru factura comision vamal*/
insert into facturi select subunitate,'',0x54,left(cont_tert_vama,8),tert_vama,max(data_receptiei),max(substring(tert_comis,4,2)+'/'+left(tert_comis,2)+'/'+substring(tert_comis,7,4)), 0,0,0,'',0,0,0,0, max(cont_com_vam), 0,0,'',max(data_receptiei) 
from inserted where @contfv=0 and tert_vama<>'' and left(cont_tert_vama,8) not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert_vama and tip=0x54) and factura_comis in ('','D')
group by subunitate,tert_vama,cont_tert_vama
  /*Inserare pentru factura TVA vama*/
insert into facturi select subunitate,'',0x54, factura_TVA,tert_vama,max(data_receptiei),max(substring(tert_comis,4,2)+'/'+left(tert_comis,2)+'/'+substring(tert_comis,7,4)), 0,0,0,'', 0,0,0,0, max(cont_factura_TVA),0,0,'',max(data_receptiei) 
from inserted where @contfv=0 and tert_vama<>'' and factura_TVA not in (select factura from facturi where subunitate=inserted.subunitate and tert=inserted.tert_vama and tip=0x54) and factura_comis in ('','D')
group by subunitate,tert_vama,factura_TVA

declare @valoare float,@valoarev float,@valoaretva float,@soldf float,@valuta char(3),@gvaluta char(3),@cont varchar(40), @gcont varchar(40)
declare @csub char(9),@ctert char(13),@cfactura char(20),@semn int,@suma float,@sumav float,@tva22 float
declare @gsub char(9),@gtert char(13),@gfactura char(20), @gfetch int

declare tmp cursor for
select subunitate,tert_cif as tert,factura_cif as factura,1,valoare_cif_lei as valoare_comis,(case when valuta_cif='' then 0 else
valoare_cif end),TVA_cif as TVA_comis, valuta_cif, cont_CIF
from inserted where tert_CIF<>''
union all
select subunitate,tert_vama,factura_vama,1,
suma_vama+suma_suprataxe+dif_vama+(case when @contfv=1 then suma_com_vam+dif_com_vam else 0 end)+(case when @accimp=1 then valoare_accize+tva_11 else 0 end), 0, (case when @contfv=1 and total_vama<>1 then tva_22 else 0 end), '', (case when @contfv=0 or cont_tert_vama='' then cont_vama else cont_tert_vama end) 
from inserted where tert_vama<>'' and factura_comis in ('','D')
union all
select subunitate, tert_vama, left(cont_tert_vama,8), 1, suma_com_vam+dif_com_vam, 0, 0, '', cont_com_vam 
from inserted where @contfv=0 and tert_vama<>'' and factura_comis in ('','D')
union all
select subunitate, tert_vama, factura_tva, 1, 0, 0, (case when total_vama<>1 then tva_22 else 0 end), '', cont_factura_TVA 
from inserted where @contfv=0 and tert_vama<>'' and factura_comis in ('','D')

union all
select subunitate,tert_cif,factura_cif,-1,valoare_cif_lei,(case when valuta_cif='' then 0 else valoare_cif end),TVA_cif, valuta_cif, cont_CIF
from deleted where tert_CIF<>'' 
union all
select subunitate,tert_vama,factura_vama,-1,suma_vama+suma_suprataxe+dif_vama+(case when @contfv=1 then suma_com_vam+dif_com_vam else 0 end)+(case when @accimp=1 then valoare_accize+tva_11 else 0 end), 0, (case when @contfv=1 and total_vama<>1 then tva_22 else 0 end), '', (case when @contfv=0 or cont_tert_vama='' then cont_vama else cont_tert_vama end) 
from deleted where tert_vama<>'' and factura_comis in ('','D')
union all
select subunitate, tert_vama, left(cont_tert_vama,8), -1, suma_com_vam+dif_com_vam, 0, 0, '', cont_com_vam 
from deleted where @contfv=0 and tert_vama<>'' and factura_comis in ('','D')
union all
select subunitate,tert_vama,factura_tva, -1, 0, 0, (case when total_vama<>1 then tva_22 else 0 end), '', cont_factura_TVA 
from deleted where @contfv=0 and tert_vama<>'' and factura_comis in ('','D') 
order by subunitate,tert,factura

open tmp
fetch next from tmp into @csub,@ctert,@cfactura,@semn,@suma,@sumav,@tva22,@valuta,@cont
set @gsub=@csub
set @gtert=@ctert
set @gfactura=@cfactura
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @Valoare=0
	set @Valoarev=0
	set @Valoaretva=0
	set @soldf=0
	set @gvaluta=''
	set @gcont=''
	while @gsub=@csub and @gtert=@ctert and @gfactura=@cfactura and @gfetch=0
	begin
		set @soldf=@soldf+@suma*@semn+@tva22*@semn
		set @valoare=@valoare+@suma*@semn
		set @valoarev=@valoarev+@sumav*@semn
		set @valoaretva=@valoaretva+@tva22*@semn
		if @semn=1 set @gvaluta=@valuta
		if @semn=1 set @gcont=@cont
		fetch next from tmp into @csub,@ctert,@cfactura,@semn,@suma,@sumav,@tva22,@valuta,@cont
                                set @gfetch=@@fetch_status
	end
	update facturi set valoare=valoare+@valoare, tva_22=tva_22+@valoaretva, sold=sold+@valoare+@valoaretva,
		valoare_valuta=valoare_valuta+@valoarev, sold_valuta=sold_valuta+@valoarev, valuta=(case when @gvaluta='' then valuta else @gvaluta end), cont_de_tert=(case when @gcont='' then cont_de_tert else @gcont end)
	        where subunitate=@gsub and tip=0x54 and tert=@gtert and factura=@gfactura
	delete from facturi where subunitate=@gsub and tip=0x54 and tert=@gtert and factura=@gfactura 
		and valoare=0 and tva_22=0 and tva_11=0 and achitat=0 and valoare_valuta=0 and achitat_valuta=0
	set @gsub=@csub
	set @gtert=@ctert
	set @gfactura=@cfactura
end

close tmp
deallocate tmp
end
