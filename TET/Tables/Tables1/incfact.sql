CREATE TABLE [dbo].[incfact] (
    [Subunitate]    CHAR (9)     NOT NULL,
    [Numar_factura] CHAR (20)    NOT NULL,
    [Numar_pozitie] INT          NOT NULL,
    [Mod_plata]     CHAR (1)     NOT NULL,
    [Serie_doc]     CHAR (5)     NOT NULL,
    [Nr_doc]        CHAR (20)    NOT NULL,
    [data_doc]      DATETIME     NOT NULL,
    [suma_doc]      FLOAT (53)   NOT NULL,
    [datasc_doc]    DATETIME     NOT NULL,
    [mod_tp]        CHAR (1)     NOT NULL,
    [info_tp]       CHAR (50)    NOT NULL,
    [Tert]          CHAR (13)    NOT NULL,
    [Cont]          VARCHAR (20) NULL,
    [Loc_de_munca]  CHAR (13)    NOT NULL,
    [Utilizator]    CHAR (10)    NOT NULL,
    [Data_operarii] DATETIME     NOT NULL,
    [Ora_operarii]  CHAR (6)     NOT NULL,
    [Jurnal]        CHAR (3)     NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[incfact]([Subunitate] ASC, [Numar_factura] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar]
    ON [dbo].[incfact]([Subunitate] ASC, [Mod_plata] ASC, [Nr_doc] ASC);


GO
--***
CREATE TRIGGER incplin ON incFact FOR DELETE, INSERT, UPDATE NOT FOR REPLICATION AS
begin
-------------	din tabela par (parametri trimis de Magic):
	--	[Trim (FX)], [Trim (FZ)], GA, FY, [Trim (GS)], HI, [Trim (GU)], GT, GV
	declare @incnumf_a varchar(13), @credcard_a varchar(13), @credcard_n int, @incnumf_n int, @incefecte_a varchar(13), @incnumini int,
		@incec_a varchar(13), @incefecte_n int, @incec_n int
	set @incnumf_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru='GE' and parametru='INCNUMF'),''))
	set @credcard_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru='GE' and parametru='CREDCARD'),''))
	set @credcard_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='CREDCARD'),0)
	set @incnumf_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='INCNUMF'),0)
	set @incefecte_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru='GE' and parametru='INCEFECTE'),''))
	set @incnumini=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='INCNUMINI'),0)
	set @incec_a=rtrim(isnull((select top 1 val_alfanumerica from par where tip_parametru='GE' and parametru='INCCEC'),''))
	set @incefecte_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='INCEFECTE'),0)
	set @incec_n=isnull((select top 1 val_numerica from par where tip_parametru='GE' and parametru='INCCEC'),0)
-------------
SELECT DISTINCT A.Subunitate, 
(case when a.mod_plata='F' then @incefecte_a+(case when @incefecte_n=1 then '.'+rtrim(a.loc_de_munca) else '' end) when a.mod_plata='C' then @incec_a+(case when @incec_n=1 then '.'+rtrim(a.loc_de_munca) else '' end) 
	when a.mod_plata='K' then @credcard_a+(case when @credcard_n=1 then '.'+rtrim(a.loc_de_munca) else '' end) when a.mod_plata='N' and @incnumini=1 or a.mod_plata='V' then a.loc_de_munca 
	else @incnumf_a+(case when @incnumf_n=1 then '.'+rtrim(a.loc_de_munca) else '' end) end) as cont, 
