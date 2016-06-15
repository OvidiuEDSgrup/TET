CREATE TABLE [dbo].[incrate] (
    [Subunitate]      CHAR (9)     NOT NULL,
    [Tip_contract]    CHAR (2)     NOT NULL,
    [Contract]        CHAR (20)    NOT NULL,
    [Numar_rata]      SMALLINT     NOT NULL,
    [Data_incasarii]  DATETIME     NOT NULL,
    [Numar_chitanta]  CHAR (8)     NOT NULL,
    [Suma_rata]       FLOAT (53)   NOT NULL,
    [Suma_dobanda]    FLOAT (53)   NOT NULL,
    [Suma_comision]   FLOAT (53)   NOT NULL,
    [Suma_penalitati] FLOAT (53)   NOT NULL,
    [Suma_incasata]   FLOAT (53)   NOT NULL,
    [Cont_incasare]   VARCHAR (20) NULL,
    [Tip_incasare]    BIT          NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[incrate]([Subunitate] ASC, [Tip_contract] ASC, [Contract] ASC, [Data_incasarii] ASC, [Numar_rata] ASC, [Numar_chitanta] ASC);


GO
--***
CREATE TRIGGER RATEPLIN ON INCRATE FOR INSERT, UPDATE, DELETE NOT FOR REPLICATION as
BEGIN
--rata si TVA
INSERT INTO POZPLIN 
(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22,
Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, 
Cont_dif, Suma_dif, Achit_fact, Jurnal)
SELECT distinct A.SUBUNITATE, a.cont_incasare, A.DATA_incasarii, A.NUMAR_CHITANTA, 'IR', B.TERT, B.FACTURA, 
isnull(C.CONT_de_tert,'4111'), 0, ' ', ' ',' ' ,' ',' ',' ',
'Rate: Inc. contract rate '+b.contract+' rata '+str(a.numar_rata,3), B.LOC_DE_MUNCA, b.contract+'RA'+ str(a.numar_rata,3), 'UC2000', GETDATE(), ' ',2*A.NUMAR_RATA+1, ' ',' ',' ',' '
FROM INSERTED A, CON B
left outer join facturi C on b.factura=c.factura and b.tert=c.tert and c.tip=0x46
WHERE A.contract=b.contract and
not exists (select numar from pozplin where numar=a.numar_chitanta and cont=a.cont_incasare and  a.subunitate=subunitate AND DATA=A.DATA_INCASARII and  PLATA_INCASARE='IR' and right(comanda,3)=str(a.numar_rata,3))
--dobanda
INSERT INTO POZPLIN 
(Subunitate, Cont, Data, Numar, Plata_incasare, Tert, Factura, 
Cont_corespondent, Suma, Valuta, Curs, Suma_valuta, Curs_la_valuta_facturii, TVA11, TVA22,
Explicatii, Loc_de_munca, Comanda, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, 
Cont_dif, Suma_dif, Achit_fact, Jurnal)
SELECT DISTINCT A.SUBUNITATE, a.cont_incasare, A.DATA_incasarii, A.NUMAR_CHITANTA, 'IC', ' ', A.NUMAR_CHITANTA, 
isnull(C.CONT_de_tert,'4111'), 0, ' ', ' ',' ' ,' ',' ',' ',
'Rate: Inc. dob. contract rate '+b.contract+' rata '+str(a.numar_rata,3), B.LOC_DE_MUNCA, b.contract+'RA'+ str(a.numar_rata,3), 'UC2000', GETDATE(), ' ',2*A.NUMAR_RATA+2, ' ',' ',' ',' '
FROM INSERTED A, CON B
left outer join facturi C on b.factura=c.factura and b.tert=c.tert and c.tip=0x46
WHERE A.contract=b.contract and 
not exists (select numar from pozplin where numar=a.numar_chitanta and cont=a.cont_incasare and  a.subunitate=subunitate AND DATA=A.DATA_INCASARII and  PLATA_INCASARE='IC' and right(comanda,3)=str(a.numar_rata,3))

DECLARE @GFETCH INT, @VALOARE1 FLOAT, @VALOARE2 FLOAT
DECLARE @SUB INT, @TIP_C CHAR(9),   @CONTR CHAR(20) ,  @DATA_I DATETIME ,@NUMAR_RATA CHAR(9) 
declare @numar_chit char(9),  @SUMA_R  FLOAT, @SUMA_i FLOAT, @SUMA_D FLOAT, @CONT_I CHAR(9), @SEMN INT
DECLARE @BSUB INT, @BTIP_C CHAR(9), @BCONTR CHAR(20),  @BDATA_I DATETIME, @BNUMAR_RATA CHAR(9), @bnumar_chit char(9)
declare @BSUMA_R FLOAT, @BSUMA_i FLOAT, @BSUMA_D FLOAT, @BCONT_I CHAR(9), @BSEMN INT
declare @@chek int

declare tmpip cursor for
select subunitate, tip_contract, contract, numar_rata, data_incasarii, numar_chitanta, suma_rata,  
suma_dobanda, suma_incasata, cont_incasare, 1
from inserted where tip_contract='BR'
union 
select subunitate, tip_contract, contract, numar_rata, data_incasarii, numar_chitanta, suma_rata, 
suma_dobanda, suma_incasata, cont_incasare, -1
from deleted  WHERE TIP_CONTRACT='BR'
order by subunitate, TIP_CONTRACT, CONTRACT, data_incasarii, NUMAR_RATA, numar_chitanta

OPEN TMPIP
FETCH NEXT FROM TMPIP INTO @sub, @tip_c, @contr, @numar_rata, @data_i, @numar_chit, @suma_r, @suma_d, @suma_i, @cont_i, @semn
set @gfetch=@@fetch_status
set @bsub=@sub 
set @btip_c=@tip_c
set @bcontr=@contr
set @bdata_i=@data_i
set @bnumar_rata=@numar_rata
set @bnumar_chit=@numar_chit
SET @bcont_i=@cont_i

while @gfetch=0

begin
set @valoare1=0
SET @valoare2=0

while @gfetch=0 and  @bsub=@sub and @btip_c=@tip_c and @Bcontr=@contr and @bdata_i=@data_i and @bnumar_chit=@numar_chit
	begin
	set @valoare1=@valoare1+@semn*@suma_R
	set @valoare2=@valoare2+@semn*@suma_D
	FETCH NEXT FROM TMPIP INTO @sub, @tip_c, @contr,@numar_rata, @data_i,@numar_chit, @suma_r, @suma_d, @suma_i, @cont_i, @semn
	set @gfetch=@@fetch_status
end
update pozplin set suma=suma+@valoare1
	WHERE SUBUNITATE=@bsub AND CONT=@bcont_i AND NUMAR=@bnumar_chit AND PLATA_INCASARE='IR' and right(comanda,3)=str(@bnumar_rata,3)
update pozplin set suma=suma+@valoare2
	WHERE SUBUNITATE=@bsub AND CONT=@bcont_i AND NUMAR=@bnumar_chit AND PLATA_INCASARE='IC' and right(comanda,3)=str(@bnumar_rata,3)

delete from pozplin  
	WHERE SUBUNITATE=@bsub AND CONT=@bcont_i AND NUMAR=@bnumar_chit AND PLATA_INCASARE in ('IR','IC') and right(comanda,3)=str(@bnumar_rata,3) and 
	suma=0	
 
set @bsub=@sub 
set @btip_c=@tip_c
set @bcontr=@contr
set @bdata_i=@data_i
set @bnumar_rata=@numar_rata
set @bnumar_chit=@numar_chit
set @bcont_i=@cont_i

end
close tmpip
deallocate tmpip
END
