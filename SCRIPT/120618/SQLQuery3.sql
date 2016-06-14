create procedure OPGenCMdinTE @sub char(9), @tip char(2), @Numar char(8), @Data datetime as
--declare @sub char(9), @tip char(2), @Numar char(8), @Data datetime

DECLARE @RC int, @Gestiune char(9), @Cod char(20), @CodIntrare char(13), @Cantitate float
	, @LM char(9), @Comanda char(40), @Barcod char(30), @Factura char(20),@Schimb int, @Serie char(20), @Utilizator char(10)
	, @Jurnal char(3), @Stare int, @NrPozitie int, @PozitieNoua int, @CtCoresp char(13)

set @Utilizator=dbo.fIaUtilizator(null)

declare pozte cursor for
select gestiune=p.gestiune_primitoare, cod=p.cod, codintrare=p.grupa, cantitate=p.cantitate
	, lm=p.loc_de_munca, comanda=p.comanda, barcod=p.barcod, Factura='', schimb=0, serie=null, Utilizator=@Utilizator
	, jurnal=p.Jurnal, Stare=p.Stare, nrpozitie=p.Numar_pozitie, pozitienoua=0, ctcoresp=''
from pozdoc P
where p.tip='TE'

fetch next from pozte 
into @Numar 
  ,@Data 
  ,@Gestiune
  ,@Cod
  ,@CodIntrare
  ,@Cantitate
  ,@LM
  ,@Comanda
  ,@Barcod
  ,@Factura
  ,@Schimb
  ,@Serie
  ,@Utilizator
  ,@Jurnal
  ,@Stare
  ,@NrPozitie 
  ,@PozitieNoua
  ,@CtCoresp

while @@FETCH_STATUS=0
begin

	EXECUTE @RC = scriuCM 
	   @Numar=@Numar OUTPUT
	  ,@Data=@Data OUTPUT
	  ,@Gestiune=@Gestiune
	  ,@Cod=@Cod
	  ,@CodIntrare=@CodIntrare
	  ,@Cantitate=@Cantitate
	  ,@LM=@LM
	  ,@Comanda=@Comanda
	  ,@Barcod=@Barcod
	  ,@Factura=@Factura
	  ,@Schimb=@Schimb
	  ,@Serie=@Serie
	  ,@Utilizator=@Utilizator
	  ,@Jurnal=@Jurnal
	  ,@Stare=@Stare
	  ,@NrPozitie=@NrPozitie OUTPUT
	  ,@PozitieNoua=@PozitieNoua
	  ,@CtCoresp=@CtCoresp
	  
	fetch next from pozte 
	into @Numar 
	  ,@Data 
	  ,@Gestiune
	  ,@Cod
	  ,@CodIntrare
	  ,@Cantitate
	  ,@LM
	  ,@Comanda
	  ,@Barcod
	  ,@Factura
	  ,@Schimb
	  ,@Serie
	  ,@Utilizator
	  ,@Jurnal
	  ,@Stare
	  ,@NrPozitie 
	  ,@PozitieNoua
	  ,@CtCoresp
end  
GO