a.Data_doc as data, rtrim(a.nr_doc) as numar, 'IB' as plata_incasare, a.Tert, a.numar_Factura as factura, 
a.cont as cont_corespondent, left('INC.FACT.'+a.mod_plata+' - '+rtrim(c.denumire), 50) as explicatii, b.Loc_de_munca, 
(case when 1=0 and a.mod_plata in ('K', 'C', 'F') then convert(char(10), a.datasc_doc, 102) else b.comanda end) as comanda, 
a.Utilizator, a.Data_operarii, a.ora_operarii, identity(int, 1, 1) as numar_pozitie, a.Jurnal, a.datasc_doc as data_scad,
(case when a.mod_plata = 'C' then a.serie_doc else '' end) as serieEfect, (case when a.mod_plata = 'C' then a.nr_doc else '' end) as numarEfect,
(case when a.mod_plata = 'C' then ltrim(left(a.info_tp,25)) else '' end) as bancaTERT, (case when a.mod_plata = 'C' then ltrim(substring(a.info_tp,26,25)) else '' end) as contTERT
into #incplin
FROM INSERTED A, facturi b, terti c 
WHERE a.tert=c.tert and a.tert=b.tert and a.numar_factura=b.factura and b.tip=0x46 and 
A.MOD_PLATA in ('N', 'V', 'K', 'F', 'C') and a.suma_doc<>0 
and not exists (select numar from pozplin where subunitate=a.subunitate 
	and cont=(case when a.mod_plata='F' then @incefecte_a+(case when @incefecte_n=1 then '.'+rtrim(a.loc_de_munca) else '' end) when a.mod_plata='C' then @incec_a+(case when @incec_n=1 then '.'+rtrim(a.loc_de_munca) else '' end) 
		when a.mod_plata='K' then @credcard_a+(case when @credcard_n=1 then '.'+rtrim(a.loc_de_munca) else '' end) when a.mod_plata='N' and @incnumini=1 or a.mod_plata='V' then a.loc_de_munca 
		else @incnumf_a+(case when @incnumf_n=1 then '.'+rtrim(a.loc_de_munca) else '' end) end) 
	and plata_incasare='IB' and data=a.data_doc and numar=a.nr_doc)

declare @NrPoz int, @Pozitii int
set @Pozitii = (select count(*) from #incplin)
set @NrPoz = isnull((select max(val_numerica) from par where tip_parametru='DO' and parametru='POZITIE'), 0)
if @NrPoz+@Pozitii > 999999999 set @NrPoz = 0
update par set val_numerica=@NrPoz+@Pozitii where tip_parametru='DO' and parametru='POZITIE'

INSERT INTO POZPLIN (Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22, 
Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, 
Cont_dif, Suma_dif, Achit_fact, Jurnal, detalii, tip_tva)
SELECT Subunitate, cont, data, numar, plata_incasare, tert, factura, 
cont_corespondent, 0, '', 0, 0, 0, 0, 0, 
explicatii, loc_de_munca, comanda, Utilizator, Data_operarii, Ora_operarii, @NrPoz+numar_pozitie, 
'', 0, 0, Jurnal, 
(select (case when serieEfect<>'' then serieEfect end) as serieefect, (case when numarEfect<>'' then numarEfect end) as numarefect, 
	(case when bancaTERT<>'' then bancaTERT end) as bancatert, (case when contTERT<>'' then contTERT end) as contbctert, 
	(case when data_scad<>'01/01/1901' then convert(varchar(10),data_scad,101) end) as datascad for xml raw), 0
from #incplin
drop table #incplin

declare @valoare float, @valoare_valuta float, @gfetch int, @glocm char(13), @gcont varchar(40), @gmodpl char(1), 
	@csub char(9), @cnumar char(9), @ctert char(13), @cfactura char(20), @suma float, @ddata datetime, @ddatasc datetime, @semn int, @valuta char(3), @curs float, 
	@gsub char(9), @gtert char(13), @gfactura char(20), @gnumar char(9), @gdata datetime, @gvaluta char(3), @gcurs float,
	@modpl char(1), @locm char(13), @gdatasc varchar(10), @vcont varchar(40)

declare tmpx cursor for
select subunitate, mod_plata, nr_doc, data_doc, tert, numar_factura, 1, suma_doc, 
loc_de_munca, datasc_doc,
rtrim(case when mod_plata='V' then left(info_tp, 3) else '' end) as valuta_doc, 
(case when mod_plata='V' and isnumeric(substring(info_tp, 4, 11))=1 then convert(float, substring(info_tp, 4, 11)) else 0 end) as curs_doc
from inserted where mod_plata in ('N', 'V', 'K', 'F', 'C') 
union all 
select subunitate, mod_plata, nr_doc, data_doc, tert, numar_factura, -1, suma_doc, 
loc_de_munca, datasc_doc,
rtrim(case when mod_plata='V' then left(info_tp, 3) else '' end), 
(case when mod_plata='V' and isnumeric(substring(info_tp, 4, 11))=1 then convert(float, substring(info_tp, 4, 11)) else 0 end)
from deleted where mod_plata in ('N', 'V', 'K', 'F', 'C') 
order by subunitate, mod_plata, nr_doc, data_doc, tert, numar_factura, valuta_doc, curs_doc

open tmpx
fetch next from tmpx into @csub, @modpl, @cnumar, @ddata, @ctert, @cfactura, @semn, @suma, @locm, @ddatasc, @valuta, @curs
set @gsub=@csub
set @gmodpl=@modpl
set @gnumar=@cnumar
set @gdata=@ddata
set @gvaluta=@valuta
set @gcurs=@curs
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @valoare=0
	set @valoare_valuta=0
	set @gtert=@ctert
	set @gfactura=@cfactura
	set @glocm=@locm
	set @gdatasc=convert(varchar(10),@ddatasc,101)
	while @gsub=@csub and @gmodpl=@modpl and @gnumar=@cnumar and @gdata=@ddata and @gvaluta=@valuta and @gcurs=@curs and @gfetch=0
	begin
		set @valoare=@valoare+@semn*(case when @modpl='V' then round(convert(decimal(18,5), @suma*@curs), 2) else @suma end)
		if @valuta<>'' and @curs<>0
			set @valoare_valuta=@valoare_valuta+@semn*@suma
		if @semn=1 set @gtert=@ctert
		if @semn=1 set @gfactura=@cfactura
		if @semn=1 set @glocm=@locm
		if @semn=1 set @gdatasc=convert(varchar(10),@ddatasc,101)
		fetch next from tmpx into @csub, @modpl, @cnumar, @ddata, @ctert, @cfactura, @semn, @suma, @locm, @ddatasc, @valuta, @curs
		set @gfetch=@@fetch_status
	end
	set @vcont=(case when @gmodpl='F' then @incefecte_a+(case when @incefecte_n=1 then '.'+rtrim(@glocm) else '' end) when @gmodpl='C' then @incec_a+(case when @incec_n=1 then '.'+rtrim(@glocm) else '' end) 
					when @gmodpl='K' then @credcard_a+(case when @credcard_n=1 then '.'+rtrim(@glocm) else '' end) when @gmodpl='N' and @incnumini=1 or @gmodpl='V' then @glocm 
					else @incnumf_a+(case when @incnumf_n=1 then '.'+rtrim(@glocm) else '' end) end)
	update pozplin 
	set suma=suma+@valoare, tert=@gtert, factura=@gfactura, 
	valuta=@gvaluta, curs=@gcurs, suma_valuta=@valoare_valuta,
	Curs_la_valuta_facturii=@gcurs, achit_fact=@valoare_valuta, 
	detalii=(case when detalii is null and isnull(@ddatasc,'01/01/1901')<>'01/01/1901' then '<row />' else detalii end)
	where subunitate=@gsub and data=@gdata  and plata_incasare='IB' and numar=@gnumar and cont=@vcont 

	if isnull(@gdatasc,'01/01/1901')<>'01/01/1901'
	begin
		update pozplin 
		set detalii.modify ('replace value of (/row/@datascad)[1] with sql:variable("@gdatasc")') 
		where subunitate=@gsub and data=@gdata and plata_incasare='IB' and numar=@gnumar and cont=@vcont and detalii.value('(/row/@datascad)[1]','varchar(10)') is not null

		update pozplin 
		set detalii.modify ('insert (attribute datascad {sql:variable("@gdatasc")}) into (/row)[1]')
		where subunitate=@gsub and data=@gdata and plata_incasare='IB' and numar=@gnumar and cont=@vcont and detalii.value('(/row/@datascad)[1]','varchar(10)') is null
	end

	delete from pozplin  
	where subunitate=@gsub and data=@gdata  and plata_incasare='IB' and numar=@gnumar and suma=0 and cont=@vcont 

	if exists (select 1 from DocDeContat where Subunitate='1' and Tip='PI' and Numar=@vcont and Data=@gdata)
		exec faInregistrariContabile @dinTabela=0, @Subunitate='1',@Tip='PI',@Numar=@vcont, @Data=@gdata

	set @gsub=@csub
	set @gmodpl=@modpl
	set @gnumar=@cnumar
	set @gdata=@ddata
	set @gvaluta=@valuta
	set @gcurs=@curs
end
close tmpx
deallocate tmpx
end
